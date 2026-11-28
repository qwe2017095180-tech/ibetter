import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/services/achievement_service.dart';
import 'achievement_badge.dart';
import 'achievement_utils.dart';

/// Opens a searchable, stage-filtered encyclopedia sheet for all 274
/// single-project milestones from Day 1 to Day 365.
Future<void> showSingleProjectCatalogSheet(
  BuildContext context, {
  required List<AchievementItem> items,
  required DateTime today,
  required ValueChanged<AchievementItem> onTapItem,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SingleProjectCatalogSheet(
      items: items,
      today: today,
      onTapItem: onTapItem,
    ),
  );
}

class _SingleProjectCatalogSheet extends StatefulWidget {
  const _SingleProjectCatalogSheet({
    required this.items,
    required this.today,
    required this.onTapItem,
  });

  final List<AchievementItem> items;
  final DateTime today;
  final ValueChanged<AchievementItem> onTapItem;

  @override
  State<_SingleProjectCatalogSheet> createState() =>
      _SingleProjectCatalogSheetState();
}

class _SingleProjectCatalogSheetState
    extends State<_SingleProjectCatalogSheet> {
  final _searchController = TextEditingController();
  String _stageId = 'all';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesStage(AchievementItem item, SingleMilestoneStage stage) {
    if (stage.unlockedOnly) return item.unlocked;
    final days = item.milestoneDays ?? 0;
    if (stage.minDays != null && days < stage.minDays!) return false;
    if (stage.maxDays != null && days > stage.maxDays!) return false;
    return true;
  }

  bool _matchesQuery(AchievementItem item, String queryLower) {
    if (queryLower.isEmpty) return true;
    final daysStr = '${item.milestoneDays ?? ''}';
    final title = item.displayTitle.toLowerCase();
    final sub = item.displaySubtitle.toLowerCase();
    final lore = (item.displayLore ?? '').toLowerCase();
    return daysStr.contains(queryLower) ||
        title.contains(queryLower) ||
        sub.contains(queryLower) ||
        lore.contains(queryLower);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final unlockedCount = items.where((a) => a.unlocked).length;
    final activeStage = kSingleMilestoneStages.firstWhere(
      (s) => s.id == _stageId,
      orElse: () => kSingleMilestoneStages.first,
    );
    final queryLower = _query.trim().toLowerCase();

    final filtered = [
      for (final item in items)
        if (_matchesStage(item, activeStage) && _matchesQuery(item, queryLower))
          item,
    ];

    final stageCounts = <String, int>{
      for (final stage in kSingleMilestoneStages)
        stage.id: items
            .where((a) => _matchesStage(a, stage) && _matchesQuery(a, queryLower))
            .length,
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                      const Expanded(
                        child: Text(
                          '单项目成就图鉴',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '已解锁 $unlockedCount / ${items.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  child: TextField(
                    key: const ValueKey('single_catalog_search_input'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: '搜索天数、典故或热梗（如 325、42、233）',
                      hintStyle: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (var i = 0; i < kSingleMilestoneStages.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Builder(
                            builder: (_) {
                              final stage = kSingleMilestoneStages[i];
                              final selected = stage.id == _stageId;
                              final count = stageCounts[stage.id] ?? 0;
                              return InkWell(
                                key: ValueKey('catalog_stage_${stage.id}'),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                onTap: () => setState(() => _stageId = stage.id),
                                child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary.withValues(alpha: 0.14)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Text(
                                    '${stage.label} ($count)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            '没有找到匹配的单项目成就',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (_, index) {
                            final item = filtered[index];
                            return _CatalogRow(
                              key: ValueKey('catalog_row_${item.id}'),
                              item: item,
                              today: widget.today,
                              onTap: item.unlocked
                                  ? () => widget.onTapItem(item)
                                  : null,
                            );
                          },
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

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    super.key,
    required this.item,
    required this.today,
    this.onTap,
  });

  final AchievementItem item;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        item.unlocked ? formatAchievementDate(item.latestDate, today) : '';
    final lore = item.displayLore ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
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
                      color: item.unlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.displaySubtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (lore.isNotEmpty) ...[
                    const SizedBox(height: 3),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                      color: item.unlocked
                          ? AppColors.primary
                          : AppColors.textSecondary,
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
