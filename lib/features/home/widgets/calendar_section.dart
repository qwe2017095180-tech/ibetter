import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/prefs/app_prefs.dart';
import '../../../core/providers.dart';
import '../../../domain/date_key.dart' as dk;
import '../../../domain/models/check_in.dart';
import '../../../domain/models/habit.dart';
import '../home_providers.dart';

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

/// Top weekday header row + collapsible, swipeable calendar grid.
class CalendarSection extends ConsumerStatefulWidget {
  const CalendarSection({super.key});

  @override
  ConsumerState<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends ConsumerState<CalendarSection> {
  double _dragDeltaX = 0;

  void _shiftCalendar(int direction) {
    final isExpanded = ref.read(calendarExpandedProvider);
    final selected = dk.dateOnly(ref.read(selectedDateProvider));
    final weekDelta = isExpanded ? 5 * direction : direction;
    if (isExpanded) {
      ref.read(calendarWindowStartProvider.notifier).shiftWeeks(weekDelta);
    }
    ref
        .read(selectedDateProvider.notifier)
        .select(dk.addDays(selected, weekDelta * 7));
  }

  void _toggleExpanded() {
    final wasExpanded = ref.read(calendarExpandedProvider);
    if (wasExpanded) {
      ref.read(calendarExpandedProvider.notifier).setExpanded(false);
    } else {
      final selected = ref.read(selectedDateProvider);
      ref.read(calendarWindowStartProvider.notifier).jumpToDate(selected);
      ref.read(calendarExpandedProvider.notifier).setExpanded(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = dk.dateOnly(ref.watch(todayProvider));
    final selected = dk.dateOnly(ref.watch(selectedDateProvider));
    final isExpanded = ref.watch(calendarExpandedProvider);
    final days = ref.watch(calendarDaysProvider);
    final prefs = ref.watch(appPrefsProvider).asData?.value ?? const AppPrefs();
    final range = (from: dk.dateKey(days.first), to: dk.dateKey(days.last));

    final habits = ref.watch(habitsProvider).asData?.value ?? const <Habit>[];
    final rangeCheckIns =
        ref.watch(checkInsInRangeProvider(range)).asData?.value ??
            const <CheckIn>[];
    final stats = ref.watch(statsServiceProvider);

    final byDate = <String, List<CheckIn>>{};
    for (final c in rangeCheckIns) {
      (byDate[c.date] ??= <CheckIn>[]).add(c);
    }

    final rows = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      rows.add(days.sublist(i, i + 7));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WeekdayHeaderRow(
          weekStartsOnMonday: prefs.weekStartsOnMonday,
          selectedColumn: dk.weekdayColumnIndex(
            selected,
            weekStartsOnMonday: prefs.weekStartsOnMonday,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (_) => _dragDeltaX = 0,
                onHorizontalDragUpdate: (details) =>
                    _dragDeltaX += details.delta.dx,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -200 || _dragDeltaX < -48) {
                    _shiftCalendar(1);
                  } else if (velocity > 200 || _dragDeltaX > 48) {
                    _shiftCalendar(-1);
                  }
                  _dragDeltaX = 0;
                },
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Container(
                    key: const ValueKey('calendar_grid'),
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellWidth = (constraints.maxWidth - 6) / 7;
                        final cellHeight = cellWidth.clamp(40.0, 56.0);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var r = 0; r < rows.length; r++) ...[
                              if (r > 0) const SizedBox(height: 1),
                              Row(
                                children: [
                                  for (var c = 0; c < 7; c++) ...[
                                    if (c > 0) const SizedBox(width: 1),
                                    Expanded(
                                      child: _CalendarDayCell(
                                        day: rows[r][c],
                                        height: cellHeight,
                                        isSelected:
                                            dk.isSameDay(rows[r][c], selected),
                                        isToday:
                                            dk.isSameDay(rows[r][c], today),
                                        isFuture: rows[r][c].isAfter(today),
                                        allDone: stats.dayCompletion(
                                              habits,
                                              byDate[dk.dateKey(rows[r][c])] ??
                                                  const <CheckIn>[],
                                              rows[r][c],
                                            ) ==
                                            true,
                                        doneTheme: prefs.calendarDoneTheme,
                                        onTap: () => ref
                                            .read(selectedDateProvider.notifier)
                                            .select(rows[r][c]),
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
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 0,
              child: _CollapseToggleButton(
                isExpanded: isExpanded,
                onTap: _toggleExpanded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow({
    required this.weekStartsOnMonday,
    required this.selectedColumn,
  });

  final bool weekStartsOnMonday;
  final int selectedColumn;

  @override
  Widget build(BuildContext context) {
    final labels =
        weekStartsOnMonday ? _mondayFirstLabels : _sundayFirstLabels;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        i == selectedColumn ? FontWeight.w600 : FontWeight.w400,
                    color: i == selectedColumn
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.height,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.allDone,
    required this.doneTheme,
    required this.onTap,
  });

  final DateTime day;
  final double height;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final bool allDone;
  final CalendarDoneTheme doneTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    if (allDone) {
      textColor = doneTheme.textColor;
    } else if (isSelected || isToday) {
      textColor = AppColors.primary;
    } else if (isFuture) {
      textColor = AppColors.textHint;
    } else {
      textColor = AppColors.textSecondary;
    }

    final fontWeight =
        (allDone || isSelected || isToday) ? FontWeight.w600 : FontWeight.w400;

    final backgroundColor = allDone
        ? doneTheme.color
        : (isSelected ? Colors.white : AppColors.calendarCell);

    return GestureDetector(
      key: ValueKey('calendar_day_${dk.dateKey(day)}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            if (allDone && doneTheme == CalendarDoneTheme.goldStar)
              const Positioned(
                right: 2,
                top: 2,
                child: Icon(
                  Icons.star_rounded,
                  size: 11,
                  color: Color(0xFFD97706),
                ),
              ),
            Center(
              child: day.day == 1
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _monthAbbr[day.month - 1],
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${day.month}月',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: fontWeight,
                            color: textColor,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.0,
                        fontWeight: fontWeight,
                        color: textColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapseToggleButton extends StatelessWidget {
  const _CollapseToggleButton({
    required this.isExpanded,
    required this.onTap,
  });

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isExpanded ? '收起日历' : '展开日历',
      child: Material(
        key: const ValueKey('calendar_collapse_toggle'),
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.calendarCellBorder),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
