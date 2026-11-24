import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/models/reminder.dart';
import 'editor_row.dart';

/// Card 2: Scheduled reminders section with '点击添加' trigger and removable 'HH:mm' chips.
class ReminderSectionCard extends StatelessWidget {
  const ReminderSectionCard({
    super.key,
    required this.reminders,
    required this.onAddTap,
    required this.onRemoveAt,
  });

  final List<ReminderDraft> reminders;
  final VoidCallback onAddTap;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorFormRow(
            icon: Icons.alarm,
            label: '定时提醒',
            valueText: '点击添加',
            showDropdownArrow: false,
            onTap: onAddTap,
          ),
          if (reminders.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < reminders.length; i++)
                    _ReminderChip(
                      label: reminders[i].timeLabel,
                      onRemove: () => onRemoveAt(i),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
