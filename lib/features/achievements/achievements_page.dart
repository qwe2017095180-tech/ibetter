import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/prefs/app_prefs.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/date_key.dart' as dk;
import '../../../domain/models/check_in.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/services/achievement_service.dart';
import '../home/widgets/celebration_banner.dart';
import '../home/widgets/perfect_day_dialog.dart';
import '../icon_picker/icon_registry.dart';
import 'widgets/achievement_badge.dart';
import 'widgets/achievement_list_sheet.dart';
import 'widgets/achievement_unlock_dialog.dart';
import 'widgets/achievement_utils.dart';
import 'widgets/report_card_sheet.dart';
import 'widgets/weekly_chart.dart';

/// "我的成就" tab displaying KPI summary, yearly progress, recent heatmap,
/// interactive weekly chart, and categorized milestone achievement cards.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  int? _selectedYear;
  int _lastScheduledSeenCount = -1;

  Future<void> _openAchievementDetail(
    BuildContext context,
    AchievementItem item, {
    required List<Habit> habits,
    required List<CheckIn> checkIns,
  }) async {
    if (!item.unlocked) return;
    if (item.id == 'perfect_day' && item.latestDate != null) {
      final targetKey = item.latestDate!;
      final targetDate = dk.parseDateKey(targetKey);
      final scheduleService = ref.read(scheduleServiceProvider);
      final statsService = ref.read(statsServiceProvider);
      final countByHabit = <int, int>{
        for (final c in checkIns)
          if (c.date == targetKey) c.habitId: c.count,
      };
      final completedHabits = <PerfectDayHabitItem>[
        for (final h in habits)
          if (h.isActive &&
              scheduleService.isScheduledOn(h, targetDate) &&
              scheduleService.isDone(h, countByHabit[h.id] ?? 0))
            PerfectDayHabitItem(
              habit: h,
              totalDays: statsService.doneDates(h, checkIns).length,
            ),
      ];
      await showPerfectDayDialog(
        context,
        date: targetDate,
        completedHabits: completedHabits,
      );
      return;
    }
    await showAchievementUnlockDialog(context, items: [item]);
  }

  @override
  Widget build(BuildContext context) {
    final today = dk.dateOnly(ref.watch(todayProvider));
    final selectedYear = (_selectedYear ?? today.year).clamp(1900, today.year);
    final habitsAsync = ref.watch(habitsProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    final prefsAsync = ref.watch(appPrefsProvider);
    final achievementService = ref.watch(achievementServiceProvider);
    final stats = ref.watch(overallStatsProvider);

    final hasData = habitsAsync.hasValue && checkInsAsync.hasValue;
    final prefs = prefsAsync.asData?.value;
    if (hasData &&
        prefs != null &&
        stats.totalAchievementCount > 0 &&
        stats.totalAchievementCount > prefs.seenAchievementCount &&
        _lastScheduledSeenCount != stats.totalAchievementCount) {
      final targetCount = stats.totalAchievementCount;
      _lastScheduledSeenCount = targetCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(appPrefsProvider.notifier).markAchievementsSeen(targetCount);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _AchievementsTopBar(
        onTapReportCard: !hasData
            ? null
            : () {
                void openSheet() {
                  showReportCardSheet(
                    context,
                    stats: stats,
                    today: today,
                    onShared: () =>
                        ref.read(appPrefsProvider.notifier).recordShare(today),
                  );
                }

                if (prefs?.reportDisplayStyle == CelebrationStyle.banner) {
                  showCelebrationBanner(
                    context,
                    title: '新成绩单已生成',
                    subtitle: '点击查看 ${today.year} 年打卡成绩单',
                    color: AppColors.primary,
                    onTap: () {
                      if (!mounted) return;
                      openSheet();
                    },
                  );
                } else {
                  openSheet();
                }
              },
      ),
      body: _buildBody(
        context,
        today: today,
        selectedYear: selectedYear,
        habitsAsync: habitsAsync,
        checkInsAsync: checkInsAsync,
        achievementService: achievementService,
        stats: stats,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required DateTime today,
    required int selectedYear,
    required AsyncValue<List<Habit>> habitsAsync,
    required AsyncValue<List<CheckIn>> checkInsAsync,
    required AchievementService achievementService,
    required OverallStats stats,
  }) {
    if (habitsAsync.hasError) {
      return Center(child: Text('加载失败：${habitsAsync.error}'));
    }
    if (checkInsAsync.hasError) {
      return Center(child: Text('加载失败：${checkInsAsync.error}'));
    }
    if (!habitsAsync.hasValue || !checkInsAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final habits = habitsAsync.asData!.value;
    final checkIns = checkInsAsync.asData!.value;
    final dailyCounts = achievementService.dailyCompletionCounts(habits, checkIns);
    final weeklyRecords = achievementService.weeklyRecordsForYear(
      habits,
      checkIns,
      year: selectedYear,
      today: today,
    );

    final singleList = stats.byCategory(AchievementCategory.singleProject);
    final streakList = stats.byCategory(AchievementCategory.streak);
    final taskList = stats.byCategory(AchievementCategory.task);
    final hiddenList = stats.byCategory(AchievementCategory.hidden);
    final specialList = stats.byCategory(AchievementCategory.special);

    final highestList = <AchievementItem>[
      if (stats.highestSingleAchievement != null) stats.highestSingleAchievement!,
      if (stats.highestStreakAchievement != null) stats.highestStreakAchievement!,
    ];

    void handleTap(AchievementItem item) =>
        _openAchievementDetail(context, item, habits: habits, checkIns: checkIns);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _KpiRow(stats: stats),
        _YearProgressBanner(year: today.year, stats: stats),
        _MyRecordCard(
          today: today,
          stats: stats,
          dailyCounts: dailyCounts,
          onTapSummary: () => showAchievementsSheet(context, stats: stats, today: today),
        ),
        WeeklyChartCard(
          selectedYear: selectedYear,
          maxYear: today.year,
          weeks: weeklyRecords,
          onYearChanged: (year) => setState(() => _selectedYear = year),
        ),
        _LatestAchievementCard(
          today: today,
          latest: stats.latestAchievement,
          onTapItem: handleTap,
        ),
        if (highestList.isNotEmpty)
          _AchievementSectionCard(
            key: const ValueKey('achievement_section_highest'),
            sectionKey: 'highest',
            title: '最高成就',
            items: highestList,
            today: today,
            onTapItem: handleTap,
          ),
        _AchievementSectionCard(
          key: const ValueKey('achievement_section_singleProject'),
          sectionKey: 'singleProject',
          title: '单项目成就',
          trailingCount: '${singleList.length}',
          items: singleList,
          today: today,
          onTapItem: handleTap,
        ),
        _AchievementSectionCard(
          key: const ValueKey('achievement_section_streak'),
          sectionKey: 'streak',
          title: '连续成就',
          trailingCount: '${streakList.length}',
          items: streakList,
          today: today,
          onTapItem: handleTap,
        ),
        _AchievementSectionCard(
          key: const ValueKey('achievement_section_task'),
          sectionKey: 'task',
          title: '任务成就',
          trailingCount: '${taskList.length}',
          items: taskList,
          today: today,
          onTapItem: handleTap,
        ),
        _AchievementSectionCard(
          key: const ValueKey('achievement_section_hidden'),
          sectionKey: 'hidden',
          title: '隐藏成就',
          trailingCount: '${hiddenList.length}',
          items: hiddenList,
          today: today,
          onTapItem: handleTap,
        ),
        _AchievementSectionCard(
          key: const ValueKey('achievement_section_special'),
          sectionKey: 'special',
          title: '特殊成就',
          trailingCount: '${specialList.length}',
          items: specialList,
          today: today,
          onTapItem: handleTap,
        ),
      ],
    );
  }
}

