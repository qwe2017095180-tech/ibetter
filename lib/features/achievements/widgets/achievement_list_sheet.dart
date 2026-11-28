import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/services/achievement_service.dart';
import 'achievement_badge.dart';
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

class _AchievementListSheet extends StatefulWidget {
  const _AchievementListSheet({
    required this.stats,
    required this.today,
  });

  final OverallStats stats;
  final DateTime today;

  @override
  State<_AchievementListSheet> createState() => _AchievementListSheetState();
}

enum _ListSheetFilter { all, unlocked, locked }

class _AchievementListSheetState extends State<_AchievementListSheet> {
  _ListSheetFilter _filter = _ListSheetFilter.all;

  @override
  Widget build(BuildContext context) {
    final items = widget.stats.achievements;
    final unlockedCount = items.where((a) => a.unlocked).length;
    final lockedCount = items.length - unlockedCount;
    final filtered = switch (_filter) {
      _ListSheetFilter.all => items,
      _ListSheetFilter.unlocked => [for (final a in items) if (a.unlocked) a],
      _ListSheetFilter.locked => [for (final a in items) if (!a.unlocked) a],
    };

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (f, label) in [
                          (_ListSheetFilter.all, '全部 (${items.length})'),
                          (_ListSheetFilter.unlocked, '已解锁 ($unlockedCount)'),
                          (_ListSheetFilter.locked, '未解锁 ($lockedCount)'),
                        ]) ...[
                          if (f != _ListSheetFilter.all) const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            onTap: () => setState(() => _filter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _filter == f
                                    ? AppColors.primary.withValues(alpha: 0.14)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: _filter == f
                                      ? AppColors.primary
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _filter == f
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: _filter == f
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                    itemBuilder: (_, index) => _AchievementRow(
                      item: filtered[index],
                      today: widget.today,
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
    final lore = item.displayLore;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          AchievementBadge(item: item, size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.displayTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: item.unlocked ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.displaySubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (lore != null && lore.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    lore,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
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
    );
  }
}
