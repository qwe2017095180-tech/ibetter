import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_agenda_repository.dart';
import 'package:ibetter/domain/models/agenda_item.dart';
import 'package:ibetter/domain/models/qingsong_notice.dart';
import 'package:ibetter/features/more/more_page.dart';
import 'package:ibetter/features/qingsong/qingsong_client.dart';
import 'package:ibetter/features/qingsong/qingsong_config.dart';
import 'package:ibetter/features/qingsong/qingsong_providers.dart';
import 'package:material_ui/material_ui.dart';

class _FakeApi implements QingsongApi {
  @override
  Future<QingsongPing> ping() async => const QingsongPing(version: '1.1.1', protocol: 1);

  @override
  Future<List<QingsongNotice>> fetchNotices() async => const [
        QingsongNotice(
          id: 'n-more-1',
          title: '英语四级报名截止',
          deadline: '2026-11-25 17:00',
          status: 'todo',
          category: '通知',
        ),
      ];

  @override
  Future<Map<String, String>> createItems(List<AgendaItem> items) async => const {};

  @override
  Future<void> setStatus(String remoteId, {required bool done}) async {}
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('MorePage configures Qingsong address/token, tests connection, and syncs',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final configStore = InMemoryQingsongConfigStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          qingsongConfigStoreProvider.overrideWithValue(configStore),
          qingsongApiFactoryProvider.overrideWithValue((_, _) => _FakeApi()),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const MorePage()),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to the 轻松日程 section.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('more_qingsong_sync_row')),
      200,
    );

    // Set address.
    await tester.tap(find.byKey(const ValueKey('more_qingsong_address_row')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('qingsong_address_input')), '192.168.1.9:7790');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('192.168.1.9:7790'), findsOneWidget);

    // Set token.
    await tester.tap(find.byKey(const ValueKey('more_qingsong_token_row')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('qingsong_token_input')), 'abcd2345');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('ABCD2345'), findsOneWidget);

    // Test connection.
    await tester.tap(find.byKey(const ValueKey('more_qingsong_test_row')));
    await tester.pumpAndSettle();
    expect(find.text('已连上轻松日程 v1.1.1'), findsOneWidget);

    // Sync now -> pulls notice into DB.
    await tester.tap(find.byKey(const ValueKey('more_qingsong_sync_row')));
    await tester.pumpAndSettle();
    expect(find.textContaining('新增 1 条'), findsWidgets);

    final items = await tester.runAsync(
      () => DriftAgendaRepository(db).watchByDate('2026-11-25').first,
    );
    expect(items!.single.title, '英语四级报名截止');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
