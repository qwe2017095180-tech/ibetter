import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/models/habit.dart';
import '../reminders/notification_service.dart';

/// Filter options for the "我的项目" list.
enum ProjectFilter {
  all('全部'),
  active('进行中'),
  paused('已暂停');

  const ProjectFilter(this.label);
  final String label;
}

/// Sort options for the "我的项目" list.
enum ProjectSort {
  defaultOrder('默认排序'),
  totalDaysDesc('按累计天数'),
  streakDesc('按连续天数');

  const ProjectSort(this.label);
  final String label;
}

class ProjectFilterNotifier extends Notifier<ProjectFilter> {
  @override
  ProjectFilter build() => ProjectFilter.all;

  void select(ProjectFilter filter) => state = filter;
}

final projectFilterProvider =
    NotifierProvider<ProjectFilterNotifier, ProjectFilter>(ProjectFilterNotifier.new);

class ProjectSortNotifier extends Notifier<ProjectSort> {
  @override
  ProjectSort build() => ProjectSort.defaultOrder;

  void select(ProjectSort sort) => state = sort;
}

final projectSortProvider =
    NotifierProvider<ProjectSortNotifier, ProjectSort>(ProjectSortNotifier.new);

/// Filtered and sorted habits for the "我的项目" screen.
final filteredProjectsProvider = Provider<AsyncValue<List<Habit>>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final filter = ref.watch(projectFilterProvider);
  final sort = ref.watch(projectSortProvider);

  return habitsAsync.whenData((habits) {
    final filtered = switch (filter) {
      ProjectFilter.all => habits,
      ProjectFilter.active => habits.where((h) => h.isActive).toList(),
      ProjectFilter.paused => habits.where((h) => !h.isActive).toList(),
    };
    if (sort == ProjectSort.defaultOrder) return filtered;

    final statsById = {
      for (final h in filtered) h.id: ref.watch(habitStatsProvider(h.id)),
    };
    final sorted = List<Habit>.of(filtered);
    sorted.sort((a, b) {
      final sa = statsById[a.id]!;
      final sb = statsById[b.id]!;
      final cmp = switch (sort) {
        ProjectSort.defaultOrder => 0,
        ProjectSort.totalDaysDesc => sb.totalDays.compareTo(sa.totalDays),
        ProjectSort.streakDesc => sb.currentStreak.compareTo(sa.currentStreak),
      };
      if (cmp != 0) return cmp;
      final orderCmp = a.sortOrder.compareTo(b.sortOrder);
      return orderCmp != 0 ? orderCmp : a.id.compareTo(b.id);
    });
    return sorted;
  });
});

/// Side-effect actions for the projects screen (pause/resume, delete).
class ProjectsActions {
  const ProjectsActions(this._ref);

  final Ref _ref;

  Future<void> setActive(Habit habit, bool active) async {
    final habitRepo = _ref.read(habitRepositoryProvider);
    final reminderRepo = _ref.read(reminderRepositoryProvider);
    final notifications = _ref.read(notificationServiceProvider);
    await habitRepo.setActive(habit.id, active);
    if (active) {
      final reminders = await reminderRepo.getByHabit(habit.id);
      await notifications.syncHabit(habit.copyWith(isActive: true), reminders);
    } else {
      await notifications.cancelHabit(habit.id);
    }
  }

  Future<void> deleteHabit(int habitId) async {
    final notifications = _ref.read(notificationServiceProvider);
    final habitRepo = _ref.read(habitRepositoryProvider);
    await notifications.cancelHabit(habitId);
    await habitRepo.delete(habitId);
  }
}

final projectsActionsProvider = Provider<ProjectsActions>(ProjectsActions.new);
