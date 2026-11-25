import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../domain/date_key.dart';
import '../../domain/models/check_in.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/reminder.dart';
import 'repositories.dart';

// ---------------------------------------------------------------- mappers

Habit _habitFromRow(HabitRow r) => Habit(
      id: r.id,
      name: r.name,
      iconKey: r.iconKey,
      schedule: Schedule(
        type: ScheduleType.values[r.scheduleType.clamp(0, ScheduleType.values.length - 1)],
        value: r.scheduleValue,
        weekdaysMask: r.weekdaysMask,
      ),
      goalDays: r.goalDays,
      startDate: parseDateKey(r.startDate),
      motto: r.motto,
      enableScore: r.enableScore,
      enableMood: r.enableMood,
      dailyTarget: r.dailyTarget,
      isActive: r.isActive,
      sortOrder: r.sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    );

HabitsCompanion _companionFromDraft(HabitDraft d) => HabitsCompanion(
      name: Value(d.name.trim()),
      iconKey: Value(d.iconKey),
      scheduleType: Value(d.schedule.type.index),
      scheduleValue: Value(d.schedule.value),
      weekdaysMask: Value(d.schedule.weekdaysMask),
      goalDays: Value(d.goalDays),
      startDate: Value(dateKey(d.startDate)),
      motto: Value(d.motto),
      enableScore: Value(d.enableScore),
      enableMood: Value(d.enableMood),
      dailyTarget: Value(d.dailyTarget < 1 ? 1 : d.dailyTarget),
      isActive: Value(d.isActive),
    );

CheckIn _checkInFromRow(CheckInRow r) => CheckIn(
      id: r.id,
      habitId: r.habitId,
      date: r.date,
      count: r.doneCount,
      score: r.score,
      mood: r.mood,
      note: r.note,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    );

Reminder _reminderFromRow(ReminderRow r) => Reminder(
      id: r.id,
      habitId: r.habitId,
      minutesOfDay: r.minutesOfDay,
      weekdaysMask: r.weekdaysMask,
      enabled: r.enabled,
    );

int _now() => DateTime.now().millisecondsSinceEpoch;

// ---------------------------------------------------------------- habits

class DriftHabitRepository implements HabitRepository {
  DriftHabitRepository(this._db);
  final AppDatabase _db;

  SimpleSelectStatement<$HabitsTable, HabitRow> _ordered() =>
      _db.select(_db.habits)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]);

  @override
  Stream<List<Habit>> watchAll({bool? activeOnly}) {
    final q = _ordered();
    if (activeOnly != null) q.where((t) => t.isActive.equals(activeOnly));
    return q.watch().map((rows) => rows.map(_habitFromRow).toList());
  }

  @override
  Stream<Habit?> watchById(int id) => (_db.select(_db.habits)..where((t) => t.id.equals(id)))
      .watchSingleOrNull()
      .map((r) => r == null ? null : _habitFromRow(r));

  @override
  Future<Habit?> getById(int id) async {
    final r = await (_db.select(_db.habits)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _habitFromRow(r);
  }

  @override
  Future<int> create(HabitDraft d) async {
    final maxOrder = _db.habits.sortOrder.max();
    final row = await (_db.selectOnly(_db.habits)..addColumns([maxOrder])).getSingle();
    final next = (row.read(maxOrder) ?? -1) + 1;
    return _db.into(_db.habits).insert(_companionFromDraft(d).copyWith(
          sortOrder: Value(next),
          createdAt: Value(_now()),
        ));
  }

  @override
  Future<void> update(Habit h) async {
    await (_db.update(_db.habits)..where((t) => t.id.equals(h.id))).write(
      _companionFromDraft(h.toDraft()).copyWith(sortOrder: Value(h.sortOrder)),
    );
  }

  @override
  Future<void> setActive(int id, bool active) async {
    await (_db.update(_db.habits)..where((t) => t.id.equals(id)))
        .write(HabitsCompanion(isActive: Value(active)));
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.habits)..where((t) => t.id.equals(id))).go();
  }
}

// ---------------------------------------------------------------- check-ins

class DriftCheckInRepository implements CheckInRepository {
  DriftCheckInRepository(this._db);
  final AppDatabase _db;

