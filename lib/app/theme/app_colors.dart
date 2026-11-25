import 'package:material_ui/material_ui.dart';

/// Design tokens sampled from the reference screenshots.
abstract final class AppColors {
  static const background = Color(0xFFF3EEEE);
  static const surface = Colors.white;
  static const primary = Color(0xFF3B87D6); // titles, selected, links
  static const habitCard = Color(0xFF8E96FF); // purple habit card
  static const habitCardShadow = Color(0xFF6F78F0); // 3D bottom edge
  static const done = Color(0xFF2DB84B); // 完成 button
  static const doneShadow = Color(0xFF1E9A3A);
  static const calendarCell = Color(0xFFF5F5F5);
  static const calendarCellBorder = Color(0xFFEDEDED);
  static const textPrimary = Color(0xFF222222);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textHint = Color(0xFFB5B5B5);
  static const divider = Color(0xFFEAEAEA);
  static const badge = Color(0xFFF2554B);
  static const cardShadow = Color(0xFFDCD6D6);
  static const inputFill = Color(0xFFF4F4F4);
}

abstract final class AppRadius {
  static const card = 16.0;
  static const pill = 999.0;
  static const cell = 4.0;
}
