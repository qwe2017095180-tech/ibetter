import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/date_key.dart' as dk;
import '../../../domain/models/habit.dart';
import '../../../domain/services/schedule_service.dart';

/// Computed summary for a single calendar year of a habit.
class YearlyStatsSummary {
  const YearlyStatsSummary({
    required this.year,
    required this.doneDays,
    required this.eligibleDays,
    required this.completionRatePercent,
    required this.monthDoneCounts,
  });

  final int year;
  final int doneDays;
  final int eligibleDays;
  final int completionRatePercent;
  final List<int> monthDoneCounts;
}

/// Computes completed days, eligible scheduled days, and per-month counts for [year].
YearlyStatsSummary computeYearlyStats({
  required Habit habit,
  required Set<String> doneDates,
  required int year,
  required DateTime today,
  required ScheduleService scheduleService,
}) {
  final t = dk.dateOnly(today);
  final start = dk.dateOnly(habit.startDate);
  final yearStart = DateTime(year, 1, 1);
  final yearEnd = DateTime(year, 12, 31);

  var totalDone = 0;
  final monthCounts = List<int>.filled(12, 0);
  for (var m = 1; m <= 12; m++) {
    final daysCount = dk.daysInMonth(DateTime(year, m, 1));
    var count = 0;
    for (var d = 1; d <= daysCount; d++) {
      if (doneDates.contains(dk.dateKey(DateTime(year, m, d)))) {
        count++;
      }
    }
    monthCounts[m - 1] = count;
    totalDone += count;
  }

  final from = start.isAfter(yearStart) ? start : yearStart;
  final to = t.isBefore(yearEnd) ? t : yearEnd;
  var eligible = 0;
  if (!from.isAfter(to)) {
    for (var d = from; !d.isAfter(to); d = dk.addDays(d, 1)) {
      if (scheduleService.isScheduledOn(habit, d)) {
        eligible++;
      }
    }
  }

  final rate = eligible == 0 ? 0 : ((totalDone / eligible) * 100).round().clamp(0, 100);
  return YearlyStatsSummary(
    year: year,
    doneDays: totalDone,
    eligibleDays: eligible,
    completionRatePercent: rate,
    monthDoneCounts: monthCounts,
  );
}

/// Yearly stats view showing year selector, summary metrics, and 12-month mini heatmap.
class DetailYearlyStats extends StatelessWidget {
  const DetailYearlyStats({
    super.key,
    required this.habit,
    required this.year,
    required this.today,
    required this.doneDates,
    required this.scheduleService,
    required this.onPrevYear,
    required this.onNextYear,
  });

  final Habit habit;
  final int year;
  final DateTime today;
  final Set<String> doneDates;
  final ScheduleService scheduleService;
  final VoidCallback onPrevYear;
  final VoidCallback? onNextYear;

  static const _doneSquareColor = Color(0xFF5698DF);
  static const _undoneSquareColor = Color(0xFFEAEAEA);

  @override
  Widget build(BuildContext context) {
    final summary = computeYearlyStats(
      habit: habit,
      doneDates: doneDates,
      year: year,
      today: today,
      scheduleService: scheduleService,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('year_prev_button'),
                tooltip: '上一年',
                onPressed: onPrevYear,
                icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 26),
              ),
              Expanded(
                child: Text(
                  '$year年',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('year_next_button'),
                tooltip: '下一年',
                onPressed: onNextYear,
                icon: Icon(
                  Icons.chevron_right,
                  color: onNextYear != null ? AppColors.primary : AppColors.textHint,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.calendarCell,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '本年完成 ${summary.doneDays} 天',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '完成率 ${summary.completionRatePercent}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var month = 1; month <= 12; month++) ...[
            if (month > 1) const SizedBox(height: 8),
            _MonthHeatmapRow(
              key: ValueKey('year_month_row_$month'),
              year: year,
              month: month,
              monthDoneCount: summary.monthDoneCounts[month - 1],
              doneDates: doneDates,
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthHeatmapRow extends StatelessWidget {
  const _MonthHeatmapRow({
    super.key,
    required this.year,
    required this.month,
    required this.monthDoneCount,
    required this.doneDates,
  });

  final int year;
  final int month;
  final int monthDoneCount;
  final Set<String> doneDates;

  @override
  Widget build(BuildContext context) {
    final daysCount = dk.daysInMonth(DateTime(year, month, 1));
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            '$month月',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 1.5;
              final size = ((constraints.maxWidth - 30 * gap) / 31).clamp(3.0, 10.0);
              return Row(
                children: [
                  for (var d = 1; d <= daysCount; d++) ...[
                    if (d > 1) const SizedBox(width: gap),
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: doneDates.contains(dk.dateKey(DateTime(year, month, d)))
                            ? DetailYearlyStats._doneSquareColor
                            : DetailYearlyStats._undoneSquareColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 34,
          child: Text(
            '$monthDoneCount天',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
