import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';

/// Standard form row inside a [SectionCard] with a grey leading icon and
/// either a blue value + dropdown chevron or a custom trailing widget.
class EditorFormRow extends StatelessWidget {
  const EditorFormRow({
    super.key,
    required this.icon,
    required this.label,
    this.valueText,
    this.showDropdownArrow = true,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? valueText;
  final bool showDropdownArrow;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (valueText != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText!,
                  style: const TextStyle(fontSize: 15, color: AppColors.primary),
                ),
                if (showDropdownArrow) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 22),
                ],
              ],
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
