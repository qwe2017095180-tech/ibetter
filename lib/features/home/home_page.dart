import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_brand.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../domain/date_key.dart' as dk;
import '../../domain/models/check_in.dart';
import '../../domain/models/habit.dart';
import '../achievements/widgets/achievement_unlock_dialog.dart';
import '../project_editor/quotes.dart';
import '../qingsong/qingsong_providers.dart';
import 'home_providers.dart';
import 'widgets/agenda_section.dart';
import 'widgets/calendar_section.dart';
import 'widgets/check_in_detail_sheet.dart';
import 'widgets/habit_check_in_card.dart';
import 'widgets/home_empty_state.dart';
import 'widgets/home_footer.dart';
import 'widgets/perfect_day_dialog.dart';

/// Home screen: collapsible calendar + 今日日程 + scheduled habit cards for the selected day.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _initialSynced = false;
  List<String>? _cachedQuotes;

  @override
  void initState() {
    super.initState();
    unawaited(_preloadQuotes());
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSilentSync());
  }

  Future<void> _preloadQuotes() async {
    try {
      final loaded = await ref.read(quotesLoaderProvider)();
      if (mounted) _cachedQuotes = loaded;
    } catch (_) {
      // Fallback quotes remain available if loading fails.
    }
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

  List<CheckIn> _withUpdatedCheckIn(
    List<CheckIn> checkIns, {
    required int habitId,
    required String dateKey,
    required int count,
    required DateTime updatedAt,
  }) {
    var replaced = false;
    final updated = <CheckIn>[];
    for (final c in checkIns) {
      if (c.habitId == habitId && c.date == dateKey) {
        replaced = true;
        updated.add(
          CheckIn(
            id: c.id,
            habitId: c.habitId,
            date: c.date,
            count: count,
            score: c.score,
            mood: c.mood,
            note: c.note,
            updatedAt: updatedAt,
          ),
        );
      } else {
        updated.add(c);
      }
    }
    if (!replaced) {
      updated.add(
        CheckIn(
          id: 0,
          habitId: habitId,
          date: dateKey,
          count: count,
          updatedAt: updatedAt,
        ),
      );
    }
    return updated;
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

    final scheduleService = ref.read(scheduleServiceProvider);
    final wasDone = scheduleService.isDone(habit, currentCount);
    final isNowDone = scheduleService.isDone(habit, nextCount);

    if (wasDone || !isNowDone) {
      await ref
          .read(checkInRepositoryProvider)
          .setCount(habit.id, key, nextCount);
      return;
    }

    final habits = ref.read(habitsProvider).asData?.value ?? const <Habit>[];
    final allCheckInsBefore =
        ref.read(allCheckInsProvider).asData?.value ??
        await ref.read(checkInRepositoryProvider).watchAll().first;

    await ref
        .read(checkInRepositoryProvider)
        .setCount(habit.id, key, nextCount);
    if (!mounted || !context.mounted) return;

    final allCheckInsAfter = _withUpdatedCheckIn(
      allCheckInsBefore,
      habitId: habit.id,
      dateKey: key,
      count: nextCount,
      updatedAt: DateTime.now(),
    );

    final statsService = ref.read(statsServiceProvider);
    final dayBefore = allCheckInsBefore.where((c) => c.date == key);
    final dayAfter = allCheckInsAfter.where((c) => c.date == key);
    final wasAllDone =
        statsService.dayCompletion(habits, dayBefore, selectedDate) == true;
    final isAllDone =
        statsService.dayCompletion(habits, dayAfter, selectedDate) == true;

    if (!wasAllDone && isAllDone) {
      final scheduledHabits = habits
          .where(
            (h) => h.isActive && scheduleService.isScheduledOn(h, selectedDate),
          )
          .toList();
      final completedHabits = [
        for (final h in scheduledHabits)
          PerfectDayHabitItem(
            habit: h,
            totalDays: statsService.doneDates(h, allCheckInsAfter).length,
          ),
      ];
      final quotes = _cachedQuotes ?? fallbackQuotes;
      await showPerfectDayDialog(
        context,
        date: selectedDate,
        completedHabits: completedHabits,
        quote: pickRandomQuote(quotes),
      );
      if (!mounted || !context.mounted) return;
    }

    final newlyUnlocked = ref
        .read(achievementServiceProvider)
        .newlyUnlockedForCheckIn(
          habit: habit,
          date: selectedDate,
          allHabits: habits,
          allCheckInsBefore: allCheckInsBefore,
          allCheckInsAfter: allCheckInsAfter,
          today: today,
        );
    if (newlyUnlocked.isNotEmpty) {
      await showAchievementUnlockDialog(context, items: newlyUnlocked);
    }
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

  void _jumpToToday(DateTime today) {
    ref.read(selectedDateProvider.notifier).select(today);
    ref.read(calendarWindowStartProvider.notifier).jumpToDate(today);
  }

  @override
  Widget build(BuildContext context) {
    final today = dk.dateOnly(ref.watch(todayProvider));
    final selectedDate = dk.dateOnly(ref.watch(selectedDateProvider));
    final selectedKey = dk.dateKey(selectedDate);

    ref.watch(allCheckInsProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final checkIns =
        ref.watch(checkInsByDateProvider(selectedKey)).asData?.value ??
        const <CheckIn>[];
    final scheduleService = ref.watch(scheduleServiceProvider);

    final checkInByHabit = {
      for (final checkIn in checkIns) checkIn.habitId: checkIn,
    };
    final isToday = dk.isSameDay(selectedDate, today);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: AppBrand.name,
        leading: PillIconButton(
          icon: Icons.access_time,
          tooltip: '历史记录',
          onPressed: () => context.push(Routes.history),
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
            if (!isToday)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Center(
                  child: Tooltip(
                    message: '回到今天',
                    child: Material(
                      key: const ValueKey('home_jump_today'),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () => _jumpToToday(today),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.today_rounded,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '回到今天',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
                          final checkIn = checkInByHabit[habit.id];
                          final count = checkIn?.count ?? 0;
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
                            onLongPressCard: () => showCheckInDetailSheet(
                              context,
                              habit: habit,
                              date: selectedKey,
                              checkIn: checkIn,
                              canEditRecord: canCheckIn,
                              save: ({score, mood, note}) => ref
                                  .read(checkInRepositoryProvider)
                                  .saveDetail(
                                    habit.id,
                                    selectedKey,
                                    score: score,
                                    mood: mood,
                                    note: note,
                                  ),
                              editHabit: () =>
                                  context.push(Routes.editHabit(habit.id)),
                            ),
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
