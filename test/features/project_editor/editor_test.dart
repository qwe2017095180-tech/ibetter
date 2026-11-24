import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPicker, GlobalCupertinoLocalizations;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibetter/app/router.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/models/reminder.dart';
import 'package:ibetter/features/icon_picker/icon_registry.dart';
import 'package:ibetter/features/project_editor/editor_controller.dart';
import 'package:ibetter/features/project_editor/project_editor_page.dart';
import 'package:ibetter/features/project_editor/quotes.dart';
import 'package:ibetter/features/reminders/notification_service.dart';
import 'package:material_ui/material_ui.dart';

class _FailingAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(Exception('missing'));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      Future.error(Exception('missing'));
}

class _SpyNotificationService extends NoopNotificationService {
  int requestPermissionCalls = 0;
  final List<(Habit, List<Reminder>)> synced = [];
  final List<int> cancelled = [];

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return true;
  }

  @override
  Future<void> syncHabit(Habit habit, List<Reminder> reminders) async {
    synced.add((habit, reminders));
  }

  @override
  Future<void> cancelHabit(int habitId) async {
    cancelled.add(habitId);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late _SpyNotificationService notifications;
  final fixedToday = DateTime(2026, 11, 24);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notifications = _SpyNotificationService();
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer makeContainer({
    Future<List<String>> Function()? quotesLoader,
  }) {
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notifications),
        todayProvider.overrideWithValue(fixedToday),
        if (quotesLoader != null) quotesLoaderProvider.overrideWithValue(quotesLoader),
      ],
    );
  }

  Widget wrapWithRouter({
    required GoRouter router,
    Future<List<String>> Function()? quotesLoader,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notifications),
        todayProvider.overrideWithValue(fixedToday),
        if (quotesLoader != null) quotesLoaderProvider.overrideWithValue(quotesLoader),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }

  group('assets/quotes.json', () {
    test('contains >= 60 original Chinese quotes each <= 20 chars', () {
      final raw = File('assets/quotes.json').readAsStringSync();
      final list = (jsonDecode(raw) as List).cast<String>();
      expect(list.length, greaterThanOrEqualTo(60));
      for (final line in list) {
        expect(line.trim(), isNotEmpty);
        expect(line.length, lessThanOrEqualTo(20), reason: 'Quote too long: $line');
      }
      expect(list.toSet().length, list.length);
    });

    test('loadQuotes returns fallbackQuotes when asset loading fails', () async {
      final loaded = await loadQuotes(bundle: _FailingAssetBundle());
      expect(loaded, fallbackQuotes);
    });
  });

  group('EditorController unit tests', () {
    test('defaults, schedule labels, goal label, and draft building', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final provider = editorControllerProvider(null);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      var state = container.read(provider);
      expect(state.isEditMode, isFalse);
      expect(state.name, '');
      expect(state.iconKey, IconRegistry.defaultKey);
      expect(state.schedule, const Schedule.daily());
      expect(state.schedule.label, '每天');
      expect(state.goalDays, isNull);
      expect(state.goalLabel, '永远');
      expect(state.startDate, fixedToday);
      expect(state.canSave, isFalse);
      expect(state.isDirty, isFalse);

      final ctrl = container.read(provider.notifier);
      ctrl.setName('   ');
      expect(container.read(provider).canSave, isFalse);

      ctrl.setName('  早起阅读  ');
      ctrl.setSchedule(const Schedule.weekdays(0x2A)); // Mon, Wed, Fri
      ctrl.setGoalDays(21);
      ctrl.setStartDate(DateTime(2026, 12, 1, 18, 30));
      ctrl.setMotto('每天进步一点点。');
      ctrl.setEnableScore(true);
      ctrl.setEnableMood(true);
      ctrl.setDailyTarget(3);
      ctrl.setIconKey('achievement/trophy');

      state = container.read(provider);
      expect(state.canSave, isTrue);
      expect(state.isDirty, isTrue);
      expect(state.schedule.label, '每周一三五');
      expect(state.goalLabel, '21天');
      expect(state.dailyTargetLabel, '3次');

      final draft = state.buildDraft();
      expect(draft.name, '早起阅读');
      expect(draft.iconKey, 'achievement/trophy');
      expect(draft.schedule, const Schedule.weekdays(0x2A));
      expect(draft.goalDays, 21);
      expect(draft.startDate, DateTime(2026, 12, 1));
      expect(draft.motto, '每天进步一点点。');
      expect(draft.enableScore, isTrue);
      expect(draft.enableMood, isTrue);
      expect(draft.dailyTarget, 3);
      expect(draft.isActive, isTrue);

      ctrl.setSchedule(const Schedule.timesPerWeek(4));
      expect(container.read(provider).schedule.label, '每周4天');

      ctrl.setSchedule(const Schedule.timesPerMonth(15));
      expect(container.read(provider).schedule.label, '每月15天');

      ctrl.setGoalDays(null);
      expect(container.read(provider).goalLabel, '永远');
      expect(container.read(provider).buildDraft().goalDays, isNull);
    });

    test('nextQuote picks a quote different from current', () async {
      final container = makeContainer(
        quotesLoader: () async => const ['第一句鼓励语', '第二句鼓励语'],
      );
      addTearDown(container.dispose);

      final provider = editorControllerProvider(null);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      final ctrl = container.read(provider.notifier);
      final first = await ctrl.nextQuote();
      expect(['第一句鼓励语', '第二句鼓励语'], contains(first));

      final second = await ctrl.nextQuote();
      expect(second, isNot(first));
    });

    test('reminders request permission only on first add and sync on save', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final provider = editorControllerProvider(null);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      final ctrl = container.read(provider.notifier);
      ctrl.setName('喝水');
      await ctrl.addReminder(1200); // 20:00
      expect(notifications.requestPermissionCalls, 1);

      await ctrl.addReminder(480); // 08:00
      expect(notifications.requestPermissionCalls, 1);
      expect(
        container.read(provider).reminders.map((r) => r.timeLabel),
        ['08:00', '20:00'],
      );

      final ok = await ctrl.save();
      expect(ok, isTrue);

      final habits = await container.read(habitRepositoryProvider).watchAll().first;
      expect(habits.single.name, '喝水');
      final reminders = await container.read(reminderRepositoryProvider).getByHabit(habits.single.id);
      expect(reminders.map((r) => r.timeLabel), ['08:00', '20:00']);
      expect(notifications.synced.length, 1);
      expect(notifications.synced.single.$2.map((r) => r.timeLabel), ['08:00', '20:00']);
    });

    test('edit mode loads existing habit + reminders, saves updates, and deletes', () async {
      final habitRepo = DriftHabitRepository(db);
      final reminderRepo = DriftReminderRepository(db);
      final id = await habitRepo.create(
        HabitDraft(
          name: '冥想',
          iconKey: 'achievement/star',
          schedule: const Schedule.timesPerWeek(3),
          goalDays: 30,
          startDate: DateTime(2026, 11, 20),
          motto: '保持平静',
          enableScore: true,
          enableMood: false,
          dailyTarget: 2,
          isActive: false,
        ),
      );
      await reminderRepo.replaceForHabit(id, const [ReminderDraft(minutesOfDay: 510)]);

      final container = makeContainer();
      addTearDown(container.dispose);

      final provider = editorControllerProvider(id);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      // Wait for microtask _loadHabit to complete.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final loaded = container.read(provider);
      expect(loaded.isLoading, isFalse);
      expect(loaded.name, '冥想');
      expect(loaded.schedule, const Schedule.timesPerWeek(3));
      expect(loaded.goalDays, 30);
      expect(loaded.startDate, DateTime(2026, 11, 20));
      expect(loaded.motto, '保持平静');
      expect(loaded.enableScore, isTrue);
      expect(loaded.enableMood, isFalse);
      expect(loaded.dailyTarget, 2);
      expect(loaded.isActive, isFalse);
      expect(loaded.reminders.single.timeLabel, '08:30');
      expect(loaded.isDirty, isFalse);

      final ctrl = container.read(provider.notifier);
      ctrl.setName('正念冥想');
      expect(container.read(provider).isDirty, isTrue);

      expect(await ctrl.save(), isTrue);
      final updated = await container.read(habitRepositoryProvider).getById(id);
      expect(updated?.name, '正念冥想');
      expect(updated?.isActive, isFalse);

      expect(await ctrl.deleteHabit(), isTrue);
      expect(notifications.cancelled, [id]);
      expect(await container.read(habitRepositoryProvider).getById(id), isNull);
    });
  });

  group('ProjectEditorPage widget tests', () {
    testWidgets('create mode: enter name, change schedule/goal/quote, tap 完成 persists habit',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/projects',
        routes: [
          GoRoute(
            path: '/projects',
            builder: (context, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push(Routes.editor),
                  child: const Text('新建'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: Routes.editor,
            builder: (_, _) => const ProjectEditorPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        wrapWithRouter(
          router: router,
          quotesLoader: () async => const ['每天进步一点点。', '自己来选择，不会后悔的道路。'],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('新建'));
      await tester.pumpAndSettle();

      expect(find.text('创建项目'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);

      // Enter habit name.
      await tester.enterText(
        find.widgetWithText(TextField, '输入你想坚持的事情'),
        '晨跑打卡',
      );
      await tester.pump();

      // Open schedule page and pick 每周 x 天 -> increment from 3 to 4.
      await tester.tap(find.text('时间规划'));
      await tester.pumpAndSettle();
      expect(find.text('每天'), findsOneWidget);
      await tester.tap(find.text('每周 x 天'));
      await tester.pumpAndSettle();
      expect(find.text('3 天'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('4 天'), findsOneWidget);
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.text('每周4天'), findsOneWidget);

      // Open goal picker sheet and select 7天.
      await tester.tap(find.text('设置坚持目标'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoPicker), findsOneWidget);
      await tester.drag(find.byType(CupertinoPicker), const Offset(0, -126)); // ~3 items down -> 7天
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(find.text('永远'), findsNothing);

      // Shuffle quote via 换一句.
      await tester.tap(find.text('换一句'));
      await tester.pumpAndSettle();
      expect(find.text('40'), findsNothing);

      // Add reminder via 点击添加 -> time picker -> 09:00, then verify chip appears.
      await tester.tap(find.text('点击添加'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(find.text('09:00'), findsOneWidget);
      expect(notifications.requestPermissionCalls, 1);

      // Toggle switches and change daily target (scroll them into view in 600px test viewport).
      await tester.scrollUntilVisible(
        find.text('给自己打分'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('给自己打分'));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('记录心情'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('记录心情'));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('每日打卡次数'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('每日打卡次数'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CupertinoPicker), const Offset(0, -84));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // Save.
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      // Returned to /projects and habit persisted in Drift DB.
      expect(find.text('新建'), findsOneWidget);
      final persisted = await tester.runAsync(
        () => db.select(db.habits).get(),
      );
      expect(persisted, hasLength(1));
      expect(persisted!.single.name, '晨跑打卡');
      expect(persisted.single.scheduleType, ScheduleType.timesPerWeek.index);
      expect(persisted.single.scheduleValue, 4);
      expect(persisted.single.motto, isNotEmpty);
      expect(persisted.single.enableScore, isTrue);
      expect(persisted.single.enableMood, isTrue);
      expect(persisted.single.dailyTarget, greaterThan(1));
      final persistedReminders = await tester.runAsync(
        () => db.select(db.reminders).get(),
      );
      expect(persistedReminders?.single.minutesOfDay, 540);

      // Unmount widget tree before tearDown closes db to flush drift timers cleanly.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('edit mode loads existing values, saves changes, and supports delete',
        (tester) async {
      late int habitId;
      await tester.runAsync(() async {
        final habitRepo = DriftHabitRepository(db);
        final reminderRepo = DriftReminderRepository(db);
        habitId = await habitRepo.create(
          HabitDraft(
            name: '背单词',
            iconKey: 'study/book',
            schedule: const Schedule.weekdays(0x2A), // 一三五
            goalDays: 21,
            startDate: DateTime(2026, 11, 20),
            motto: '坚持就是胜利',
            enableScore: true,
            enableMood: true,
            dailyTarget: 2,
          ),
        );
        await reminderRepo.replaceForHabit(habitId, const [ReminderDraft(minutesOfDay: 510)]);
      });

      final router = GoRouter(
        initialLocation: Routes.editHabit(habitId),
        routes: [
          GoRoute(
            path: Routes.projects,
            builder: (_, _) => const Scaffold(body: Center(child: Text('我的项目页'))),
          ),
          GoRoute(
            path: '${Routes.editor}/:id',
            builder: (_, state) => ProjectEditorPage(
              habitId: int.tryParse(state.pathParameters['id'] ?? ''),
            ),
          ),
        ],
      );

      await tester.pumpWidget(wrapWithRouter(router: router));
      await tester.pumpAndSettle();

      expect(find.text('编辑项目'), findsOneWidget);
      expect(find.text('背单词'), findsOneWidget);
      expect(find.text('每周一三五'), findsOneWidget);
      expect(find.text('21天'), findsOneWidget);
      expect(find.text('2026.11.20'), findsOneWidget);
      expect(find.text('坚持就是胜利'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('2次'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2次'), findsOneWidget);

      // Scroll to bottom to verify 删除项目 button and delete flow.
      await tester.scrollUntilVisible(
        find.text('删除项目'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('删除项目'), findsOneWidget);

      await tester.tap(find.text('删除项目'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(find.text('我的项目页'), findsOneWidget);
      expect(notifications.cancelled, [habitId]);
      final remaining = await tester.runAsync(() => db.select(db.habits).get());
      expect(remaining, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('schedule page supports weekdays multi-select and monthly stepper', (tester) async {
      final router = GoRouter(
        initialLocation: Routes.editor,
        routes: [
          GoRoute(
            path: Routes.editor,
            builder: (_, _) => const ProjectEditorPage(),
          ),
        ],
      );

      await tester.pumpWidget(wrapWithRouter(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('时间规划'));
      await tester.pumpAndSettle();

      // Switch to 每周 and toggle off 日 and 六 (leaving 一二三四五).
      await tester.tap(find.text('每周'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('日'));
      await tester.tap(find.text('六'));
      await tester.pump();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.text('每周一二三四五'), findsOneWidget);

      // Switch to 每月 x 天 and increment from 10 to 11.
      await tester.tap(find.text('时间规划'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('每月 x 天'));
      await tester.pumpAndSettle();
      expect(find.text('10 天'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.text('每月11天'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('dirty form confirms discard on back press', (tester) async {
      final router = GoRouter(
        initialLocation: '/projects',
        routes: [
          GoRoute(
            path: '/projects',
            builder: (context, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push(Routes.editor),
                  child: const Text('新建'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: Routes.editor,
            builder: (_, _) => const ProjectEditorPage(),
          ),
        ],
      );

      await tester.pumpWidget(wrapWithRouter(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('新建'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '输入你想坚持的事情'), '吉他练习');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('放弃修改'), findsOneWidget);
      await tester.tap(find.text('放弃'));
      await tester.pumpAndSettle();

      expect(find.text('新建'), findsOneWidget);
      final persisted = await tester.runAsync(() => db.select(db.habits).get());
      expect(persisted, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
