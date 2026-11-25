import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/models/reminder.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late DriftHabitRepository habits;
  late DriftCheckInRepository checkIns;
  late DriftReminderRepository reminders;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    habits = DriftHabitRepository(db);
    checkIns = DriftCheckInRepository(db);
    reminders = DriftReminderRepository(db);
  });
  tearDown(() => db.close());

  HabitDraft draft(String name) => HabitDraft(
        name: name,
        iconKey: 'study/book',
        schedule: const Schedule.timesPerWeek(3),
        goalDays: 21,
        startDate: DateTime(2026, 11, 21),
        motto: '自己来选择',
      );

  test('habit CRUD + ordering + active filter', () async {
    final a = await habits.create(draft('A'));
    final b = await habits.create(draft('B'));
    var all = await habits.watchAll().first;
    expect(all.map((h) => h.name), ['A', 'B']);
    expect(all.first.schedule, const Schedule.timesPerWeek(3));
    expect(all.first.startDate, DateTime(2026, 11, 21));
    expect(all.first.goalDays, 21);

    await habits.setActive(b, false);
    expect((await habits.watchAll(activeOnly: true).first).map((h) => h.id), [a]);

    final h = (await habits.getById(a))!;
    await habits.update(h.copyWithDraft(draft('A2')));
    expect((await habits.getById(a))!.name, 'A2');

    await habits.delete(a);
    all = await habits.watchAll().first;
    expect(all.map((h) => h.id), [b]);
  });

  test('check-in upsert, delete on zero, detail, cascade', () async {
    final id = await habits.create(draft('A'));
    await checkIns.setCount(id, '2026-11-24', 1);
    await checkIns.setCount(id, '2026-11-24', 2);
    var day = await checkIns.watchByDate('2026-11-24').first;
    expect(day.single.count, 2);

    await checkIns.saveDetail(id, '2026-11-24', score: 90, mood: 3);
    day = await checkIns.watchByDate('2026-11-24').first;
    expect(day.single.count, 2);
    expect(day.single.score, 90);

    await checkIns.setCount(id, '2026-11-01', 1);
    expect((await checkIns.watchByMonth(2026, 11).first).length, 2);
    expect((await checkIns.watchByMonth(2026, 10).first), isEmpty);

    await checkIns.setCount(id, '2026-11-24', 0);
    day = await checkIns.watchByDate('2026-11-24').first;
    expect(day.single.count, 0);
    expect(day.single.score, 90);
    expect(day.single.mood, 3);
    await checkIns.setCount(id, '2026-11-01', 0);
    expect(await checkIns.watchByDate('2026-11-01').first, isEmpty);

    await reminders.replaceForHabit(id, const [ReminderDraft(minutesOfDay: 480)]);
    await habits.delete(id);
    expect(await checkIns.watchAll().first, isEmpty);
    expect(await reminders.getAll(), isEmpty);
  });

  test('reminders replace', () async {
    final id = await habits.create(draft('A'));
    await reminders.replaceForHabit(id, const [ReminderDraft(minutesOfDay: 1200), ReminderDraft(minutesOfDay: 480)]);
    var list = await reminders.getByHabit(id);
    expect(list.map((r) => r.timeLabel), ['08:00', '20:00']);
    await reminders.replaceForHabit(id, const [ReminderDraft(minutesOfDay: 600)]);
    list = await reminders.getByHabit(id);
    expect(list.single.timeLabel, '10:00');
  });
}
