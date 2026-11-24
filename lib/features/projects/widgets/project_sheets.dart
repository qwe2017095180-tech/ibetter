import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/models/habit.dart';
import '../projects_providers.dart';

enum ProjectCardAction { edit, delete }

/// Opens the filter/sort bottom sheet for "我的项目".
Future<void> showProjectFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (_) => const _ProjectFilterSheet(),
  );
}

class _ProjectFilterSheet extends ConsumerWidget {
  const _ProjectFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(projectFilterProvider);
    final currentSort = ref.watch(projectSortProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '筛选项目',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            for (final option in ProjectFilter.values)
              ListTile(
                title: Text(option.label),
                trailing: currentFilter == option
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(projectFilterProvider.notifier).select(option);
                  Navigator.of(context).pop();
                },
              ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '排序方式',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sort in ProjectSort.values)
                        ChoiceChip(
                          label: Text(sort.label),
                          selected: currentSort == sort,
                          onSelected: (_) => ref.read(projectSortProvider.notifier).select(sort),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the long-press action sheet ('编辑' / '删除') for a project card.
Future<ProjectCardAction?> showProjectActionSheet(BuildContext context, Habit habit) {
  return showModalBottomSheet<ProjectCardAction>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
              title: const Text('编辑'),
              onTap: () => Navigator.of(sheetContext).pop(ProjectCardAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.badge),
              title: const Text('删除', style: TextStyle(color: AppColors.badge)),
              onTap: () => Navigator.of(sheetContext).pop(ProjectCardAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// Shows confirmation dialog before deleting a habit and its check-ins.
Future<bool> showDeleteHabitDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除项目'),
      content: const Text('删除后打卡记录将一并清除'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.badge),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
