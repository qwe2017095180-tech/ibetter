import '../date_key.dart';

class ReminderDraft {
  const ReminderDraft({
    required this.minutesOfDay,
    this.weekdaysMask = allWeekdaysMask,
    this.enabled = true,
  });

  /// 0..1439
  final int minutesOfDay;

  /// bit0 = Sunday ... bit6 = Saturday
  final int weekdaysMask;
  final bool enabled;

  int get hour => minutesOfDay ~/ 60;
  int get minute => minutesOfDay % 60;
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class Reminder extends ReminderDraft {
  const Reminder({
    required this.id,
    required this.habitId,
    required super.minutesOfDay,
    super.weekdaysMask,
    super.enabled,
  });

  final int id;
  final int habitId;
}
