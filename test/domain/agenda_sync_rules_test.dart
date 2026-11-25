import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/domain/models/agenda_item.dart';
import 'package:ibetter/domain/models/qingsong_notice.dart';
import 'package:ibetter/domain/services/agenda_sync_rules.dart';

void main() {
  group('parseDeadline', () {
    test('parses date + HH:mm and date-only', () {
      expect(parseDeadline('2026-11-25 16:30'), (date: '2026-11-25', minutes: 16 * 60 + 30));
      expect(parseDeadline('2026-11-25'), (date: '2026-11-25', minutes: null));
      expect(parseDeadline('2026-11-25T08:05'), (date: '2026-11-25', minutes: 8 * 60 + 5));
      expect(parseDeadline('invalid'), isNull);
      expect(parseDeadline(null), isNull);
    });
  });

  group('mapNoticeToAgenda', () {
    test('maps deadline notice regardless of new/todo status', () {
      const n = QingsongNotice(
        id: 'n1',
        title: '交设计表达作业',
        summary: 'A3 纸 5 视图',
        category: '作业',
        deadline: '2026-11-25 16:00',
        status: 'new',
        group: '设计班群',
      );
      final e = mapNoticeToAgenda(n);
      expect(e, isNotNull);
      expect(e!.date, '2026-11-25');
      expect(e.minutesOfDay, 960);
      expect(e.title, '交设计表达作业');
      expect(e.note, 'A3 纸 5 视图');
      expect(e.origin, '设计班群');
      expect(e.isDone, isFalse);
    });

    test('skips skip-status and new-status without deadline', () {
      expect(
        mapNoticeToAgenda(const QingsongNotice(
          id: 'n2',
          title: '忽略通知',
          deadline: '2026-11-25',
          status: 'skip',
        )),
        isNull,
      );
      expect(
        mapNoticeToAgenda(QingsongNotice(
          id: 'n3',
          title: '普通新通知',
          status: 'new',
          createdAt: DateTime(2026, 11, 25, 10, 0).millisecondsSinceEpoch,
        )),
        isNull,
      );
    });

    test('places todo notice without deadline on its createdAt date', () {
      final created = DateTime(2026, 11, 25, 9, 30).millisecondsSinceEpoch;
      final e = mapNoticeToAgenda(QingsongNotice(
        id: 'n4',
        title: '社团会议',
        status: 'todo',
        category: '活动',
        createdAt: created,
      ));
      expect(e, isNotNull);
      expect(e!.date, '2026-11-25');
      expect(e.minutesOfDay, isNull);
    });
  });

  group('planRemoteMerge', () {
    test('inserts new remote, links externalId without duplicate, preserves dirty local', () {
      final local = [
        const AgendaItem(
          id: 1,
          date: '2026-11-25',
          title: '去图书馆还书',
          clientId: 'ib-local-1',
          source: AgendaSource.local,
          syncToRemote: true,
        ),
        const AgendaItem(
          id: 2,
          date: '2026-11-25',
          title: '已有远端项',
          clientId: 'qs-n2',
          remoteId: 'n2',
          source: AgendaSource.qingsong,
          isDone: true,
          dirty: true, // local change not yet pushed
        ),
        const AgendaItem(
          id: 3,
          date: '2026-11-25',
          title: '电脑已删未完成',
          clientId: 'qs-gone',
          remoteId: 'gone',
          source: AgendaSource.qingsong,
          isDone: false,
        ),
        const AgendaItem(
          id: 4,
          date: '2026-11-25',
          title: '本地创建但电脑已删',
          clientId: 'ib-gone',
          remoteId: 'gone-local',
          source: AgendaSource.local,
        ),
      ];

      final notices = [
        const QingsongNotice(
          id: 'r-from-local',
          title: '去图书馆还书',
          deadline: '2026-11-25',
          status: 'done',
          externalId: 'ib-local-1',
        ),
        const QingsongNotice(
          id: 'n2',
          title: '已有远端项（改名）',
          deadline: '2026-11-25 18:00',
          status: 'todo',
          category: '作业',
        ),
        const QingsongNotice(
          id: 'n-brand-new',
          title: '新作业通知',
          deadline: '2026-11-26 20:00',
          status: 'new',
          category: '作业',
        ),
      ];

      final plan = planRemoteMerge(local, notices);

      expect(plan.inserts.map((e) => e.remoteId), ['n-brand-new']);
      expect(plan.deletes, [3]);
      expect(plan.detaches, [4]);

      final u1 = plan.updates.singleWhere((u) => u.id == 1);
      expect(u1.remoteId, 'r-from-local');
      expect(u1.isDone, isTrue);
      expect(u1.content, isNull); // local content untouched

      final u2 = plan.updates.singleWhere((u) => u.id == 2);
      expect(u2.content?.title, '已有远端项（改名）');
      expect(u2.isDone, isNull); // dirty item keeps local done status
    });
  });
}
