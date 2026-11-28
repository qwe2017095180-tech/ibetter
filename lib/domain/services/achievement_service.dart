import '../date_key.dart';
import '../models/check_in.dart';
import '../models/habit.dart';
import 'schedule_service.dart';
import 'single_project_milestones.dart';
import 'stats_service.dart';
import 'streak_service.dart';

export 'single_project_milestones.dart';

/// Category tabs / sections on "我的成就".
enum AchievementCategory {
  singleProject,
  streak,
  task,
  hidden,
  special,
}

/// Visual badge style used to render an achievement emblem.
enum AchievementBadgeStyle {
  starCircle,
  singleDayRibbon,
  streakScallop,
  trophy,
  hiddenCircle,
}

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
    this.lore,
    this.category = AchievementCategory.task,
    this.badgeStyle = AchievementBadgeStyle.trophy,
    this.milestoneDays,
    this.isHidden = false,
    this.habitName,
    this.habitIconKey,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconKey;

  /// How many times earned (0 = locked).
  final int count;

  /// Latest date (`yyyy-MM-dd`) this achievement was earned, if known.
  final String? latestDate;

  /// Optional allusion/meme backstory shown on cards, unlock popups, and the catalog.
  final String? lore;

  final AchievementCategory category;
  final AchievementBadgeStyle badgeStyle;

  /// Numeric milestone displayed inside the badge (e.g. `1`, `2`, `3`, `7`).
  final int? milestoneDays;

  /// When true and `!unlocked`, UI masks title/subtitle as `隐藏成就` / `达到特定条件解锁`.
  final bool isHidden;

  /// Habit that most recently triggered this achievement (for celebration popup).
  final String? habitName;
  final String? habitIconKey;

  bool get unlocked => count > 0;

  String get displayTitle => (isHidden && !unlocked) ? '隐藏成就' : title;
  String get displaySubtitle => (isHidden && !unlocked) ? '达到特定条件解锁' : subtitle;
  String? get displayLore => (isHidden && !unlocked) ? null : lore;
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
    this.highestSingleAchievement,
    this.highestStreakAchievement,
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
  final AchievementItem? highestSingleAchievement;
  final AchievementItem? highestStreakAchievement;

  List<AchievementItem> byCategory(AchievementCategory cat) =>
      achievements.where((a) => a.category == cat).toList();
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

  static const _streakMilestones =
      <(int days, String id, String title, String icon, bool hidden)>[
    (3, 'streak_3', '三天打鱼', 'achievement/water_wave', false),
    (7, 'streak_7', '习惯养成', 'achievement/sports_medal', false),
    (14, 'streak_14', '渐入佳境', 'achievement/fire', false),
    (21, 'streak_21', '轻车熟路', 'achievement/trophy', false),
    (49, 'streak_49', '龙珠', 'achievement/ringed_planet', false),
    (100, 'streak_100', '百日传奇', 'achievement/crown', true),
  ];

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
  int weekOfYear(DateTime d) {
    final clean = dateOnly(d);
    final jan1 = DateTime(clean.year, 1, 1);
    final offset = weekdayIndex(jan1); // 0=Sun..6=Sat
    final dayIdx = clean.difference(jan1).inDays;
    return ((dayIdx + offset) ~/ 7) + 1;
  }

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

  /// Weekly completed check-in totals for every week of [year].
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

  /// Computes full overall summary and categorized achievements for [today].
  OverallStats compute(
    List<Habit> habits,
    Iterable<CheckIn> checkIns, {
    required DateTime today,
    int shareCount = 0,
    String? lastShareDate,
    bool cloudSynced = false,
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
      today: t,
      shareCount: shareCount,
      lastShareDate: lastShareDate,
      cloudSynced: cloudSynced,
    );

    final totalAchievementCount =
        achievements.fold<int>(0, (sum, a) => sum + a.count);

    // Latest unlocked achievement (prefer highest latestDate, then 完美的一天).
    final unlocked = achievements.where((a) => a.unlocked).toList();
    AchievementItem? latest;
    if (unlocked.isNotEmpty) {
      unlocked.sort((a, b) {
        final cmpDate = (b.latestDate ?? '').compareTo(a.latestDate ?? '');
        if (cmpDate != 0) return cmpDate;
        if (a.id == 'perfect_day') return -1;
        if (b.id == 'perfect_day') return 1;
        return (b.milestoneDays ?? 0).compareTo(a.milestoneDays ?? 0);
      });
      latest = unlocked.first;
    }

    // Highest unlocked single-project achievement.
    final unlockedSingle = achievements
        .where((a) => a.category == AchievementCategory.singleProject && a.unlocked)
        .toList();
    final highestSingle = unlockedSingle.isEmpty ? null : unlockedSingle.last;

    // Highest unlocked streak milestone achievement (excluding 完美的一天).
    final unlockedStreaks = achievements
        .where((a) =>
            a.category == AchievementCategory.streak &&
            a.id != 'perfect_day' &&
            a.unlocked)
        .toList();
    final highestStreak = unlockedStreaks.isEmpty ? null : unlockedStreaks.last;

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
      highestSingleAchievement: highestSingle,
      highestStreakAchievement: highestStreak,
    );
  }

  /// Returns milestone achievements newly unlocked by [habit] when completing [date].
  /// Useful for showing the orange celebration carousel right after a check-in!
  List<AchievementItem> newlyUnlockedForCheckIn({
    required Habit habit,
    required DateTime date,
    required List<Habit> allHabits,
    required Iterable<CheckIn> allCheckInsBefore,
    required Iterable<CheckIn> allCheckInsAfter,
    required DateTime today,
  }) {
    final before = compute(allHabits, allCheckInsBefore, today: today);
    final after = compute(allHabits, allCheckInsAfter, today: today);
    final beforeById = {for (final a in before.achievements) a.id: a.count};
    final dateStr = dateKey(date);

    final unlocked = <AchievementItem>[];
    for (final a in after.achievements) {
      if (a.id == 'perfect_day') continue; // PerfectDayDialog handles 完美的一天 separately.
      final prev = beforeById[a.id] ?? 0;
      if (a.count > prev) {
        unlocked.add(AchievementItem(
          id: a.id,
          title: a.title,
          subtitle: a.subtitle,
          iconKey: a.iconKey,
          count: a.count,
          latestDate: dateStr,
          lore: a.lore,
          category: a.category,
          badgeStyle: a.badgeStyle,
          milestoneDays: a.milestoneDays,
          isHidden: a.isHidden,
          habitName: habit.name,
          habitIconKey: habit.iconKey,
        ));
      }
    }
    return unlocked;
  }

  /// Finds the date (`yyyy-MM-dd`) on which a habit first reached a streak of [target] days.
  String? _firstDateReachingStreak(Habit habit, List<String> sortedDoneDates, int target) {
    if (sortedDoneDates.length < target) return null;
    var cur = 0;
    DateTime? prev;
    for (final k in sortedDoneDates) {
      final d = parseDateKey(k);
      if (prev == null) {
        cur = 1;
      } else {
        var next = addDays(prev, 1);
        var guard = 0;
        while (habit.schedule.type == ScheduleType.weekdays &&
            !_schedule.isScheduledOn(habit, next) &&
            guard++ < 7) {
          next = addDays(next, 1);
        }
        cur = isSameDay(next, d) ? cur + 1 : 1;
      }
      if (cur >= target) return k;
      prev = d;
    }
    return null;
  }

  /// Checks if the user has 5 consecutive weekday (Mon–Fri) check-ins in any single week.
  ({int count, String? latestDate}) _computeWorkdayStreaks(Set<String> recordedDates) {
    if (recordedDates.isEmpty) return (count: 0, latestDate: null);
    final sorted = recordedDates.toList()..sort();
    var count = 0;
    String? latest;
    final checkedMondays = <String>{};
    for (final k in sorted) {
      final d = parseDateKey(k);
      if (d.weekday != DateTime.monday) continue;
      if (!checkedMondays.add(k)) continue;
      var allFive = true;
      for (var i = 0; i < 5; i++) {
        if (!recordedDates.contains(dateKey(addDays(d, i)))) {
          allFive = false;
          break;
        }
      }
      if (allFive) {
        count++;
        latest = dateKey(addDays(d, 4));
      }
    }
    return (count: count, latestDate: latest);
  }

  List<AchievementItem> _computeAchievements({
    required List<Habit> habits,
    required Iterable<CheckIn> checkIns,
    required Map<int, Set<String>> doneByHabit,
    required Map<String, int> dailyCounts,
    required int totalCompletions,
    required DateTime today,
    required int shareCount,
    required String? lastShareDate,
    required bool cloudSynced,
  }) {
    final sortedAllDates = dailyCounts.keys.toList()..sort();
    final latestAnyDate = sortedAllDates.isEmpty ? null : sortedAllDates.last;
    final recordedSet = dailyCounts.keys.toSet();

    // Sorted done dates per habit.
    final sortedByHabit = <int, List<String>>{
      for (final h in habits) h.id: (doneByHabit[h.id]?.toList() ?? <String>[])..sort(),
    };

    // 1. 单项目成就 (singleProject)
    final singleItems = <AchievementItem>[];
    for (final m in kSingleProjectMilestones) {
      var hits = 0;
      String? latest;
      Habit? latestHabit;
      for (final h in habits) {
        final dates = sortedByHabit[h.id] ?? const <String>[];
        if (dates.length >= m.days) {
          hits++;
          final reachedOn = dates[m.days - 1];
          if (latest == null || reachedOn.compareTo(latest) >= 0) {
            latest = reachedOn;
            latestHabit = h;
          }
        }
      }
      singleItems.add(AchievementItem(
        id: m.id,
        title: m.title,
        subtitle: '单项目坚持${m.days}天',
        lore: m.lore,
        iconKey: m.iconKey,
        count: hits,
        latestDate: latest,
        category: AchievementCategory.singleProject,
        badgeStyle: AchievementBadgeStyle.singleDayRibbon,
        milestoneDays: m.days,
        habitName: latestHabit?.name,
        habitIconKey: latestHabit?.iconKey,
      ));
    }

    // 2. 连续成就 (streak)
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

    final streakItems = <AchievementItem>[
      AchievementItem(
        id: 'perfect_day',
        title: '完美的一天',
        subtitle: '完成当日所有打卡',
        iconKey: 'achievement/star',
        count: perfectDates.length,
        latestDate: perfectDates.isEmpty ? null : perfectDates.last,
        category: AchievementCategory.streak,
        badgeStyle: AchievementBadgeStyle.starCircle,
      ),
    ];

    for (final (days, id, title, icon, isHidden) in _streakMilestones) {
      var hits = 0;
      String? latest;
      Habit? latestHabit;
      for (final h in habits) {
        final reachedOn = _firstDateReachingStreak(h, sortedByHabit[h.id] ?? const [], days);
        if (reachedOn != null) {
          hits++;
          if (latest == null || reachedOn.compareTo(latest) >= 0) {
            latest = reachedOn;
            latestHabit = h;
          }
        }
      }
      streakItems.add(AchievementItem(
        id: id,
        title: title,
        subtitle: '连续打卡$days天',
        iconKey: icon,
        count: hits,
        latestDate: latest,
        category: AchievementCategory.streak,
        badgeStyle: AchievementBadgeStyle.streakScallop,
        milestoneDays: days,
        isHidden: isHidden,
        habitName: latestHabit?.name,
        habitIconKey: latestHabit?.iconKey,
      ));
    }

    // 3. 任务成就 (task — matches screenshot 7!)
    var goalsReached = 0;
    String? latestGoalDate;
    for (final h in habits) {
      final dates = sortedByHabit[h.id] ?? const <String>[];
      if (h.goalDays != null && dates.length >= h.goalDays!) {
        goalsReached++;
        final d = dates[h.goalDays! - 1];
        if (latestGoalDate == null || d.compareTo(latestGoalDate) > 0) {
          latestGoalDate = d;
        }
      }
    }

    String? thirdHabitDate;
    if (habits.length >= 3) {
      final sortedCreated = habits.map((h) => dateKey(h.createdAt)).toList()..sort();
      thirdHabitDate = sortedCreated[2];
    }

    final workday = _computeWorkdayStreaks(recordedSet);
    final octopusDates = dailyCounts.entries
        .where((e) => e.value >= 8)
        .map((e) => e.key)
        .toList()
      ..sort();

    final taskItems = <AchievementItem>[
      AchievementItem(
        id: 'goal_reached',
        title: '罗马之石',
        subtitle: '完成目标任务',
        iconKey: 'achievement/gem_stone',
        count: goalsReached,
        latestDate: latestGoalDate,
        category: AchievementCategory.task,
        badgeStyle: AchievementBadgeStyle.trophy,
      ),
      AchievementItem(
        id: 'total_100',
        title: '百日维新',
        subtitle: '总打卡数量达到100',
        iconKey: 'achievement/hundred_points',
        count: totalCompletions ~/ 100,
        latestDate: totalCompletions >= 100 ? latestAnyDate : null,
        category: AchievementCategory.task,
        badgeStyle: AchievementBadgeStyle.trophy,
        milestoneDays: 100,
      ),
      AchievementItem(
        id: 'three_habits',
        title: '三国鼎立',
        subtitle: '添加三个任务',
        iconKey: 'achievement/trophy',
        count: habits.length >= 3 ? 1 : 0,
        latestDate: thirdHabitDate,
        category: AchievementCategory.task,
        badgeStyle: AchievementBadgeStyle.trophy,
        milestoneDays: 3,
      ),
      AchievementItem(
        id: 'friendship_medal',
        title: '友谊勋章',
        subtitle: '分享一次',
        iconKey: 'achievement/party_popper',
        count: shareCount > 0 ? 1 : 0,
        latestDate: shareCount > 0 ? (lastShareDate ?? dateKey(today)) : null,
        category: AchievementCategory.task,
        badgeStyle: AchievementBadgeStyle.trophy,
      ),
      AchievementItem(
        id: 'workday_warrior',
        title: '工作日狂魔',
        subtitle: '连续5个工作日打卡',
        iconKey: 'achievement/rocket',
        count: workday.count,
        latestDate: workday.latestDate,
        category: AchievementCategory.task,
        badgeStyle: AchievementBadgeStyle.trophy,
      ),
      AchievementItem(
        id: 'sync_400',
        title: '同步率 400%',
        subtitle: '成功云端同步数据',
        iconKey: 'achievement/milky_way',
        count: cloudSynced ? 1 : 0,
        latestDate: cloudSynced ? dateKey(today) : null,
        category: AchievementCategory.task,
        badgeStyle: AchievementBadgeStyle.trophy,
      ),
      AchievementItem(
        id: 'octopus_medal',
        title: '八爪鱼勋章',
        subtitle: '同一天完成8个项目',
        iconKey: 'achievement/sparkles',
        count: octopusDates.length,
        latestDate: octopusDates.isEmpty ? null : octopusDates.last,
        category: AchievementCategory.task,
        badgeStyle: AchievementBadgeStyle.trophy,
      ),
    ];

    // 4. 隐藏成就 (hidden — genuine unlockable easter-egg conditions)
    final earlyBirdDates = <String>[];
    final nightOwlDates = <String>[];
    final weekendDates = <String>[];
    for (final c in checkIns) {
      if (c.count <= 0) continue;
      final hour = c.updatedAt.hour;
      if (hour >= 4 && hour < 7) earlyBirdDates.add(c.date);
      if (hour >= 23 || hour < 3) nightOwlDates.add(c.date);
      final wd = parseDateKey(c.date).weekday;
      if (wd == DateTime.saturday || wd == DateTime.sunday) {
        weekendDates.add(c.date);
      }
    }
    earlyBirdDates.sort();
    nightOwlDates.sort();
    weekendDates.sort();

    final hiddenItems = <AchievementItem>[
      AchievementItem(
        id: 'hidden_early_bird',
        title: '晨曦行者',
        subtitle: '在清晨 7 点前完成打卡',
        iconKey: 'mind/sunrise',
        count: earlyBirdDates.toSet().length,
        latestDate: earlyBirdDates.isEmpty ? null : earlyBirdDates.last,
        category: AchievementCategory.hidden,
        badgeStyle: AchievementBadgeStyle.hiddenCircle,
        isHidden: true,
      ),
      AchievementItem(
        id: 'hidden_night_owl',
        title: '守夜人',
        subtitle: '在深夜 23 点后坚持打卡',
        iconKey: 'health/crescent_moon',
        count: nightOwlDates.toSet().length,
        latestDate: nightOwlDates.isEmpty ? null : nightOwlDates.last,
        category: AchievementCategory.hidden,
        badgeStyle: AchievementBadgeStyle.hiddenCircle,
        isHidden: true,
      ),
      AchievementItem(
        id: 'hidden_weekend_warrior',
        title: '周末不打烊',
        subtitle: '在周末完成 4 天打卡',
        iconKey: 'achievement/confetti_ball',
        count: weekendDates.toSet().length >= 4 ? 1 : 0,
        latestDate: weekendDates.toSet().length >= 4 ? weekendDates.last : null,
        category: AchievementCategory.hidden,
        badgeStyle: AchievementBadgeStyle.hiddenCircle,
        isHidden: true,
      ),
      AchievementItem(
        id: 'hidden_perfect_week',
        title: '完美七日',
        subtitle: '累计获得 7 次完美的一天',
        iconKey: 'achievement/crown',
        count: perfectDates.length >= 7 ? 1 : 0,
        latestDate: perfectDates.length >= 7 ? perfectDates[6] : null,
        category: AchievementCategory.hidden,
        badgeStyle: AchievementBadgeStyle.hiddenCircle,
        isHidden: true,
      ),
    ];

    // 5. 特殊成就 (special)
    final unlockedSoFar = [
      ...singleItems,
      ...streakItems,
      ...taskItems,
      ...hiddenItems,
    ].where((a) => a.unlocked).length;

    final specialItems = <AchievementItem>[
      AchievementItem(
        id: 'special_collector',
        title: '勋章收藏家',
        subtitle: '累计解锁 10 项不同成就',
        iconKey: 'achievement/military_medal',
        count: unlockedSoFar >= 10 ? 1 : 0,
        latestDate: unlockedSoFar >= 10 ? latestAnyDate : null,
        category: AchievementCategory.special,
        badgeStyle: AchievementBadgeStyle.hiddenCircle,
      ),
      AchievementItem(
        id: 'special_multi_5',
        title: '五线并行',
        subtitle: '同时进行 5 个及以上项目',
        iconKey: 'achievement/shield',
        count: habits.where((h) => h.isActive).length >= 5 ? 1 : 0,
        latestDate: habits.where((h) => h.isActive).length >= 5 ? dateKey(today) : null,
        category: AchievementCategory.special,
        badgeStyle: AchievementBadgeStyle.hiddenCircle,
      ),
      AchievementItem(
        id: 'special_year_legend',
        title: '年度传奇',
        subtitle: '累计打卡记录达到 180 天',
        iconKey: 'achievement/flying_saucer',
        count: recordedSet.length >= 180 ? 1 : 0,
        latestDate: recordedSet.length >= 180 ? latestAnyDate : null,
        category: AchievementCategory.special,
        badgeStyle: AchievementBadgeStyle.hiddenCircle,
        isHidden: true,
      ),
    ];

    return [
      ...singleItems,
      ...streakItems,
      ...taskItems,
      ...hiddenItems,
      ...specialItems,
    ];
  }
}
