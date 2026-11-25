import 'dart:io';

import 'package:drift/drift.dart' show GeneratedDatabase, Table, TableInfo, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/data/repositories/drift_agenda_repository.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/agenda_item.dart';
import 'package:ibetter/domain/services/agenda_sync_rules.dart';

class _V1SeedDatabase extends GeneratedDatabase {
  _V1SeedDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftAgendaRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftAgendaRepository(db);
  });

  tearDown(() => db.close());

  test('create, display ordering, toggle done, and delete', () async {
    final idAllDay = await repo.create(const AgendaDraft(
      date: '2026-11-25',
      title: '全天事项',
    ));
    final idEvening = await repo.create(const AgendaDraft(
      date: '2026-11-25',
      minutesOfDay: 19 * 60,
      title: '晚上开会',
      syncToRemote: true,
    ));
    final idMorning = await repo.create(const AgendaDraft(
      date: '2026-11-25',
      minutesOfDay: 9 * 60,
      title: '早起复习',
    ));

    var list = await repo.watchByDate('2026-11-25').first;
    expect(list.map((e) => e.id), [idMorning, idEvening, idAllDay]);

    // Marking morning done moves it after unfinished items.
    await repo.setDone(idMorning, true);
    list = await repo.watchByDate('2026-11-25').first;
    expect(list.map((e) => e.id), [idEvening, idAllDay, idMorning]);
    expect(list.last.dirty, isFalse); // local unlinked item does not mark dirty

    // Pending uploads only includes syncToRemote items without remoteId.
    final pending = await repo.pendingUploads();
    expect(pending.map((e) => e.id), [idEvening]);

    // After marking uploaded, toggling done sets dirty = true.
    await repo.markUploaded(idEvening, 'qs-remote-1');
    expect(await repo.pendingUploads(), isEmpty);
    await repo.setDone(idEvening, true);
    final dirtyList = await repo.pendingStatusChanges();
    expect(dirtyList.map((e) => e.id), [idEvening]);
    await repo.markStatusPushed(idEvening, pushedDone: true);
    expect(await repo.pendingStatusChanges(), isEmpty);

    // Deleting unlinked item removes row; deleting linked item hides it.
    await repo.delete(idAllDay);
    await repo.delete(idEvening);
    list = await repo.watchByDate('2026-11-25').first;
    expect(list.map((e) => e.id), [idMorning]);
    final all = await repo.getAll();
    expect(all.any((e) => e.id == idAllDay), isFalse);
    expect(all.any((e) => e.id == idEvening), isTrue); // hidden row kept to avoid re-import
  });

  test('applyMergePlan inserts, updates, detaches, and deletes', () async {
    final localId = await repo.create(const AgendaDraft(
      date: '2026-11-25',
      title: '本地同步项',
      syncToRemote: true,
    ));
    await repo.markUploaded(localId, 'r-local');

    await repo.applyMergePlan(const MergePlan(
      inserts: [
        RemoteAgendaEntry(
          remoteId: 'r-1',
          date: '2026-11-25',
          minutesOfDay: 16 * 60,
          title: '交设计表达作业',
          note: 'A3 纸',
          category: '作业',
          origin: '设计班群',
        ),
      ],
      detaches: [],
    ));

    var list = await repo.watchByDate('2026-11-25').first;
    expect(list.length, 2);
    final remoteItem = list.singleWhere((e) => e.remoteId == 'r-1');
    expect(remoteItem.source, AgendaSource.qingsong);
    expect(remoteItem.origin, '设计班群');

    await repo.applyMergePlan(MergePlan(
      updates: [AgendaUpdate(id: remoteItem.id, isDone: true)],
      detaches: [localId],
    ));

    final updatedLocal = await repo.getById(localId);
    expect(updatedLocal!.remoteId, isNull);
    expect(updatedLocal.syncToRemote, isFalse);
    final updatedRemote = await repo.getById(remoteItem.id);
    expect(updatedRemote!.isDone, isTrue);
  });

  test('upgrades an existing v1 SQLite file to v2 without losing habits', () async {
    final tmpDir = await Directory.systemTemp.createTemp('ibetter_mig_');
    final dbFile = File('${tmpDir.path}/v1.sqlite');
    try {
      final v1 = _V1SeedDatabase(NativeDatabase(dbFile));
      await v1.customStatement('''
        CREATE TABLE habits (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon_key TEXT NOT NULL,
          schedule_type INTEGER NOT NULL DEFAULT 0,
          schedule_value INTEGER NOT NULL DEFAULT 0,
          weekdays_mask INTEGER NOT NULL DEFAULT 127,
          goal_days INTEGER NULL,
          start_date TEXT NOT NULL,
          motto TEXT NOT NULL DEFAULT '',
          enable_score INTEGER NOT NULL DEFAULT 0,
          enable_mood INTEGER NOT NULL DEFAULT 0,
          daily_target INTEGER NOT NULL DEFAULT 1,
          is_active INTEGER NOT NULL DEFAULT 1,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )''');
      await v1.customStatement('''
        CREATE TABLE check_ins (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
          date TEXT NOT NULL,
          count INTEGER NOT NULL DEFAULT 0,
          score INTEGER NULL,
          mood INTEGER NULL,
          note TEXT NULL,
          updated_at INTEGER NOT NULL,
          UNIQUE (habit_id, date)
        )''');
      await v1.customStatement('''
        CREATE TABLE reminders (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
          minutes_of_day INTEGER NOT NULL,
          weekdays_mask INTEGER NOT NULL DEFAULT 127,
          enabled INTEGER NOT NULL DEFAULT 1
        )''');
      await v1.customStatement('''
        INSERT INTO habits (name, icon_key, start_date, created_at)
        VALUES ('保留旧习惯', 'study/book', '2026-11-01', 1795000000000)''');
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      final upgraded = AppDatabase(NativeDatabase(dbFile));
      try {
        final habits = await DriftHabitRepository(upgraded).watchAll().first;
        expect(habits.single.name, '保留旧习惯');

        final agendaRepo = DriftAgendaRepository(upgraded);
        final id = await agendaRepo.create(const AgendaDraft(
          date: '2026-11-25',
          title: '升级后新增日程',
        ));
        final items = await agendaRepo.watchByDate('2026-11-25').first;
        expect(items.single.id, id);
      } finally {
        await upgraded.close();
      }
    } finally {
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    }
  });
}
