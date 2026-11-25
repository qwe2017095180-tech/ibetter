import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_agenda_repository.dart';
import 'package:ibetter/domain/models/agenda_item.dart';
import 'package:ibetter/domain/models/qingsong_notice.dart';
import 'package:ibetter/features/home/home_page.dart';
import 'package:ibetter/features/qingsong/qingsong_client.dart';
import 'package:ibetter/features/qingsong/qingsong_config.dart';
import 'package:ibetter/features/qingsong/qingsong_providers.dart';
import 'package:material_ui/material_ui.dart';

class _StubQingsongApi implements QingsongApi {
  final List<QingsongNotice> notices;
  final List<AgendaItem> uploaded = [];
  final List<({String id, bool done})> statusPushed = [];

  _StubQingsongApi(this.notices);

  @override
  Future<QingsongPing> ping() async => const QingsongPing(version: '1.1.1', protocol: 1);

  @override
  Future<List<QingsongNotice>> fetchNotices() async => notices;

  @override
  Future<Map<String, String>> createItems(List<AgendaItem> items) async {
    uploaded.addAll(items);
    return {for (final i in items) i.clientId: 'r-${i.clientId}'};
  }

  @override
  Future<void> setStatus(String remoteId, {required bool done}) async {
    statusPushed.add((id: remoteId, done: done));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedToday = DateTime(2026, 11, 25);

  late AppDatabase db;
  late DriftAgendaRepository agendaRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    agendaRepo = DriftAgendaRepository(db);
  });

  tearDown(() => db.close());

  Widget buildApp({
    QingsongConfig config = const QingsongConfig(),
    QingsongApi? api,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
    );
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(fixedToday),
        qingsongConfigStoreProvider.overrideWithValue(InMemoryQingsongConfigStore(config)),
        if (api != null) qingsongApiFactoryProvider.overrideWithValue((_, _) => api),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  testWidgets('add today agenda via sheet, toggle done, and delete via long press', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('今日日程'), findsOneWidget);
    expect(find.byKey(const ValueKey('agenda_empty_prompt')), findsOneWidget);

    // Tap "添加日程" button to open bottom sheet.
    await tester.tap(find.byKey(const ValueKey('add_agenda_button')));
    await tester.pumpAndSettle();

    // Empty title shows validation error.
    await tester.tap(find.byKey(const ValueKey('agenda_submit_button')));
    await tester.pumpAndSettle();
    expect(find.text('请输入日程标题'), findsOneWidget);

    // Fill title + note and submit.
    await tester.enterText(find.byKey(const ValueKey('agenda_title_input')), '交高数作业');
    await tester.enterText(find.byKey(const ValueKey('agenda_note_input')), '课前交到讲台');
    await tester.tap(find.byKey(const ValueKey('agenda_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('交高数作业'), findsOneWidget);
    expect(find.text('课前交到讲台'), findsOneWidget);
    expect(find.text('待办 1/1'), findsOneWidget);

    final saved = await tester.runAsync(() => agendaRepo.watchByDate('2026-11-25').first);
    final id = saved!.single.id;

    // Toggle done checkbox.
    await tester.tap(find.byKey(ValueKey('agenda_checkbox_$id')));
    await tester.pumpAndSettle();
    expect(find.text('已全部完成'), findsOneWidget);

    // Long press to delete.
    await tester.longPress(find.byKey(ValueKey('agenda_tile_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('交高数作业'), findsNothing);
    expect(find.byKey(const ValueKey('agenda_empty_prompt')), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('auto-syncs from Qingsong on Home open and displays synced card', (tester) async {
    final stubApi = _StubQingsongApi(const [
      QingsongNotice(
        id: 'qs-99',
        title: '校运会志愿者培训',
        summary: '晚上 7 点教学楼 302',
        category: '志愿',
        deadline: '2026-11-25 19:00',
        status: 'todo',
        group: '设计学院通知群',
      ),
    ]);

    await tester.pumpWidget(
      buildApp(
        config: const QingsongConfig(
          address: '192.168.1.8:7790',
          token: 'ABCD2345',
          autoSync: true,
        ),
        api: stubApi,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('校运会志愿者培训'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('设计学院通知群'), findsOneWidget);

    // Checking it done pushes status back to Qingsong.
    final item = (await tester.runAsync(() => agendaRepo.watchByDate('2026-11-25').first))!.single;
    await tester.tap(find.byKey(ValueKey('agenda_checkbox_${item.id}')));
    await tester.pumpAndSettle();

    expect(stubApi.statusPushed, hasLength(1));
    expect(stubApi.statusPushed.single.id, 'qs-99');
    expect(stubApi.statusPushed.single.done, isTrue);

    await disposeTree(tester);
  });
}
