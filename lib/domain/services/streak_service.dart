import '../date_key.dart';
import '../models/habit.dart';
import 'schedule_service.dart';

/// Streak (连续) computation.
///
/// [doneDates] = set of `yyyy-MM-dd` keys where the habit was completed
/// (count >= dailyTarget).
///
/// Unit of the returned streak:
/// - daily / weekdays → days
/// - timesPerWeek → weeks, timesPerMonth → months (consecutive periods meeting quota)
///
/// An unfinished *current* day/period never breaks the streak; it just isn't counted yet.
class StreakService {
  const StreakService([this._schedule = const ScheduleService()]);

  final ScheduleService _schedule;

  /// Safety bound for backward scans (~10 years).
  static const _maxScan = 3700;

  int currentStreak(Habit habit, Set<String> doneDates, {required DateTime today}) {
    final t = dateOnly(today);
    final start = dateOnly(habit.startDate);
    if (t.isBefore(start)) return 0;

    switch (habit.schedule.type) {
      case ScheduleType.daily:
      case ScheduleType.weekdays:
        return _dayStreak(habit, doneDates, t, start);
      case ScheduleType.timesPerWeek:
      case ScheduleType.timesPerMonth:
        return _periodStreak(habit, doneDates, t, start);
    }
  }

  int _dayStreak(Habit habit, Set<String> done, DateTime t, DateTime start) {
    var d = t;
    // Today not finished yet → start counting from the previous scheduled day.
    if (!done.contains(dateKey(d))) d = addDays(d, -1);
    var streak = 0;
    for (var i = 0; i < _maxScan && !d.isBefore(start); i++, d = addDays(d, -1)) {
      if (!_schedule.isScheduledOn(habit, d)) continue; // unscheduled days don't break
      if (done.contains(dateKey(d))) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _periodStreak(Habit habit, Set<String> done, DateTime t, DateTime start) {
    final quota = _schedule.periodQuota(habit);
    var pStart = _schedule.periodStart(habit, t);
    var streak = 0;
    var first = true;
    for (var i = 0; i < _maxScan; i++) {
      final pEnd = _schedule.periodEnd(habit, pStart);
      if (!pEnd.isAfter(start)) break; // period entirely before start date
      final n = _countIn(done, pStart, pEnd, start);
      if (n >= quota) {
        streak++;
      } else if (!first) {
        break;
      }
      first = false;
      pStart = _schedule.periodStart(habit, addDays(pStart, -1));
    }
    return streak;
  }

  int _countIn(Set<String> done, DateTime from, DateTime toExcl, DateTime start) {
    var n = 0;
    for (var d = from.isBefore(start) ? start : from; d.isBefore(toExcl); d = addDays(d, 1)) {
      if (done.contains(dateKey(d))) n++;
    }
    return n;
  }

  /// Longest day-streak ever (daily / weekdays semantics; for period schedules
  /// counts consecutive done calendar days).
  int longestStreak(Habit habit, Set<String> doneDates) {
    if (doneDates.isEmpty) return 0;
    final sorted = doneDates.map(parseDateKey).toList()..sort();
    var best = 0, cur = 0;
    DateTime? prevScheduled;
    for (final d in sorted) {
      if (prevScheduled == null) {
        cur = 1;
      } else {
        // next scheduled day after prev
        var next = addDays(prevScheduled, 1);
        var guard = 0;
        while (habit.schedule.type == ScheduleType.weekdays &&
            !_schedule.isScheduledOn(habit, next) &&
            guard++ < 7) {
          next = addDays(next, 1);
        }
        cur = isSameDay(next, d) ? cur + 1 : 1;
      }
      if (cur > best) best = cur;
      prevScheduled = d;
    }
    return best;
  }
}
