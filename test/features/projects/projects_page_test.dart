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
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/models/reminder.dart';
import 'package:ibetter/features/projects/projects_page.dart';
import 'package:ibetter/features/projects/widgets/project_card.dart';
import 'package:ibetter/features/reminders/notification_service.dart';
import 'package:material_ui/material_ui.dart';

class _SpyNotificationService extends NoopNotificationService {
  final List<int> cancelledHabitIds = [];
  final List<(Habit, List<Reminder>)> syncedHabits = [];

  @override
  Future<void> cancelHabit(int habitId) async {
    cancelledHabitIds.add(habitId);
  }

  @override
  Future<void> syncHabit(Habit habit, List<Reminder> reminders) async {
    syncedHabits.add((habit, reminders));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final today = DateTime(2026, 11, 24);

  Future<({AppDatabase db, _SpyNotificationService notifications, List<String> pushedRoutes})>
      pumpProjectsApp(
    WidgetTester tester, {
    NotificationService? notificationService,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final notifications = _SpyNotificationService();
    final pushedRoutes = <String>[];

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    });

    final router = GoRouter(
      initialLocation: Routes.projects,
      routes: [
        GoRoute(
          path: Routes.projects,
          builder: (_, _) => const ProjectsPage(),
        ),
        GoRoute(
          path: '/projects/:id',
          builder: (_, state) {
            pushedRoutes.add(state.uri.toString());
            return Scaffold(
              body: Center(child: Text('Detail ${state.pathParameters['id']}')),
            );
          },
        ),
        GoRoute(
          path: Routes.editor,
          builder: (_, state) {
            pushedRoutes.add(state.uri.toString());
            return const Scaffold(body: Center(child: Text('Editor New')));
          },
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
          notificationServiceProvider.overrideWithValue(notificationService ?? notifications),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    return (db: db, notifications: notifications, pushedRoutes: pushedRoutes);
  }

  testWidgets('shows empty state when no habits exist and navigates to editor', (tester) async {
    final env = await pumpProjectsApp(tester);

    expect(find.text('我的项目'), findsOneWidget);
    expect(find.text('还没有项目'), findsOneWidget);
    expect(find.text('创建项目'), findsOneWidget);

    await tester.tap(find.text('创建项目'));
    await tester.pumpAndSettle();
    expect(env.pushedRoutes, [Routes.editor]);

    GoRouter.of(tester.element(find.text('Editor New'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(env.pushedRoutes, [Routes.editor, Routes.editor]);
  });

  testWidgets('card displays totals, month, streak, goal progress, and units from seeded check-ins',
      (tester) async {
    final env = await pumpProjectsApp(tester, notificationService: NoopNotificationService());
    final container = ProviderScope.containerOf(tester.element(find.byType(ProjectsPage)));
    final habitRepo = container.read(habitRepositoryProvider);
    final checkInRepo = container.read(checkInRepositoryProvider);

    // Daily habit with 4 total days (1 in Oct, 3 in Nov), 3-day streak, goal 21 days.
    final dailyId = await habitRepo.create(
      HabitDraft(
        name: '早起喝水',
        iconKey: 'health/water',
        schedule: const Schedule.daily(),
        goalDays: 21,
        startDate: DateTime(2026, 10, 1),
        motto: '每天一杯温水',
      ),
    );
    await checkInRepo.setCount(dailyId, '2026-10-31', 1);
    await checkInRepo.setCount(dailyId, '2026-11-22', 1);
    await checkInRepo.setCount(dailyId, '2026-11-23', 1);
    await checkInRepo.setCount(dailyId, '2026-11-24', 1);

    // Weekly quota habit with goal reached (goal = 4, total = 4, streak = 2 weeks).
    final weeklyId = await habitRepo.create(
      HabitDraft(
        name: '健身房锻炼',
        iconKey: 'sport/gym',
        schedule: const Schedule.timesPerWeek(2),
        goalDays: 4,
        startDate: DateTime(2026, 11, 1),
        motto: '保持体能',
      ),
    );
    await checkInRepo.setCount(weeklyId, '2026-11-16', 1);
    await checkInRepo.setCount(weeklyId, '2026-11-18', 1);
    await checkInRepo.setCount(weeklyId, '2026-11-22', 1);
    await checkInRepo.setCount(weeklyId, '2026-11-24', 1);

    // Monthly quota habit with goalDays == null ('永远'), total = 1 ('Day'), streak = 1 ('月').
    final monthlyId = await habitRepo.create(
      HabitDraft(
        name: '月度复盘',
        iconKey: 'study/book',
        schedule: const Schedule.timesPerMonth(1),
        goalDays: null,
        startDate: DateTime(2026, 11, 1),
      ),
    );
    await checkInRepo.setCount(monthlyId, '2026-11-24', 1);

    await tester.pumpAndSettle();

    final dailyCard = find.byKey(ValueKey('project-card-$dailyId'));
    expect(dailyCard, findsOneWidget);
    expect(find.descendant(of: dailyCard, matching: find.text('早起喝水')), findsOneWidget);
    expect(find.descendant(of: dailyCard, matching: find.text('每天一杯温水')), findsOneWidget);
    expect(find.descendant(of: dailyCard, matching: find.text('4')), findsOneWidget); // totalDays
    expect(find.descendant(of: dailyCard, matching: find.text('3')), findsNWidgets(2)); // month & streak
    expect(find.descendant(of: dailyCard, matching: find.text('Days')), findsNWidgets(3));
    expect(find.descendant(of: dailyCard, matching: find.text('21天')), findsOneWidget);
    expect(find.descendant(of: dailyCard, matching: find.text('已达成')), findsNothing);
    expect(find.descendant(of: dailyCard, matching: find.text('项目进行中')), findsOneWidget);
    expect(find.descendant(of: dailyCard, matching: find.text('Since 10月 1, 2026')), findsOneWidget);

    final dailyProgress = tester.widget<LinearProgressIndicator>(
      find.descendant(of: dailyCard, matching: find.byType(LinearProgressIndicator)),
    );
    expect(dailyProgress.value, closeTo(4 / 21, 1e-6));

    // Scroll to check weekly habit.
    final weeklyCard = find.byKey(ValueKey('project-card-$weeklyId'));
    await tester.scrollUntilVisible(weeklyCard, 200);
    await tester.pumpAndSettle();

    expect(find.descendant(of: weeklyCard, matching: find.text('健身房锻炼')), findsOneWidget);
    expect(find.descendant(of: weeklyCard, matching: find.text('2')), findsOneWidget); // 2-week streak
    expect(find.descendant(of: weeklyCard, matching: find.text('周')), findsOneWidget);
    expect(find.descendant(of: weeklyCard, matching: find.text('4天')), findsOneWidget);
    expect(find.descendant(of: weeklyCard, matching: find.text('已达成')), findsOneWidget);
    expect(find.descendant(of: weeklyCard, matching: find.text('Since 11月 1, 2026')), findsOneWidget);

    // Scroll to check monthly habit ('永远', singular 'Day', '月' chip, no progress bar).
    final monthlyCard = find.byKey(ValueKey('project-card-$monthlyId'));
    await tester.scrollUntilVisible(monthlyCard, 200);
    await tester.pumpAndSettle();

    expect(find.descendant(of: monthlyCard, matching: find.text('月度复盘')), findsOneWidget);
    expect(find.descendant(of: monthlyCard, matching: find.text('Day')), findsNWidgets(2)); // total & month
    expect(find.descendant(of: monthlyCard, matching: find.text('月')), findsOneWidget);
    expect(find.descendant(of: monthlyCard, matching: find.text('永远')), findsOneWidget);
    expect(
      find.descendant(of: monthlyCard, matching: find.byType(LinearProgressIndicator)),
      findsNothing,
    );
    expect(env.db.schemaVersion, 2);
  });

  testWidgets('toggling switch pauses and resumes habit and updates notifications', (tester) async {
    final env = await pumpProjectsApp(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(ProjectsPage)));
    final habitRepo = container.read(habitRepositoryProvider);
    final reminderRepo = container.read(reminderRepositoryProvider);

    final id = await habitRepo.create(
      HabitDraft(
        name: '阅读',
        iconKey: 'study/book',
        startDate: DateTime(2026, 11, 21),
      ),
    );
    await reminderRepo.replaceForHabit(id, const [ReminderDraft(minutesOfDay: 480)]);
    await tester.pumpAndSettle();

    expect(find.text('项目进行中'), findsOneWidget);
    expect(find.text('Since 11月 21, 2026'), findsOneWidget);

    // Pause habit via Switch.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final pausedHabit = await habitRepo.getById(id);
    expect(pausedHabit!.isActive, isFalse);
    expect(find.text('项目已暂停'), findsOneWidget);
    expect(env.notifications.cancelledHabitIds, [id]);

    // Check paused card header is grey #B8B8C8.
    final pausedInk = tester.widget<Ink>(
      find.descendant(of: find.byType(ProjectCard), matching: find.byType(Ink)),
    );
    expect((pausedInk.decoration! as BoxDecoration).color, const Color(0xFFB8B8C8));

    // Resume habit via Switch.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final resumedHabit = await habitRepo.getById(id);
    expect(resumedHabit!.isActive, isTrue);
    expect(find.text('项目进行中'), findsOneWidget);
    expect(env.notifications.syncedHabits, hasLength(1));
    expect(env.notifications.syncedHabits.single.$1.id, id);
    expect(env.notifications.syncedHabits.single.$1.isActive, isTrue);
    expect(env.notifications.syncedHabits.single.$2.single.minutesOfDay, 480);

    final activeInk = tester.widget<Ink>(
      find.descendant(of: find.byType(ProjectCard), matching: find.byType(Ink)),
    );
    expect((activeInk.decoration! as BoxDecoration).color, AppColors.habitCard);
  });

  testWidgets('tap card and long-press actions (edit, cancel delete, confirm delete)',
      (tester) async {
    final env = await pumpProjectsApp(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(ProjectsPage)));
    final habitRepo = container.read(habitRepositoryProvider);

    final id = await habitRepo.create(
      HabitDraft(
        name: '背单词',
        iconKey: 'study/book',
        startDate: DateTime(2026, 11, 21),
      ),
    );
    await tester.pumpAndSettle();

    // Tap card navigates to project detail route.
    await tester.tap(find.byKey(ValueKey('project-card-$id')));
    await tester.pumpAndSettle();
    expect(env.pushedRoutes, [Routes.projectDetail(id)]);

    GoRouter.of(tester.element(find.text('Detail $id'))).pop();
    await tester.pumpAndSettle();

    // Long-press -> 编辑 navigates to edit route.
    await tester.longPress(find.byKey(ValueKey('project-card-$id')));
    await tester.pumpAndSettle();
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(env.pushedRoutes, [Routes.projectDetail(id), Routes.editHabit(id)]);

    GoRouter.of(tester.element(find.text('Editor $id'))).pop();
    await tester.pumpAndSettle();

    // Long-press -> 删除 -> 取消 keeps habit.
    await tester.longPress(find.byKey(ValueKey('project-card-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除后打卡记录将一并清除'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await habitRepo.getById(id), isNotNull);
    expect(env.notifications.cancelledHabitIds, isEmpty);

    // Long-press -> 删除 -> confirm removes card and cancels notifications.
    await tester.longPress(find.byKey(ValueKey('project-card-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(env.notifications.cancelledHabitIds, [id]);
    expect(await habitRepo.getById(id), isNull);
    expect(find.byKey(ValueKey('project-card-$id')), findsNothing);
    expect(find.text('还没有项目'), findsOneWidget);
  });

  testWidgets('filter bottom sheet filters by 已暂停, 进行中, and sorts by total days',
      (tester) async {
    await pumpProjectsApp(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(ProjectsPage)));
    final habitRepo = container.read(habitRepositoryProvider);
    final checkInRepo = container.read(checkInRepositoryProvider);

    final runId = await habitRepo.create(
      HabitDraft(
        name: '跑步',
        iconKey: 'sport/run',
        startDate: DateTime(2026, 11, 21),
        isActive: true,
      ),
    );
    await checkInRepo.setCount(runId, '2026-11-24', 1);

    final meditateId = await habitRepo.create(
      HabitDraft(
        name: '冥想',
        iconKey: 'mind/meditate',
        startDate: DateTime(2026, 11, 21),
        isActive: false,
      ),
    );
    await checkInRepo.setCount(meditateId, '2026-11-22', 1);
    await checkInRepo.setCount(meditateId, '2026-11-23', 1);
    await tester.pumpAndSettle();

    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('冥想'), findsOneWidget);

    // Open filter sheet, sort by 累计天数, and select 已暂停.
    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('已暂停'), findsOneWidget);

    await tester.tap(find.text('按累计天数'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('已暂停'));
    await tester.pumpAndSettle();

    expect(find.text('冥想'), findsOneWidget);
    expect(find.text('跑步'), findsNothing);

    // Switch back to 全部 and verify 冥想 (2 days) comes before 跑步 (1 day).
    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();

    final meditateTop = tester.getTopLeft(find.byKey(ValueKey('project-card-$meditateId'))).dy;
    final runTop = tester.getTopLeft(find.byKey(ValueKey('project-card-$runId'))).dy;
    expect(meditateTop, lessThan(runTop));

    // Switch filter to 进行中.
    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进行中'));
    await tester.pumpAndSettle();

    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('冥想'), findsNothing);
  });
}
