import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibetter/app/router.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/platform/native_bridge.dart';
import 'package:ibetter/core/prefs/app_prefs.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/features/me/inbox_items.dart';
import 'package:ibetter/features/me/me_page.dart';
import 'package:material_ui/material_ui.dart';

class _FakePickerBridge extends NativeBridge {
  _FakePickerBridge(this.pathsBySlot);

  final Map<String, String> pathsBySlot;
  final List<String> pickedSlots = [];

  @override
  bool get supportsGalleryPicker => true;

  @override
  Future<String?> pickImage(String slot) async {
    pickedSlots.add(slot);
    return pathsBySlot[slot];
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedToday = DateTime(2026, 11, 24);
  late AppDatabase db;
  late MemoryAppPrefsStore prefsStore;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    prefsStore = MemoryAppPrefsStore();
  });

  tearDown(() async => db.close());

  Widget buildApp({NativeBridge? bridge}) {
    final router = GoRouter(
      initialLocation: Routes.me,
      routes: [
        GoRoute(path: Routes.me, builder: (_, _) => const MePage()),
        GoRoute(
          path: Routes.settings,
          builder: (_, _) => const Scaffold(body: Text('SETTINGS_ROUTE')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(fixedToday),
        appPrefsStoreProvider.overrideWithValue(prefsStore),
        if (bridge != null) nativeBridgeProvider.overrideWithValue(bridge),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  testWidgets('displays profile, KPIs, edits profile, reads inbox, and navigates to settings',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      final hId = await DriftHabitRepository(db).create(
        HabitDraft(name: '背单词', iconKey: 'study/book', startDate: DateTime(2026, 11, 20)),
      );
      await DriftCheckInRepository(db).setCount(hId, '2026-11-24', 1);
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('打卡达人'), findsOneWidget);
    expect(find.text('@qingsong'), findsWidgets);
    expect(find.text('我的收件箱'), findsOneWidget);
    expect(find.text('${kInboxMessages.length}未读'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(4)); // 4 KPI values = 1

    // Edit profile via modal bottom sheet.
    await tester.tap(find.byKey(const ValueKey('me_edit_profile_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('profile_nickname_input')), '昔日');
    await tester.enterText(find.byKey(const ValueKey('profile_handle_input')), 'forever_our');
    await tester.enterText(
      find.byKey(const ValueKey('profile_bio_input')),
      'The earth revolves around me.',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('昔日'), findsOneWidget);
    expect(find.text('@forever_our'), findsOneWidget);
    expect(find.textContaining('The earth revolves around me.'), findsOneWidget);
    final savedPrefs = await prefsStore.load();
    expect(savedPrefs.nickname, '昔日');
    expect(savedPrefs.handle, '@forever_our');

    // Open first inbox message -> unread count decrements by 1.
    await tester.tap(find.text(kInboxMessages.first.title));
    await tester.pumpAndSettle();
    expect(find.text('知道了'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(find.text('${kInboxMessages.length - 1}未读'), findsOneWidget);

    // Gear button opens Settings route.
    await tester.tap(find.byKey(const ValueKey('me_settings_button')));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS_ROUTE'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('tapping cover wallpaper button and avatar directly updates custom photos',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Valid 1x1 transparent PNG so Image.file decodes cleanly in widget tests.
    final pngBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    );
    final tmpDir = Directory.systemTemp.createTempSync('ibetter_me_photo_');
    addTearDown(() => tmpDir.deleteSync(recursive: true));
    final coverFile = File('${tmpDir.path}/cover.png')..writeAsBytesSync(pngBytes);
    final avatarFile = File('${tmpDir.path}/avatar.png')..writeAsBytesSync(pngBytes);

    final bridge = _FakePickerBridge({
      'cover': coverFile.path,
      'avatar': avatarFile.path,
    });

    await tester.pumpWidget(buildApp(bridge: bridge));
    await tester.pumpAndSettle();

    expect(find.text('自选壁纸'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('me_change_cover_button')));
    await tester.pumpAndSettle();

    expect(bridge.pickedSlots, ['cover']);
    expect((await prefsStore.load()).coverImagePath, coverFile.path);
    expect(find.text('更换壁纸'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('me_avatar_tap')));
    await tester.pumpAndSettle();

    expect(bridge.pickedSlots, ['cover', 'avatar']);
    expect((await prefsStore.load()).avatarImagePath, avatarFile.path);

    await disposeTree(tester);
  });
}
