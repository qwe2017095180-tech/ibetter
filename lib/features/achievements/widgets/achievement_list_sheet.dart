import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/services/achievement_service.dart';
import '../../icon_picker/icon_registry.dart';
import 'achievement_utils.dart';

/// Opens a draggable bottom sheet listing every unlockable achievement.
Future<void> showAchievementsSheet(
  BuildContext context, {
  required OverallStats stats,
  required DateTime today,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AchievementListSheet(stats: stats, today: today),
  );
}

class _AchievementListSheet extends StatelessWidget {
  const _AchievementListSheet({
    required this.stats,
    required this.today,
  });

  final OverallStats stats;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final items = stats.achievements;
    final unlockedCount = items.where((a) => a.unlocked).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '全部成就 ($unlockedCount/${items.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                    itemBuilder: (_, index) => _AchievementRow(
                      item: items[index],
                      today: today,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.item,
    required this.today,
  });

  final AchievementItem item;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final dateLabel = item.unlocked ? formatAchievementDate(item.latestDate, today) : '';

    return Opacity(
      opacity: item.unlocked ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.unlocked ? const Color(0xFFFFF7E0) : const Color(0xFFF3F3F3),
              ),
              child: HabitIcon(item.iconKey, size: 42),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.unlocked
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    item.unlocked ? '获得 ${item.count} 次' : '未解锁',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.unlocked ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
