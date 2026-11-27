import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/app/app.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/prefs/app_prefs.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/models/reminder.dart';
import 'package:ibetter/features/reminders/notification_service.dart';
import 'package:material_ui/material_ui.dart';

class _SpyNotificationService extends NoopNotificationService {
  final List<int> syncedHabitIds = [];
  final List<int> cancelledHabitIds = [];

  @override
  Future<void> syncHabit(Habit habit, List<Reminder> reminders) async {
    syncedHabitIds.add(habit.id);
  }

  @override
  Future<void> cancelHabit(int habitId) async {
    cancelledHabitIds.add(habitId);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedToday = DateTime(2026, 11, 24);

  group('WP9 E2E acceptance flows', () {
    late AppDatabase db;
    late _SpyNotificationService spyNotif;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      spyNotif = _SpyNotificationService();
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            todayProvider.overrideWithValue(fixedToday),
            notificationServiceProvider.overrideWithValue(spyNotif),
            appPrefsStoreProvider.overrideWithValue(MemoryAppPrefsStore()),
          ],
          child: const IBetterApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> disposeTree(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    }

    testWidgets(
      'create daily habit -> check in today & yesterday -> verify stats -> pause hides from home',
      (tester) async {
        await pumpApp(tester);

        // Initially empty on Home.
        expect(find.text('创建第一个项目'), findsOneWidget);

        // Tap '+' to open editor.
        await tester.tap(find.byTooltip('创建项目'));
        await tester.pumpAndSettle();
        expect(find.text('创建项目'), findsOneWidget);

        // Enter habit name & save.
        await tester.enterText(find.byType(TextField).first, '背单词');
        await tester.pump();
        await tester.tap(find.text('完成'));
        await tester.pumpAndSettle();

        // Back on Home: habit is visible, pending badge = 1.
        expect(find.text('轻松打卡'), findsWidgets);
        expect(find.text('背单词'), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // badge on Today tab

        // Fetch created habit id via runAsync.
        final habitId = await tester.runAsync(() async {
          final habits = await DriftHabitRepository(db).watchAll().first;
          return habits.single.id;
        });
        expect(habitId, isNotNull);

        // Check in today -> triggers Perfect Day dialog, then 1-day achievement dialog.
        await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
        await tester.pumpAndSettle();
        expect(find.text('完美的一天！'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle();
        // Close achievement unlock dialog ('一日幸运') if shown.
        if (find.byIcon(Icons.close).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.close).first);
          await tester.pumpAndSettle();
        }

        // Open History timeline via top-left clock button and verify check-in appears.
        await tester.tap(find.byTooltip('历史记录'));
        await tester.pumpAndSettle();
        expect(find.text('历史记录'), findsOneWidget);
        expect(find.text('11月, 2026'), findsOneWidget);
        expect(find.text('背单词'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();

        // All scheduled habits done today -> green checkmark badge on Today tab!
        expect(find.byKey(const ValueKey('today_all_done_badge')), findsOneWidget);

        // Switch to Projects tab (index 1).
        await tester.tap(find.byIcon(Icons.assignment_outlined));
        await tester.pumpAndSettle();
        expect(find.text('我的项目'), findsOneWidget);
        expect(find.text('背单词'), findsOneWidget);
        // Total=1 Day, Month=1 Day, Streak=1 Day.
        expect(find.text('1'), findsNWidgets(3));

        // Tap project card -> opens ProjectDetailPage with 每月统计 / 每年统计.
        await tester.tap(find.text('背单词'));
        await tester.pumpAndSettle();
        expect(find.text('每月统计'), findsOneWidget);
        expect(find.text('每年统计'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();
        expect(find.text('我的项目'), findsOneWidget);

        // Move startDate to 2026-11-22 so yesterday (2026-11-23) can be backfilled.
        await tester.runAsync(() async {
          final repo = DriftHabitRepository(db);
          final h = (await repo.getById(habitId!))!;
          await repo.update(
            h.copyWithDraft(
              HabitDraft(
                name: h.name,
                iconKey: h.iconKey,
                schedule: h.schedule,
                goalDays: h.goalDays,
                startDate: DateTime(2026, 11, 22),
                motto: h.motto,
                enableScore: h.enableScore,
                enableMood: h.enableMood,
                dailyTarget: h.dailyTarget,
                isActive: h.isActive,
              ),
            ),
          );
        });
        await tester.pumpAndSettle();

        // Switch back to Today tab (bottom bar calendar icon showing '24').
        await tester.tap(find.text('24').last);
        await tester.pumpAndSettle();

        // Tap yesterday (2026-11-23) cell and check in.
        await tester.tap(find.byKey(const ValueKey('calendar_day_2026-11-23')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('habit_checkbox_$habitId')));
        await tester.pumpAndSettle();
        // Dismiss Perfect Day & 2-day milestone ('不二法门') dialogs.
        while (find.byIcon(Icons.close).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.close).first);
          await tester.pumpAndSettle();
        }

        // Switch to Projects tab and verify Total=2, Month=2, Streak=2.
        await tester.tap(find.byIcon(Icons.assignment_outlined));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsNWidgets(3));

        // Toggle active switch off -> paused, notification cancelled.
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();
        expect(find.text('项目已暂停'), findsOneWidget);
        expect(spyNotif.cancelledHabitIds, contains(habitId));

        // Back to Home: paused habit no longer shown.
        await tester.tap(find.text('24').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('回到今天'));
        await tester.pumpAndSettle();
        expect(find.text('背单词'), findsNothing);

        await disposeTree(tester);
      },
    );

    testWidgets(
      'future startDate habit is hidden today and disabled on future calendar date',
      (tester) async {
        final futureId = await tester.runAsync(() async {
          return DriftHabitRepository(db).create(
            HabitDraft(
              name: '未来计划',
              iconKey: 'study/book',
              startDate: DateTime(2026, 11, 26),
            ),
          );
        });

        await pumpApp(tester);

        // Today (2026-11-24): future habit does not appear.
        expect(find.text('未来计划'), findsNothing);

        // Select 2026-11-26 on calendar: habit appears but check-in is blocked.
        await tester.tap(find.byKey(const ValueKey('calendar_day_2026-11-26')));
        await tester.pumpAndSettle();
        expect(find.text('未来计划'), findsOneWidget);

        await tester.tap(find.byKey(ValueKey('habit_checkbox_$futureId')));
        await tester.pumpAndSettle();
        expect(find.text('不能为未来打卡'), findsOneWidget);

        final checkIns = await tester.runAsync(
          () => DriftCheckInRepository(db).watchAll().first,
        );
        expect(checkIns, isEmpty);

        await disposeTree(tester);
      },
    );

    testWidgets('tab navigation covers all 5 tabs cleanly', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.assignment_outlined));
      await tester.pumpAndSettle();
      expect(find.text('我的项目'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.emoji_events_outlined));
      await tester.pumpAndSettle();
      expect(find.text('我的成就'), findsOneWidget);
      expect(find.text('成绩单'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.account_circle));
      await tester.pumpAndSettle();
      expect(find.text('我的'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text('更多'), findsOneWidget);

      await disposeTree(tester);
    });
  });

