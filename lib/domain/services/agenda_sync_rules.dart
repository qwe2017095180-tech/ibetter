/// 轻松日程 ↔ iBetter 日程的同步规则（docs/QINGSONG_INTEGRATION.md §5）。
/// 纯 Dart：输入本地日程和远端通知，输出要执行的变更计划，由 Repository 落库。
library;

import '../date_key.dart' as dk;
import '../models/agenda_item.dart';
import '../models/qingsong_notice.dart';

/// 一条远端通知映射成的日程内容。
class RemoteAgendaEntry {
  const RemoteAgendaEntry({
    required this.remoteId,
    required this.date,
    required this.title,
    this.minutesOfDay,
    this.note = '',
    this.category = '其他',
    this.origin = '',
    this.isDone = false,
  });

  final String remoteId;
  final String date;
  final int? minutesOfDay;
  final String title;
  final String note;
  final String category;
  final String origin;
  final bool isDone;

  @override
  bool operator ==(Object other) =>
      other is RemoteAgendaEntry &&
      other.remoteId == remoteId &&
      other.date == date &&
      other.minutesOfDay == minutesOfDay &&
      other.title == title &&
      other.note == note &&
      other.category == category &&
      other.origin == origin &&
      other.isDone == isDone;

  @override
  int get hashCode =>
      Object.hash(remoteId, date, minutesOfDay, title, note, category, origin, isDone);

  @override
  String toString() => 'RemoteAgendaEntry($remoteId, $date $minutesOfDay $title, done=$isDone)';
}

/// 对一条已有本地日程的修改；null 字段表示不改。
class AgendaUpdate {
  const AgendaUpdate({required this.id, this.remoteId, this.content, this.isDone});

  final int id;

  /// 回填远端 id（自己上行过去的那条）。
  final String? remoteId;

  /// 覆盖日期/时间/标题/备注/分类/来源（只对来自轻松日程的条目）。
  final RemoteAgendaEntry? content;
  final bool? isDone;

  @override
  String toString() => 'AgendaUpdate($id, remote=$remoteId, content=$content, done=$isDone)';
}

class MergePlan {
  const MergePlan({
    this.inserts = const [],
    this.updates = const [],
    this.deletes = const [],
    this.detaches = const [],
  });

  /// 新出现的远端条目，以 [AgendaSource.qingsong] 插入。
  final List<RemoteAgendaEntry> inserts;
  final List<AgendaUpdate> updates;

  /// 要删除的本地 id。
  final List<int> deletes;

  /// 远端已删除的本地新建条目：断开关联（remoteId = null、不再同步），保留本地内容。
  final List<int> detaches;

  bool get isEmpty => inserts.isEmpty && updates.isEmpty && deletes.isEmpty && detaches.isEmpty;
}

/// 解析 `YYYY-MM-DD[ HH:mm]`；不合法返回 null。
({String date, int? minutes})? parseDeadline(String? deadline) {
  if (deadline == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{1,2}):(\d{2}))?').firstMatch(deadline.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final date = dk.dateKey(DateTime(y, mo, d));
  int? minutes;
  if (m.group(4) != null) {
    final h = int.parse(m.group(4)!);
    final min = int.parse(m.group(5)!);
    if (h <= 23 && min <= 59) minutes = h * 60 + min;
  }
  return (date: date, minutes: minutes);
}

