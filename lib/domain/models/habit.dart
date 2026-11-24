import '../date_key.dart';

/// How often a habit should be performed.
enum ScheduleType {
  /// 每天
  daily,

  /// 每周（指定星期几，见 [Schedule.weekdaysMask]）
  weekdays,

  /// 每周 x 天（周内任意 x 天）
  timesPerWeek,

  /// 每月 x 天（月内任意 x 天）
  timesPerMonth,
}

class Schedule {
  const Schedule({
    this.type = ScheduleType.daily,
    this.value = 0,
    this.weekdaysMask = allWeekdaysMask,
  });

  const Schedule.daily() : this();
  const Schedule.weekdays(int mask) : this(type: ScheduleType.weekdays, weekdaysMask: mask);
  const Schedule.timesPerWeek(int x) : this(type: ScheduleType.timesPerWeek, value: x);
  const Schedule.timesPerMonth(int x) : this(type: ScheduleType.timesPerMonth, value: x);

  final ScheduleType type;

  /// x for [ScheduleType.timesPerWeek] (1-7) / [ScheduleType.timesPerMonth] (1-31).
  final int value;

  /// bit0 = Sunday ... bit6 = Saturday; used by [ScheduleType.weekdays].
  final int weekdaysMask;

  /// Human readable label (zh-CN), e.g. 每天 / 每周一三五 / 每周3天 / 每月10天.
  String get label {
    switch (type) {
      case ScheduleType.daily:
        return '每天';
      case ScheduleType.weekdays:
        if (weekdaysMask == allWeekdaysMask) return '每天';
        const names = ['日', '一', '二', '三', '四', '五', '六'];
        final b = StringBuffer('每周');
        for (var i = 0; i < 7; i++) {
          if (maskHas(weekdaysMask, i)) b.write(names[i]);
        }
        return b.toString();
      case ScheduleType.timesPerWeek:
        return '每周$value天';
      case ScheduleType.timesPerMonth:
        return '每月$value天';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Schedule &&
      other.type == type &&
      other.value == value &&
      other.weekdaysMask == weekdaysMask;

  @override
  int get hashCode => Object.hash(type, value, weekdaysMask);
}

/// Editable fields of a habit (used for create / update forms).
class HabitDraft {
  const HabitDraft({
    required this.name,
    required this.iconKey,
    this.schedule = const Schedule.daily(),
    this.goalDays,
    required this.startDate,
    this.motto = '',
    this.enableScore = false,
    this.enableMood = false,
    this.dailyTarget = 1,
    this.isActive = true,
  });

  final String name;
  final String iconKey;
  final Schedule schedule;

  /// null = 永远
  final int? goalDays;

  /// Local midnight.
  final DateTime startDate;
  final String motto;
  final bool enableScore;
  final bool enableMood;

  /// 每日打卡次数 (>= 1)
  final int dailyTarget;
  final bool isActive;
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.iconKey,
    this.schedule = const Schedule.daily(),
    this.goalDays,
    required this.startDate,
    this.motto = '',
    this.enableScore = false,
    this.enableMood = false,
    this.dailyTarget = 1,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String iconKey;
  final Schedule schedule;
  final int? goalDays;
  final DateTime startDate;
  final String motto;
  final bool enableScore;
  final bool enableMood;
  final int dailyTarget;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  String get goalLabel => goalDays == null ? '永远' : '$goalDays天';

  HabitDraft toDraft() => HabitDraft(
        name: name,
        iconKey: iconKey,
        schedule: schedule,
        goalDays: goalDays,
        startDate: startDate,
        motto: motto,
        enableScore: enableScore,
        enableMood: enableMood,
        dailyTarget: dailyTarget,
        isActive: isActive,
      );

  Habit copyWithDraft(HabitDraft d) => Habit(
        id: id,
        name: d.name,
        iconKey: d.iconKey,
        schedule: d.schedule,
        goalDays: d.goalDays,
        startDate: d.startDate,
        motto: d.motto,
        enableScore: d.enableScore,
        enableMood: d.enableMood,
        dailyTarget: d.dailyTarget,
        isActive: d.isActive,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  Habit copyWith({bool? isActive, int? sortOrder}) => Habit(
        id: id,
        name: name,
        iconKey: iconKey,
        schedule: schedule,
        goalDays: goalDays,
        startDate: startDate,
        motto: motto,
        enableScore: enableScore,
        enableMood: enableMood,
        dailyTarget: dailyTarget,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}
