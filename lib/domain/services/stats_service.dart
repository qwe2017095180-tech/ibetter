import '../date_key.dart';
import '../models/check_in.dart';
import '../models/habit.dart';
import 'schedule_service.dart';
import 'streak_service.dart';

/// Numbers shown on the "我的项目" card.
class HabitStats {
  const HabitStats({
    required this.totalDays,
    required this.monthDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.goalDays,
    required this.doneToday,
  });

  /// 累计完成天数 (big number top-right).
  final int totalDays;

  /// 本月完成天数.
  final int monthDays;

  /// 连续 (days, or periods for timesPerWeek / timesPerMonth).
  final int currentStreak;
  final int longestStreak;

  /// null = 永远.
  final int? goalDays;
  final bool doneToday;

  bool get goalReached => goalDays != null && totalDays >= goalDays!;

  /// 0..1, or null when goal is 永远.
  double? get goalProgress =>
      goalDays == null || goalDays == 0 ? null : (totalDays / goalDays!).clamp(0.0, 1.0);

  static const empty = HabitStats(
    totalDays: 0,
    monthDays: 0,
    currentStreak: 0,
    longestStreak: 0,
    goalDays: null,
    doneToday: false,
  );
}

class StatsService {
  const StatsService([this._schedule = const ScheduleService(), this._streak = const StreakService()]);

  final ScheduleService _schedule;
  final StreakService _streak;

  /// Set of done date keys for [habit] from its check-ins.
  Set<String> doneDates(Habit habit, Iterable<CheckIn> checkIns) => {
        for (final c in checkIns)
          if (c.habitId == habit.id && _schedule.isDone(habit, c.count)) c.date,
      };

  HabitStats compute(Habit habit, Iterable<CheckIn> checkIns, {required DateTime today}) {
    final done = doneDates(habit, checkIns);
    final t = dateOnly(today);
    final monthPrefix = dateKey(t).substring(0, 8); // yyyy-MM-
    return HabitStats(
      totalDays: done.length,
      monthDays: done.where((k) => k.startsWith(monthPrefix)).length,
      currentStreak: _streak.currentStreak(habit, done, today: t),
      longestStreak: _streak.longestStreak(habit, done),
      goalDays: habit.goalDays,
      doneToday: done.contains(dateKey(t)),
    );
  }

  /// Day status for the calendar: null = nothing scheduled, true = all scheduled
  /// active habits done, false = some pending.
  bool? dayCompletion(List<Habit> habits, Iterable<CheckIn> checkInsOfDay, DateTime day) {
    final scheduled =
        habits.where((h) => h.isActive && _schedule.isScheduledOn(h, day)).toList();
    if (scheduled.isEmpty) return null;
    final byHabit = {for (final c in checkInsOfDay) c.habitId: c.count};
    return scheduled.every((h) => _schedule.isDone(h, byHabit[h.id] ?? 0));
  }
}
