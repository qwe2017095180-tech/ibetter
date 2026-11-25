import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../domain/date_key.dart' as dk;
import '../../domain/models/check_in.dart';
import '../../domain/models/habit.dart';
import '../qingsong/qingsong_providers.dart';
import 'home_providers.dart';
import 'widgets/agenda_section.dart';
import 'widgets/calendar_section.dart';
import 'widgets/habit_check_in_card.dart';
import 'widgets/home_empty_state.dart';
import 'widgets/home_footer.dart';

/// Home screen: collapsible calendar + 今日日程 + scheduled habit cards for the selected day.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _initialSynced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSilentSync());
  }

  void _runSilentSync() {
    if (_initialSynced || !mounted) return;
    _initialSynced = true;
    unawaited(ref.read(qingsongSyncProvider.notifier).sync(silent: true));
  }

  Future<void> _onRefresh() async {
    final config = await ref.read(qingsongConfigProvider.future);
    if (!config.isConfigured) return;
    final outcome = await ref.read(qingsongSyncProvider.notifier).sync();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(outcome.message)));
  }

  void _showFutureDisabledMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('不能为未来打卡')));
  }

  Future<void> _onTapCheck(
    BuildContext context, {
    required Habit habit,
    required DateTime selectedDate,
    required DateTime today,
    required int currentCount,
    required bool canCheckIn,
  }) async {
    if (!canCheckIn) {
      _showFutureDisabledMessage(context);
      return;
    }
    final key = dk.dateKey(selectedDate);
    final nextCount = habit.dailyTarget <= 1
        ? (currentCount >= 1 ? 0 : 1)
        : (currentCount < habit.dailyTarget
            ? currentCount + 1
            : habit.dailyTarget);
    if (nextCount == currentCount) return;
    await ref.read(checkInRepositoryProvider).setCount(habit.id, key, nextCount);
  }

  Future<void> _onLongPressCheck(
    BuildContext context, {
    required Habit habit,
    required DateTime selectedDate,
    required int currentCount,
    required bool canCheckIn,
  }) async {
    if (!canCheckIn) {
      _showFutureDisabledMessage(context);
      return;
    }
    if (habit.dailyTarget <= 1 || currentCount <= 0) return;
    await ref
        .read(checkInRepositoryProvider)
        .setCount(habit.id, dk.dateKey(selectedDate), currentCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    final today = dk.dateOnly(ref.watch(todayProvider));
    final selectedDate = dk.dateOnly(ref.watch(selectedDateProvider));
    final selectedKey = dk.dateKey(selectedDate);

    final habitsAsync = ref.watch(habitsProvider);
    final checkIns =
        ref.watch(checkInsByDateProvider(selectedKey)).asData?.value ??
            const <CheckIn>[];
    final scheduleService = ref.watch(scheduleServiceProvider);

    final countByHabit = {
      for (final c in checkIns) c.habitId: c.count,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'iBetter',
        leading: PillIconButton(
          icon: Icons.access_time,
          tooltip: '回到今天',
          onPressed: () {
            ref.read(selectedDateProvider.notifier).select(today);
            ref.read(calendarWindowStartProvider.notifier).jumpToDate(today);
          },
        ),
        trailing: PillIconButton(
          icon: Icons.add,
          tooltip: '创建项目',
          onPressed: () => context.push(Routes.editor),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            const CalendarSection(),
            const SizedBox(height: 8),
            const AgendaSection(),
            const SizedBox(height: 6),
            habitsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('加载失败：$err')),
              ),
              data: (habits) {
                final scheduled = habits
                    .where(
                      (h) =>
                          h.isActive &&
                          scheduleService.isScheduledOn(h, selectedDate),
                    )
                    .toList();

                if (scheduled.isEmpty) {
                  return HomeEmptyState(
                    hasAnyHabits: habits.isNotEmpty,
                    onCreateHabit: () => context.push(Routes.editor),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final habit in scheduled)
                      Builder(
                        builder: (context) {
                          final count = countByHabit[habit.id] ?? 0;
                          final canCheckIn = scheduleService.canCheckIn(
                            habit,
                            selectedDate,
                            today: today,
                          );
                          return HabitCheckInCard(
                            habit: habit,
                            count: count,
                            isDone: scheduleService.isDone(habit, count),
                            canCheckIn: canCheckIn,
                            onTapCard: () =>
                                context.push(Routes.editHabit(habit.id)),
                            onTapCheck: () => _onTapCheck(
                              context,
                              habit: habit,
                              selectedDate: selectedDate,
                              today: today,
                              currentCount: count,
                              canCheckIn: canCheckIn,
                            ),
                            onLongPressCheck: habit.dailyTarget > 1
                                ? () => _onLongPressCheck(
                                      context,
                                      habit: habit,
                                      selectedDate: selectedDate,
                                      currentCount: count,
                                      canCheckIn: canCheckIn,
                                    )
                                : null,
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }
}
