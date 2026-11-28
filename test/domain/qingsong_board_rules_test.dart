import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/domain/models/agenda_item.dart';
import 'package:ibetter/domain/models/qingsong_notice.dart';
import 'package:ibetter/domain/services/qingsong_board_rules.dart';

void main() {
  final now = DateTime(2026, 11, 28, 0, 41);

  group('deadline parsing, formatting & countdown', () {
    test('formats no-deadline, same-year date/datetime, and cross-year date', () {
      expect(formatNoticeDeadline(null, now), '没有明确截止时间');
      expect(formatNoticeDeadline('2026-11-30', now), '11月30日');
      expect(formatNoticeDeadline('2026-11-28 12:00', now), '11月28日 12:00');
      expect(formatNoticeDeadline('2027-01-02', now), '2027年1月2日');
    });

    test('computes countdown text and urgency tiers matching app.js', () {
      expect(computeNoticeCountdown(null, now).urgency, CountdownUrgency.none);
      expect(computeNoticeCountdown(null, now).text, '无截止');

      final expired = computeNoticeCountdown('2026-11-27 23:00', now);
      expect(expired.urgency, CountdownUrgency.expired);
      expect(expired.text, '已截止');

      final minsLeft = computeNoticeCountdown('2026-11-28 01:15', now);
      expect(minsLeft.urgency, CountdownUrgency.urgent);
      expect(minsLeft.text, '还剩 34 分钟');

      final hoursUrgent = computeNoticeCountdown('2026-11-28 03:41', now);
      expect(hoursUrgent.urgency, CountdownUrgency.urgent);
      expect(hoursUrgent.text, '还剩 3 小时');

      final hoursSoon = computeNoticeCountdown('2026-11-28 12:00', now);
      expect(hoursSoon.urgency, CountdownUrgency.soon);
      expect(hoursSoon.text, '还剩 11 小时 19 分');

      final twoDays = computeNoticeCountdown('2026-11-30', now);
      expect(twoDays.urgency, CountdownUrgency.soon);
      expect(twoDays.text, '还剩 2 天 23 小时');

      final longTerm = computeNoticeCountdown('2027-01-02', now);
      expect(longTerm.urgency, CountdownUrgency.ok);
      expect(longTerm.text, '还剩 35 天 23 小时');
    });
  });

  group('filtering, sorting, counts & mergeBoardItems', () {
    final sample = [
      const QingsongNotice(
        id: 'n_done',
        title: '已完成旧事项',
        category: '通知',
        status: 'done',
        archivedAt: 300,
      ),
      const QingsongNotice(
        id: 'n_skip',
        title: '已忽略',
        category: '活动',
        status: 'skip',
        archivedAt: 500,
      ),
      const QingsongNotice(
        id: 'n_todo_far',
        title: '国家安全教育学习',
        category: '其他',
        deadline: '2027-01-02',
        status: 'todo',
      ),
      const QingsongNotice(
        id: 'n_new_no_dl',
        title: '宿舍区除四害消杀',
        category: '通知',
        status: 'new',
        createdAt: 200,
      ),
      const QingsongNotice(
        id: 'n_new_dl',
        title: '课堂教学问题反馈',
        category: '通知',
        deadline: '2026-11-28 12:00',
        status: 'new',
        createdAt: 100,
      ),
    ];

    test('computes tab counts accurately across all/todo/category/archive', () {
      final counts = computeBoardTabCounts(sample);
      expect(counts['all'], 3);
      expect(counts['todo'], 1);
      expect(counts['通知'], 2);
      expect(counts['其他'], 1);
      expect(counts['活动'], 0);
      expect(counts['archive'], 2);
    });

    test('sorts all tab with new notices by createdAt desc before todo by deadline', () {
      final all = filterAndSortBoardNotices(sample, 'all', now);
      expect(all.map((n) => n.id).toList(), ['n_new_no_dl', 'n_new_dl', 'n_todo_far']);

      final archive = filterAndSortBoardNotices(sample, 'archive', now);
      expect(archive.map((n) => n.id).toList(), ['n_skip', 'n_done']);

      final noticesOnly = filterAndSortBoardNotices(sample, '通知', now);
      expect(noticesOnly.map((n) => n.id).toList(), ['n_new_dl', 'n_new_no_dl']);
    });

    test('mergeBoardItems preserves cached notices and appends only unlinked local items', () {
      final local = [
        const AgendaItem(
          id: 1,
          date: '2026-11-28',
          title: '已在缓存里的',
          clientId: 'c1',
          remoteId: 'n_new_dl',
          source: AgendaSource.qingsong,
        ),
        const AgendaItem(
          id: 2,
          date: '2026-11-29',
          minutesOfDay: 540,
          title: '本地作业',
          clientId: 'c2',
          category: '作业',
          note: '交实验报告',
          source: AgendaSource.local,
        ),
      ];

      final merged = mergeBoardItems(sample, local);
      expect(merged, hasLength(sample.length + 1));
      final added = merged.last;
      expect(added.id, 'local:2');
      expect(added.category, '作业');
      expect(added.deadline, '2026-11-29 09:00');
      expect(added.status, 'todo');
      expect(added.group, '本地日程');
    });
  });
}
