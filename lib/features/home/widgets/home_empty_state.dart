import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';

/// Empty-state card/prompt for the home habit list.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    super.key,
    required this.hasAnyHabits,
    required this.onCreateHabit,
  });

  final bool hasAnyHabits;
  final VoidCallback onCreateHabit;

  @override
  Widget build(BuildContext context) {
    if (hasAnyHabits) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Center(
          child: Text(
            '今天没有安排的项目',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 12),
            const Text(
              '还没有习惯项目，从这里开始养成好习惯吧',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreateHabit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '创建第一个项目',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
