import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibetter/app/router.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/prefs/app_prefs.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_agenda_repository.dart';
import 'package:ibetter/domain/models/agenda_item.dart';
import 'package:ibetter/domain/models/qingsong_notice.dart';
import 'package:ibetter/features/qingsong/qingsong_board_page.dart';
import 'package:ibetter/features/qingsong/qingsong_client.dart';
import 'package:ibetter/features/qingsong/qingsong_config.dart';
import 'package:ibetter/features/qingsong/qingsong_notice_cache.dart';
import 'package:ibetter/features/qingsong/qingsong_providers.dart';
import 'package:material_ui/material_ui.dart';

class _BoardFakeApi implements QingsongApi {
  _BoardFakeApi({
    List<QingsongNotice>? remoteNotices,
    this.rejectNonTodoStatus = false,
  }) : remoteNotices = List<QingsongNotice>.of(remoteNotices ?? const []);

  final List<QingsongNotice> remoteNotices;
  final bool rejectNonTodoStatus;
  final List<({String id, String status})> statusCalls = [];
  int fetchCalls = 0;

  @override
  Future<QingsongPing> ping() async => const QingsongPing(version: '1.3.0', protocol: 1);

  @override
  Future<List<QingsongNotice>> fetchNotices() async {
    fetchCalls++;
    return List<QingsongNotice>.of(remoteNotices);
  }

  @override
  Future<Map<String, String>> createItems(List<AgendaItem> items) async => const {};

  @override
  Future<void> setStatus(String remoteId, {required bool done}) async {
    await setNoticeStatus(remoteId, done ? 'done' : 'todo');
  }

