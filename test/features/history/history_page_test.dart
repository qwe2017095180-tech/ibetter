import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ibetter/app/router.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/prefs/app_prefs.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/features/history/history_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftHabitRepository habitRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    habitRepo = DriftHabitRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp({String initialLocation = Routes.history}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Root Home')),
        ),
        GoRoute(
          path: Routes.history,
          builder: (_, _) => const HistoryPage(),
        ),
        GoRoute(
          path: '/projects/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Project Detail ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(DateTime(2026, 11, 26)),
        appPrefsStoreProvider.overrideWithValue(MemoryAppPrefsStore()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }

  Future<void> disposeWidgetTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  Future<void> insertCheckIn({
    required int habitId,
    required String date,
    required int count,
    required DateTime updatedAt,
    String? note,
  }) async {
    await db.into(db.checkIns).insert(
          CheckInsCompanion.insert(
            habitId: habitId,
            date: date,
            doneCount: Value(count),
            note: Value(note),
            updatedAt: updatedAt.millisecondsSinceEpoch,
          ),
        );
  }

  testWidgets('empty state renders 还没有打卡记录', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('历史记录'), findsOneWidget);
    expect(find.text('还没有打卡记录'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets(
      'renders reverse-chronological timeline grouped by month and day and opens project detail on tap',
      (tester) async {
    late int readId;
    late int wordId;
    await tester.runAsync(() async {
      readId = await habitRepo.create(
        HabitDraft(
          name: '早起阅读',
          iconKey: 'study/book',
          startDate: DateTime(2026, 10, 1),
        ),
      );
      wordId = await habitRepo.create(
        HabitDraft(
          name: '背单词',
          iconKey: 'study/abc',
          startDate: DateTime(2026, 10, 1),
        ),
      );
      await insertCheckIn(
        habitId: wordId,
        date: '2026-11-26',
        count: 1,
        updatedAt: DateTime(2026, 11, 26, 10, 50),
      );
      await insertCheckIn(
        habitId: readId,
        date: '2026-11-24',
        count: 1,
        updatedAt: DateTime(2026, 11, 24, 19, 5),
      );
      await insertCheckIn(
        habitId: wordId,
        date: '2026-11-24',
        count: 1,
        updatedAt: DateTime(2026, 11, 24, 9, 15),
      );
      await insertCheckIn(
        habitId: readId,
        date: '2026-10-30',
        count: 1,
        updatedAt: DateTime(2026, 10, 30, 8, 9),
      );
      // Undone record (note only, count=0) must not appear in History.
      await insertCheckIn(
        habitId: readId,
        date: '2026-10-29',
        count: 0,
        note: '未完成',
        updatedAt: DateTime(2026, 10, 29, 21, 0),
      );
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('11月, 2026'), findsOneWidget);
    expect(find.text('10月, 2026'), findsOneWidget);

    expect(find.text('26'), findsOneWidget);
    expect(find.text('周四'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('周二'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('周五'), findsOneWidget);
    expect(find.text('29'), findsNothing);

    expect(find.text('10:50'), findsOneWidget);
    expect(find.text('19:05'), findsOneWidget);
    expect(find.text('09:15'), findsOneWidget);
    expect(find.text('08:09'), findsOneWidget);
    expect(find.text('早起阅读'), findsNWidgets(2));
    expect(find.text('背单词'), findsNWidgets(2));

    // Verify 11月 appears above 10月.
    final novY = tester.getTopLeft(find.text('11月, 2026')).dy;
    final octY = tester.getTopLeft(find.text('10月, 2026')).dy;
    expect(novY, lessThan(octY));

    // Tapping a row navigates to Routes.projectDetail(habitId).
    await tester.tap(
      find.byKey(ValueKey('history_entry_${wordId}_2026-11-26')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Project Detail $wordId'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets('back button pops history page', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push(Routes.history),
                child: const Text('Go History'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.history,
          builder: (_, _) => const HistoryPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPrefsStoreProvider.overrideWithValue(MemoryAppPrefsStore()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go History'));
    await tester.pumpAndSettle();
    expect(find.text('历史记录'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('Go History'), findsOneWidget);

    await disposeWidgetTree(tester);
  });
}
