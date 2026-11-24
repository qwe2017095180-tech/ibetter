import '../date_key.dart';
import '../models/check_in.dart';
import '../models/habit.dart';
import 'schedule_service.dart';
import 'stats_service.dart';
import 'streak_service.dart';

/// One weekly bucket for the "每周打卡记录" chart.
class WeeklyRecord {
  const WeeklyRecord({
    required this.weekNumber,
    required this.weekStart,
    required this.completions,
  });

  /// 1-based week number within the year.
  final int weekNumber;
  final DateTime weekStart;
  final int completions;
}

/// One unlockable achievement item.
class AchievementItem {
  const AchievementItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.count,
    this.latestDate,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconKey;

  /// How many times earned (0 = locked).
  final int count;

  /// Latest date (`yyyy-MM-dd`) this achievement was earned, if known.
  final String? latestDate;

  bool get unlocked => count > 0;
}

/// Aggregated summary powering "我的成就" & "成绩单".
class OverallStats {
  const OverallStats({
    required this.projectCount,
    required this.recordedDays,
    required this.totalCompletions,
    required this.longestStreak,
    required this.yearRecordedDays,
    required this.topHabitName,
    required this.dayOfYear,
    required this.weekOfYear,
    required this.remainingDaysInYear,
    required this.achievements,
    required this.totalAchievementCount,
    this.latestAchievement,
  });

  final int projectCount;
  final int recordedDays;
  final int totalCompletions;
  final int longestStreak;
  final int yearRecordedDays;
  final String? topHabitName;
  final int dayOfYear;
  final int weekOfYear;
  final int remainingDaysInYear;
  final List<AchievementItem> achievements;
  final int totalAchievementCount;
  final AchievementItem? latestAchievement;
}

/// Pure-Dart analytics & achievement computation.
class AchievementService {
  const AchievementService([
    this._schedule = const ScheduleService(),
    this._streak = const StreakService(),
    this._stats = const StatsService(),
  ]);

  final ScheduleService _schedule;
  final StreakService _streak;
  final StatsService _stats;

  /// 1-based day index in the calendar year of [d] (Jan 1 = 1).
  int dayOfYear(DateTime d) {
    final clean = dateOnly(d);
    final jan1 = DateTime(clean.year, 1, 1);
    return clean.difference(jan1).inDays + 1;
  }

  /// Total days in [year] (365 or 366).
  int daysInYear(int year) {
    final start = DateTime(year, 1, 1);
    final next = DateTime(year + 1, 1, 1);
    return next.difference(start).inDays;
  }

  /// 1-based Sunday-first week number of [d] in its calendar year.
  /// Matches the app's Sunday-first calendar (2026-11-24 -> week 48).
  int weekOfYear(DateTime d) {
    final clean = dateOnly(d);
    final jan1 = DateTime(clean.year, 1, 1);
    final offset = weekdayIndex(jan1); // 0=Sun..6=Sat
    final dayIdx = clean.difference(jan1).inDays; // 0-based
    return ((dayIdx + offset) ~/ 7) + 1;
  }

  /// All completed check-ins paired with their habit, filtered to existing habits
  /// where `count >= habit.dailyTarget`.
  Map<int, Set<String>> _doneDatesByHabit(List<Habit> habits, Iterable<CheckIn> checkIns) {
    final byId = {for (final h in habits) h.id: h};
    final result = <int, Set<String>>{for (final h in habits) h.id: <String>{}};
    for (final c in checkIns) {
      final h = byId[c.habitId];
      if (h != null && _schedule.isDone(h, c.count)) {
        result[h.id]!.add(c.date);
      }
    }
    return result;
  }

