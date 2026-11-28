import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/data/repositories/drift_agenda_repository.dart';
import 'package:ibetter/domain/models/agenda_item.dart';
import 'package:ibetter/domain/models/qingsong_notice.dart';
import 'package:ibetter/features/qingsong/qingsong_client.dart';
import 'package:ibetter/features/qingsong/qingsong_sync_service.dart';

class _FakeQingsongApi implements QingsongApi {
  final List<QingsongNotice> remoteNotices = [];
  final List<({String id, bool done})> statusCalls = [];
  int _seq = 0;

  @override
  Future<QingsongPing> ping() async => const QingsongPing(version: '1.1.1', protocol: 1);

  @override
  Future<List<QingsongNotice>> fetchNotices() async => List.of(remoteNotices);

  @override
  Future<Map<String, String>> createItems(List<AgendaItem> items) async {
    final map = <String, String>{};
    for (final it in items) {
      final id = 'qs-${++_seq}';
      map[it.clientId] = id;
      remoteNotices.add(QingsongNotice(
        id: id,
        title: it.title,
        summary: it.note,
        deadline: it.timeLabel != null ? '${it.date} ${it.timeLabel}' : it.date,
        status: 'todo',
        group: 'iBetter',
        externalId: it.clientId,
      ));
    }
    return map;
  }

  @override
  Future<void> setStatus(String remoteId, {required bool done}) async {
    statusCalls.add((id: remoteId, done: done));
    final idx = remoteNotices.indexWhere((n) => n.id == remoteId);
    if (idx < 0) throw const QingsongException('not found', statusCode: 404);
    final old = remoteNotices[idx];
    remoteNotices[idx] = QingsongNotice(
      id: old.id,
      title: old.title,
      summary: old.summary,
      deadline: old.deadline,
      status: done ? 'done' : 'todo',
      group: old.group,
      externalId: old.externalId,
    );
  }

  @override
  Future<QingsongNotice?> setNoticeStatus(String remoteId, String status) async {
    final idx = remoteNotices.indexWhere((n) => n.id == remoteId);
    if (idx < 0) throw const QingsongException('not found', statusCode: 404);
    final updated = remoteNotices[idx].copyWith(status: status);
    remoteNotices[idx] = updated;
    return updated;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('normalizeQingsongAddress handles bare IP, host:port, and full URL', () {
    expect(normalizeQingsongAddress('192.168.1.8').toString(), 'http://192.168.1.8:7790');
    expect(normalizeQingsongAddress('192.168.1.8:8000').toString(), 'http://192.168.1.8:8000');
    expect(normalizeQingsongAddress('http://10.0.0.2:7790/').toString(), 'http://10.0.0.2:7790');
    expect(normalizeQingsongAddress('   '), isNull);
    expect(normalizeQingsongAddress('ftp://192.168.1.8'), isNull);
  });

  group('QingsongSyncService', () {
    late AppDatabase db;
    late DriftAgendaRepository repo;
    late _FakeQingsongApi api;
    late QingsongSyncService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftAgendaRepository(db);
      api = _FakeQingsongApi();
      service = QingsongSyncService(api: api, repository: repo);
    });

    tearDown(() => db.close());

    test('pushes new local item, pulls remote notice, and syncs status bidirectionally', () async {
      // Seed one remote notice on PC and one local agenda on phone.
      api.remoteNotices.add(const QingsongNotice(
        id: 'pc-1',
        title: '交设计表达作业',
        summary: 'A3 五视图',
        category: '作业',
        deadline: '2026-11-25 16:00',
        status: 'new',
        group: '设计班群',
      ));

      final localId = await repo.create(const AgendaDraft(
        date: '2026-11-25',
        minutesOfDay: 18 * 60 + 30,
        title: '去图书馆还书',
        note: '三本专业书',
        syncToRemote: true,
      ));

      // First sync: uploads local item + pulls pc-1.
      final r1 = await service.sync();
      expect(r1.uploaded, 1);
      expect(r1.inserted, 1);

      final todayItems = await repo.watchByDate('2026-11-25').first;
      expect(todayItems.length, 2);
      final pcItem = todayItems.singleWhere((e) => e.remoteId == 'pc-1');
      final syncedLocal = todayItems.singleWhere((e) => e.id == localId);
      expect(syncedLocal.remoteId, isNotNull);

      // User completes pc-1 on phone -> next sync pushes done to PC.
      await repo.setDone(pcItem.id, true);
      final r2 = await service.sync();
      expect(r2.statusPushed, 1);
      expect(api.remoteNotices.singleWhere((n) => n.id == 'pc-1').status, 'done');

      // PC marks local item done -> next sync updates phone.
      await api.setStatus(syncedLocal.remoteId!, done: true);
      final r3 = await service.sync();
      expect(r3.updated, 1);
      expect((await repo.getById(localId))!.isDone, isTrue);
    });
  });

  test('QingsongClient communicates over real HTTP and checks Bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    const expectedToken = 'ABCD2345';
    final stored = <Map<String, dynamic>>[
      {
        'id': 'n1',
        'title': '实验报告',
        'summary': '周五提交',
        'category': '作业',
        'deadline': '2026-11-25 20:00',
        'status': 'todo',
        'group': '课程群',
      },
    ];

    server.listen((req) async {
      final auth = req.headers.value(HttpHeaders.authorizationHeader);
      if (auth != 'Bearer $expectedToken') {
        req.response
          ..statusCode = 401
          ..write(jsonEncode({'ok': false, 'error': '配对码不对'}));
        await req.response.close();
        return;
      }
      final bodyText = await utf8.decoder.bind(req).join();
      final body = bodyText.isEmpty ? <String, dynamic>{} : jsonDecode(bodyText) as Map<String, dynamic>;

      if (req.uri.path == '/bridge/v1/ping') {
        req.response.write(jsonEncode({'ok': true, 'app': 'qingsong-rili', 'version': '1.1.1', 'protocol': 1}));
      } else if (req.uri.path == '/bridge/v1/notices' && req.method == 'GET') {
        req.response.write(jsonEncode({'ok': true, 'notices': stored}));
      } else if (req.uri.path == '/bridge/v1/notices' && req.method == 'POST') {
        final items = body['items'] as List;
        final created = [
          for (final it in items)
            {
              'clientId': (it as Map)['clientId'],
              'id': 'srv-${it['clientId']}',
              'category': it['category'],
            },
        ];
        req.response.write(jsonEncode({'ok': true, 'items': created}));
      } else if (req.uri.path == '/bridge/v1/notices/status') {
        req.response.write(jsonEncode({'ok': true}));
      }
      await req.response.close();
    });

    final baseUri = Uri.parse('http://127.0.0.1:${server.port}');
    final badClient = QingsongClient(baseUri: baseUri, token: 'WRONG');
    expect(() => badClient.ping(), throwsA(isA<QingsongException>().having((e) => e.statusCode, 'status', 401)));

    final client = QingsongClient(baseUri: baseUri, token: 'abcd2345'); // lowercase auto-uppercased
    final ping = await client.ping();
    expect(ping.version, '1.1.1');
    final notices = await client.fetchNotices();
    expect(notices.single.title, '实验报告');
    final created = await client.createItems(const [
      AgendaItem(id: 1, date: '2026-11-25', title: '买文具', category: '作业', clientId: 'ib-1'),
    ]);
    expect(created['ib-1'], 'srv-ib-1');
    await client.setStatus('n1', done: true);
  });
}
