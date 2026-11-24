import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import 'icon_picker_grid.dart';
import 'icon_registry.dart';

/// Full-screen icon picker page. Pushes onto the navigation stack and returns
/// the tapped icon key via `Navigator.pop(context, key)`.
class IconPickerPage extends StatelessWidget {
  const IconPickerPage({
    super.key,
    this.selectedKey = IconRegistry.defaultKey,
    this.title = '选择图标',
  });

  final String selectedKey;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: title,
        leading: PillIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: '返回',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: IconPickerGrid(
              selectedKey: selectedKey,
              onSelected: (key) => Navigator.of(context).pop(key),
            ),
          ),
        ),
      ),
    );
  }
}