/// 把一条通知映射成日程；返回 null 表示这条不进 iBetter 日程。
///
/// - skip（电脑上忽略了）→ 不显示
/// - 有截止时间 → 放在截止那天
/// - 没截止时间且已加入待办 → 放在卡片创建那天
/// - 没截止时间且还只是「新通知」→ 不显示，避免刷屏
RemoteAgendaEntry? mapNoticeToAgenda(QingsongNotice n) {
  if (n.isSkipped) return null;
  final title = n.title.trim();
  if (title.isEmpty) return null;
  final parsed = parseDeadline(n.deadline);
  String date;
  int? minutes;
  if (parsed != null) {
    date = parsed.date;
    minutes = parsed.minutes;
  } else if (n.status == 'todo' || n.status == 'done') {
    final created = n.createdAt;
    if (created == null) return null;
    date = dk.dateKey(DateTime.fromMillisecondsSinceEpoch(created));
  } else {
    return null;
  }
  final note = n.summary.isNotEmpty ? n.summary : _truncate(n.detail, 80);
  return RemoteAgendaEntry(
    remoteId: n.id,
    date: date,
    minutesOfDay: minutes,
    title: _truncate(title, agendaTitleMaxLength),
    note: note,
    category: n.category.isEmpty ? '其他' : n.category,
    origin: n.group,
    isDone: n.isDone,
  );
}

String _truncate(String s, int max) => s.length <= max ? s : '${s.substring(0, max)}…';

bool _sameContent(AgendaItem l, RemoteAgendaEntry e) =>
    l.date == e.date &&
    l.minutesOfDay == e.minutesOfDay &&
    l.title == e.title &&
    l.note == e.note &&
    l.category == e.category &&
    l.origin == e.origin;

/// 计算下行合并计划。调用前应已完成上行（先推后拉），所以 [local] 里的 dirty 条目
/// 一般只剩推送失败的那些，它们的完成状态以本地为准。
MergePlan planRemoteMerge(List<AgendaItem> local, List<QingsongNotice> notices) {
  final byRemoteId = <String, AgendaItem>{
    for (final l in local)
      if (l.remoteId != null) l.remoteId!: l,
  };
  final byClientId = <String, AgendaItem>{for (final l in local) l.clientId: l};
  final remoteIds = <String>{};

  final inserts = <RemoteAgendaEntry>[];
  final updates = <AgendaUpdate>[];
  final deletes = <int>[];
  final detaches = <int>[];
  final touched = <int>{};

  for (final n in notices) {
    remoteIds.add(n.id);
    final entry = mapNoticeToAgenda(n);
    var l = byRemoteId[n.id];
    var linkByExternal = false;
    if (l == null && n.externalId != null) {
      l = byClientId[n.externalId!];
      linkByExternal = l != null && l.remoteId == null;
      if (l != null && l.remoteId != null && l.remoteId != n.id) l = null;
    }
    if (l != null && !touched.add(l.id)) continue; // 同一本地条目只处理一次

    if (l == null) {
      if (entry != null) inserts.add(entry);
      continue;
    }

    if (l.source == AgendaSource.local) {
      // 手机上新建的：内容以手机为准，只同步关联和完成状态；电脑上忽略了也不删手机上的
      final done = (!l.dirty && !n.isSkipped && l.isDone != n.isDone) ? n.isDone : null;
      if (linkByExternal || done != null) {
        updates.add(AgendaUpdate(id: l.id, remoteId: linkByExternal ? n.id : null, isDone: done));
      }
      continue;
    }

    // 来自轻松日程的
    if (entry == null) {
      deletes.add(l.id);
      continue;
    }
    final content = _sameContent(l, entry) ? null : entry;
    final done = (!l.dirty && l.isDone != entry.isDone) ? entry.isDone : null;
    if (content != null || done != null) {
      updates.add(AgendaUpdate(id: l.id, content: content, isDone: done));
    }
  }

  for (final l in local) {
    if (l.remoteId == null || remoteIds.contains(l.remoteId)) continue;
    if (touched.contains(l.id)) continue;
    if (l.source == AgendaSource.qingsong) {
      // 电脑上已删除（或归档超过 7 天被清理）：未完成的删掉，已完成的留作记录
      if (!l.isDone) deletes.add(l.id);
    } else {
      detaches.add(l.id);
    }
  }

  return MergePlan(inserts: inserts, updates: updates, deletes: deletes, detaches: detaches);
}
