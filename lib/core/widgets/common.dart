import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

/// White rounded pill button used in the top bar (clock / + / back).
class PillIconButton extends StatelessWidget {
  const PillIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onPressed,
        child: Container(
          width: 62,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: const [BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 2), blurRadius: 2)],
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Green 3D "完成" button.
class DoneButton extends StatelessWidget {
  const DoneButton({super.key, required this.onPressed, this.label = '完成'});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.done,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: const [BoxShadow(color: AppColors.doneShadow, offset: Offset(0, 4))],
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

/// Top bar row: [leading]  title  [trailing], matching the screenshots.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.leading, this.trailing});

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(width: 80, child: Align(alignment: Alignment.centerLeft, child: leading)),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 80, child: Align(alignment: Alignment.centerRight, child: trailing)),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded card with a soft bottom edge — used for form sections and project cards.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = EdgeInsets.zero, this.margin});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Rounded card with a darker solid bottom edge (3D look) — purple habit cards.
class RaisedCard extends StatelessWidget {
  const RaisedCard({
    super.key,
    required this.child,
    this.color = AppColors.habitCard,
    this.edgeColor = AppColors.habitCardShadow,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
  });

  final Widget child;
  final Color color;
  final Color edgeColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [BoxShadow(color: edgeColor, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Small red counter badge.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.badge,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
