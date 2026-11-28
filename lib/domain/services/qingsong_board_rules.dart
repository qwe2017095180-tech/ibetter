/// 纯 Dart「轻松日程」看板过滤、排序、截止时间与倒计时规则（与 PC 端 app.js 一致）。
library;

import '../models/agenda_item.dart';
import '../models/qingsong_notice.dart';

const List<String> kQingsongCategories = [
  '作业',
  '兼职',
  '比赛',
  '活动',
  '志愿',
  '通知',
  '其他',
];

const Map<String, String> kQingsongCategoryEmojis = {
  '作业': '📘',
  '兼职': '💼',
  '比赛': '🏆',
  '活动': '🎪',
  '志愿': '🤝',
  '通知': '📢',
  '其他': '📎',
};

class QingsongBoardTab {
  const QingsongBoardTab({
    required this.id,
    required this.label,
    this.emoji = '',
  });

  final String id;
  final String label;
  final String emoji;
}

const List<QingsongBoardTab> kQingsongBoardTabs = [
  QingsongBoardTab(id: 'all', label: '全部'),
  QingsongBoardTab(id: 'todo', label: '待办', emoji: '⏳'),
  QingsongBoardTab(id: '作业', label: '作业', emoji: '📘'),
  QingsongBoardTab(id: '兼职', label: '兼职', emoji: '💼'),
  QingsongBoardTab(id: '比赛', label: '比赛', emoji: '🏆'),
  QingsongBoardTab(id: '活动', label: '活动', emoji: '🎪'),
  QingsongBoardTab(id: '志愿', label: '志愿', emoji: '🤝'),
  QingsongBoardTab(id: '通知', label: '通知', emoji: '📢'),
  QingsongBoardTab(id: '其他', label: '其他', emoji: '📎'),
  QingsongBoardTab(id: 'archive', label: '归档', emoji: '🗃️'),
];

/// Parses `YYYY-MM-DD HH:mm` (exact minute) or `YYYY-MM-DD` (end of day 23:59:59).
DateTime? parseNoticeDeadline(String? deadline) {
  if (deadline == null) return null;
  final trimmed = deadline.trim();
  if (trimmed.isEmpty) return null;
  final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T](\d{1,2})[:：](\d{2}))?')
      .firstMatch(trimmed);
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  if (m.group(4) != null) {
    final h = int.parse(m.group(4)!);
    final min = int.parse(m.group(5)!);
    if (h > 23 || min > 59) return null;
    return DateTime(y, mo, d, h, min);
  }
  return DateTime(y, mo, d, 23, 59, 59);
}

bool noticeDeadlineHasTime(String? deadline) =>
    deadline != null && RegExp(r'[:：]\d{2}').hasMatch(deadline);

/// Formats deadline like `没有明确截止时间`, `11月30日`, `11月28日 12:00`, or `2027年1月2日`.
String formatNoticeDeadline(String? deadline, DateTime now) {
  final d = parseNoticeDeadline(deadline);
  if (d == null) return '没有明确截止时间';
  final yearPrefix = d.year == now.year ? '' : '${d.year}年';
  final datePart = '$yearPrefix${d.month}月${d.day}日';
  if (noticeDeadlineHasTime(deadline)) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$datePart $hh:$mm';
  }
  return datePart;
}

enum CountdownUrgency { none, ok, soon, urgent, expired }

class NoticeCountdown {
  const NoticeCountdown({required this.text, required this.urgency});

  final String text;
  final CountdownUrgency urgency;
}

/// Computes remaining time label and urgency matching `wechat-schedule/public/app.js`.
NoticeCountdown computeNoticeCountdown(String? deadline, DateTime now) {
  final d = parseNoticeDeadline(deadline);
  if (d == null) {
    return const NoticeCountdown(text: '无截止', urgency: CountdownUrgency.none);
  }
  final ms = d.difference(now).inMilliseconds;
  if (ms <= 0) {
    return const NoticeCountdown(text: '已截止', urgency: CountdownUrgency.expired);
  }
  final mins = ms / 60000.0;
  if (mins < 60) {
    return NoticeCountdown(
      text: '还剩 ${mins.ceil()} 分钟',
      urgency: CountdownUrgency.urgent,
    );
  }
  if (mins < 24 * 60) {
    var h = mins ~/ 60;
    var m = (mins % 60).round();
    if (m == 60) {
      h += 1;
      m = 0;
    }
    final text = m > 0 ? '还剩 $h 小时 $m 分' : '还剩 $h 小时';
    return NoticeCountdown(
      text: text,
      urgency: mins < 6 * 60 ? CountdownUrgency.urgent : CountdownUrgency.soon,
    );
  }
  final days = mins ~/ 1440;
  final hh = ((mins % 1440) ~/ 60);
  final text = hh > 0 ? '还剩 $days 天 $hh 小时' : '还剩 $days 天';
  return NoticeCountdown(
    text: text,
    urgency: days <= 2 ? CountdownUrgency.soon : CountdownUrgency.ok,
  );
}

