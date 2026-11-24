import '../date_key.dart';
import '../models/habit.dart';

/// Rules about *when* a habit applies. Pure Dart, no Flutter / drift.
class ScheduleService {
  const ScheduleService();

  /// Whether [habit] should appear / may be checked in on [date].
  ///
  /// - before start date → false
  /// - daily → true
  /// - weekdays → weekday bit set
  /// - timesPerWeek / timesPerMonth → any day in the period is eligible
  bool isScheduledOn(Habit habit, DateTime date) {
    final d = dateOnly(date);
    if (d.isBefore(dateOnly(habit.startDate))) return false;
    switch (habit.schedule.type) {
      case ScheduleType.daily:
      case ScheduleType.timesPerWeek:
      case ScheduleType.timesPerMonth:
        return true;
      case ScheduleType.weekdays:
        return maskHas(habit.schedule.weekdaysMask, weekdayIndex(d));
    }
  }

  /// Whether a check-in may be edited for [date] (not before start, not in the future).
  bool canCheckIn(Habit habit, DateTime date, {required DateTime today}) {
    final d = dateOnly(date);
    if (d.isAfter(dateOnly(today))) return false;
    return isScheduledOn(habit, d);
  }

  bool isDone(Habit habit, int count) => count >= habit.dailyTarget;

  /// Start (inclusive) of the period containing [date] for period-based schedules.
  DateTime periodStart(Habit habit, DateTime date) {
    switch (habit.schedule.type) {
      case ScheduleType.timesPerMonth:
        return startOfMonth(date);
      case ScheduleType.timesPerWeek:
        return startOfWeek(date);
      case ScheduleType.daily:
      case ScheduleType.weekdays:
        return dateOnly(date);
    }
  }

  /// End (exclusive) of the period that starts at [start].
  DateTime periodEnd(Habit habit, DateTime start) {
    switch (habit.schedule.type) {
      case ScheduleType.timesPerMonth:
        return DateTime(start.year, start.month + 1, 1);
      case ScheduleType.timesPerWeek:
        return addDays(start, 7);
      case ScheduleType.daily:
      case ScheduleType.weekdays:
        return addDays(start, 1);
    }
  }

  /// Required done-days inside one period.
  int periodQuota(Habit habit) {
    switch (habit.schedule.type) {
      case ScheduleType.timesPerWeek:
        return habit.schedule.value.clamp(1, 7);
      case ScheduleType.timesPerMonth:
        return habit.schedule.value.clamp(1, 31);
      case ScheduleType.daily:
      case ScheduleType.weekdays:
        return 1;
    }
  }
}
