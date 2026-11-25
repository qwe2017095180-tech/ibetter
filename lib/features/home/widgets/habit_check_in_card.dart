import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/common.dart';
import '../../../domain/models/habit.dart';
import '../../icon_picker/icon_registry.dart';

/// Purple habit card on the home page with icon, title/motto, and check-in box.
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
  });

  final Habit habit;
  final int count;
  final bool isDone;
  final bool canCheckIn;
  final VoidCallback onTapCard;
  final VoidCallback onTapCheck;
  final VoidCallback? onLongPressCard;
  final VoidCallback? onLongPressCheck;

  @override
  Widget build(BuildContext context) {
    final hasMotto = habit.motto.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: RaisedCard(
        key: ValueKey('habit_card_${habit.id}'),
        onTap: onTapCard,
        onLongPress: onLongPressCard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
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
                    style: const TextStyle(
                      color: Colors.white,
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
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
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
                    color: Colors.white.withValues(alpha: 0.9),
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
              onTap: onTapCheck,
              onLongPress: onLongPressCheck,
            ),
          ],
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
  });

  final int habitId;
  final bool checked;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('habit_checkbox_$habitId'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