String normalizeNoticeCategory(String raw) =>
    kQingsongCategories.contains(raw) ? raw : '其他';

/// Merges cached PC notices with any unlinked local phone [AgendaItem]s.
List<QingsongNotice> mergeBoardItems(
  List<QingsongNotice> cachedNotices,
  List<AgendaItem> localVisible,
) {
  final cachedIds = <String>{for (final n in cachedNotices) n.id};
  final merged = List<QingsongNotice>.of(cachedNotices);

  for (final item in localVisible) {
    if (item.remoteId != null && cachedIds.contains(item.remoteId)) {
      continue;
    }
    merged.add(
      QingsongNotice(
        id: 'local:${item.id}',
        title: item.title,
        summary: item.note,
        detail: item.note,
        category: normalizeNoticeCategory(item.category),
        deadline: item.timeLabel != null ? '${item.date} ${item.timeLabel}' : item.date,
        status: item.isDone ? 'done' : 'todo',
        group: item.origin.isNotEmpty ? item.origin : '本地日程',
        externalId: item.clientId,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        archivedAt: item.isDone ? item.updatedAt : null,
      ),
    );
  }
  return merged;
}

/// Computes badge counts for each board tab.
Map<String, int> computeBoardTabCounts(List<QingsongNotice> items) {
  final counts = <String, int>{
    for (final tab in kQingsongBoardTabs) tab.id: 0,
  };
  for (final n in items) {
    if (n.isArchived) {
      counts['archive'] = (counts['archive'] ?? 0) + 1;
      continue;
    }
    counts['all'] = (counts['all'] ?? 0) + 1;
    if (n.isTodo) {
      counts['todo'] = (counts['todo'] ?? 0) + 1;
    }
    final cat = normalizeNoticeCategory(n.category);
    counts[cat] = (counts[cat] ?? 0) + 1;
  }
  return counts;
}

const int _noDeadlineSortMs = 9000000000000000;

int _deadlineSortKey(QingsongNotice n) {
  final d = parseNoticeDeadline(n.deadline);
  return d == null ? _noDeadlineSortMs : d.millisecondsSinceEpoch;
}

int _statusRank(String status) => switch (status) {
      'new' => 0,
      'todo' => 1,
      'done' => 2,
      'skip' => 3,
      _ => 1,
    };

/// Filters and sorts [items] for the active [tab] matching `wechat-schedule/public/app.js`.
List<QingsongNotice> filterAndSortBoardNotices(
  List<QingsongNotice> items,
  String tab,
  DateTime now,
) {
  final filtered = items.where((n) {
    if (tab == 'all') return !n.isArchived;
    if (tab == 'todo') return n.isTodo;
    if (tab == 'archive') return n.isArchived;
    return !n.isArchived && normalizeNoticeCategory(n.category) == tab;
  }).toList();

  if (tab == 'all') {
    filtered.sort((a, b) {
      final ra = _statusRank(a.status);
      final rb = _statusRank(b.status);
      if (ra != rb) return ra.compareTo(rb);
      if (a.isNew && b.isNew) {
        return (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
      }
      final cmpDl = _deadlineSortKey(a).compareTo(_deadlineSortKey(b));
      if (cmpDl != 0) return cmpDl;
      return (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
    });
  } else if (tab == 'archive') {
    filtered.sort((a, b) {
      final ta = a.archivedAt ?? a.updatedAt ?? a.createdAt ?? 0;
      final tb = b.archivedAt ?? b.updatedAt ?? b.createdAt ?? 0;
      return tb.compareTo(ta);
    });
  } else {
    filtered.sort((a, b) {
      final cmpDl = _deadlineSortKey(a).compareTo(_deadlineSortKey(b));
      if (cmpDl != 0) return cmpDl;
      return (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
    });
  }

  return filtered;
}
