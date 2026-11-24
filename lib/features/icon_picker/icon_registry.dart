import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import 'icon_catalog.g.dart';

/// ===== Contract (WP7 owns the implementation, keep this public API stable) =====
///
/// Icon keys look like `<categoryKey>/<name>`, e.g. `achievement/trophy`.
/// Assets live under `assets/icons/<categoryKey>/<name>.png`.
/// Unknown keys must render [IconRegistry.fallbackKey] instead of crashing.

class IconCategory {
  const IconCategory({required this.key, required this.title, this.subtitle, required this.iconKeys});

  final String key;

  /// e.g. 追求成就
  final String title;

  /// e.g. 早睡早起,每日果蔬,喝牛奶,敷面膜...
  final String? subtitle;
  final List<String> iconKeys;
}

abstract final class IconRegistry {
  static const fallbackKey = 'achievement/star';

  /// Default icon for new habits.
  static const defaultKey = 'study/book';

  /// Catalog generated from `assets/icons/<category>/*.png`.
  static const List<IconCategory> categories = iconCatalogCategories;

  /// Resolves [key] to a known catalog key, falling back to [fallbackKey].
  static String resolveKey(String key) => iconCatalogKeys.contains(key) ? key : fallbackKey;

  /// Renders the icon for [key] at [size]. Must never throw.
  static Widget build(String key, {double size = 48}) {
    final resolved = resolveKey(key);
    return _buildAsset(resolved, size: size, allowFallbackAsset: resolved != fallbackKey);
  }

  static Widget _buildAsset(String key, {required double size, required bool allowFallbackAsset}) {
    return Image.asset(
      'assets/icons/$key.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) {
        if (allowFallbackAsset) {
          return _buildAsset(fallbackKey, size: size, allowFallbackAsset: false);
        }
        return Icon(Icons.star_rounded, size: size, color: AppColors.primary);
      },
    );
  }
}

/// Convenience widget.
class HabitIcon extends StatelessWidget {
  const HabitIcon(this.iconKey, {super.key, this.size = 48});

  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: IconRegistry.build(iconKey, size: size));
}
