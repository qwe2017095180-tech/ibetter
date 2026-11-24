import 'package:material_ui/material_ui.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(c.title, style: const TextStyle(fontSize: 15, color: Color(0xFF666666))),
          ),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final k in c.iconKeys)
                InkWell(
                  onTap: () => onSelected(k),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: k == selectedKey ? Border.all(color: const Color(0xFF3B87D6), width: 2) : null,
                    ),
                    child: Center(child: HabitIcon(k, size: 44)),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
