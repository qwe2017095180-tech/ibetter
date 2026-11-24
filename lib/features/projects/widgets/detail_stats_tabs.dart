import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';

enum DetailStatsTab {
  monthly('每月统计'),
  yearly('每年统计');

  const DetailStatsTab(this.label);
  final String label;
}

/// Tabbed container with seamlessly connected rounded-top tabs ("每月统计" / "每年统计").
class DetailStatsTabs extends StatelessWidget {
  const DetailStatsTabs({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.child,
  });

  final DetailStatsTab activeTab;
  final ValueChanged<DetailStatsTab> onTabSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _TabHeader(
                  key: const ValueKey('stats_tab_monthly'),
                  label: DetailStatsTab.monthly.label,
                  selected: activeTab == DetailStatsTab.monthly,
                  onTap: () => onTabSelected(DetailStatsTab.monthly),
                ),
              ),
              Expanded(
                child: _TabHeader(
                  key: const ValueKey('stats_tab_yearly'),
                  label: DetailStatsTab.yearly.label,
                  selected: activeTab == DetailStatsTab.yearly,
                  onTap: () => onTabSelected(DetailStatsTab.yearly),
                ),
              ),
            ],
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.card)),
              boxShadow: [BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 3))],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(14));
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
