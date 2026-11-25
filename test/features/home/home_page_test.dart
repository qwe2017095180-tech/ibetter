import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
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
import 'package:ibetter/features/home/home_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedToday = DateTime(2026, 11, 24); // Tuesday

  late AppDatabase db;
  late DriftHabitRepository habitRepo;
  late DriftCheckInRepository checkInRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    habitRepo = DriftHabitRepository(db);
    checkInRepo = DriftCheckInRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp({GoRouter? router}) {
    final appRouter = router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HomePage()),
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

  testWidgets('tapping check box toggles count=1 and 0 in DB and updates UI', (
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

    expect(find.byIcon(Icons.check), findsOneWidget);
    final saved = await tester.runAsync(
      () => checkInRepo.watchByDate('2026-11-24').first,
    );
    expect(saved!.single.count, 1);

    // Day completion green dot renders on today's calendar cell.
    final todayCell = find.byKey(const ValueKey('calendar_day_2026-11-24'));
    expect(
      find.descendant(
        of: todayCell,
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == AppColors.done,
        ),
      ),
      findsOneWidget,
    );

    // Tap again to uncheck (count = 0).
    await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing);
    final afterUncheck = await tester.runAsync(
      () => checkInRepo.watchByDate('2026-11-24').first,
    );
    expect(afterUncheck, isEmpty);

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

  testWidgets('horizontal swipe moves window and clock button jumps back to today',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Swipe left in expanded mode -> +5 weeks (window moves 2026-11-15 -> 2026-12-20).
    await tester.fling(
      find.byKey(const ValueKey('calendar_grid')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar_day_2026-12-20')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-24')), findsNothing);
    // Selected date moved +35 days: 2026-11-24 (Tue) -> 2026-12-29 (Tue).
    final dec29Cell = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('calendar_day_2026-12-29')),
        matching: find.byType(Container),
      ),
    );
    expect((dec29Cell.decoration! as BoxDecoration).color, Colors.white);

    // Tap clock button -> jumps selected date and window back to today (2026-11-24).
    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar_day_2026-11-24')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_day_2026-11-15')), findsOneWidget);

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

    // Jump back to today and tap card body -> opens edit route.
    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();

    await tester.tap(find.text('周二健身'));
    await tester.pumpAndSettle();
    expect(find.text('Editor $habitId'), findsOneWidget);

    await disposeWidgetTree(tester);
  });
}