class _AchievementsTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _AchievementsTopBar({this.onTapReportCard});

  final VoidCallback? onTapReportCard;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Text(
                  '我的成就',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        offset: Offset(0, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      key: const ValueKey('report_card_button'),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: onTapReportCard,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HabitIcon('achievement/sports_medal', size: 22),
                            SizedBox(width: 4),
                            Text(
                              '成绩单',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.stats});

  final OverallStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('kpi_row'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _KpiColumn(
            key: const ValueKey('kpi_project_count'),
            label: '项目数',
            value: stats.projectCount,
          ),
          _KpiColumn(
            key: const ValueKey('kpi_recorded_days'),
            label: '记录天数',
            value: stats.recordedDays,
          ),
          _KpiColumn(
            key: const ValueKey('kpi_total_completions'),
            label: '达成次数',
            value: stats.totalCompletions,
          ),
          _KpiColumn(
            key: const ValueKey('kpi_longest_streak'),
            label: '最长连续',
            value: stats.longestStreak,
          ),
        ],
      ),
    );
  }
}

class _KpiColumn extends StatelessWidget {
  const _KpiColumn({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A4A),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearProgressBanner extends StatelessWidget {
  const _YearProgressBanner({required this.year, required this.stats});

  final int year;
  final OverallStats stats;

  static const _normalStyle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  static const _boldStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFF333333),
  );

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBDBDBD), width: 1.2),
            ),
            child: Text(
              '$year',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  style: _normalStyle,
                  children: [
                    const TextSpan(text: '第 '),
                    TextSpan(text: '${stats.weekOfYear}', style: _boldStyle),
                    const TextSpan(text: ' 周  第 '),
                    TextSpan(text: '${stats.dayOfYear}', style: _boldStyle),
                    const TextSpan(text: ' 天  今年还有 '),
                    TextSpan(text: '${stats.remainingDaysInYear}', style: _boldStyle),
                    const TextSpan(text: ' 天'),
                  ],
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRecordCard extends StatelessWidget {
  const _MyRecordCard({
    required this.today,
    required this.stats,
    required this.dailyCounts,
    required this.onTapSummary,
  });

  final DateTime today;
  final OverallStats stats;
  final Map<String, int> dailyCounts;
  final VoidCallback onTapSummary;

  static const _lineStyle = TextStyle(
    fontSize: 15,
    color: AppColors.textSecondary,
    height: 1.55,
  );
  static const _boldStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Color(0xFF333333),
  );

  @override
  Widget build(BuildContext context) {
    final months = recentThreeMonths(today);

    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                '我的记录',
                style: TextStyle(fontSize: 17, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${today.year}',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('my_record_summary_row'),
              borderRadius: BorderRadius.circular(12),
              onTap: onTapSummary,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const HabitIcon('achievement/shield', size: 68),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: _lineStyle,
                              children: [
                                const TextSpan(text: '记录天数 '),
                                TextSpan(text: '${stats.yearRecordedDays}', style: _boldStyle),
                                const TextSpan(text: ' 天'),
                              ],
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              style: _lineStyle,
                              children: [
                                const TextSpan(text: '完成最多的项目 '),
                                TextSpan(
                                  text: stats.topHabitName ?? '暂无',
                                  style: _boldStyle,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text.rich(
                            TextSpan(
                              style: _lineStyle,
                              children: [
                                const TextSpan(text: '获得成就 '),
                                TextSpan(text: '${stats.totalAchievementCount}', style: _boldStyle),
                                const TextSpan(text: ' 次'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: AppColors.textHint, size: 22),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < months.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _MonthHeatmapRow(monthStart: months[i], dailyCounts: dailyCounts),
          ],
        ],
      ),
    );
  }
}

class _MonthHeatmapRow extends StatelessWidget {
  const _MonthHeatmapRow({
    required this.monthStart,
    required this.dailyCounts,
  });

  final DateTime monthStart;
  final Map<String, int> dailyCounts;

  Color _colorForCount(int count) {
    if (count <= 0) return const Color(0xFFE6E6E6);
    if (count == 1) return const Color(0xFF6BD98A);
    if (count == 2) return const Color(0xFF2DB84B);
    return const Color(0xFF159835);
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = dk.daysInMonth(monthStart);

    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            '${monthStart.month}月',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 2.0;
              const maxSlots = 31;
              final available = math.max(0.0, constraints.maxWidth - (maxSlots - 1) * gap);
              final cellSize = (available / maxSlots).clamp(2.0, 14.0);
              return Row(
                children: [
                  for (var day = 1; day <= totalDays; day++) ...[
                    if (day > 1) const SizedBox(width: gap),
                    Builder(
                      builder: (context) {
                        final cellDate = DateTime(monthStart.year, monthStart.month, day);
                        final key = dk.dateKey(cellDate);
                        final count = dailyCounts[key] ?? 0;
                        return Container(
                          key: ValueKey('heatmap_$key'),
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: _colorForCount(count),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LatestAchievementCard extends StatelessWidget {
  const _LatestAchievementCard({
    required this.today,
    required this.latest,
    required this.onTapItem,
  });

  final DateTime today;
  final AchievementItem? latest;
  final ValueChanged<AchievementItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    final item = latest;

    return SectionCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('latest_achievement_card'),
          onTap: item == null ? null : () => onTapItem(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '最新成就',
                  style: TextStyle(fontSize: 17, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                if (item != null)
                  _AchievementRowContent(
                    item: item,
                    today: today,
                    badgeSize: 60,
                  )
                else
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF3F3F3),
                        ),
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          size: 32,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          '完成打卡即可解锁你的第一个成就',
                          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementSectionCard extends StatelessWidget {
  const _AchievementSectionCard({
    super.key,
    required this.sectionKey,
    required this.title,
    this.trailingCount,
    required this.items,
    required this.today,
    required this.onTapItem,
  });

  final String sectionKey;
  final String title;
  final String? trailingCount;
  final List<AchievementItem> items;
  final DateTime today;
  final ValueChanged<AchievementItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, color: AppColors.textSecondary),
                ),
                if (trailingCount != null) ...[
                  const Spacer(),
                  Text(
                    trailingCount!,
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 0.8,
                indent: 16,
                endIndent: 16,
                color: AppColors.divider,
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('achievement_row_${sectionKey}_${items[i].id}'),
                onTap: items[i].unlocked ? () => onTapItem(items[i]) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: _AchievementRowContent(
                    item: items[i],
                    today: today,
                    badgeSize: 58,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementRowContent extends StatelessWidget {
  const _AchievementRowContent({
    required this.item,
    required this.today,
    this.badgeSize = 58,
  });

  final AchievementItem item;
  final DateTime today;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    final dateLabel = item.unlocked ? formatAchievementDate(item.latestDate, today) : '';
    final metaText = dateLabel.isNotEmpty
        ? '获得${item.count}次  |  $dateLabel'
        : '获得${item.count}次';

    return Row(
      children: [
        AchievementBadge(item: item, size: badgeSize),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.displayTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.displaySubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metaText,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (item.unlocked) ...[
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 22),
        ],
      ],
    );
  }
}
