import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/providers.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/features/achievements/achievements_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final fixedToday = DateTime(2026, 11, 24);

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

  Widget buildApp({DateTime? today}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(today ?? fixedToday),
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

  testWidgets('renders KPIs, year progress, record heatmap, weekly chart, and latest achievement',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(seedThreeHabitsAllCheckedToday);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Top bar.
    expect(find.text('我的成就'), findsOneWidget);
    expect(find.text('成绩单'), findsOneWidget);

    // Top 4-column KPI row: 3, 1, 3, 1.
    expect(
      find.descendant(of: find.byKey(const ValueKey('kpi_project_count')), matching: find.text('项目数')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('kpi_project_count')), matching: find.text('3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('kpi_recorded_days')), matching: find.text('记录天数')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('kpi_recorded_days')), matching: find.text('1')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kpi_total_completions')),
        matching: find.text('达成次数'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('kpi_total_completions')), matching: find.text('3')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kpi_longest_streak')),
        matching: find.text('最长连续'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const ValueKey('kpi_longest_streak')), matching: find.text('1')),
      findsOneWidget,
    );

    // Year progress banner.
    expect(find.textContaining('第 48 周'), findsOneWidget);
    expect(find.textContaining('第 328 天'), findsOneWidget);
    expect(find.textContaining('今年还有 37 天'), findsOneWidget);

    // 我的记录 card.
    expect(find.text('我的记录'), findsOneWidget);
    expect(find.textContaining('应付作业'), findsOneWidget);
    expect(find.text('9月'), findsOneWidget);
    expect(find.text('10月'), findsOneWidget);
    expect(find.text('11月'), findsOneWidget);

    // Heatmap color intensities: 2026-11-24 has 3 completions (#159835), 2026-11-23 has 0 (#E6E6E6).
    final todayBox = tester.widget<Container>(find.byKey(const ValueKey('heatmap_2026-11-24')));
    expect((todayBox.decoration! as BoxDecoration).color, const Color(0xFF159835));
    final emptyBox = tester.widget<Container>(find.byKey(const ValueKey('heatmap_2026-11-23')));
    expect((emptyBox.decoration! as BoxDecoration).color, const Color(0xFFE6E6E6));

    // 每周打卡记录 card + year switcher.
    expect(find.text('每周打卡记录'), findsOneWidget);
    expect(find.text('第48周'), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly_selected_year')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('weekly_selected_year'))).data,
      '2026',
    );

    // Next year button is disabled at today.year (2026).
    await tester.tap(find.byKey(const ValueKey('weekly_next_year')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('weekly_selected_year'))).data,
      '2026',
    );

    // Switch back to 2025, then forward to 2026.
    await tester.tap(find.byKey(const ValueKey('weekly_prev_year')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('weekly_selected_year'))).data,
      '2025',
    );
    expect(find.text('第53周'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weekly_next_year')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('weekly_selected_year'))).data,
      '2026',
    );
    expect(find.text('第48周'), findsOneWidget);

    // 最新成就 card.
    await tester.scrollUntilVisible(
      find.text('最新成就'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('最新成就'), findsOneWidget);
    expect(find.text('完美的一天'), findsOneWidget);
    expect(find.text('完成当日所有打卡'), findsOneWidget);
    expect(find.textContaining('今天获得'), findsOneWidget);

    await disposeWidgetTree(tester);
  });

  testWidgets('tapping 最新成就 opens 全部成就 sheet and tapping 成绩单 opens report sheet with copy',
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

    // Tap 最新成就 -> opens 全部成就 sheet.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('latest_achievement_card')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('latest_achievement_card')));
    await tester.pumpAndSettle();

    expect(find.textContaining('全部成就'), findsOneWidget);
    expect(find.text('全部成就 (4/10)'), findsOneWidget);
    expect(find.text('新的开始'), findsOneWidget);
    expect(find.text('迈出第一步'), findsOneWidget);
    expect(find.text('多面手'), findsOneWidget);
    expect(find.text('未解锁'), findsWidgets);

    // Dismiss achievements sheet.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.textContaining('全部成就'), findsNothing);

    // Scroll back up to top bar and tap 成绩单 -> opens report sheet/dialog.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('report_card_button')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report_card_button')));
    await tester.pumpAndSettle();

    expect(find.text('我的成绩单'), findsOneWidget);
    expect(find.text('2026 年度总结'), findsOneWidget);
    expect(find.text('获得成就次数'), findsOneWidget);
    expect(find.text('复制成绩单'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);

    await tester.tap(find.text('复制成绩单'));
    await tester.pumpAndSettle();
    expect(find.text('已复制成绩单'), findsOneWidget);
    expect(copiedText, contains('轻松打卡 2026 年度成绩单'));
    expect(copiedText, contains('完成最多的项目：应付作业'));

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('我的成绩单'), findsNothing);

    await disposeWidgetTree(tester);
  });

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

    // Tap 第42周 label to highlight week 42.
    await tester.tap(find.text('第42周'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('第42周 1次'), findsOneWidget);

    // Swipe right on chart to scroll back to earlier weeks (weeks 35..41).
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

  testWidgets('heatmap displays 1-count and 2-count green levels and yesterday achievement label',
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
      find.text('最新成就'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('完美的一天'), findsOneWidget);
    expect(find.textContaining('昨天获得'), findsOneWidget);

    await disposeWidgetTree(tester);
  });
}