  /// Map of `yyyy-MM-dd` -> count of completed habits on that day.
  Map<String, int> dailyCompletionCounts(List<Habit> habits, Iterable<CheckIn> checkIns) {
    final byId = {for (final h in habits) h.id: h};
    final counts = <String, int>{};
    for (final c in checkIns) {
      final h = byId[c.habitId];
      if (h != null && _schedule.isDone(h, c.count)) {
        counts[c.date] = (counts[c.date] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Weekly completed check-in totals for every week of [year] (up to current week
  /// if [year] == [today].year, or all weeks of [year] for past years).
  List<WeeklyRecord> weeklyRecordsForYear(
    List<Habit> habits,
    Iterable<CheckIn> checkIns, {
    required int year,
    required DateTime today,
  }) {
    final t = dateOnly(today);
    final jan1 = DateTime(year, 1, 1);
    final dec31 = DateTime(year, 12, 31);
    final maxWeek = year == t.year
        ? weekOfYear(t)
        : (year < t.year ? weekOfYear(dec31) : 1);

    final daily = dailyCompletionCounts(habits, checkIns);
    final byWeek = <int, int>{};
    final yearPrefix = '${year.toString().padLeft(4, '0')}-';
    daily.forEach((key, count) {
      if (!key.startsWith(yearPrefix)) return;
      final d = parseDateKey(key);
      final w = weekOfYear(d);
      byWeek[w] = (byWeek[w] ?? 0) + count;
    });

    final firstSunday = startOfWeek(jan1);
    return List.generate(maxWeek, (i) {
      final weekNum = i + 1;
      final ws = addDays(firstSunday, i * 7);
      return WeeklyRecord(
        weekNumber: weekNum,
        weekStart: ws.isBefore(jan1) ? jan1 : ws,
        completions: byWeek[weekNum] ?? 0,
      );
    });
  }

  /// Computes full overall summary and unlocked achievements for [today].
  OverallStats compute(
    List<Habit> habits,
    Iterable<CheckIn> checkIns, {
    required DateTime today,
  }) {
    final t = dateOnly(today);
    final doneByHabit = _doneDatesByHabit(habits, checkIns);
    final dailyCounts = dailyCompletionCounts(habits, checkIns);

    var totalCompletions = 0;
    var bestStreak = 0;
    Habit? topHabit;
    var topCount = 0;

    for (final h in habits) {
      final done = doneByHabit[h.id] ?? const <String>{};
      totalCompletions += done.length;
      final longest = _streak.longestStreak(h, done);
      if (longest > bestStreak) bestStreak = longest;
      if (done.length > topCount) {
        topCount = done.length;
        topHabit = h;
      }
    }

    final yearPrefix = '${t.year.toString().padLeft(4, '0')}-';
    final yearRecordedDays =
        dailyCounts.keys.where((k) => k.startsWith(yearPrefix)).length;

    final achievements = _computeAchievements(
      habits: habits,
      checkIns: checkIns,
      doneByHabit: doneByHabit,
      dailyCounts: dailyCounts,
      totalCompletions: totalCompletions,
      bestStreak: bestStreak,
      today: t,
    );

    final totalAchievementCount =
        achievements.fold<int>(0, (sum, a) => sum + a.count);

    // Pick the most recent unlocked achievement (preferring highest latestDate,
    // and prioritizing "完美的一天" when tied on the same latestDate).
    final unlocked = achievements.where((a) => a.unlocked).toList();
    AchievementItem? latest;
    if (unlocked.isNotEmpty) {
      unlocked.sort((a, b) {
        final cmpDate = (b.latestDate ?? '').compareTo(a.latestDate ?? '');
        if (cmpDate != 0) return cmpDate;
        if (a.id == 'perfect_day') return -1;
        if (b.id == 'perfect_day') return 1;
        return 0;
      });
      latest = unlocked.first;
    }

    final doy = dayOfYear(t);
    final totalYearDays = daysInYear(t.year);

    return OverallStats(
      projectCount: habits.length,
      recordedDays: dailyCounts.length,
      totalCompletions: totalCompletions,
      longestStreak: bestStreak,
      yearRecordedDays: yearRecordedDays,
      topHabitName: topHabit?.name,
      dayOfYear: doy,
      weekOfYear: weekOfYear(t),
      remainingDaysInYear: (totalYearDays - doy).clamp(0, totalYearDays),
      achievements: achievements,
      totalAchievementCount: totalAchievementCount,
      latestAchievement: latest,
    );
  }

  List<AchievementItem> _computeAchievements({
    required List<Habit> habits,
    required Iterable<CheckIn> checkIns,
    required Map<int, Set<String>> doneByHabit,
    required Map<String, int> dailyCounts,
    required int totalCompletions,
    required int bestStreak,
    required DateTime today,
  }) {
    final sortedAllDates = dailyCounts.keys.toList()..sort();
    final latestAnyDate = sortedAllDates.isEmpty ? null : sortedAllDates.last;
    final firstHabitDate = habits.isEmpty
        ? null
        : (habits.map((h) => dateKey(h.startDate)).toList()..sort()).first;

    // Perfect days: dates where at least one active habit was scheduled and ALL
    // scheduled active habits were completed.
    final checkInsByDate = <String, List<CheckIn>>{};
    for (final c in checkIns) {
      (checkInsByDate[c.date] ??= <CheckIn>[]).add(c);
    }
    final perfectDates = <String>[];
    for (final k in sortedAllDates) {
      final d = parseDateKey(k);
      if (d.isAfter(today)) continue;
      if (_stats.dayCompletion(habits, checkInsByDate[k] ?? const [], d) == true) {
        perfectDates.add(k);
      }
    }

    // Goals reached count.
    var goalsReached = 0;
    for (final h in habits) {
      final done = doneByHabit[h.id] ?? const <String>{};
      if (h.goalDays != null && done.length >= h.goalDays!) {
        goalsReached++;
      }
    }

    // Active habits count.
    final activeCount = habits.where((h) => h.isActive).length;

    // Longest consecutive days with ANY check-in.
    var bestAnyDayRun = 0;
    var curRun = 0;
    DateTime? prev;
    for (final k in sortedAllDates) {
      final d = parseDateKey(k);
      if (prev != null && isSameDay(addDays(prev, 1), d)) {
        curRun++;
      } else {
        curRun = 1;
      }
      if (curRun > bestAnyDayRun) bestAnyDayRun = curRun;
      prev = d;
    }

    return [
      AchievementItem(
        id: 'perfect_day',
        title: '完美的一天',
        subtitle: '完成当日所有打卡',
        iconKey: 'achievement/star',
        count: perfectDates.length,
        latestDate: perfectDates.isEmpty ? null : perfectDates.last,
      ),
      AchievementItem(
        id: 'first_project',
        title: '新的开始',
        subtitle: '创建第一个习惯项目',
        iconKey: 'achievement/rocket',
        count: habits.isNotEmpty ? 1 : 0,
        latestDate: firstHabitDate,
      ),
      AchievementItem(
        id: 'first_checkin',
        title: '迈出第一步',
        subtitle: '完成第一次打卡',
        iconKey: 'achievement/sparkles',
        count: totalCompletions > 0 ? 1 : 0,
        latestDate: sortedAllDates.isEmpty ? null : sortedAllDates.first,
      ),
      AchievementItem(
        id: 'multi_habit',
        title: '多面手',
        subtitle: '同时进行 3 个及以上项目',
        iconKey: 'achievement/light_bulb',
        count: activeCount >= 3 ? 1 : 0,
        latestDate: activeCount >= 3 ? dateKey(today) : null,
      ),
      AchievementItem(
        id: 'streak_3',
        title: '小试牛刀',
        subtitle: '单个项目连续打卡 3 天',
        iconKey: 'achievement/fire',
        count: bestStreak >= 3 ? 1 : 0,
        latestDate: bestStreak >= 3 ? latestAnyDate : null,
      ),
      AchievementItem(
        id: 'streak_7',
        title: '坚持一周',
        subtitle: '单个项目连续打卡 7 天',
        iconKey: 'achievement/sports_medal',
        count: bestStreak >= 7 ? 1 : 0,
        latestDate: bestStreak >= 7 ? latestAnyDate : null,
      ),
      AchievementItem(
        id: 'streak_21',
        title: '习惯养成',
        subtitle: '单个项目连续打卡 21 天',
        iconKey: 'achievement/trophy',
        count: bestStreak >= 21 ? 1 : 0,
        latestDate: bestStreak >= 21 ? latestAnyDate : null,
      ),
      AchievementItem(
        id: 'full_week',
        title: '全勤一周',
        subtitle: '连续 7 天每日都有打卡记录',
        iconKey: 'achievement/1st_place_medal',
        count: bestAnyDayRun >= 7 ? 1 : 0,
        latestDate: bestAnyDayRun >= 7 ? latestAnyDate : null,
      ),
      AchievementItem(
        id: 'total_100',
        title: '百日筑基',
        subtitle: '累计达成 100 次打卡',
        iconKey: 'achievement/crown',
        count: totalCompletions ~/ 100,
        latestDate: totalCompletions >= 100 ? latestAnyDate : null,
      ),
      AchievementItem(
        id: 'goal_reached',
        title: '目标达成',
        subtitle: '完成一个设定天数目标的项目',
        iconKey: 'achievement/gem_stone',
        count: goalsReached,
        latestDate: goalsReached > 0 ? latestAnyDate : null,
      ),
    ];
  }
}
