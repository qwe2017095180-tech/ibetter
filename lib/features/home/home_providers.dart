import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/date_key.dart' as dk;
import '../../domain/models/check_in.dart';

/// Inclusive `yyyy-MM-dd` range key with structural equality for `.family`.
typedef DateRangeKey = ({String from, String to});

/// Whether the home calendar grid is expanded (5 rows) or collapsed (1 row).
class CalendarExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;

  void setExpanded(bool expanded) => state = expanded;
}

final calendarExpandedProvider =
    NotifierProvider<CalendarExpandedNotifier, bool>(CalendarExpandedNotifier.new);

/// Start Sunday of the 5-week expanded calendar window.
///
/// Defaults to the Sunday of the week 1 week before [todayProvider]'s week so
/// today appears in row 2. Automatically recenters if [selectedDateProvider]
/// moves outside the visible 35-day window.
class CalendarWindowStartNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final today = dk.dateOnly(ref.watch(todayProvider));
    ref.listen<DateTime>(selectedDateProvider, (_, next) {
      final d = dk.dateOnly(next);
      if (!ref.read(calendarExpandedProvider)) {
        state = dk.addDays(dk.startOfWeek(d), -7);
        return;
      }
      final end = dk.addDays(state, 34);
      if (d.isBefore(state) || d.isAfter(end)) {
        state = dk.addDays(dk.startOfWeek(d), -7);
      }
    });
    return dk.addDays(dk.startOfWeek(today), -7);
  }

  /// Moves the 5-week window by [weeks] (positive = forward, negative = back).
  void shiftWeeks(int weeks) {
    state = dk.addDays(state, weeks * 7);
  }

  /// Recenters the 5-week window so [date]'s week sits in row 2.
  void jumpToDate(DateTime date) {
    state = dk.addDays(dk.startOfWeek(dk.dateOnly(date)), -7);
  }
}

final calendarWindowStartProvider =
    NotifierProvider<CalendarWindowStartNotifier, DateTime>(
  CalendarWindowStartNotifier.new,
);

/// Visible calendar days: 35 days when expanded, 7 days when collapsed.
final calendarDaysProvider = Provider<List<DateTime>>((ref) {
  final isExpanded = ref.watch(calendarExpandedProvider);
  if (!isExpanded) {
    final selected = dk.dateOnly(ref.watch(selectedDateProvider));
    final weekStart = dk.startOfWeek(selected);
    return List.generate(7, (i) => dk.addDays(weekStart, i));
  }
  final windowStart = ref.watch(calendarWindowStartProvider);
  return List.generate(35, (i) => dk.addDays(windowStart, i));
});

/// Check-ins for a single `yyyy-MM-dd` date.
final checkInsByDateProvider =
    StreamProvider.family<List<CheckIn>, String>((ref, date) {
  return ref.watch(checkInRepositoryProvider).watchByDate(date);
});

/// Check-ins across an inclusive `yyyy-MM-dd` calendar window.
final checkInsInRangeProvider =
    StreamProvider.family<List<CheckIn>, DateRangeKey>((ref, range) {
  return ref.watch(checkInRepositoryProvider).watchRange(range.from, range.to);
});
