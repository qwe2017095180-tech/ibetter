import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibetter/app/router.dart';
import 'package:ibetter/app/theme/app_colors.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/features/projects/project_detail_page.dart';
import 'package:ibetter/features/projects/widgets/detail_monthly_calendar.dart';
import 'package:ibetter/features/projects/widgets/project_card.dart';
import 'package:ibetter/features/reminders/notification_service.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final today = DateTime(2026, 11, 24);
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  Future<int> seedHabit(
    WidgetTester tester, {
    String name = '早起阅读',
    String motto = '每天读二十页',
    DateTime? startDate,
    Schedule schedule = const Schedule.daily(),
    int? goalDays = 30,
    int dailyTarget = 1,
    List<String> doneDates = const ['2026-11-22', '2026-11-24'],
  }) async {
    final id = await tester.runAsync(() async {
      final habitRepo = DriftHabitRepository(db);
      final checkInRepo = DriftCheckInRepository(db);
      final habitId = await habitRepo.create(
        HabitDraft(
          name: name,
          iconKey: 'study/book',
          schedule: schedule,
          goalDays: goalDays,
          startDate: startDate ?? DateTime(2026, 11, 20),
          motto: motto,
          dailyTarget: dailyTarget,
        ),
      );
      for (final date in doneDates) {
        await checkInRepo.setCount(habitId, date, dailyTarget);
      }
      return habitId;
    });
    return id!;
  }

  Future<List<String>> pumpDetailApp(
    WidgetTester tester, {
    required int habitId,
  }) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Ensure Drift database is initialized before pumping streams.
    await tester.runAsync(() => DriftHabitRepository(db).watchAll().first);

    final pushedRoutes = <String>[];
    final router = GoRouter(
      initialLocation: Routes.projectDetail(habitId),
      routes: [
        GoRoute(
          path: '/projects/:id',
          builder: (_, state) => ProjectDetailPage(
            habitId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
          ),
        ),
        GoRoute(
          path: '${Routes.editor}/:id',
          builder: (_, state) {
            pushedRoutes.add(state.uri.toString());
            return Scaffold(
              body: Center(child: Text('Editor ${state.pathParameters['id']}')),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(today),
          notificationServiceProvider.overrideWithValue(NoopNotificationService()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return pushedRoutes;
  }

  testWidgets('renders top card, monthly calendar with NOV 11月, and highlights completed day in blue',
      (tester) async {
    final habitId = await seedHabit(tester);
    await pumpDetailApp(tester, habitId: habitId);

    expect(find.text('iBetter'), findsOneWidget);
    expect(find.byType(ProjectCard), findsOneWidget);
    expect(find.text('早起阅读'), findsOneWidget);
    expect(find.text('每天读二十页'), findsOneWidget);

    // Monthly tab active and calendar header displays NOV 11月.
    expect(find.text('每月统计'), findsOneWidget);
    expect(find.text('每年统计'), findsOneWidget);
    expect(find.text('NOV 11月'), findsOneWidget);
    expect(find.text('周日'), findsOneWidget);
    expect(find.text('周六'), findsOneWidget);

    // Bilingual 1st-of-month cells for Nov 1 and Dec 1 in the 6-row grid.
    expect(find.text('NOV\n11月'), findsOneWidget);
    expect(find.text('DEC\n12月'), findsOneWidget);

    // Completed day 2026-11-24 has #5698DF fill and 2px AppColors.primary border.
    final doneCellFinder = find.descendant(
      of: find.byKey(const ValueKey('detail_month_day_2026-11-24')),
      matching: find.byType(Container),
    );
    final doneContainer = tester.widget<Container>(doneCellFinder);
    final doneDecoration = doneContainer.decoration! as BoxDecoration;
    expect(doneDecoration.color, DetailMonthlyCalendar.completedCellFill);
    expect(doneDecoration.color, const Color(0xFF5698DF));
    expect(doneDecoration.border, Border.all(color: AppColors.primary, width: 2));

    // Undone day 2026-11-23 has light grey calendarCell fill.
    final undoneCellFinder = find.descendant(
      of: find.byKey(const ValueKey('detail_month_day_2026-11-23')),
      matching: find.byType(Container),
    );
    final undoneContainer = tester.widget<Container>(undoneCellFinder);
    final undoneDecoration = undoneContainer.decoration! as BoxDecoration;
    expect(undoneDecoration.color, AppColors.calendarCell);
    expect(undoneDecoration.border, isNull);

    // Next month '>' is disabled on today's month; prev '<' moves to OCT 10月 and shows year outside 2026.
    final nextMonthBtn = tester.widget<IconButton>(find.byKey(const ValueKey('month_next_button')));
    expect(nextMonthBtn.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('month_prev_button')));
    await tester.pumpAndSettle();
    expect(find.text('OCT 10月'), findsOneWidget);

    // Navigate back 10 months to 2025 DEC 12月.
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byKey(const ValueKey('month_prev_button')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('2025 DEC 12月'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('tapping eligible date toggles check-in in DB and updates stats; future date shows guard',
      (tester) async {
    final habitId = await seedHabit(
      tester,
      startDate: DateTime(2026, 11, 20),
      doneDates: const ['2026-11-22', '2026-11-24'],
    );
    await pumpDetailApp(tester, habitId: habitId);

    final checkInRepo = DriftCheckInRepository(db);

    // Initially totalDays = 2, monthDays = 2, streak = 1.
    expect(find.descendant(of: find.byType(ProjectCard), matching: find.text('2')), findsNWidgets(2));
    expect(find.descendant(of: find.byType(ProjectCard), matching: find.text('1')), findsOneWidget);

    // Tap 2026-11-23 (eligible undone day) -> marks completed and streak becomes 3!
    await tester.tap(find.byKey(const ValueKey('detail_month_day_2026-11-23')));
    await tester.pumpAndSettle();

    final afterCheck = await tester.runAsync(() => checkInRepo.watchByHabit(habitId).first);
    expect(afterCheck!.map((c) => c.date).toSet(), {'2026-11-22', '2026-11-23', '2026-11-24'});

    // Now totalDays = 3, monthDays = 3, streak = 3!
    expect(find.descendant(of: find.byType(ProjectCard), matching: find.text('3')), findsNWidgets(3));

    final day23Container = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('detail_month_day_2026-11-23')),
        matching: find.byType(Container),
      ),
    );
    expect((day23Container.decoration! as BoxDecoration).color, const Color(0xFF5698DF));

    // Tap 2026-11-23 again -> unchecks in DB and updates stats back.
    await tester.tap(find.byKey(const ValueKey('detail_month_day_2026-11-23')));
    await tester.pumpAndSettle();

    final afterUncheck = await tester.runAsync(() => checkInRepo.watchByHabit(habitId).first);
    expect(afterUncheck!.map((c) => c.date).toSet(), {'2026-11-22', '2026-11-24'});
    expect(find.descendant(of: find.byType(ProjectCard), matching: find.text('2')), findsNWidgets(2));

    // Tap future date 2026-11-25 -> shows SnackBar and leaves DB untouched.
    await tester.tap(find.byKey(const ValueKey('detail_month_day_2026-11-25')));
    await tester.pumpAndSettle();
    expect(find.text('不能为未来打卡'), findsOneWidget);

    // Tap date before startDate (2026-11-19) -> does not write check-in.
    await tester.tap(find.byKey(const ValueKey('detail_month_day_2026-11-19')));
    await tester.pumpAndSettle();
    final finalCheckIns = await tester.runAsync(() => checkInRepo.watchByHabit(habitId).first);
    expect(finalCheckIns!.map((c) => c.date).toSet(), {'2026-11-22', '2026-11-24'});

    await disposeTree(tester);
  });

  testWidgets('switching to 每年统计 tab shows 2026年, 12 months, and accurate yearly stats',
      (tester) async {
    // startDate 2026-11-20 to today 2026-11-24 = 5 eligible days; 3 completed = 60%.
    final habitId = await seedHabit(
      tester,
      startDate: DateTime(2026, 11, 20),
      doneDates: const ['2026-11-20', '2026-11-22', '2026-11-24'],
    );
    await pumpDetailApp(tester, habitId: habitId);

    await tester.tap(find.byKey(const ValueKey('stats_tab_yearly')));
    await tester.pumpAndSettle();

    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('本年完成 3 天'), findsOneWidget);
    expect(find.text('完成率 60%'), findsOneWidget);

    for (var m = 1; m <= 12; m++) {
      expect(find.byKey(ValueKey('year_month_row_$m')), findsOneWidget);
      expect(find.text('$m月'), findsOneWidget);
    }

    expect(
      find.descendant(of: find.byKey(const ValueKey('year_month_row_11')), matching: find.text('3天')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('year_month_row_1')), matching: find.text('0天')),
      findsOneWidget,
    );

    final nextYearBtn = tester.widget<IconButton>(find.byKey(const ValueKey('year_next_button')));
    expect(nextYearBtn.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('year_prev_button')));
    await tester.pumpAndSettle();
    expect(find.text('2025年'), findsOneWidget);
    expect(find.text('本年完成 0 天'), findsOneWidget);
    expect(find.text('完成率 0%'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('tapping 分享 opens preview dialog and 复制分享文案 copies text cleanly',
      (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<dynamic, dynamic>;
          copiedText = args['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final habitId = await seedHabit(
      tester,
      name: '每日冥想',
      motto: '保持专注',
      startDate: DateTime(2026, 11, 20),
      doneDates: const ['2026-11-23', '2026-11-24'],
    );
    await pumpDetailApp(tester, habitId: habitId);

    await tester.tap(find.byKey(const ValueKey('detail_bottom_share_button')));
    await tester.pumpAndSettle();

    expect(find.text('累计坚持'), findsOneWidget);
    expect(find.text('当前连续'), findsOneWidget);
    expect(find.text('2026年11月20日'), findsOneWidget);
    expect(find.text('复制分享文案'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);

    await tester.tap(find.text('复制分享文案'));
    await tester.pumpAndSettle();

    expect(find.text('已复制分享文案'), findsOneWidget);
    expect(copiedText, isNotNull);
    expect(copiedText, contains('每日冥想'));
    expect(copiedText, contains('累计完成：2 天'));
    expect(copiedText, contains('当前连续：2 天'));
    expect(copiedText, contains('2026-11-20'));
    expect(copiedText, contains('保持专注'));

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('复制分享文案'), findsNothing);

    await disposeTree(tester);
  });

  testWidgets('tapping 编辑 (top and bottom) navigates to Routes.editHabit(id)', (tester) async {
    final habitId = await seedHabit(tester);
    final pushedRoutes = await pumpDetailApp(tester, habitId: habitId);

    await tester.tap(find.byKey(const ValueKey('detail_top_edit_button')));
    await tester.pumpAndSettle();
    expect(pushedRoutes, [Routes.editHabit(habitId)]);

    GoRouter.of(tester.element(find.text('Editor $habitId'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('detail_bottom_edit_button')));
    await tester.pumpAndSettle();
    expect(pushedRoutes, [Routes.editHabit(habitId), Routes.editHabit(habitId)]);

    await disposeTree(tester);
  });

  testWidgets('shows not found state when habit id does not exist', (tester) async {
    await pumpDetailApp(tester, habitId: 999);
    expect(find.text('未找到该项目'), findsOneWidget);
    expect(find.byKey(const ValueKey('detail_top_edit_button')), findsNothing);
    expect(find.byKey(const ValueKey('detail_bottom_share_button')), findsNothing);

    await disposeTree(tester);
  });
}