  @override
  Future<QingsongNotice?> setNoticeStatus(String remoteId, String status) async {
    statusCalls.add((id: remoteId, status: status));
    if (rejectNonTodoStatus && status != 'todo' && status != 'done') {
      throw const QingsongException('status 只能是 todo 或 done', statusCode: 400);
    }
    final idx = remoteNotices.indexWhere((n) => n.id == remoteId);
    if (idx < 0) throw const QingsongException('not found', statusCode: 404);
    final updated = remoteNotices[idx].copyWith(status: status);
    remoteNotices[idx] = updated;
    return updated;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedNow = DateTime(2026, 11, 28, 0, 41);
  final fixedToday = DateTime(2026, 11, 28);

  late AppDatabase db;
  late DriftAgendaRepository agendaRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    agendaRepo = DriftAgendaRepository(db);
  });

  tearDown(() => db.close());

  Widget buildBoard({
    required QingsongConfig config,
    required MemoryQingsongNoticeCacheStore cacheStore,
    QingsongApi? api,
    Size size = const Size(412, 915),
  }) {
    final router = GoRouter(
      initialLocation: Routes.qingsongBoard,
      routes: [
        GoRoute(
          path: Routes.qingsongBoard,
          builder: (_, _) => const QingsongBoardPage(),
        ),
        GoRoute(
          path: Routes.more,
          builder: (_, _) => const Scaffold(body: Text('MORE_PAIRING_PAGE')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(fixedToday),
        nowProvider.overrideWithValue(() => fixedNow),
        appPrefsStoreProvider.overrideWithValue(MemoryAppPrefsStore()),
        qingsongConfigStoreProvider.overrideWithValue(InMemoryQingsongConfigStore(config)),
        qingsongNoticeCacheStoreProvider.overrideWithValue(cacheStore),
        if (api != null) qingsongApiFactoryProvider.overrideWithValue((_, _) => api),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  testWidgets('renders cached notices & local items, filters categories, and handles full actions',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const initialNotices = [
      QingsongNotice(
        id: 'n1',
        title: '宿舍区除四害消杀',
        summary: '今天下午两点宿舍区统一消杀，注意关好门窗。',
        detail: '全楼栋下午两点消杀，请收好桌面物品。',
        category: '通知',
        status: 'new',
        group: 'D39.40.41栋26级宿舍群',
        createdAt: 200,
      ),
      QingsongNotice(
        id: 'n2',
        title: '人工智能未来设计赛报名',
        summary: '报名工业文化创新发展大赛。',
        category: '比赛',
        deadline: '2026-11-30',
        status: 'new',
        group: '2026设计表达课程群',
        createdAt: 100,
      ),
      QingsongNotice(
        id: 'n3',
        title: '国家安全教育学习',
        summary: '在超星学习通完成课程视频。',
        category: '其他',
        deadline: '2027-01-02',
        status: 'todo',
        group: '发通知的',
      ),
      QingsongNotice(
        id: 'n_arch',
        title: '已归档通知',
        category: '通知',
        status: 'done',
        archivedAt: 1000,
      ),
    ];

    await tester.runAsync(() async {
      await agendaRepo.create(
        const AgendaDraft(date: '2026-11-29', title: '交设计作业', category: '作业'),
      );
    });

    final cacheStore = MemoryQingsongNoticeCacheStore(initialNotices);
    final fakeApi = _BoardFakeApi(remoteNotices: initialNotices);

    await tester.pumpWidget(
      buildBoard(
        config: const QingsongConfig(address: '192.168.1.8:7790', token: 'ABCD2345'),
        cacheStore: cacheStore,
        api: fakeApi,
      ),
    );
    await tester.pumpAndSettle();

    // Renders cards & countdowns matching screenshot.
    expect(find.text('宿舍区除四害消杀'), findsOneWidget);
    expect(find.text('没有明确截止时间'), findsOneWidget);
    expect(find.text('还剩 2 天 23 小时'), findsOneWidget);
    expect(find.text('2027年1月2日'), findsOneWidget);
    expect(find.text('还剩 35 天 23 小时'), findsOneWidget);
    expect(find.text('交设计作业'), findsOneWidget);
    expect(find.text('已归档通知'), findsNothing);

    // Filter by '比赛' category.
    await tester.ensureVisible(find.byKey(const ValueKey('board_tab_比赛')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('board_tab_比赛')));
    await tester.pumpAndSettle();
    expect(find.text('人工智能未来设计赛报名'), findsOneWidget);
    expect(find.text('宿舍区除四害消杀'), findsNothing);

    // Back to '全部' tab & tap card to view detail sheet.
    await tester.ensureVisible(find.byKey(const ValueKey('board_tab_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('board_tab_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('宿舍区除四害消杀'));
    await tester.pumpAndSettle();
    expect(find.text('全楼栋下午两点消杀，请收好桌面物品。'), findsOneWidget);
    Navigator.of(tester.element(find.text('全楼栋下午两点消杀，请收好桌面物品。'))).pop();
    await tester.pumpAndSettle();

    // Join todo on n1 -> switches card to '✓ 完成' and updates remote API.
    await tester.tap(find.byKey(const ValueKey('notice_todo_n1')));
    await tester.pumpAndSettle();
    expect(fakeApi.statusCalls.last, (id: 'n1', status: 'todo'));
    expect(find.byKey(const ValueKey('notice_done_n1')), findsOneWidget);

    // Mark n1 complete -> moves out of active list into archive tab.
    await tester.tap(find.byKey(const ValueKey('notice_done_n1')));
    await tester.pumpAndSettle();
    expect(fakeApi.statusCalls.last, (id: 'n1', status: 'done'));
    expect(find.text('宿舍区除四害消杀'), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('board_tab_archive')));
    await tester.tap(find.byKey(const ValueKey('board_tab_archive')));
    await tester.pumpAndSettle();
    expect(find.text('宿舍区除四害消杀'), findsOneWidget);

    // Restore n1 back to active list.
    await tester.tap(find.byKey(const ValueKey('notice_restore_n1')));
    await tester.pumpAndSettle();
    expect(fakeApi.statusCalls.last, (id: 'n1', status: 'todo'));
    await tester.ensureVisible(find.byKey(const ValueKey('board_tab_all')));
    await tester.tap(find.byKey(const ValueKey('board_tab_all')));
    await tester.pumpAndSettle();
    expect(find.text('宿舍区除四害消杀'), findsOneWidget);

    // Add new schedule from '+ 添加' button.
    await tester.tap(find.byKey(const ValueKey('qingsong_board_add_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('agenda_title_input')), '团队周会');
    await tester.tap(find.byKey(const ValueKey('agenda_submit_button')));
    await tester.pumpAndSettle();
    expect(find.text('团队周会'), findsOneWidget);

    // Trigger manual sync -> fetches remote notices into cache and updates board.
    // Adding '团队周会' with paired autoSync already triggered 1 background sync.
    expect(fakeApi.fetchCalls, 1);
    fakeApi.remoteNotices.add(
      const QingsongNotice(
        id: 'n_fresh',
        title: '新拉取的通知',
        category: '通知',
        status: 'new',
        createdAt: 9999,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('qingsong_board_sync_btn')));
    await tester.pumpAndSettle();
    expect(fakeApi.fetchCalls, 2);
    expect(find.text('新拉取的通知'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('keeps local skip status gracefully when PC bridge returns HTTP 400 and navigates pairing',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final cacheStore = MemoryQingsongNoticeCacheStore(const [
      QingsongNotice(
        id: 'n_skip_me',
        title: '可选讲座通知',
        category: '活动',
        status: 'new',
        createdAt: 10,
      ),
    ]);
    final fakeApi = _BoardFakeApi(
      remoteNotices: const [
        QingsongNotice(id: 'n_skip_me', title: '可选讲座通知', category: '活动', status: 'new'),
      ],
      rejectNonTodoStatus: true,
    );

    await tester.pumpWidget(
      buildBoard(
        config: const QingsongConfig(address: '192.168.1.8:7790', token: 'ABCD2345'),
        cacheStore: cacheStore,
        api: fakeApi,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notice_skip_n_skip_me')));
    await tester.pumpAndSettle();
    expect(find.text('可选讲座通知'), findsNothing);
    expect(find.textContaining('电脑端暂仅同步待办/完成状态'), findsOneWidget);
    expect((await cacheStore.load()).single.status, 'skip');

    await disposeTree(tester);

    // Verify unpaired banner + '去配对' navigation.
    await tester.pumpWidget(
      buildBoard(
        config: const QingsongConfig(),
        cacheStore: MemoryQingsongNoticeCacheStore(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('去配对'), findsOneWidget);
    await tester.tap(find.text('去配对'));
    await tester.pumpAndSettle();
    expect(find.text('MORE_PAIRING_PAGE'), findsOneWidget);

    await disposeTree(tester);
  });
}
