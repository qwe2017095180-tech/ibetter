import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibetter/app/router.dart';
import 'package:ibetter/app/theme/app_colors.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/platform/native_bridge.dart';
import 'package:ibetter/core/prefs/app_prefs.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/features/home/home_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedToday = DateTime(2026, 11, 24); // Tuesday
  final fixedNow = DateTime(2026, 11, 24, 12); // Daytime noon

  late AppDatabase db;
  late DriftHabitRepository habitRepo;
  late DriftCheckInRepository checkInRepo;
  late MemoryAppPrefsStore prefsStore;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    habitRepo = DriftHabitRepository(db);
    checkInRepo = DriftCheckInRepository(db, now: () => fixedNow);
    prefsStore = MemoryAppPrefsStore();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp({GoRouter? router, NativeBridge? bridge}) {
    final appRouter =
        router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HomePage()),
            GoRoute(
              path: Routes.history,
              builder: (_, _) => const Scaffold(body: Text('History Timeline')),
            ),
            GoRoute(
              path: Routes.editor,
              builder: (_, _) => const Scaffold(body: Text('Editor New')),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      Scaffold(body: Text('Editor ${state.pathParameters['id']}')),
                ),
              ],
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(fixedToday),
        nowProvider.overrideWithValue(() => fixedNow),
        appPrefsStoreProvider.overrideWithValue(prefsStore),
        if (bridge != null) nativeBridgeProvider.overrideWithValue(bridge),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: appRouter,
      ),
    );
  }

  Future<void> disposeWidgetTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  Future<void> dismissCelebrationDialogs(WidgetTester tester) async {
    while (find.byIcon(Icons.close).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
    }
  }

  HabitDraft dailyDraft(
    String name, {
    String motto = '每天进步一点点',
    int dailyTarget = 1,
    bool isActive = true,
    DateTime? startDate,
    Schedule schedule = const Schedule.daily(),
  }) {
    return HabitDraft(
      name: name,
      iconKey: 'study/book',
      schedule: schedule,
      startDate: startDate ?? DateTime(2026, 11, 1),
      motto: motto,
      dailyTarget: dailyTarget,
      isActive: isActive,
    );
  }

  testWidgets('shows scheduled active habits and hides unscheduled/paused', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await habitRepo.create(dailyDraft('早起阅读'));
      await habitRepo.create(dailyDraft('已暂停', isActive: false));
      // 2026-11-24 is Tuesday (bit 2). Only schedule Monday (bit 1 = 0x02).
      await habitRepo.create(
        dailyDraft('周一跑步', schedule: const Schedule.weekdays(0x02)),
      );
      // Starts tomorrow.
      await habitRepo.create(
        dailyDraft('未来项目', startDate: DateTime(2026, 11, 25)),
      );
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('早起阅读'), findsOneWidget);
    expect(find.text('每天进步一点点'), findsOneWidget);
    expect(find.text('已暂停'), findsNothing);
    expect(find.text('周一跑步'), findsNothing);
    expect(find.text('未来项目'), findsNothing);

    await disposeWidgetTree(tester);
  });

  testWidgets('tapping check box toggles count=1 and 0 in DB and updates solid green cell', (
    tester,
  ) async {
    late int habitId;
    await tester.runAsync(() async {
      habitId = await habitRepo.create(dailyDraft('喝水'));
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
    await tester.pumpAndSettle();

    // Completing the only habit shows Perfect Day, then Achievement Unlock.
    expect(find.text('完美的一天！'), findsOneWidget);
    await dismissCelebrationDialogs(tester);

    expect(find.byIcon(Icons.check), findsOneWidget);
    final saved = await tester.runAsync(
      () => checkInRepo.watchByDate('2026-11-24').first,
    );
    expect(saved!.single.count, 1);

    // Day completion fills today's calendar cell with solid green and retains selection border.
    final todayCellFinder = find.byKey(const ValueKey('calendar_day_2026-11-24'));
    final todayContainer = tester.widget<Container>(
      find.descendant(of: todayCellFinder, matching: find.byType(Container)),
    );
    final todayDecoration = todayContainer.decoration! as BoxDecoration;
    expect(todayDecoration.color, const Color(0xFF34B853));
    expect(todayDecoration.border, isNotNull);

    final day24Text = tester.widget<Text>(
      find.descendant(of: todayCellFinder, matching: find.text('24')),
    );
    expect(day24Text.style?.color, Colors.white);
    expect(day24Text.style?.fontWeight, FontWeight.w600);

    // Select tomorrow so today is unselected -> still keeps solid green fill without border.
    await tester.tap(find.byKey(const ValueKey('calendar_day_2026-11-25')));
    await tester.pumpAndSettle();
    final unselectedTodayContainer = tester.widget<Container>(
      find.descendant(of: todayCellFinder, matching: find.byType(Container)),
    );
    final unselectedDecoration =
        unselectedTodayContainer.decoration! as BoxDecoration;
    expect(unselectedDecoration.color, const Color(0xFF34B853));
    expect(unselectedDecoration.border, isNull);

    // Jump back to today and uncheck (count = 0).
    await tester.tap(find.byKey(const ValueKey('home_jump_today')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing);
    final afterUncheck = await tester.runAsync(
      () => checkInRepo.watchByDate('2026-11-24').first,
    );
    expect(afterUncheck, isEmpty);

    final revertedContainer = tester.widget<Container>(
      find.descendant(of: todayCellFinder, matching: find.byType(Container)),
    );
    expect((revertedContainer.decoration! as BoxDecoration).color, Colors.white);

    await disposeWidgetTree(tester);
  });

  testWidgets(
      'completing last habit opens PerfectDayDialog and 3-day milestone opens AchievementUnlockDialog',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final text = (call.arguments as Map<dynamic, dynamic>)['text'];
            if (text is String) copied.add(text);
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    late int habitId;
    await tester.runAsync(() async {
      habitId = await habitRepo.create(dailyDraft('背单词'));
      await checkInRepo.setCount(habitId, '2026-11-22', 1);
      await checkInRepo.setCount(habitId, '2026-11-23', 1);
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
    await tester.pumpAndSettle();

    // PerfectDayDialog appears first.
    expect(find.text('我在 轻松打卡 完美的一天'), findsOneWidget);
    expect(find.text('完美的一天！'), findsOneWidget);
    expect(find.text('3天'), findsOneWidget);
    expect(find.text('赢得日期：2026年11月24日'), findsOneWidget);
    expect(find.text('🤩 保存完美的一天'), findsOneWidget);

    await tester.tap(find.text('🤩 保存完美的一天'));
    await tester.pumpAndSettle();

    expect(find.text('已保存完美的一天'), findsOneWidget);
    expect(copied.last, contains('完美的一天'));
    expect((await prefsStore.load()).shareCount, 1);

    // Next, AchievementUnlockDialog opens for 3-day milestones (single_3 + streak_3).
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('立即分享给朋友'), findsWidgets);
    expect(
      find.textContaining('三生万物').evaluate().isNotEmpty ||
          find.textContaining('三天打鱼').evaluate().isNotEmpty,
      isTrue,
    );

    await tester.tap(find.text('立即分享给朋友').first);
    await tester.pumpAndSettle();

    expect(find.text('已复制分享文案，快去分享给朋友吧'), findsOneWidget);
    expect(copied.last, contains('我在轻松打卡解锁了成就'));
    expect((await prefsStore.load()).shareCount, 2);

    await disposeWidgetTree(tester);
  });

  testWidgets('multi-target habit increments on tap and decrements on long press',
      (tester) async {
    late int habitId;
    await tester.runAsync(() async {
      habitId = await habitRepo.create(dailyDraft('背单词', dailyTarget: 3));
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('0/3'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    final box = find.byKey(ValueKey('habit_checkbox_$habitId'));
    await tester.tap(box);
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(box);
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(box);
    await tester.pumpAndSettle();
    await dismissCelebrationDialogs(tester);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Long press decrements back to 2/3.
    await tester.longPress(box);
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await disposeWidgetTree(tester);
  });

  testWidgets('future date disables check-in with opacity 0.5 and SnackBar', (
    tester,
  ) async {
    late int habitId;
    await tester.runAsync(() async {
      habitId = await habitRepo.create(dailyDraft('冥想'));
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Tap tomorrow (2026-11-25).
    await tester.tap(find.byKey(const ValueKey('calendar_day_2026-11-25')));
    await tester.pumpAndSettle();

    final checkBoxFinder = find.byKey(ValueKey('habit_checkbox_$habitId'));
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: checkBoxFinder,
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.5);

    await tester.tap(checkBoxFinder);
    await tester.pumpAndSettle();

    expect(find.text('不能为未来打卡'), findsOneWidget);
    final checkIns = await tester.runAsync(
      () => checkInRepo.watchByDate('2026-11-25').first,
    );
    expect(checkIns, isEmpty);

    await disposeWidgetTree(tester);
  });

  testWidgets('collapse toggle switches between 35 days (5 rows) and 7 days (1 row)',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    int countCalendarCells() => find
        .byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('calendar_day_'),
        )
        .evaluate()
        .length;

    // Expanded: 35 days starting 2026-11-15 (week before 2026-11-22), DEC 12月 visible.
    expect(countCalendarCells(), 35);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-15')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-12-19')), findsOneWidget);
    expect(find.text('DEC'), findsOneWidget);
    expect(find.text('12月'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);

    // Toggle to collapsed: 7 days (2026-11-22 .. 2026-11-28).
    await tester.tap(find.byKey(const ValueKey('calendar_collapse_toggle')));
    await tester.pumpAndSettle();

    expect(countCalendarCells(), 7);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-22')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-28')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-15')), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    // Toggle back to expanded: 35 days again.
    await tester.tap(find.byKey(const ValueKey('calendar_collapse_toggle')));
    await tester.pumpAndSettle();
    expect(countCalendarCells(), 35);

    await disposeWidgetTree(tester);
  });

  testWidgets('horizontal swipe moves window, jump-today chip returns to today, clock opens history',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home_jump_today')), findsNothing);

    // Swipe left in expanded mode -> +5 weeks (window moves 2026-11-15 -> 2026-12-20).
    await tester.fling(
      find.byKey(const ValueKey('calendar_grid')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar_day_2026-12-20')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-24')), findsNothing);
    expect(find.byKey(const ValueKey('home_jump_today')), findsOneWidget);
    // Selected date moved +35 days: 2026-11-24 (Tue) -> 2026-12-29 (Tue).
    final dec29Cell = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('calendar_day_2026-12-29')),
        matching: find.byType(Container),
      ),
    );
    expect((dec29Cell.decoration! as BoxDecoration).color, Colors.white);

    // Tap '回到今天' chip -> jumps selected date and window back to today (2026-11-24).
    await tester.tap(find.byKey(const ValueKey('home_jump_today')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar_day_2026-11-24')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-15')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_jump_today')), findsNothing);

    // Collapse to 1 week and swipe left -> +1 week (2026-11-29 .. 2026-12-05).
    await tester.tap(find.byKey(const ValueKey('calendar_collapse_toggle')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('calendar_grid')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calendar_day_2026-11-29')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-12-05')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-24')), findsNothing);

    // Tap top-left clock button -> navigates to Routes.history.
    await tester.tap(find.byTooltip('历史记录'));
    await tester.pumpAndSettle();
    expect(find.text('History Timeline'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets('weekday header highlights selected weekday and top-bar + opens editor',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // 2026-11-24 is Tuesday -> '周二' in AppColors.primary, '周日' in textSecondary.
    final tueText = tester.widget<Text>(find.text('周二'));
    final sunText = tester.widget<Text>(find.text('周日'));
    expect(tueText.style?.color, AppColors.primary);
    expect(sunText.style?.color, AppColors.textSecondary);

    // Footer renders brand pill + tagline when scrolled into view.
    await tester.scrollUntilVisible(
      find.text('人生养成计划'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('人生养成计划'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Editor New'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets('empty states and navigation to editor', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('创建第一个项目'), findsOneWidget);
    await tester.ensureVisible(find.text('创建第一个项目'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('创建第一个项目'));
    await tester.pumpAndSettle();
    expect(find.text('Editor New'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets('tapping habit card navigates to edit route and unscheduled day shows empty text',
      (tester) async {
    late int habitId;
    await tester.runAsync(() async {
      // Only scheduled on Tuesdays (today = 2026-11-24, weekdayIndex = 2, mask = 1 << 2 = 0x04).
      habitId = await habitRepo.create(
        dailyDraft('周二健身', schedule: const Schedule.weekdays(0x04)),
      );
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('周二健身'), findsOneWidget);

    // Tap Wednesday (2026-11-25) -> habit exists, none scheduled that day.
    await tester.tap(find.byKey(const ValueKey('calendar_day_2026-11-25')));
    await tester.pumpAndSettle();
    expect(find.text('今天没有安排的项目'), findsOneWidget);

    // Return to today via '回到今天' chip.
    await tester.tap(find.byKey(const ValueKey('home_jump_today')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('周二健身'));
    await tester.pumpAndSettle();
    expect(find.text('Editor $habitId'), findsOneWidget);
    GoRouter.of(tester.element(find.text('Editor $habitId'))).pop();
    await tester.pumpAndSettle();

    await tester.longPress(find.text('周二健身'));
    await tester.pumpAndSettle();
    expect(find.text('打卡详情'), findsOneWidget);
    final note = find.byType(TextFormField);
    await tester.enterText(note, '今天加练了十分钟');
    await tester.tap(find.text('保存记录'));
    await tester.pumpAndSettle();
    final record = await tester.runAsync(
      () => checkInRepo.watchByDate('2026-11-24').first,
    );
    expect(record?.single.note, '今天加练了十分钟');
    expect(record?.single.count, 0);

    await tester.longPress(find.text('周二健身'));
    await tester.pumpAndSettle();
    expect(find.text('今天加练了十分钟'), findsOneWidget);
    await tester.tap(find.text('编辑项目'));
    await tester.pumpAndSettle();
    expect(find.text('Editor $habitId'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets(
      'partial completion skips PerfectDayDialog, single unlock omits counter, and 5 habits scroll in PerfectDayDialog',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ids = <int>[];
    await tester.runAsync(() async {
      for (var i = 1; i <= 5; i++) {
        ids.add(await habitRepo.create(dailyDraft('项目$i')));
      }
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Checking 1st habit opens single-card AchievementUnlockDialog ('一日幸运') without PerfectDayDialog.
    await tester.tap(find.byKey(ValueKey('habit_checkbox_${ids[0]}')));
    await tester.pumpAndSettle();
    expect(find.text('完美的一天！'), findsNothing);
    expect(find.text('一日幸运'), findsOneWidget);
    expect(find.text('1 / 1'), findsNothing);
    expect(find.text('立即分享给朋友'), findsOneWidget);

    await dismissCelebrationDialogs(tester);

    // Check habits 2..4 (no PerfectDayDialog yet).
    for (var i = 1; i < 4; i++) {
      final checkbox = find.byKey(ValueKey('habit_checkbox_${ids[i]}'));
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      await dismissCelebrationDialogs(tester);
    }

    // Check 5th (last) habit -> PerfectDayDialog lists all 5 habits without overflowing.
    final lastCheckbox = find.byKey(ValueKey('habit_checkbox_${ids[4]}'));
    await tester.ensureVisible(lastCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(lastCheckbox);
    await tester.pumpAndSettle();

    expect(find.text('完美的一天！'), findsOneWidget);
    expect(find.text('项目1'), findsWidgets);
    expect(find.text('🤩 保存完美的一天'), findsOneWidget);

    await dismissCelebrationDialogs(tester);
    await disposeWidgetTree(tester);
  });

  testWidgets(
      'supports white card style, compact/ultraCompact layouts, Monday week start, and goldStar calendar theme',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    prefsStore = MemoryAppPrefsStore(
      const AppPrefs(
        cardStyle: CardStyle.white,
        cardLayout: CardLayout.compact,
        calendarDoneTheme: CalendarDoneTheme.goldStar,
        weekStartsOnMonday: true,
      ),
    );

    await tester.runAsync(() async {
      final h1 = await habitRepo.create(dailyDraft('早起喝水', motto: '清清爽爽'));
      await habitRepo.create(dailyDraft('冥想十分钟', motto: '静心呼吸'));
      await habitRepo.create(dailyDraft('阅读半小时', motto: '日积月累'));
      // Complete all scheduled habits on 2026-11-23? Only 1 habit? All 3 on 2026-11-24 after creating them starting 2026-11-24.
      await checkInRepo.setCount(h1, '2026-11-24', 1);
    });

    // Make only h1 active/all-done on 2026-11-24? No, let's complete all 3 on 2026-11-24.
    await tester.runAsync(() async {
      final all = await habitRepo.watchAll().first;
      for (final h in all) {
        await checkInRepo.setCount(h.id, '2026-11-24', 1);
      }
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Monday first -> '周一' is leftmost, '周日' is rightmost.
    expect(
      tester.getTopLeft(find.text('周一')).dx,
      lessThan(tester.getTopLeft(find.text('周二')).dx),
    );
    expect(
      tester.getTopLeft(find.text('周日')).dx,
      greaterThan(tester.getTopLeft(find.text('周六')).dx),
    );

    // Gold star icon shown on all-done day cell.
    expect(find.byIcon(Icons.star_rounded), findsAtLeastNWidgets(1));

    // Compact layout renders habits in 2-column grid (mottos hidden, titles visible side by side).
    expect(find.text('早起喝水'), findsOneWidget);
    expect(find.text('冥想十分钟'), findsOneWidget);
    expect(find.text('清清爽爽'), findsNothing);
    expect(
      tester.getTopLeft(find.text('冥想十分钟')).dy,
      closeTo(tester.getTopLeft(find.text('早起喝水')).dy, 16),
    );

    // Switch live to ultraCompact (3-column grid) & check layout without overflow.
    final container = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    await container.read(appPrefsProvider.notifier).setCardLayout(CardLayout.ultraCompact);
    await tester.pumpAndSettle();

    expect(find.text('阅读半小时'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('阅读半小时')).dy,
      closeTo(tester.getTopLeft(find.text('早起喝水')).dy, 16),
    );

    await disposeWidgetTree(tester);
  });

  testWidgets('banner celebration style displays floating top banner instead of dialog',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    prefsStore = MemoryAppPrefsStore(
      const AppPrefs(
        achievementDisplayStyle: CelebrationStyle.banner,
        perfectDayDisplayStyle: CelebrationStyle.banner,
      ),
    );

    late int habitId;
    await tester.runAsync(() async {
      habitId = await habitRepo.create(dailyDraft('练字二十分钟'));
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Top floating banner appears instead of full modal dialogs.
    expect(find.byKey(const ValueKey('celebration_top_banner')), findsAtLeastNWidgets(1));
    expect(find.text('🤩 保存完美的一天'), findsNothing);

    // Dismiss floating banners cleanly so no timers remain active.
    while (find.byKey(const ValueKey('celebration_top_banner')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('celebration_top_banner')).first);
      await tester.pumpAndSettle();
    }

    await disposeWidgetTree(tester);
  });

  testWidgets('plays native check-in, uncheck, perfect day, and achievement sounds unless disabled',
      (tester) async {
    final spyBridge = _SpySoundBridge();

    late int habitId;
    await tester.runAsync(() async {
      habitId = await habitRepo.create(dailyDraft('弹吉他'));
    });

    await tester.pumpWidget(buildApp(bridge: spyBridge));
    await tester.pumpAndSettle();

    // Checking in plays checkIn + perfectDay immediately, then achievement after closing PerfectDayDialog.
    await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
    await tester.pumpAndSettle();
    expect(spyBridge.playedSounds, [AppSound.checkIn, AppSound.perfectDay]);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(
      spyBridge.playedSounds,
      [AppSound.checkIn, AppSound.perfectDay, AppSound.achievement],
    );
    await dismissCelebrationDialogs(tester);

    // Unchecking plays uncheck.
    spyBridge.playedSounds.clear();
    await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
    await tester.pumpAndSettle();
    expect(spyBridge.playedSounds, [AppSound.uncheck]);

    // Turning soundEnabled off suppresses all sounds.
    spyBridge.playedSounds.clear();
    final container = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    await container.read(appPrefsProvider.notifier).setSoundEnabled(false);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
    await tester.pumpAndSettle();
    expect(spyBridge.playedSounds, isEmpty);
    await dismissCelebrationDialogs(tester);

    await disposeWidgetTree(tester);
  });
}

class _SpySoundBridge extends NativeBridge {
  final List<AppSound> playedSounds = [];

  @override
  Future<void> playSound(AppSound sound) async {
    playedSounds.add(sound);
  }
}
