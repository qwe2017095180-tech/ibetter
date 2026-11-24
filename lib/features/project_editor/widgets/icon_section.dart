import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../icon_picker/icon_picker_grid.dart';
import '../../icon_picker/icon_registry.dart';

/// Card 4: Icon header with selected preview and inline 5-column [IconPickerGrid].
class IconSectionCard extends StatelessWidget {
  const IconSectionCard({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '选择图标',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),
                HabitIcon(selectedKey, size: 32),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IconPickerGrid(
              selectedKey: selectedKey,
              onSelected: onSelected,
            ),
          ),
        ],
      ),
    );
  }
}
