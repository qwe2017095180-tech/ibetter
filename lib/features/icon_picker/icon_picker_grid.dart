import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import 'icon_registry.dart';

/// ===== Contract (WP7 owns the implementation, keep constructor stable) =====
/// Grouped icon grid (5 columns) used inline at the bottom of the project editor.
/// Non-scrollable by itself (shrinkWrap) so it can live inside a parent ListView.
class IconPickerGrid extends StatelessWidget {
  const IconPickerGrid({super.key, required this.selectedKey, required this.onSelected});

  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in IconRegistry.categories) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: _CategoryHeader(category: c),
          ),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final k in c.iconKeys)
                _IconTile(
                  iconKey: k,
                  selected: k == selectedKey,
                  onTap: () => onSelected(k),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final IconCategory category;

  @override
  Widget build(BuildContext context) {
    final subtitle = category.subtitle;
    return Text.rich(
      TextSpan(
        text: category.title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        children: [
          if (subtitle != null && subtitle.isNotEmpty)
            TextSpan(
              text: '（$subtitle）',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _IconTile extends StatefulWidget {
  const _IconTile({required this.iconKey, required this.selected, required this.onTap});

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_IconTile> createState() => _IconTileState();
}

class _IconTileState extends State<_IconTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.iconKey,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: widget.selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: radius,
                border: Border.all(
                  color: widget.selected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(child: HabitIcon(widget.iconKey, size: 42)),
            ),
          ),
        ),
      ),
    );
  }
}
