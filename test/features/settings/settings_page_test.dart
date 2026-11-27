import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibetter/app/router.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/prefs/app_prefs.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/backup_service.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/features/reminders/notification_service.dart';
import 'package:ibetter/features/settings/passcode_page.dart';
import 'package:ibetter/features/settings/project_sort_page.dart';
import 'package:ibetter/features/settings/settings_page.dart';
import 'package:ibetter/features/settings/widget_guide_page.dart';
import 'package:material_ui/material_ui.dart';

class _SpyNotificationService extends NoopNotificationService {
  bool? lastReportEnabled;
  int? lastReportMinutes;
  int syncReportCalls = 0;
  int testNotificationCalls = 0;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> syncReportReminder({
    required bool enabled,
    required int minutesOfDay,
  }) async {
    syncReportCalls++;
    lastReportEnabled = enabled;
    lastReportMinutes = minutesOfDay;
  }

  @override
  Future<bool> showTestNotification() async {
    testNotificationCalls++;
    return true;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedToday = DateTime(2026, 11, 24);
  late AppDatabase db;
  late MemoryAppPrefsStore prefsStore;
  late _SpyNotificationService spyNotif;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    prefsStore = MemoryAppPrefsStore();
    spyNotif = _SpyNotificationService();
  });

  tearDown(() async => db.close());

  Widget buildSettingsApp({String initialLocation = Routes.settings}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: Routes.settings, builder: (_, _) => const SettingsPage()),
        GoRoute(path: Routes.projectSort, builder: (_, _) => const ProjectSortPage()),
        GoRoute(path: Routes.passcode, builder: (_, _) => const PasscodePage()),
        GoRoute(path: Routes.widgetGuide, builder: (_, _) => const WidgetGuidePage()),
      ],
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(fixedToday),
        appPrefsStoreProvider.overrideWithValue(prefsStore),
        notificationServiceProvider.overrideWithValue(spyNotif),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => AppLockGate(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final ch in pin.split('')) {
      await tester.tap(find.byKey(ValueKey('pin_key_$ch')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  testWidgets('SettingsPage updates style, layout, calendar color, notifications, week start, and backup restore',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? copiedBackupJson;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedBackupJson = (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    late String backupJson;
    await tester.runAsync(() async {
      await DriftHabitRepository(db).create(
        HabitDraft(name: '初始习惯', iconKey: 'study/book', startDate: DateTime(2026, 11, 20)),
      );
      final seeded = await BackupService(
        db,
        MemoryAppPrefsStore(const AppPrefs(nickname: '从备份恢复', soundEnabled: false)),
      ).exportJson();
      backupJson = seeded.jsonText;
    });

    await tester.pumpWidget(buildSettingsApp());
    await tester.pumpAndSettle();

    // Expand card style and select white.
    await tester.tap(find.byKey(const ValueKey('settings_card_style_row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('card_style_white')));
    await tester.pumpAndSettle();
    expect((await prefsStore.load()).cardStyle, CardStyle.white);

    // Select compact then ultraCompact layout.
    await scrollToAndTap(tester, find.byKey(const ValueKey('card_layout_compact')));
    expect((await prefsStore.load()).cardLayout, CardLayout.compact);

    await scrollToAndTap(tester, find.byKey(const ValueKey('card_layout_ultraCompact')));
    expect((await prefsStore.load()).cardLayout, CardLayout.ultraCompact);

    // Calendar done theme -> goldStar.
    await scrollToAndTap(tester, find.byKey(const ValueKey('calendar_theme_goldStar')));
    expect((await prefsStore.load()).calendarDoneTheme, CalendarDoneTheme.goldStar);

    // Toggle weekly report reminder & fire test notification.
    await scrollToAndTap(tester, find.byKey(const ValueKey('settings_report_reminder_row')));
    expect((await prefsStore.load()).reportReminderEnabled, isTrue);
    expect(spyNotif.syncReportCalls, 1);
    expect(spyNotif.lastReportEnabled, isTrue);

    await scrollToAndTap(tester, find.byKey(const ValueKey('settings_troubleshoot_row')));
    expect(find.text('收不到推送？排查方案'), findsOneWidget);
    await tester.tap(find.text('发送测试通知'));
    await tester.pumpAndSettle();
    expect(spyNotif.testNotificationCalls, 1);

    // Week starts on Monday.
    await scrollToAndTap(tester, find.byKey(const ValueKey('settings_week_start_row')));
    await tester.tap(find.text('星期一').last);
    await tester.pumpAndSettle();
    expect((await prefsStore.load()).weekStartsOnMonday, isTrue);

    // Sound toggle off.
    await scrollToAndTap(tester, find.byKey(const ValueKey('settings_sound_row')));
    expect((await prefsStore.load()).soundEnabled, isFalse);

    // Achievement banner style.
    await scrollToAndTap(tester, find.byKey(const ValueKey('achievement_style_banner')));
    expect((await prefsStore.load()).achievementDisplayStyle, CelebrationStyle.banner);

    // Backup export + paste restore.
    await scrollToAndTap(tester, find.byKey(const ValueKey('settings_backup_row')));
    expect(find.text('备份与恢复数据'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('backup_export_button')));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(copiedBackupJson, contains('初始习惯'));
    expect(find.textContaining('已导出并复制备份'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('backup_toggle_paste_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('backup_paste_input')), backupJson);
    await tester.tap(find.byKey(const ValueKey('backup_restore_paste_button')));
    await tester.pumpAndSettle();
    expect(find.text('确认恢复备份'), findsOneWidget);
    await tester.tap(find.text('覆盖恢复'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect((await prefsStore.load()).nickname, '从备份恢复');

    await disposeTree(tester);
  });

  testWidgets('ProjectSortPage reorders habits and saves to repository', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      final repo = DriftHabitRepository(db);
      await repo.create(HabitDraft(name: '第一项', iconKey: 'study/book', startDate: DateTime(2026, 11, 20)));
      await repo.create(HabitDraft(name: '第二项', iconKey: 'study/code', startDate: DateTime(2026, 11, 20)));
      await repo.create(HabitDraft(name: '第三项', iconKey: 'study/english', startDate: DateTime(2026, 11, 20)));
    });

    await tester.pumpWidget(buildSettingsApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_sort_row')));
    await tester.pumpAndSettle();
    expect(find.text('我的项目排序'), findsOneWidget);

    // Drag handle on first row downward past third item.
    final firstHandle = find.byIcon(Icons.menu).at(1);
    await tester.drag(firstHandle, const Offset(0, 160));
    await tester.pumpAndSettle();

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    final reordered = await tester.runAsync(() => DriftHabitRepository(db).watchAll().first);
    expect(reordered!.first.name, isNot('第一项'));

    await disposeTree(tester);
  });

  testWidgets('PasscodePage enables and disables PIN cleanly without locking active session',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSettingsApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();

    await scrollToAndTap(tester, find.byKey(const ValueKey('settings_passcode_row')));
    expect(find.text('密码保护'), findsWidgets);

    await enterPin(tester, '2468');
    await enterPin(tester, '2468');

    // Back in Settings, NOT locked out by AppLockGate, status shows '已开启'.
    expect(find.text('已开启'), findsOneWidget);
    expect((await prefsStore.load()).passcode, '2468');

    // Re-open PasscodePage -> disable PIN after wrong-then-right verification.
    await scrollToAndTap(tester, find.byKey(const ValueKey('settings_passcode_row')));
    expect(find.text('密码保护已开启'), findsOneWidget);
    await tester.tap(find.text('关闭密码保护'));
    await tester.pumpAndSettle();

    await enterPin(tester, '0000');
    expect(find.text('原密码不正确'), findsOneWidget);

    await enterPin(tester, '2468');
    expect(find.text('未开启'), findsOneWidget);
    expect((await prefsStore.load()).hasActivePasscode, isFalse);

    await disposeTree(tester);
  });

  testWidgets('AppLockGate blocks cold start when PIN is enabled and unlocks on valid PIN',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    prefsStore = MemoryAppPrefsStore(
      const AppPrefs(passcodeEnabled: true, passcode: '1357'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(fixedToday),
          appPrefsStoreProvider.overrideWithValue(prefsStore),
          notificationServiceProvider.overrideWithValue(spyNotif),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (_, child) => AppLockGate(child: child!),
          home: const Scaffold(body: Text('UNLOCKED_HOME')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('请输入锁屏密码'), findsOneWidget);
    expect(find.text('UNLOCKED_HOME'), findsNothing);

    await enterPin(tester, '9999');
    expect(find.text('密码错误，请重试'), findsOneWidget);

    await enterPin(tester, '1357');
    expect(find.text('UNLOCKED_HOME'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('WidgetGuidePage renders cleanly', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSettingsApp(initialLocation: Routes.widgetGuide));
    await tester.pumpAndSettle();

    expect(find.text('调整桌面小部件'), findsOneWidget);
    await disposeTree(tester);
  });
}
