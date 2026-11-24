import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/domain/models/check_in.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/services/achievement_service.dart';

Habit _habit(int id, String name, {DateTime? start, int? goalDays, bool active = true}) => Habit(
      id: id,
      name: name,
      iconKey: 'study/book',
      startDate: start ?? DateTime(2026, 11, 21),
      goalDays: goalDays,
      isActive: active,
      createdAt: DateTime(2026, 11, 21),
    );

CheckIn _checkIn(int habitId, String date, {int count = 1}) => CheckIn(
      id: 0,
      habitId: habitId,
      date: date,
      count: count,
      updatedAt: DateTime(2026, 11, 24),
    );

void main() {
  const service = AchievementService();

  test('dayOfYear, weekOfYear, remainingDaysInYear match screenshot 2026-11-24', () {
    final today = DateTime(2026, 11, 24);
    expect(service.dayOfYear(today), 328);
    expect(service.weekOfYear(today), 48);
    expect(service.daysInYear(2026) - service.dayOfYear(today), 37);
  });

  test('computes KPIs, top habit, perfect day, and achievements', () {
    final today = DateTime(2026, 11, 24);
    final habits = [
      _habit(1, '应付作业'),
      _habit(2, '计算机常识学习'),
      _habit(3, '背单词'),
    ];
    final checkIns = [
      _checkIn(1, '2026-11-24'),
      _checkIn(2, '2026-11-24'),
      _checkIn(3, '2026-11-24'),
    ];

    final stats = service.compute(habits, checkIns, today: today);
    expect(stats.projectCount, 3);
    expect(stats.recordedDays, 1);
    expect(stats.totalCompletions, 3);
    expect(stats.longestStreak, 1);
    expect(stats.yearRecordedDays, 1);
    expect(stats.topHabitName, '应付作业');
    expect(stats.dayOfYear, 328);
    expect(stats.weekOfYear, 48);
    expect(stats.remainingDaysInYear, 37);
    expect(stats.latestAchievement?.id, 'perfect_day');
    expect(stats.latestAchievement?.count, 1);
    expect(stats.totalAchievementCount, greaterThanOrEqualTo(4));
  });

  test('weeklyRecordsForYear aggregates check-ins into Sunday-first weeks', () {
    final today = DateTime(2026, 11, 24); // week 48
    final habits = [_habit(1, 'A'), _habit(2, 'B')];
    final checkIns = [
      _checkIn(1, '2026-11-24'),
      _checkIn(2, '2026-11-24'),
      _checkIn(1, '2026-11-18'), // week 47
    ];

    final weeks = service.weeklyRecordsForYear(habits, checkIns, year: 2026, today: today);
    expect(weeks.length, 48);
    expect(weeks.last.weekNumber, 48);
    expect(weeks.last.completions, 2);
    expect(weeks[46].weekNumber, 47);
    expect(weeks[46].completions, 1);
  });
}
