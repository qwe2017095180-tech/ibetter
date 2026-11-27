import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/prefs/app_prefs.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/models/habit.dart';
import '../../icon_picker/icon_registry.dart';

/// Habit card on Home page supporting [CardStyle] (colorful / white)
/// and [CardLayout] (standard / compact / ultraCompact).
class HabitCheckInCard extends StatelessWidget {
  const HabitCheckInCard({
    super.key,
    required this.habit,
    required this.count,
    required this.isDone,
    required this.canCheckIn,
    required this.onTapCard,
    required this.onTapCheck,
    this.onLongPressCard,
    this.onLongPressCheck,
    this.cardStyle = CardStyle.colorful,
    this.cardLayout = CardLayout.standard,
  });

  final Habit habit;
  final int count;
  final bool isDone;
  final bool canCheckIn;
  final VoidCallback onTapCard;
  final VoidCallback onTapCheck;
  final VoidCallback? onLongPressCard;
  final VoidCallback? onLongPressCheck;
  final CardStyle cardStyle;
  final CardLayout cardLayout;

  @override
  Widget build(BuildContext context) {
    switch (cardLayout) {
      case CardLayout.standard:
        return _buildStandard();
      case CardLayout.compact:
        return _buildCompact();
      case CardLayout.ultraCompact:
        return _buildUltraCompact();
    }
  }

  Widget _buildStandard() {
    final hasMotto = habit.motto.trim().isNotEmpty;
    final isWhite = cardStyle == CardStyle.white;
    final titleColor = isWhite ? AppColors.textPrimary : Colors.white;
    final mottoColor = isWhite
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.7);

    final inner = Row(
      children: [
        HabitIcon(habit.iconKey, size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasMotto) ...[
                const SizedBox(height: 2),
                Text(
                  habit.motto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: mottoColor, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        if (habit.dailyTarget > 1) ...[
          const SizedBox(width: 8),
          Opacity(
            opacity: canCheckIn ? 1.0 : 0.5,
            child: Text(
              '$count/${habit.dailyTarget}',
              style: TextStyle(
                color: isWhite
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        _HabitCheckBox(
          habitId: habit.id,
          checked: isDone,
          enabled: canCheckIn,
          isWhiteCard: isWhite,
          onTap: onTapCheck,
          onLongPress: onLongPressCheck,
        ),
      ],
    );

    if (isWhite) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: _WhiteHabitCard(
          key: ValueKey('habit_card_${habit.id}'),
          onTap: onTapCard,
          onLongPress: onLongPressCard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: inner,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: RaisedCard(
        key: ValueKey('habit_card_${habit.id}'),
        onTap: onTapCard,
        onLongPress: onLongPressCard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: inner,
      ),
    );
  }

  Widget _buildCompact() {
    final isWhite = cardStyle == CardStyle.white;
    final titleColor = isWhite ? AppColors.textPrimary : Colors.white;
    final inner = Row(
      children: [
        HabitIcon(habit.iconKey, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (habit.dailyTarget > 1)
                Text(
                  '$count/${habit.dailyTarget}',
                  style: TextStyle(
                    color: isWhite
                        ? AppColors.textSecondary
                        : Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        _HabitCheckBox(
          habitId: habit.id,
          checked: isDone,
          enabled: canCheckIn,
          isWhiteCard: isWhite,
          boxSize: 28,
          onTap: onTapCheck,
          onLongPress: onLongPressCheck,
        ),
      ],
    );

    return isWhite
        ? _WhiteHabitCard(
            key: ValueKey('habit_card_${habit.id}'),
            onTap: onTapCard,
            onLongPress: onLongPressCard,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: inner,
          )
        : RaisedCard(
            key: ValueKey('habit_card_${habit.id}'),
            onTap: onTapCard,
            onLongPress: onLongPressCard,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: inner,
          );
  }

  Widget _buildUltraCompact() {
    final isWhite = cardStyle == CardStyle.white;
    final titleColor = isWhite ? AppColors.textPrimary : Colors.white;
    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: _HabitCheckBox(
            habitId: habit.id,
            checked: isDone,
            enabled: canCheckIn,
            isWhiteCard: isWhite,
            boxSize: 24,
            padding: 2,
            onTap: onTapCheck,
            onLongPress: onLongPressCheck,
          ),
        ),
        HabitIcon(habit.iconKey, size: 36),
        const SizedBox(height: 6),
        Text(
          habit.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (habit.dailyTarget > 1)
          Text(
            '$count/${habit.dailyTarget}',
            style: TextStyle(
              color: isWhite
                  ? AppColors.textSecondary
                  : Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
      ],
    );

    return isWhite
        ? _WhiteHabitCard(
            key: ValueKey('habit_card_${habit.id}'),
            onTap: onTapCard,
            onLongPress: onLongPressCard,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: inner,
          )
        : RaisedCard(
            key: ValueKey('habit_card_${habit.id}'),
            onTap: onTapCard,
            onLongPress: onLongPressCard,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: inner,
          );
  }
}

class _WhiteHabitCard extends StatelessWidget {
  const _WhiteHabitCard({
    super.key,
    required this.child,
    required this.padding,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _HabitCheckBox extends StatelessWidget {
  const _HabitCheckBox({
    required this.habitId,
    required this.checked,
    required this.enabled,
    required this.onTap,
    this.onLongPress,
    this.isWhiteCard = false,
    this.boxSize = 34,
    this.padding = 4,
  });

  final int habitId;
  final bool checked;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isWhiteCard;
  final double boxSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final Color fillColor;
    final Border? border;
    final Color iconColor;

    if (isWhiteCard) {
      fillColor = checked ? AppColors.done : const Color(0xFFF6F6F6);
      border = checked ? null : Border.all(color: const Color(0xFFDCDCDC));
      iconColor = Colors.white;
    } else {
      fillColor = checked ? Colors.white.withValues(alpha: 0.25) : Colors.white;
      border = null;
      iconColor = Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('habit_checkbox_$habitId'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Container(
              width: boxSize,
              height: boxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fillColor,
                border: border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: checked
                  ? Icon(Icons.check, color: iconColor, size: boxSize * 0.65)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
