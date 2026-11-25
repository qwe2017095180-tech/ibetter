import 'package:material_ui/material_ui.dart';

/// Colors shared by the 轻松 apps.
abstract final class AppColors {
  static const background = Color(0xFFF3F5FC);
  static const surface = Colors.white;
  static const primary = Color(0xFF3458CB); // titles, selected, links
  static const habitCard = Color(0xFF5B5ED0); // purple habit card
  static const habitCardShadow = Color(0xFF4A4DB5); // 3D bottom edge
  static const done = Color(0xFF2DB84B); // 完成 button
  static const doneShadow = Color(0xFF1E9A3A);
  static const calendarCell = Color(0xFFF5F5F5);
  static const calendarCellBorder = Color(0xFFEDEDED);
  static const textPrimary = Color(0xFF212744);
  static const textSecondary = Color(0xFF626984);
  static const textHint = Color(0xFFB5B5B5);
  static const divider = Color(0xFFE3E7F4);
  static const badge = Color(0xFFF2554B);
  static const cardShadow = Color(0xFFDDE2F1);
  static const inputFill = Color(0xFFF4F4F4);
}

abstract final class AppRadius {
  static const card = 16.0;
  static const pill = 999.0;
  static const cell = 4.0;
}
