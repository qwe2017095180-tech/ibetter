import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/widgets/common.dart';
import '../domain/services/schedule_service.dart';
import '../features/home/home_page.dart';
import '../features/placeholders/placeholder_pages.dart';
import '../features/project_editor/project_editor_page.dart';
import '../features/projects/projects_page.dart';
import 'theme/app_colors.dart';

/// Route paths. Keep in sync with docs/ARCHITECTURE.md.
abstract final class Routes {
  static const today = '/today';
  static const projects = '/projects';
  static const achievements = '/achievements';
  static const me = '/me';
  static const more = '/more';

  /// Create: `/editor`; edit: `/editor/<habitId>`.
  static const editor = '/editor';
  static String editHabit(int id) => '/editor/$id';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
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
        parentNavigatorKey: _rootKey,
        path: Routes.editor,
        builder: (_, _) => const ProjectEditorPage(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: ':id',
            builder: (_, state) =>
                ProjectEditorPage(habitId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
        ],
      ),
    ],
  );
});

/// Number of today's scheduled, active, unfinished habits (badge on the 今日 tab).
final pendingTodayCountProvider = Provider<int>((ref) {
  final habits = ref.watch(habitsProvider).asData?.value ?? const [];
  final checkIns = ref.watch(allCheckInsProvider).asData?.value ?? const [];
  final today = ref.watch(todayProvider);
  const schedule = ScheduleService();
  final todayKey =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final counts = {for (final c in checkIns.where((c) => c.date == todayKey)) c.habitId: c.count};
  return habits
      .where((h) => h.isActive && schedule.isScheduledOn(h, today) && !schedule.isDone(h, counts[h.id] ?? 0))
      .length;
});

class _Shell extends ConsumerWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingTodayCountProvider);
    final today = ref.watch(todayProvider);
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
                  badge: pending,
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
                  child: Icon(Icons.emoji_events_outlined,
                      size: 32, color: shell.currentIndex == 2 ? AppColors.primary : AppColors.textSecondary),
                ),
                _TabItem(
                  selected: shell.currentIndex == 3,
                  onTap: () => _go(3),
                  child: Icon(Icons.account_circle,
                      size: 32, color: shell.currentIndex == 3 ? AppColors.primary : AppColors.textHint),
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

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.selected, required this.onTap, required this.child, this.badge = 0});

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        child: Center(child: CountBadge(count: badge, child: child)),
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
