/// One habit's record for one local calendar day.
class CheckIn {
  const CheckIn({
    required this.id,
    required this.habitId,
    required this.date,
    required this.count,
    this.score,
    this.mood,
    this.note,
    required this.updatedAt,
  });

  final int id;
  final int habitId;

  /// `yyyy-MM-dd` local date key.
  final String date;

  /// Times completed that day. Done when `count >= habit.dailyTarget`.
  final int count;

  /// 0-100, only when habit.enableScore.
  final int? score;

  /// 0-4 (很差 ... 很好), only when habit.enableMood.
  final int? mood;
  final String? note;
  final DateTime updatedAt;
}
