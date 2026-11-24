import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../projects_providers.dart';

/// Empty state shown when no habits exist yet.
class ProjectsEmptyState extends StatelessWidget {
  const ProjectsEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: AppColors.habitCard.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 52,
                color: AppColors.habitCard,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '还没有项目',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text(
                '创建项目',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state shown when habits exist but none match the active filter.
class ProjectsFilteredEmptyState extends StatelessWidget {
  const ProjectsFilteredEmptyState({
    super.key,
    required this.filter,
    required this.onShowAll,
  });

  final ProjectFilter filter;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      ProjectFilter.active => '没有进行中的项目',
      ProjectFilter.paused => '没有已暂停的项目',
      ProjectFilter.all => '还没有项目',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 56,
              color: AppColors.textHint.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onShowAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text('查看全部'),
            ),
          ],
        ),
      ),
    );
  }
}
