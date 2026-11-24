import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/domain/date_key.dart';
import 'package:ibetter/domain/models/check_in.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/services/schedule_service.dart';
import 'package:ibetter/domain/services/stats_service.dart';
import 'package:ibetter/domain/services/streak_service.dart';

Habit habit({
  Schedule schedule = const Schedule.daily(),
  DateTime? start,
  int dailyTarget = 1,
  int? goal,
}) =>
    Habit(
      id: 1,
      name: 't',
      iconKey: 'x',
      schedule: schedule,
      startDate: start ?? DateTime(2026, 1, 1),
      dailyTarget: dailyTarget,
      goalDays: goal,
      createdAt: DateTime(2026),
    );

Set<String> keys(List<DateTime> ds) => ds.map(dateKey).toSet();

void main() {
  const schedule = ScheduleService();
  const streak = StreakService();
  const stats = StatsService();

  group('date_key', () {
    test('round trip and week start (Sunday)', () {
      expect(dateKey(DateTime(2026, 3, 5)), '2026-03-05');
      expect(parseDateKey('2026-12-31'), DateTime(2026, 12, 31));
      // 2026-11-24 is a Tuesday → week starts Sunday 2026-11-22
      expect(startOfWeek(DateTime(2026, 11, 24)), DateTime(2026, 11, 22));
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    });
  });

  group('ScheduleService', () {
    test('not scheduled before start date', () {
      final h = habit(start: DateTime(2026, 11, 24));
      expect(schedule.isScheduledOn(h, DateTime(2026, 11, 23)), isFalse);
      expect(schedule.isScheduledOn(h, DateTime(2026, 11, 24)), isTrue);
    });

    test('weekdays mask', () {
      // Mon(1) Wed(3) Fri(5)
      final h = habit(schedule: const Schedule.weekdays(0x2A));
      expect(schedule.isScheduledOn(h, DateTime(2026, 11, 23)), isTrue); // Mon
      expect(schedule.isScheduledOn(h, DateTime(2026, 11, 24)), isFalse); // Tue
      expect(h.schedule.label, '每周一三五');
    });

    test('cannot check in future', () {
      final h = habit();
      final t = DateTime(2026, 11, 24);
      expect(schedule.canCheckIn(h, DateTime(2026, 11, 25), today: t), isFalse);
      expect(schedule.canCheckIn(h, t, today: t), isTrue);
    });

    test('dailyTarget', () {
      final h = habit(dailyTarget: 3);
      expect(schedule.isDone(h, 2), isFalse);
      expect(schedule.isDone(h, 3), isTrue);
    });
  });

  group('StreakService daily', () {
    final t = DateTime(2026, 11, 24);
    test('today done counts', () {
      final d = keys([t, addDays(t, -1), addDays(t, -2), addDays(t, -4)]);
      expect(streak.currentStreak(habit(), d, today: t), 3);
    });
    test('today pending does not break', () {
      final d = keys([addDays(t, -1), addDays(t, -2)]);
      expect(streak.currentStreak(habit(), d, today: t), 2);
    });
    test('yesterday missed resets', () {
      final d = keys([addDays(t, -2)]);
      expect(streak.currentStreak(habit(), d, today: t), 0);
    });
    test('crosses year boundary', () {
      final t2 = DateTime(2027, 1, 2);
      final d = keys([DateTime(2026, 12, 30), DateTime(2026, 12, 31), DateTime(2027, 1, 1), t2]);
      expect(streak.currentStreak(habit(), d, today: t2), 4);
    });
    test('stops at start date', () {
      final h = habit(start: DateTime(2026, 11, 23));
      final d = keys([DateTime(2026, 11, 22), DateTime(2026, 11, 23), t]);
      expect(streak.currentStreak(h, d, today: t), 2);
    });
  });

  group('StreakService weekdays', () {
    test('unscheduled days do not break', () {
      // Mon/Wed/Fri. Today Tue 11-24; done Mon 23, Fri 20, Wed 18
      final h = habit(schedule: const Schedule.weekdays(0x2A));
      final d = keys([DateTime(2026, 11, 23), DateTime(2026, 11, 20), DateTime(2026, 11, 18)]);
      expect(streak.currentStreak(h, d, today: DateTime(2026, 11, 24)), 3);
    });
  });

  group('StreakService periods', () {
    test('timesPerWeek counts consecutive weeks meeting quota', () {
      final h = habit(schedule: const Schedule.timesPerWeek(2));
      final t = DateTime(2026, 11, 24); // week of 11-22
      final d = keys([
        DateTime(2026, 11, 22), // current week: 1 (not met yet, doesn't break)
        DateTime(2026, 11, 16), DateTime(2026, 11, 18), // prev week met
        DateTime(2026, 11, 9), DateTime(2026, 11, 14), // met
        DateTime(2026, 11, 3), // not met → stop
      ]);
      expect(streak.currentStreak(h, d, today: t), 2);
    });

    test('timesPerMonth current month met counts', () {
      final h = habit(schedule: const Schedule.timesPerMonth(2));
      final t = DateTime(2026, 11, 24);
      final d = keys([DateTime(2026, 11, 1), DateTime(2026, 11, 2), DateTime(2026, 10, 5), DateTime(2026, 10, 6)]);
      expect(streak.currentStreak(h, d, today: t), 2);
    });
  });

  group('StatsService', () {
    test('compute totals, month and goal', () {
      final h = habit(goal: 4);
      CheckIn c(String date, int count) =>
          CheckIn(id: 0, habitId: 1, date: date, count: count, updatedAt: DateTime(2026));
      final list = [c('2026-10-31', 1), c('2026-11-23', 1), c('2026-11-24', 1), c('2026-11-20', 0)];
      final s = stats.compute(h, list, today: DateTime(2026, 11, 24));
      expect(s.totalDays, 3);
      expect(s.monthDays, 2);
      expect(s.currentStreak, 2);
      expect(s.doneToday, isTrue);
      expect(s.goalReached, isFalse);
      expect(s.goalProgress, 0.75);
    });

    test('dayCompletion', () {
      final h = habit();
      final day = DateTime(2026, 11, 24);
      expect(stats.dayCompletion([h], const [], day), isFalse);
      expect(
          stats.dayCompletion(
              [h], [CheckIn(id: 0, habitId: 1, date: '2026-11-24', count: 1, updatedAt: DateTime(2026))], day),
          isTrue);
      expect(stats.dayCompletion([h.copyWith(isActive: false)], const [], day), isNull);
    });
  });
}
