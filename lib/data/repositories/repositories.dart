import '../../domain/models/agenda_item.dart';
import '../../domain/models/check_in.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/reminder.dart';
import '../../domain/services/agenda_sync_rules.dart';

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

/// 今日日程（schema v2，docs/QINGSONG_INTEGRATION.md §4–5）。
abstract class AgendaRepository {
  /// 某天可见（未隐藏）的日程，按 [AgendaItem.compareForDisplay] 排序。
  Stream<List<AgendaItem>> watchByDate(String date);

  /// 全部日程（含隐藏的），供同步合并使用。
  Future<List<AgendaItem>> getAll();

  Future<AgendaItem?> getById(int id);
  Future<int> create(AgendaDraft d);

  /// 已关联远端的条目会被标记 dirty，等待下次同步推给电脑。
  Future<void> setDone(int id, bool done);

  /// 未关联远端的直接删除；已关联的只隐藏，防止同步时被拉回来。
  Future<void> delete(int id);

  /// 需要上行新建：本地新建、勾选了同步、还没有 remoteId。
  Future<List<AgendaItem>> pendingUploads();

  /// 需要上行完成状态：dirty 且已有 remoteId。
  Future<List<AgendaItem>> pendingStatusChanges();
  Future<void> markUploaded(int id, String remoteId);

  /// 推送成功后清除 dirty；若期间状态又被改动（与 [pushedDone] 不同）则保留。
  Future<void> markStatusPushed(int id, {required bool pushedDone});
  Future<void> applyMergePlan(MergePlan plan);
}
