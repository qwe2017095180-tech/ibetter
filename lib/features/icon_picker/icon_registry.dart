import 'package:material_ui/material_ui.dart';

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

  /// STUB data — WP7 replaces with the real asset catalog.
  static const List<IconCategory> categories = [
    IconCategory(key: 'achievement', title: '追求成就', iconKeys: ['achievement/star', 'achievement/trophy']),
    IconCategory(key: 'study', title: '爱学习', iconKeys: ['study/book']),
  ];

  static const Map<String, IconData> _stubIcons = {
    'achievement/star': Icons.star_rounded,
    'achievement/trophy': Icons.emoji_events_rounded,
    'study/book': Icons.menu_book_rounded,
  };

  /// Renders the icon for [key] at [size]. Must never throw.
  static Widget build(String key, {double size = 48}) {
    final data = _stubIcons[key] ?? _stubIcons[fallbackKey]!;
    return Icon(data, size: size, color: const Color(0xFF3B87D6));
  }
}

/// Convenience widget.
class HabitIcon extends StatelessWidget {
  const HabitIcon(this.iconKey, {super.key, this.size = 48});

  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size, child: IconRegistry.build(iconKey, size: size));
}
