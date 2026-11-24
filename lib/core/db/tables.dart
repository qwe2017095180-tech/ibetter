import 'package:drift/drift.dart';

@DataClassName('HabitRow')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconKey => text()();
  IntColumn get scheduleType => integer().withDefault(const Constant(0))();
  IntColumn get scheduleValue => integer().withDefault(const Constant(0))();
  IntColumn get weekdaysMask => integer().withDefault(const Constant(127))();
  IntColumn get goalDays => integer().nullable()();
  TextColumn get startDate => text()();
  TextColumn get motto => text().withDefault(const Constant(''))();
  BoolColumn get enableScore => boolean().withDefault(const Constant(false))();
  BoolColumn get enableMood => boolean().withDefault(const Constant(false))();
  IntColumn get dailyTarget => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
}

@DataClassName('CheckInRow')
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()();
  IntColumn get doneCount => integer().named('count').withDefault(const Constant(0))();
  IntColumn get score => integer().nullable()();
  IntColumn get mood => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date},
      ];
}

@DataClassName('ReminderRow')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get minutesOfDay => integer()();
  IntColumn get weekdaysMask => integer().withDefault(const Constant(127))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
