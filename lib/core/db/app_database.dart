import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Habits, CheckIns, Reminders, AgendaItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// On-device database (ibetter.sqlite in app documents).
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'ibetter'));

  /// v1: habits / check_ins / reminders
  /// v2: agenda_items（今日日程 + 轻松日程同步）
  @override
  int get schemaVersion => 2;

  static const _agendaDateIndex =
      'CREATE INDEX IF NOT EXISTS idx_agenda_items_date ON agenda_items (date)';

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_check_ins_date ON check_ins (date)');
          await customStatement(_agendaDateIndex);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(agendaItems);
            await customStatement(_agendaDateIndex);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
