import '../../domain/models/check_in.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/reminder.dart';

/// ===== Interface contract (docs/ARCHITECTURE.md §7). Do not change without
/// recording it in docs/CHANGES.md. =====

abstract class HabitRepository {
  /// Ordered by sortOrder, then id.
  Stream<List<Habit>> watchAll({bool? activeOnly});
  Stream<Habit?> watchById(int id);
  Future<Habit?> getById(int id);
  Future<int> create(HabitDraft d);
  Future<void> update(Habit h);
  Future<void> setActive(int id, bool active);
  Future<void> delete(int id);
}

abstract class CheckInRepository {
  /// All check-ins of a `yyyy-MM-dd` date.
  Stream<List<CheckIn>> watchByDate(String date);
  Stream<List<CheckIn>> watchByHabit(int habitId);
  Stream<List<CheckIn>> watchByMonth(int year, int month);

  /// Inclusive `yyyy-MM-dd` range.
  Stream<List<CheckIn>> watchRange(String from, String to);
  Stream<List<CheckIn>> watchAll();

  /// Sets the completed count for a day. count <= 0 deletes the record.
  Future<void> setCount(int habitId, String date, int count);
  Future<void> saveDetail(int habitId, String date, {int? score, int? mood, String? note});
}

abstract class ReminderRepository {
  Stream<List<Reminder>> watchByHabit(int habitId);
  Future<List<Reminder>> getByHabit(int habitId);
  Future<List<Reminder>> getAll();

  /// Replaces all reminders of the habit atomically.
  Future<void> replaceForHabit(int habitId, List<ReminderDraft> items);
}
