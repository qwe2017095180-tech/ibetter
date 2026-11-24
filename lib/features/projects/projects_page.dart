import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/habit.dart';
import 'projects_providers.dart';
import 'widgets/project_card.dart';
import 'widgets/project_sheets.dart';
import 'widgets/projects_empty_state.dart';

/// "我的项目" page showing all habits with stats, pause/resume toggle, and CRUD actions.
class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allHabitsAsync = ref.watch(habitsProvider);
    final filteredAsync = ref.watch(filteredProjectsProvider);
    final filter = ref.watch(projectFilterProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: '我的项目',
        leading: PillIconButton(
          icon: Icons.access_time,
          tooltip: '筛选与排序',
          onPressed: () => showProjectFilterSheet(context),
        ),
        trailing: PillIconButton(
          icon: Icons.add,
          tooltip: '创建项目',
          onPressed: () => context.push(Routes.editor),
        ),
      ),
      body: allHabitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败：$error')),
        data: (allHabits) {
          if (allHabits.isEmpty) {
            return ProjectsEmptyState(onCreate: () => context.push(Routes.editor));
          }
          final habits = filteredAsync.asData?.value ?? allHabits;
          if (habits.isEmpty) {
            return ProjectsFilteredEmptyState(
              filter: filter,
              onShowAll: () => ref.read(projectFilterProvider.notifier).select(ProjectFilter.all),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 6, bottom: 20),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return ProjectCard(
                key: ValueKey('project-card-${habit.id}'),
                habit: habit,
                onTap: () => context.push(Routes.projectDetail(habit.id)),
                onLongPress: () => _handleCardLongPress(context, ref, habit),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleCardLongPress(BuildContext context, WidgetRef ref, Habit habit) async {
    final actions = ref.read(projectsActionsProvider);
    final action = await showProjectActionSheet(context, habit);
    if (!context.mounted || action == null) return;
    switch (action) {
      case ProjectCardAction.edit:
        await context.push(Routes.editHabit(habit.id));
      case ProjectCardAction.delete:
        final confirmed = await showDeleteHabitDialog(context);
        if (confirmed) {
          await actions.deleteHabit(habit.id);
        }
    }
  }
}
