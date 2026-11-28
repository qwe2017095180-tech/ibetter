import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/domain/date_key.dart' as dk;
import 'package:ibetter/domain/models/check_in.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/services/achievement_service.dart';
import 'package:ibetter/domain/services/history_service.dart';
import 'package:ibetter/features/icon_picker/icon_catalog.g.dart';

Habit _habit(int id, String name, {DateTime? start, int? goalDays, bool active = true}) => Habit(
      id: id,
      name: name,
      iconKey: 'study/book',
      startDate: start ?? DateTime(2026, 11, 21),
      goalDays: goalDays,
      isActive: active,
      createdAt: DateTime(2026, 11, 21),
    );

CheckIn _checkIn(int habitId, String date, {int count = 1, DateTime? updatedAt}) => CheckIn(
      id: 0,
      habitId: habitId,
      date: date,
      count: count,
      updatedAt: updatedAt ?? DateTime(2026, 11, 24, 10, 50),
    );

void main() {
  const service = AchievementService();
  const history = HistoryService();

  test('dayOfYear, weekOfYear, remainingDaysInYear match 2026-11-24', () {
    final today = DateTime(2026, 11, 24);
    expect(service.dayOfYear(today), 328);
    expect(service.weekOfYear(today), 48);
    expect(service.daysInYear(2026) - service.dayOfYear(today), 37);
  });

  test('computes KPIs, highest achievements, single/streak/task milestones, and share medal', () {
    final today = DateTime(2026, 11, 27);
    final habits = [
      _habit(1, '应付作业'),
      _habit(2, '计算机常识学习'),
      _habit(3, '背单词'),
    ];
    final checkIns = [
      for (final d in ['2026-11-24', '2026-11-25', '2026-11-26']) ...[
        _checkIn(1, d),
        _checkIn(2, d),
        _checkIn(3, d),
      ],
    ];

    final stats = service.compute(
      habits,
      checkIns,
      today: today,
      shareCount: 1,
      lastShareDate: '2026-11-24',
    );
    expect(stats.projectCount, 3);
    expect(stats.recordedDays, 3);
    expect(stats.totalCompletions, 9);
    expect(stats.longestStreak, 3);
    expect(stats.topHabitName, '应付作业');
    expect(stats.highestSingleAchievement?.id, 'single_3');
    expect(stats.highestSingleAchievement?.title, '三生万物');
    expect(stats.highestSingleAchievement?.count, 3);
    expect(stats.highestStreakAchievement?.id, 'streak_3');
    expect(stats.highestStreakAchievement?.title, '三天打鱼');
    expect(stats.highestStreakAchievement?.count, 3);

    final taskById = {for (final a in stats.byCategory(AchievementCategory.task)) a.id: a};
    expect(taskById['three_habits']?.title, '三国鼎立');
    expect(taskById['three_habits']?.count, 1);
    expect(taskById['friendship_medal']?.title, '友谊勋章');
    expect(taskById['friendship_medal']?.count, 1);
    expect(taskById['roma'] ?? taskById['goal_reached']?.title, '罗马之石');

    // Hidden achievements mask title when locked.
    final hidden = stats.byCategory(AchievementCategory.hidden);
    expect(hidden, isNotEmpty);
    expect(hidden.first.displayTitle, '隐藏成就');
    expect(hidden.first.displaySubtitle, '达到特定条件解锁');
  });

  test('newlyUnlockedForCheckIn detects 3-day milestones on day 3', () {
    final today = DateTime(2026, 11, 26);
    final h = _habit(1, '背单词');
    final before = [_checkIn(1, '2026-11-24'), _checkIn(1, '2026-11-25')];
    final after = [...before, _checkIn(1, '2026-11-26')];

    final unlocked = service.newlyUnlockedForCheckIn(
      habit: h,
      date: today,
      allHabits: [h],
      allCheckInsBefore: before,
      allCheckInsAfter: after,
      today: today,
    );

    final ids = unlocked.map((a) => a.id).toSet();
    expect(ids, containsAll(['single_3', 'streak_3']));
    expect(unlocked.first.habitName, '背单词');
  });

  test('weeklyRecordsForYear aggregates check-ins into Sunday-first weeks', () {
    final today = DateTime(2026, 11, 24);
    final habits = [_habit(1, 'A'), _habit(2, 'B')];
    final checkIns = [
      _checkIn(1, '2026-11-24'),
      _checkIn(2, '2026-11-24'),
      _checkIn(1, '2026-11-18'),
    ];

    final weeks = service.weeklyRecordsForYear(habits, checkIns, year: 2026, today: today);
    expect(weeks.length, 48);
    expect(weeks.last.weekNumber, 48);
    expect(weeks.last.completions, 2);
    expect(weeks[46].weekNumber, 47);
    expect(weeks[46].completions, 1);
  });

  test('HistoryService groups check-ins by month and day descending with HH:mm timestamps', () {
    final habits = [_habit(1, '应付作业'), _habit(2, '背单词')];
    final checkIns = [
      _checkIn(1, '2026-11-24', updatedAt: DateTime(2026, 11, 24, 19, 22)),
      _checkIn(2, '2026-11-24', updatedAt: DateTime(2026, 11, 24, 10, 5)),
      _checkIn(2, '2026-11-26', updatedAt: DateTime(2026, 11, 26, 10, 50)),
      _checkIn(1, '2026-10-30', updatedAt: DateTime(2026, 10, 30, 8, 9)),
    ];

    final months = history.buildTimeline(habits, checkIns);
    expect(months.map((m) => m.label), ['11月, 2026', '10月, 2026']);
    expect(months.first.days.map((d) => d.dateKey), ['2026-11-26', '2026-11-24']);
    expect(months.first.days[1].entries.map((e) => e.timeLabel), ['19:22', '10:05']);
    expect(months.last.days.single.entries.single.timeLabel, '08:09');
  });

  group('single-project 365-day milestone catalog', () {
    test('satisfies density, uniqueness, icon, legacy compatibility, and meme invariants', () {
      expect(kSingleProjectMilestones.length, 274);
      expect(kSingleProjectMilestones.first.days, 1);
      expect(kSingleProjectMilestones.last.days, 365);

      final seenDays = <int>{};
      final seenIds = <String>{};
      final seenTitles = <String>{};

      for (var i = 0; i < kSingleProjectMilestones.length; i++) {
        final m = kSingleProjectMilestones[i];
        expect(seenDays.add(m.days), isTrue, reason: 'duplicate days ${m.days}');
        expect(seenIds.add(m.id), isTrue, reason: 'duplicate id ${m.id}');
        expect(seenTitles.add(m.title), isTrue, reason: 'duplicate title ${m.title}');
        expect(m.lore.trim(), isNotEmpty, reason: 'empty lore on day ${m.days}');
        expect(
          iconCatalogKeys.contains(m.iconKey),
          isTrue,
          reason: 'invalid iconKey ${m.iconKey} on day ${m.days}',
        );

        if (i > 0) {
          final prev = kSingleProjectMilestones[i - 1];
          expect(m.days, greaterThan(prev.days));
          final gap = m.days - prev.days;
          expect(gap, lessThanOrEqualTo(2), reason: 'gap > 2 between ${prev.days} and ${m.days}');
          if (m.days <= 100 || prev.days >= 355) {
            expect(gap, 1, reason: 'expected daily milestone between ${prev.days} and ${m.days}');
          }
        }
      }

      final byDay = {for (final m in kSingleProjectMilestones) m.days: m};

      // Backward compatibility for original 12 milestones.
      const legacy = <int, String>{
        1: '一日幸运',
        2: '不二法门',
        3: '三生万物',
        5: '五福临门',
        7: '七星高照',
        10: '十全十美',
        15: '半月之约',
        21: '廿一成习',
        30: '满月达成',
        50: '五十知天命',
        100: '百炼成钢',
        365: '一周年纪念',
      };
      legacy.forEach((day, title) {
        expect(byDay[day]?.id, 'single_$day');
        expect(byDay[day]?.title, title);
      });

      // Requested allusion & internet-meme milestones.
      expect(byDay[325]?.title, '仙术杯 325');
      expect(byDay[325]?.lore, contains('明日方舟'));
      expect(byDay[42]?.title, '宇宙终极答案');
      expect(byDay[64]?.title, '一组方块');
      expect(byDay[86]?.title, '秋名山 AE86');
      expect(byDay[127]?.title, '本地回环 127');
      expect(byDay[200]?.title, '200 OK');
      expect(byDay[233]?.title, '23333 大笑');
      expect(byDay[300]?.title, '斯巴达吃井线');
      expect(byDay[314]?.title, '圆周率 π');
      expect(byDay[318]?.title, '此生必驾 318');
    });

    test('unlocks 325 meme achievement on day 325 and 365 anniversary on day 365', () {
      final start = DateTime(2025, 11, 29);
      final h = _habit(1, '每日坚持', start: start);

      final before325 = [
        for (var i = 0; i < 324; i++)
          _checkIn(1, dk.dateKey(dk.addDays(start, i))),
      ];
      final day325 = dk.addDays(start, 324);
      final after325 = [...before325, _checkIn(1, dk.dateKey(day325))];

      final unlockedOn325 = service.newlyUnlockedForCheckIn(
        habit: h,
        date: day325,
        allHabits: [h],
        allCheckInsBefore: before325,
        allCheckInsAfter: after325,
        today: day325,
      );
      final item325 = unlockedOn325.firstWhere((a) => a.id == 'single_325');
      expect(item325.title, '仙术杯 325');
      expect(item325.displayLore, contains('325'));

      final all365 = [
        for (var i = 0; i < 365; i++)
          _checkIn(1, dk.dateKey(dk.addDays(start, i))),
      ];
      final day365 = dk.addDays(start, 364);
      final stats365 = service.compute([h], all365, today: day365);
      expect(stats365.highestSingleAchievement?.id, 'single_365');
      expect(stats365.highestSingleAchievement?.title, '一周年纪念');
      expect(stats365.byCategory(AchievementCategory.singleProject).every((a) => a.unlocked), isTrue);
    });
  });
}
