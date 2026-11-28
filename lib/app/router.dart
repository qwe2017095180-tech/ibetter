import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/prefs/app_prefs.dart';
import '../core/providers.dart';
import '../core/widgets/common.dart';
import '../domain/date_key.dart' as dk;
import '../domain/services/schedule_service.dart';
import '../features/achievements/achievements_page.dart';
import '../features/history/history_page.dart';
import '../features/home/home_page.dart';
import '../features/me/edit_profile_sheet.dart';
import '../features/me/me_page.dart';
import '../features/more/more_page.dart';
import '../features/project_editor/project_editor_page.dart';
import '../features/projects/project_detail_page.dart';
import '../features/projects/projects_page.dart';
import '../features/qingsong/qingsong_board_page.dart';
import '../features/settings/passcode_page.dart';
import '../features/settings/project_sort_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/widget_guide_page.dart';
import '../features/updates/update_dialog.dart';
import '../features/updates/update_models.dart';
import '../features/updates/update_providers.dart';
import 'theme/app_colors.dart';

/// Route paths. Keep in sync with docs/ARCHITECTURE.md.
abstract final class Routes {
  static const today = '/today';
  static const projects = '/projects';
  static const achievements = '/achievements';
  static const me = '/me';
  static const more = '/more';

  /// History timeline page.
  static const history = '/history';

  /// Settings & sub-pages.
  static const settings = '/settings';
  static const projectSort = '/settings/sort';
  static const widgetGuide = '/settings/widget-guide';
  static const passcode = '/settings/passcode';

  /// Qingsong full schedule board page.
  static const qingsongBoard = '/qingsong-board';

  /// Project detail / stats page.
  static String projectDetail(int id) => '/projects/$id';

  /// Create: `/editor`; edit: `/editor/<habitId>`.
  static const editor = '/editor';
  static String editHabit(int id) => '/editor/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.today,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.today, builder: (_, _) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.projects, builder: (_, _) => const ProjectsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.achievements, builder: (_, _) => const AchievementsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.me, builder: (_, _) => const MePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.more, builder: (_, _) => const MorePage()),
          ]),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: Routes.history,
        builder: (_, _) => const HistoryPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: Routes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: Routes.projectSort,
        builder: (_, _) => const ProjectSortPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: Routes.widgetGuide,
        builder: (_, _) => const WidgetGuidePage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: Routes.passcode,
        builder: (_, _) => const PasscodePage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: Routes.qingsongBoard,
        builder: (_, _) => const QingsongBoardPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/projects/:id',
        builder: (_, state) => ProjectDetailPage(
          habitId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: Routes.editor,
        builder: (_, _) => const ProjectEditorPage(),
        routes: [
          GoRoute(
            parentNavigatorKey: rootKey,
            path: ':id',
            builder: (_, state) =>
                ProjectEditorPage(habitId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
        ],
      ),
    ],
  );
});

/// Today's scheduled & remaining habit counts for the 今日 tab badge.
final todayBadgeStatusProvider = Provider<({int scheduled, int pending})>((ref) {
  final habits = ref.watch(habitsProvider).asData?.value ?? const [];
  final checkIns = ref.watch(allCheckInsProvider).asData?.value ?? const [];
  final today = ref.watch(todayProvider);
  const schedule = ScheduleService();
  final todayKey = dk.dateKey(today);
  final counts = {for (final c in checkIns.where((c) => c.date == todayKey)) c.habitId: c.count};
  final scheduled = habits.where((h) => h.isActive && schedule.isScheduledOn(h, today)).toList();
  final pending = scheduled.where((h) => !schedule.isDone(h, counts[h.id] ?? 0)).length;
  return (scheduled: scheduled.length, pending: pending);
});

/// Number of today's scheduled, active, unfinished habits (kept for backwards compatibility).
final pendingTodayCountProvider = Provider<int>((ref) => ref.watch(todayBadgeStatusProvider).pending);

class _Shell extends ConsumerStatefulWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  bool _startupChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSilentUpdateCheck());
  }

  Future<void> _runSilentUpdateCheck() async {
    if (_startupChecked || !mounted) return;
    _startupChecked = true;
    final service = ref.read(updateServiceProvider);
    if (!service.supportsInAppInstall) return;

    try {
      final config = await ref.read(updateConfigProvider.future);
      if (!config.autoCheck || !config.hasValidRepo) return;
      final result = await service.checkForUpdate(config);
      if (!mounted) return;
      if (result.status == UpdateCheckStatus.updateAvailable &&
          result.release != null &&
          result.release!.tagName != config.ignoredTag) {
        await showUpdateDialog(
          context,
          release: result.release!,
          currentVersion: result.currentVersion,
        );
      }
    } catch (_) {
      // Startup checks must stay silent on transient network failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeStatus = ref.watch(todayBadgeStatusProvider);
    final allDoneToday = badgeStatus.scheduled > 0 && badgeStatus.pending == 0;
    final today = ref.watch(todayProvider);
    final prefs = ref.watch(appPrefsProvider).asData?.value ?? const AppPrefs();
    final shell = widget.shell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _TabItem(
                  selected: shell.currentIndex == 0,
                  onTap: () => _go(0),
                  badge: badgeStatus.pending,
                  showDoneCheck: allDoneToday,
                  child: _CalendarTabIcon(day: today.day, selected: shell.currentIndex == 0),
                ),
                _TabItem(
                  selected: shell.currentIndex == 1,
                  onTap: () => _go(1),
                  child: Icon(Icons.assignment_outlined,
                      size: 32, color: shell.currentIndex == 1 ? AppColors.primary : AppColors.textSecondary),
                ),
                _TabItem(
                  selected: shell.currentIndex == 2,
                  onTap: () => _go(2),
                  badge: ref.watch(unreadAchievementsCountProvider),
                  child: Icon(
                    shell.currentIndex == 2 ? Icons.emoji_events : Icons.emoji_events_outlined,
                    size: 32,
                    color: shell.currentIndex == 2 ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                _TabItem(
                  key: const ValueKey('bottom_tab_me'),
                  selected: shell.currentIndex == 3,
                  onTap: () => _go(3),
                  child: ProfileAvatar(
                    prefs: prefs,
                    size: 32,
                    borderWidth: shell.currentIndex == 3 ? 2 : 1,
                    borderColor: shell.currentIndex == 3 ? AppColors.primary : Colors.white,
                  ),
                ),
                _TabItem(
                  selected: shell.currentIndex == 4,
                  onTap: () => _go(4),
                  child: Icon(Icons.more_horiz,
                      size: 32, color: shell.currentIndex == 4 ? AppColors.primary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(int i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex);
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.badge = 0,
    this.showDoneCheck = false,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final int badge;
  final bool showDoneCheck;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = child;
    if (showDoneCheck) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -7,
            top: -7,
            child: Container(
              key: const ValueKey('today_all_done_badge'),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.done,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.check, size: 13, color: Colors.white),
            ),
          ),
        ],
      );
    } else if (badge > 0) {
      iconWidget = CountBadge(count: badge, child: child);
    }
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        child: Center(child: iconWidget),
      ),
    );
  }
}

class _CalendarTabIcon extends StatelessWidget {
  const _CalendarTabIcon({required this.day, required this.selected});

  final int day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = selected ? AppColors.primary : AppColors.textSecondary;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c, width: 2),
      ),
      child: Column(
        children: [
          Container(height: 7, color: c),
          Expanded(
            child: Center(
              child: Text('$day',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