  Stream<List<CheckIn>> _watch(Expression<bool> Function($CheckInsTable t) filter) =>
      (_db.select(_db.checkIns)
            ..where(filter)
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch()
          .map((rows) => rows.map(_checkInFromRow).toList());

  @override
  Stream<List<CheckIn>> watchByDate(String date) => _watch((t) => t.date.equals(date));

  @override
  Stream<List<CheckIn>> watchByHabit(int habitId) => _watch((t) => t.habitId.equals(habitId));

  @override
  Stream<List<CheckIn>> watchByMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    return watchRange(dateKey(first), dateKey(last));
  }

  @override
  Stream<List<CheckIn>> watchRange(String from, String to) =>
      _watch((t) => t.date.isBetweenValues(from, to));

  @override
  Stream<List<CheckIn>> watchAll() => _watch((t) => const Constant(true));

  @override
  Future<void> setCount(int habitId, String date, int count) async {
    if (count <= 0) {
      await _db.transaction(() async {
        final checkIns = _db.checkIns;
        final day = checkIns.habitId.equals(habitId) & checkIns.date.equals(date);
        final hasDetail = checkIns.score.isNotNull() |
            checkIns.mood.isNotNull() |
            checkIns.note.isNotNull();
        await (_db.update(checkIns)..where((_) => day & hasDetail)).write(
          CheckInsCompanion(doneCount: const Value(0), updatedAt: Value(_now())),
        );
        await (_db.delete(checkIns)..where((_) => day & hasDetail.not())).go();
      });
      return;
    }
    await _db.into(_db.checkIns).insert(
          CheckInsCompanion.insert(
            habitId: habitId,
            date: date,
            doneCount: Value(count),
            updatedAt: _now(),
          ),
          onConflict: DoUpdate(
            (old) => CheckInsCompanion(doneCount: Value(count), updatedAt: Value(_now())),
            target: [_db.checkIns.habitId, _db.checkIns.date],
          ),
        );
  }

  @override
  Future<void> saveDetail(int habitId, String date,
      {int? score, int? mood, String? note}) async {
    await _db.into(_db.checkIns).insert(
          CheckInsCompanion.insert(
            habitId: habitId,
            date: date,
            score: Value(score),
            mood: Value(mood),
            note: Value(note),
            updatedAt: _now(),
          ),
          onConflict: DoUpdate(
            (old) => CheckInsCompanion(
              score: Value(score),
              mood: Value(mood),
              note: Value(note),
              updatedAt: Value(_now()),
            ),
            target: [_db.checkIns.habitId, _db.checkIns.date],
          ),
        );
  }
}

// ---------------------------------------------------------------- reminders

class DriftReminderRepository implements ReminderRepository {
  DriftReminderRepository(this._db);
  final AppDatabase _db;

  SimpleSelectStatement<$RemindersTable, ReminderRow> _byHabit(int habitId) =>
      _db.select(_db.reminders)
        ..where((t) => t.habitId.equals(habitId))
        ..orderBy([(t) => OrderingTerm.asc(t.minutesOfDay)]);

  @override
  Stream<List<Reminder>> watchByHabit(int habitId) =>
      _byHabit(habitId).watch().map((rows) => rows.map(_reminderFromRow).toList());

  @override
  Future<List<Reminder>> getByHabit(int habitId) async =>
      (await _byHabit(habitId).get()).map(_reminderFromRow).toList();

  @override
  Future<List<Reminder>> getAll() async =>
      (await _db.select(_db.reminders).get()).map(_reminderFromRow).toList();

  @override
  Future<void> replaceForHabit(int habitId, List<ReminderDraft> items) =>
      _db.transaction(() async {
        await (_db.delete(_db.reminders)..where((t) => t.habitId.equals(habitId))).go();
        for (final r in items) {
          await _db.into(_db.reminders).insert(RemindersCompanion.insert(
                habitId: habitId,
                minutesOfDay: r.minutesOfDay.clamp(0, 1439),
                weekdaysMask: Value(r.weekdaysMask),
                enabled: Value(r.enabled),
              ));
        }
      });
}