  test('persistence across process restart (file-backed SQLite reopen)', () async {
    final tmpDir = await Directory.systemTemp.createTemp('ibetter_e2e_');
    final dbFile = File('${tmpDir.path}/ibetter_test.sqlite');
    try {
      // First "session": write habit, check-in, and reminder, then close DB.
      final db1 = AppDatabase(NativeDatabase(dbFile));
      final habits1 = DriftHabitRepository(db1);
      final checkIns1 = DriftCheckInRepository(db1);
      final reminders1 = DriftReminderRepository(db1);

      final id = await habits1.create(
        HabitDraft(
          name: '早起喝水',
          iconKey: 'health/droplet',
          schedule: const Schedule.timesPerWeek(5),
          goalDays: 30,
          startDate: DateTime(2026, 11, 20),
          motto: '每天进步一点点',
          dailyTarget: 2,
        ),
      );
      await checkIns1.setCount(id, '2026-11-24', 2);
      await checkIns1.saveDetail(id, '2026-11-24', score: 95, mood: 4, note: '精神饱满');
      await reminders1.replaceForHabit(id, const [ReminderDraft(minutesOfDay: 450)]);
      await db1.close();

      // Second "session": reopen same SQLite file and verify all rows survive.
      final db2 = AppDatabase(NativeDatabase(dbFile));
      try {
        final habits2 = DriftHabitRepository(db2);
        final checkIns2 = DriftCheckInRepository(db2);
        final reminders2 = DriftReminderRepository(db2);

        final loadedHabit = await habits2.getById(id);
        expect(loadedHabit, isNotNull);
        expect(loadedHabit!.name, '早起喝水');
        expect(loadedHabit.schedule, const Schedule.timesPerWeek(5));
        expect(loadedHabit.goalDays, 30);
        expect(loadedHabit.dailyTarget, 2);

        final loadedCheckIns = await checkIns2.watchByHabit(id).first;
        expect(loadedCheckIns, hasLength(1));
        expect(loadedCheckIns.single.count, 2);
        expect(loadedCheckIns.single.score, 95);
        expect(loadedCheckIns.single.mood, 4);
        expect(loadedCheckIns.single.note, '精神饱满');

        final loadedReminders = await reminders2.getByHabit(id);
        expect(loadedReminders, hasLength(1));
        expect(loadedReminders.single.timeLabel, '07:30');
      } finally {
        await db2.close();
      }
    } finally {
      await tmpDir.delete(recursive: true);
    }
  });
}
