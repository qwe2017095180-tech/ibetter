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
import '../../domain/services/schedule_service.dart';
import 'widgets/detail_bottom_actions.dart';
import 'widgets/detail_monthly_calendar.dart';
import 'widgets/detail_stats_tabs.dart';
import 'widgets/detail_yearly_stats.dart';
import 'widgets/project_card.dart';

/// Project Detail & Stats Page showing summary card, monthly/yearly stats, and edit/share actions.
class ProjectDetailPage extends ConsumerStatefulWidget {
  const ProjectDetailPage({super.key, required this.habitId});

  final int habitId;

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  DetailStatsTab _activeTab = DetailStatsTab.monthly;
  late DateTime _displayedMonth;
  late int _displayedYear;

  @override
  void initState() {
    super.initState();
    final today = dk.dateOnly(ref.read(todayProvider));
    _displayedMonth = DateTime(today.year, today.month, 1);
    _displayedYear = today.year;
  }

  void _shiftMonth(int delta, DateTime today) {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1);
    final currentMonth = DateTime(today.year, today.month, 1);
    if (next.isAfter(currentMonth)) return;
    setState(() => _displayedMonth = next);
  }

  void _shiftYear(int delta, DateTime today) {
    final next = _displayedYear + delta;
    if (next > today.year) return;
    setState(() => _displayedYear = next);
  }

  Future<void> _onDayTap(
    BuildContext context, {
    required Habit habit,
    required DateTime day,
    required DateTime today,
    required Set<String> doneDates,
    required ScheduleService scheduleService,
  }) async {
    final d = dk.dateOnly(day);
    final t = dk.dateOnly(today);
    if (d.isAfter(t)) {
      _showSnackBar(context, '不能为未来打卡');
      return;
    }
    if (!scheduleService.canCheckIn(habit, d, today: t)) {
      final msg = d.isBefore(dk.dateOnly(habit.startDate))
          ? '不能在起始日之前打卡'
          : '该日不在时间规划内';
      _showSnackBar(context, msg);
      return;
    }
    final key = dk.dateKey(d);
    final isDone = doneDates.contains(key);
    await ref
        .read(checkInRepositoryProvider)
        .setCount(habit.id, key, isDone ? 0 : habit.dailyTarget);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final checkIns = ref.watch(allCheckInsProvider).asData?.value ?? const <CheckIn>[];
    final today = dk.dateOnly(ref.watch(todayProvider));
    final scheduleService = ref.watch(scheduleServiceProvider);
    final statsService = ref.watch(statsServiceProvider);

    final loadedHabit = habitsAsync.asData?.value
        .where((h) => h.id == widget.habitId)
        .firstOrNull;

    final canGoNextMonth = _displayedMonth.year < today.year ||
        (_displayedMonth.year == today.year && _displayedMonth.month < today.month);
    final canGoNextYear = _displayedYear < today.year;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: AppBrand.name,
        leading: PillIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: loadedHabit == null
            ? null
            : _TopEditPillButton(
                key: const ValueKey('detail_top_edit_button'),
                onPressed: () => context.push(Routes.editHabit(widget.habitId)),
              ),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败：$error')),
        data: (habits) {
          final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
          if (habit == null) {
            return const Center(
              child: Text(
                '未找到该项目',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }

          final doneDates = statsService.doneDates(habit, checkIns);

          return ListView(
            padding: const EdgeInsets.only(top: 6, bottom: 20),
            children: [
              ProjectCard(
                habit: habit,
                onTap: () {},
                onLongPress: () {},
              ),
              DetailStatsTabs(
                activeTab: _activeTab,
                onTabSelected: (tab) => setState(() => _activeTab = tab),
                child: _activeTab == DetailStatsTab.monthly
                    ? DetailMonthlyCalendar(
                        displayedMonth: _displayedMonth,
                        today: today,
                        doneDates: doneDates,
                        weekStartsOnMonday: ref
                                .watch(appPrefsProvider)
                                .asData
                                ?.value
                                .weekStartsOnMonday ??
                            false,
                        onPrevMonth: () => _shiftMonth(-1, today),
                        onNextMonth: canGoNextMonth ? () => _shiftMonth(1, today) : null,
                        onDayTap: (day) => _onDayTap(
                          context,
                          habit: habit,
                          day: day,
                          today: today,
                          doneDates: doneDates,
                          scheduleService: scheduleService,
                        ),
                      )
                    : DetailYearlyStats(
                        habit: habit,
                        year: _displayedYear,
                        today: today,
                        doneDates: doneDates,
                        scheduleService: scheduleService,
                        onPrevYear: () => _shiftYear(-1, today),
                        onNextYear: canGoNextYear ? () => _shiftYear(1, today) : null,
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: loadedHabit == null
          ? null
          : DetailBottomActions(
              onEdit: () => context.push(Routes.editHabit(widget.habitId)),
              onShare: () => showHabitShareDialog(
                context,
                habit: loadedHabit,
                stats: ref.read(habitStatsProvider(loadedHabit.id)),
                onShared: () => ref.read(appPrefsProvider.notifier).recordShare(today),
              ),
            ),
    );
  }
}

class _TopEditPillButton extends StatelessWidget {
  const _TopEditPillButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 2), blurRadius: 2)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onPressed,
          child: const Center(
            child: Text(
              '编辑',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
