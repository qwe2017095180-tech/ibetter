import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/date_key.dart' as dk;

const _sundayFirstLabels = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
const _mondayFirstLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
const _monthAbbr = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// Monthly stats calendar grid with prev/next month controls and interactive check-in cells.
class DetailMonthlyCalendar extends StatelessWidget {
  const DetailMonthlyCalendar({
    super.key,
    required this.displayedMonth,
    required this.today,
    required this.doneDates,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
    this.weekStartsOnMonday = false,
  });

  final DateTime displayedMonth;
  final DateTime today;
  final Set<String> doneDates;
  final VoidCallback onPrevMonth;
  final VoidCallback? onNextMonth;
  final ValueChanged<DateTime> onDayTap;
  final bool weekStartsOnMonday;

  static const Color completedCellFill = Color(0xFF5698DF);

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final gridStart = dk.startOfWeek(firstOfMonth, weekStartsOnMonday: weekStartsOnMonday);
    final weekdayLabels = weekStartsOnMonday ? _mondayFirstLabels : _sundayFirstLabels;
    final days = List<DateTime>.generate(42, (i) => dk.addDays(gridStart, i));
    final abbr = _monthAbbr[displayedMonth.month - 1];
    final headerText = displayedMonth.year == today.year
        ? '$abbr ${displayedMonth.month}月'
        : '${displayedMonth.year} $abbr ${displayedMonth.month}月';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('month_prev_button'),
                tooltip: '上个月',
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 26),
              ),
              Expanded(
                child: Text(
                  headerText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('month_next_button'),
                tooltip: '下个月',
                onPressed: onNextMonth,
                icon: Icon(
                  Icons.chevron_right,
                  color: onNextMonth != null ? AppColors.primary : AppColors.textHint,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = (constraints.maxWidth - 6) / 7;
              final cellHeight = cellWidth.clamp(40.0, 52.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < 6; r++) ...[
                    if (r > 0) const SizedBox(height: 1),
                    Row(
                      children: [
                        for (var c = 0; c < 7; c++) ...[
                          if (c > 0) const SizedBox(width: 1),
                          Expanded(
                            child: _MonthDayCell(
                              day: days[r * 7 + c],
                              height: cellHeight,
                              inDisplayedMonth:
                                  days[r * 7 + c].year == displayedMonth.year &&
                                      days[r * 7 + c].month == displayedMonth.month,
                              isDone: doneDates.contains(dk.dateKey(days[r * 7 + c])),
                              isToday: dk.isSameDay(days[r * 7 + c], today),
                              isFuture: days[r * 7 + c].isAfter(today),
                              onTap: () => onDayTap(days[r * 7 + c]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.height,
    required this.inDisplayedMonth,
    required this.isDone,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime day;
  final double height;
  final bool inDisplayedMonth;
  final bool isDone;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final BoxBorder? border;
    final Color textColor;
    final FontWeight fontWeight;

    if (isDone) {
      bgColor = DetailMonthlyCalendar.completedCellFill;
      border = Border.all(color: AppColors.primary, width: 2);
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
    } else {
      bgColor = AppColors.calendarCell;
      border = null;
      if (isToday && inDisplayedMonth) {
        textColor = AppColors.primary;
        fontWeight = FontWeight.w600;
      } else if (inDisplayedMonth && !isFuture) {
        textColor = AppColors.textSecondary;
        fontWeight = FontWeight.w400;
      } else {
        textColor = AppColors.textHint;
        fontWeight = FontWeight.w400;
      }
    }

    return GestureDetector(
      key: ValueKey('detail_month_day_${dk.dateKey(day)}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          border: border,
        ),
        child: day.day == 1
            ? Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_monthAbbr[day.month - 1]}\n',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    TextSpan(
                      text: '${day.month}月',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: fontWeight,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              )
            : Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 18,
                  height: 1.0,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}
