/// 今日日程（一次性事项），区别于需要反复打卡的习惯 [Habit]。
/// 纯 Dart，不依赖 Flutter / drift。
library;

/// 日程来源。
enum AgendaSource {
  /// 在 iBetter 里手动添加。
  local,

  /// 从电脑上的「轻松日程」同步过来。
  qingsong,
}

/// 本地新建日程的默认分类。
const String defaultAgendaCategory = '日程';

/// 标题最大长度。
const int agendaTitleMaxLength = 40;

String formatMinutesOfDay(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// Parses `HH:mm` into minutes of day; returns null when invalid.
int? parseHourMinute(String? text) {
  if (text == null) return null;
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

class AgendaItem {
  const AgendaItem({
    required this.id,
    required this.date,
    required this.title,
    required this.clientId,
    this.minutesOfDay,
    this.note = '',
    this.category = defaultAgendaCategory,
    this.origin = '',
    this.isDone = false,
    this.source = AgendaSource.local,
    this.remoteId,
    this.syncToRemote = false,
    this.dirty = false,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  final int id;

  /// `yyyy-MM-dd`。
  final String date;

  /// 0–1439；null 表示全天。
  final int? minutesOfDay;
  final String title;
  final String note;
  final String category;

  /// 来源说明，如轻松日程里的群名。
  final String origin;
  final bool isDone;
  final AgendaSource source;

  /// 本地唯一 id，上行到轻松日程时作为 externalId。
  final String clientId;

  /// 轻松日程里的 notice id；null 表示还没同步过去。
  final String? remoteId;

  /// 本地新建时是否需要同步到轻松日程。
  final bool syncToRemote;

  /// 完成状态改过、还没推给电脑。
  final bool dirty;
  final int createdAt;
  final int updatedAt;

  bool get isFromQingsong => source == AgendaSource.qingsong;
  bool get isLinked => remoteId != null;
  String? get timeLabel => minutesOfDay == null ? null : formatMinutesOfDay(minutesOfDay!);

  /// 首页排序：未完成在前；有时间的按时间，全天的排在最后；同时间按创建先后。
  static int compareForDisplay(AgendaItem a, AgendaItem b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    final ta = a.minutesOfDay ?? 24 * 60;
    final tb = b.minutesOfDay ?? 24 * 60;
    if (ta != tb) return ta.compareTo(tb);
    return a.createdAt.compareTo(b.createdAt);
  }

  @override
  String toString() => 'AgendaItem($id, $date ${timeLabel ?? '全天'} $title, done=$isDone, '
      'source=${source.name}, remote=$remoteId, dirty=$dirty)';
}

/// 新建日程的输入。
class AgendaDraft {
  const AgendaDraft({
    required this.date,
    required this.title,
    this.minutesOfDay,
    this.note = '',
    this.category = defaultAgendaCategory,
    this.syncToRemote = false,
  });

  final String date;
  final String title;
  final int? minutesOfDay;
  final String note;
  final String category;
  final bool syncToRemote;
}
