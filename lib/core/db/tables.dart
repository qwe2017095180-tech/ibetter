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

/// 今日日程（schema v2）。见 docs/QINGSONG_INTEGRATION.md §4。
@DataClassName('AgendaRow')
class AgendaItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  IntColumn get minutesOfDay => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('日程'))();
  TextColumn get origin => text().withDefault(const Constant(''))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// 0 = iBetter 本地新建，1 = 来自轻松日程。
  IntColumn get source => integer().withDefault(const Constant(0))();
  TextColumn get clientId => text().unique()();
  TextColumn get remoteId => text().nullable().unique()();
  BoolColumn get syncToRemote => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  /// 已关联远端的条目在手机上删除时只隐藏，避免下次同步又被拉回来。
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
