import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Habits, CheckIns, Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// On-device database (ibetter.sqlite in app documents).
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'ibetter'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_check_ins_date ON check_ins (date)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
