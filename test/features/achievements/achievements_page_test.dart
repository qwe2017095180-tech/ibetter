import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/app/app_brand.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/prefs/app_prefs.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/services/achievement_service.dart';
import 'package:ibetter/features/achievements/achievements_page.dart';
import 'package:ibetter/features/achievements/widgets/achievement_badge.dart';
import 'package:ibetter/features/achievements/widgets/achievement_utils.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedToday = DateTime(2026, 11, 24);

  group('formatAchievementDate', () {
    test('formats null, today, 1..30 days ago, and older raw dates', () {
      expect(formatAchievementDate(null, fixedToday), '');
      expect(formatAchievementDate('', fixedToday), '');
      expect(formatAchievementDate('2026-11-24', fixedToday), '今天获得');
      expect(formatAchievementDate('2026-11-23', fixedToday), '1天前获得');
      expect(formatAchievementDate('2026-11-18', fixedToday), '6天前获得');
      expect(formatAchievementDate('2026-10-25', fixedToday), '30天前获得');
      expect(formatAchievementDate('2026-10-24', fixedToday), '2026-10-24');
    });
  });

  group('AchievementBadge', () {
    Widget wrapBadge(AchievementItem item) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: AchievementBadge(item: item))),
      );
    }

    testWidgets('renders ? for locked badges across all styles', (tester) async {
      for (final style in AchievementBadgeStyle.values) {
        await tester.pumpWidget(
          wrapBadge(
            AchievementItem(
              id: 'locked_${style.name}',
              title: 'Locked',
              subtitle: 'Sub',
              iconKey: 'achievement/star',
              count: 0,
              badgeStyle: style,
              milestoneDays: 7,
            ),
          ),
        );
        expect(find.text('?'), findsOneWidget);
      }
    });

    testWidgets('renders DAY/DAYS ribbons, scallop streak, star, and trophy emblems when unlocked',
        (tester) async {
      await tester.pumpWidget(
        wrapBadge(
          const AchievementItem(
            id: 'single_1',
            title: '一日幸运',
            subtitle: '单项目坚持1天',
            iconKey: 'achievement/sparkles',
            count: 1,
            category: AchievementCategory.singleProject,
            badgeStyle: AchievementBadgeStyle.singleDayRibbon,
            milestoneDays: 1,
          ),
        ),
      );
      expect(find.text('1 DAY'), findsOneWidget);

      await tester.pumpWidget(
        wrapBadge(
          const AchievementItem(
            id: 'single_2',
            title: '不二法门',
            subtitle: '单项目坚持2天',
            iconKey: 'achievement/light_bulb',
            count: 1,
            category: AchievementCategory.singleProject,
            badgeStyle: AchievementBadgeStyle.singleDayRibbon,
            milestoneDays: 2,
          ),
        ),
      );
      expect(find.text('2 DAY'), findsOneWidget);

      await tester.pumpWidget(
        wrapBadge(
          const AchievementItem(
            id: 'single_3',
            title: '三生万物',
            subtitle: '单项目坚持3天',
            iconKey: 'achievement/star',
            count: 1,
            category: AchievementCategory.singleProject,
            badgeStyle: AchievementBadgeStyle.singleDayRibbon,
            milestoneDays: 3,
          ),
        ),
      );
      expect(find.text('3 DAYS'), findsOneWidget);

      await tester.pumpWidget(
        wrapBadge(
          const AchievementItem(
            id: 'streak_7',
            title: '习惯养成',
            subtitle: '连续打卡7天',
            iconKey: 'achievement/sports_medal',
            count: 1,
            category: AchievementCategory.streak,
            badgeStyle: AchievementBadgeStyle.streakScallop,
            milestoneDays: 7,
          ),
        ),
      );
      expect(find.text('7'), findsOneWidget);
      expect(find.text('DAYS'), findsOneWidget);

      await tester.pumpWidget(
        wrapBadge(
          const AchievementItem(
            id: 'three_habits',
            title: '三国鼎立',
            subtitle: '添加三个任务',
            iconKey: 'achievement/trophy',
            count: 1,
            category: AchievementCategory.task,
            badgeStyle: AchievementBadgeStyle.trophy,
            milestoneDays: 3,
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);

      await tester.pumpWidget(
        wrapBadge(
          const AchievementItem(
            id: 'friendship_medal',
            title: '友谊勋章',
            subtitle: '分享一次',
            iconKey: 'achievement/party_popper',
            count: 1,
            category: AchievementCategory.task,
            badgeStyle: AchievementBadgeStyle.trophy,
          ),
        ),
      );
      expect(find.byIcon(Icons.send), findsOneWidget);

      await tester.pumpWidget(
        wrapBadge(
          const AchievementItem(
            id: 'perfect_day',
            title: '完美的一天',
            subtitle: '完成当日所有打卡',
            iconKey: 'achievement/star',
            count: 1,
            category: AchievementCategory.streak,
            badgeStyle: AchievementBadgeStyle.starCircle,
          ),
        ),
      );
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });
  });

  group('AchievementsPage', () {
    late AppDatabase db;
    late DriftHabitRepository habitRepo;
    late DriftCheckInRepository checkInRepo;
    late MemoryAppPrefsStore prefsStore;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      habitRepo = DriftHabitRepository(db);
      checkInRepo = DriftCheckInRepository(db);
      prefsStore = MemoryAppPrefsStore();
    });

    tearDown(() async {
      await db.close();
    });

    Widget buildApp({DateTime? today}) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(today ?? fixedToday),
          appPrefsStoreProvider.overrideWithValue(prefsStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AchievementsPage(),
        ),
      );
    }

    Future<void> disposeWidgetTree(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    }

    Future<void> seedThreeHabitsThreeDayStreakEndedYesterday() async {
      final start = DateTime(2026, 11, 20);
      final h1 = await habitRepo.create(
        HabitDraft(name: '应付作业', iconKey: 'study/book', startDate: start),
      );
      final h2 = await habitRepo.create(
        HabitDraft(name: '计算机常识学习', iconKey: 'study/laptop', startDate: start),
      );
      final h3 = await habitRepo.create(
        HabitDraft(name: '背单词', iconKey: 'study/abc', startDate: start),
      );
      for (final date in ['2026-11-21', '2026-11-22', '2026-11-23']) {
        await checkInRepo.setCount(h1, date, 1);
        await checkInRepo.setCount(h2, date, 1);
        await checkInRepo.setCount(h3, date, 1);
      }
    }

    Future<void> seedThreeHabitsAllCheckedToday() async {
      final start = DateTime(2026, 11, 21);
      final h1 = await habitRepo.create(
        HabitDraft(name: '应付作业', iconKey: 'study/book', startDate: start),
      );
      final h2 = await habitRepo.create(
        HabitDraft(name: '计算机常识学习', iconKey: 'study/laptop', startDate: start),
      );
      final h3 = await habitRepo.create(
        HabitDraft(name: '背单词', iconKey: 'study/abc', startDate: start),
      );
      await checkInRepo.setCount(h1, '2026-11-24', 1);
      await checkInRepo.setCount(h2, '2026-11-24', 1);
      await checkInRepo.setCount(h3, '2026-11-24', 1);
    }

    testWidgets(
      'renders KPIs, year progress, heatmap, weekly chart, all milestone sections, and relative dates',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.runAsync(seedThreeHabitsThreeDayStreakEndedYesterday);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Top bar.
        expect(find.text('我的成就'), findsOneWidget);
        expect(find.text('成绩单'), findsOneWidget);

        // Top 4-column KPI row: 3 projects, 3 days, 9 completions, 3 longest streak.
        expect(
          find.descendant(of: find.byKey(const ValueKey('kpi_project_count')), matching: find.text('3')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: find.byKey(const ValueKey('kpi_recorded_days')), matching: find.text('3')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('kpi_total_completions')),
            matching: find.text('9'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('kpi_longest_streak')),
            matching: find.text('3'),
          ),
          findsOneWidget,
        );

        // Year progress banner.
        expect(find.textContaining('第 48 周'), findsOneWidget);
        expect(find.textContaining('第 328 天'), findsOneWidget);
        expect(find.textContaining('今年还有 37 天'), findsOneWidget);

        // 我的记录 card & 3-month heatmap.
        expect(find.text('我的记录'), findsOneWidget);
        expect(find.textContaining('应付作业'), findsOneWidget);
        expect(find.text('9月'), findsOneWidget);
        expect(find.text('10月'), findsOneWidget);
        expect(find.text('11月'), findsOneWidget);

        final prevBox = tester.widget<Container>(find.byKey(const ValueKey('heatmap_2026-11-23')));
        expect((prevBox.decoration! as BoxDecoration).color, const Color(0xFF159835));
        final emptyBox = tester.widget<Container>(find.byKey(const ValueKey('heatmap_2026-11-24')));
        expect((emptyBox.decoration! as BoxDecoration).color, const Color(0xFFE6E6E6));

        // 每周打卡记录 card + year switcher.
        expect(find.text('每周打卡记录'), findsOneWidget);
        expect(find.text('第48周'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('weekly_next_year')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('weekly_selected_year'))).data,
          '2026',
        );
        await tester.tap(find.byKey(const ValueKey('weekly_prev_year')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('weekly_selected_year'))).data,
          '2025',
        );
        expect(find.text('第53周'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('weekly_next_year')));
        await tester.pumpAndSettle();
        expect(find.text('第48周'), findsOneWidget);

        // 最新成就 card with 1天前获得.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('latest_achievement_card')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('最新成就'), findsOneWidget);
        expect(find.textContaining('1天前获得'), findsWidgets);

        // 最高成就 card shows 三生万物 & 三天打鱼.
        final highestSection = find.byKey(const ValueKey('achievement_section_highest'));
        await tester.scrollUntilVisible(
          highestSection,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.descendant(of: highestSection, matching: find.text('最高成就')), findsOneWidget);
        expect(find.descendant(of: highestSection, matching: find.text('三生万物')), findsOneWidget);
        expect(find.descendant(of: highestSection, matching: find.text('三天打鱼')), findsOneWidget);

        // 单项目成就 card + locked '?' badges + catalog button.
        final singleSection = find.byKey(const ValueKey('achievement_section_singleProject'));
        await tester.scrollUntilVisible(
          singleSection,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.descendant(of: singleSection, matching: find.text('单项目成就')), findsOneWidget);
        expect(
          find.descendant(
            of: singleSection,
            matching: find.text('3/${kSingleProjectMilestones.length}'),
          ),
          findsOneWidget,
        );
        expect(find.descendant(of: singleSection, matching: find.text('?')), findsWidgets);
        expect(find.byKey(const ValueKey('single_project_view_all_button')), findsOneWidget);

        // 连续成就 card.
        final streakSection = find.byKey(const ValueKey('achievement_section_streak'));
        await tester.scrollUntilVisible(
          streakSection,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.descendant(of: streakSection, matching: find.text('连续成就')), findsOneWidget);
        expect(find.descendant(of: streakSection, matching: find.text('完美的一天')), findsOneWidget);

        // 任务成就 card shows '7' and all 7 items.
        final taskSection = find.byKey(const ValueKey('achievement_section_task'));
        await tester.scrollUntilVisible(
          taskSection,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.descendant(of: taskSection, matching: find.text('任务成就')), findsOneWidget);
        expect(find.descendant(of: taskSection, matching: find.text('7')), findsOneWidget);
        expect(find.descendant(of: taskSection, matching: find.text('三国鼎立')), findsOneWidget);
        expect(find.descendant(of: taskSection, matching: find.text('友谊勋章')), findsOneWidget);

        // 隐藏成就 card masks locked items.
        final hiddenSection = find.byKey(const ValueKey('achievement_section_hidden'));
        await tester.scrollUntilVisible(
          hiddenSection,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.descendant(of: hiddenSection, matching: find.text('隐藏成就')), findsWidgets);
        expect(
          find.descendant(of: hiddenSection, matching: find.text('达到特定条件解锁')),
          findsWidgets,
        );
        expect(find.descendant(of: hiddenSection, matching: find.text('?')), findsWidgets);

        // 特殊成就 card.
        final specialSection = find.byKey(const ValueKey('achievement_section_special'));
        await tester.scrollUntilVisible(
          specialSection,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.descendant(of: specialSection, matching: find.text('特殊成就')), findsOneWidget);
        expect(find.descendant(of: specialSection, matching: find.text('勋章收藏家')), findsOneWidget);

        // Achievements page marked seen count in AppPrefs.
        final savedPrefs = await tester.runAsync(prefsStore.load);
        expect(savedPrefs!.seenAchievementCount, greaterThan(0));

        await disposeWidgetTree(tester);
      },
    );

    testWidgets(
      'copying 成绩单 records share and unlocks 友谊勋章, and tapping 我的记录 opens 全部成就 sheet',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        String? copiedText;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedText = (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        await tester.runAsync(seedThreeHabitsAllCheckedToday);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Tap 我的记录 summary row -> opens 全部成就 sheet.
        await tester.tap(find.byKey(const ValueKey('my_record_summary_row')));
        await tester.pumpAndSettle();
        expect(find.textContaining('全部成就'), findsOneWidget);
        expect(find.text('未解锁'), findsWidgets);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.textContaining('全部成就'), findsNothing);

        // Scroll to 任务成就 first to confirm 友谊勋章 is locked ('获得0次').
        final friendshipRow = find.byKey(const ValueKey('achievement_row_task_friendship_medal'));
        await tester.scrollUntilVisible(
          friendshipRow,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.descendant(of: friendshipRow, matching: find.text('获得0次')), findsOneWidget);
        expect(find.descendant(of: friendshipRow, matching: find.byIcon(Icons.send)), findsNothing);

        // Scroll back up to 成绩单 button -> copy report card.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('report_card_button')),
          -350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('report_card_button')));
        await tester.pumpAndSettle();

        expect(find.text('我的成绩单'), findsOneWidget);
        expect(find.text('2026 年度总结'), findsOneWidget);
        await tester.tap(find.text('复制成绩单'));
        await tester.pumpAndSettle();

        expect(find.text('已复制成绩单'), findsOneWidget);
        expect(copiedText, contains('${AppBrand.name} 2026 年度成绩单'));
        expect(copiedText, contains('完成最多的项目：应付作业'));

        await tester.tap(find.text('关闭'));
        await tester.pumpAndSettle();

        final prefsAfterShare = await tester.runAsync(prefsStore.load);
        expect(prefsAfterShare!.shareCount, 1);
        expect(prefsAfterShare.lastShareDate, '2026-11-24');

        // Verify 友谊勋章 is now unlocked live with send icon & 今天获得.
        await tester.scrollUntilVisible(
          friendshipRow,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: friendshipRow, matching: find.textContaining('今天获得')),
          findsOneWidget,
        );
        expect(find.descendant(of: friendshipRow, matching: find.byIcon(Icons.send)), findsOneWidget);

        await disposeWidgetTree(tester);
      },
    );

    testWidgets(
      'tapping unlocked rows opens celebration dialogs while locked rows do not',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.runAsync(seedThreeHabitsThreeDayStreakEndedYesterday);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Tap unlocked 单项目成就 row (三生万物) -> opens orange celebration dialog.
        final single3Row = find.byKey(const ValueKey('achievement_row_highest_single_3'));
        await tester.scrollUntilVisible(
          single3Row,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(single3Row);
        await tester.pumpAndSettle();

        expect(find.text('立即分享给朋友'), findsOneWidget);
        expect(find.text('赢得日期：2026年11月23日'), findsOneWidget);
        await tester.tap(find.byTooltip('关闭'));
        await tester.pumpAndSettle();
        expect(find.text('立即分享给朋友'), findsNothing);

        // Tap unlocked 完美的一天 row -> opens PerfectDayDialog.
        final perfectDayRow = find.byKey(const ValueKey('achievement_row_streak_perfect_day'));
        await tester.scrollUntilVisible(
          perfectDayRow,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(perfectDayRow);
        await tester.pumpAndSettle();

        expect(find.text('完美的一天！'), findsOneWidget);
        expect(find.text('🤩 保存完美的一天'), findsOneWidget);
        expect(find.text('应付作业'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('perfect_day_close_button')));
        await tester.pumpAndSettle();
        expect(find.text('完美的一天！'), findsNothing);

        // Tapping a locked row (e.g. 习惯养成 streak_7) does nothing.
        final lockedRow = find.byKey(const ValueKey('achievement_row_streak_streak_7'));
        await tester.scrollUntilVisible(
          lockedRow,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(lockedRow);
        await tester.pumpAndSettle();
        expect(find.text('立即分享给朋友'), findsNothing);
        expect(find.text('完美的一天！'), findsNothing);

        await disposeWidgetTree(tester);
      },
    );

    testWidgets('weekly chart supports tapping points and horizontal swipe to inspect earlier weeks',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.runAsync(() async {
        final h = await habitRepo.create(
          HabitDraft(
            name: '晨跑',
            iconKey: 'sport/person_running',
            startDate: DateTime(2026, 9, 1),
          ),
        );
        await checkInRepo.setCount(h, '2026-10-12', 1); // Week 42
        await checkInRepo.setCount(h, '2026-11-24', 1); // Week 48
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('第42周'), findsOneWidget);
      expect(find.text('第48周'), findsOneWidget);

      await tester.tap(find.text('第42周'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('第42周 1次'), findsOneWidget);

      await tester.fling(
        find.byKey(const ValueKey('weekly_chart_canvas')),
        const Offset(250, 0),
        800,
      );
      await tester.pumpAndSettle();
      expect(find.text('第41周'), findsOneWidget);
      expect(find.text('第48周'), findsNothing);

      await disposeWidgetTree(tester);
    });

    testWidgets('empty state and January month rollover heatmap render cleanly without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildApp(today: DateTime(2026, 1, 15)));
      await tester.pumpAndSettle();

      expect(find.text('完成打卡即可解锁你的第一个成就'), findsOneWidget);
      expect(find.textContaining('暂无'), findsOneWidget);
      expect(find.text('11月'), findsOneWidget);
      expect(find.text('12月'), findsOneWidget);
      expect(find.text('1月'), findsOneWidget);
      expect(find.byKey(const ValueKey('heatmap_2025-11-01')), findsOneWidget);
      expect(find.byKey(const ValueKey('heatmap_2025-12-31')), findsOneWidget);
      expect(find.byKey(const ValueKey('heatmap_2026-01-15')), findsOneWidget);

      await disposeWidgetTree(tester);
    });

    testWidgets('heatmap displays 1-count and 2-count green levels and 1天前获得 label',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.runAsync(() async {
        final h1 = await habitRepo.create(
          HabitDraft(name: '喝水', iconKey: 'health/droplet', startDate: DateTime(2026, 11, 20)),
        );
        final h2 = await habitRepo.create(
          HabitDraft(name: '阅读', iconKey: 'study/book', startDate: DateTime(2026, 11, 20)),
        );
        await checkInRepo.setCount(h1, '2026-11-22', 1); // 1 completion -> #6BD98A
        await checkInRepo.setCount(h1, '2026-11-23', 1);
        await checkInRepo.setCount(h2, '2026-11-23', 1); // 2 completions -> #2DB84B
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final oneBox = tester.widget<Container>(find.byKey(const ValueKey('heatmap_2026-11-22')));
      expect((oneBox.decoration! as BoxDecoration).color, const Color(0xFF6BD98A));
      final twoBox = tester.widget<Container>(find.byKey(const ValueKey('heatmap_2026-11-23')));
      expect((twoBox.decoration! as BoxDecoration).color, const Color(0xFF2DB84B));

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('latest_achievement_card')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('完美的一天'), findsOneWidget);
      expect(find.textContaining('1天前获得'), findsWidgets);

      await disposeWidgetTree(tester);
    });

    testWidgets(
      'opens 单项目成就图鉴 sheet, filters by stage, and searches 325 meme achievement',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.runAsync(seedThreeHabitsThreeDayStreakEndedYesterday);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final viewAllBtn = find.byKey(const ValueKey('single_project_view_all_button'));
        await tester.scrollUntilVisible(
          viewAllBtn,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(viewAllBtn);
        await tester.pumpAndSettle();

        expect(find.text('单项目成就图鉴'), findsOneWidget);
        expect(find.text('已解锁 3 / ${kSingleProjectMilestones.length}'), findsOneWidget);

        // Filter to 301-365天 stage.
        final stage301 = find.byKey(const ValueKey('catalog_stage_301_365'));
        await tester.ensureVisible(stage301);
        await tester.pumpAndSettle();
        await tester.tap(stage301);
        await tester.pumpAndSettle();
        expect(find.text('301 永久重定向'), findsOneWidget);

        // Search for 325 meme milestone.
        await tester.enterText(find.byKey(const ValueKey('single_catalog_search_input')), '325');
        await tester.pumpAndSettle();
        expect(find.text('仙术杯 325'), findsOneWidget);
        expect(find.textContaining('明日方舟'), findsOneWidget);

        await disposeWidgetTree(tester);
      },
    );
  });
}
