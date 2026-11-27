import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/services/stats_service.dart';
import '../../icon_picker/icon_registry.dart';

/// Builds plain-text summary copied to the clipboard when sharing a habit.
String buildHabitShareText(Habit habit, HabitStats stats) {
  final start =
      '${habit.startDate.year}-${habit.startDate.month.toString().padLeft(2, '0')}-${habit.startDate.day.toString().padLeft(2, '0')}';
  final streakUnit = switch (habit.schedule.type) {
    ScheduleType.daily || ScheduleType.weekdays => '天',
    ScheduleType.timesPerWeek => '周',
    ScheduleType.timesPerMonth => '月',
  };
  final buffer = StringBuffer()
    ..writeln('我在轻松打卡坚持「${habit.name}」')
    ..writeln('累计完成：${stats.totalDays} 天')
    ..writeln('当前连续：${stats.currentStreak} $streakUnit')
    ..write('开始于：$start');
  final motto = habit.motto.trim();
  if (motto.isNotEmpty) {
    buffer
      ..writeln()
      ..write('「$motto」');
  }
  return buffer.toString();
}

/// Bottom sticky bar with equal-width "编辑" and "分享" pill buttons.
class DetailBottomActions extends StatelessWidget {
  const DetailBottomActions({
    super.key,
    required this.onEdit,
    required this.onShare,
  });

  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: _BottomPillButton(
                key: const ValueKey('detail_bottom_edit_button'),
                icon: Icons.edit,
                label: '编辑',
                onTap: onEdit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BottomPillButton(
                key: const ValueKey('detail_bottom_share_button'),
                icon: Icons.send,
                label: '分享',
                onTap: onShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPillButton extends StatelessWidget {
  const _BottomPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 2), blurRadius: 3)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a styled share preview dialog with habit summary and copy-to-clipboard action.
Future<void> showHabitShareDialog(
  BuildContext context, {
  required Habit habit,
  required HabitStats stats,
  VoidCallback? onShared,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final shareText = buildHabitShareText(habit, stats);
  final motto = habit.motto.trim();
  final streakUnit = switch (habit.schedule.type) {
    ScheduleType.daily || ScheduleType.weekdays => stats.currentStreak == 1 ? 'Day' : 'Days',
    ScheduleType.timesPerWeek => '周',
    ScheduleType.timesPerMonth => '月',
  };
  final startLabel = '${habit.startDate.year}年${habit.startDate.month}月${habit.startDate.day}日';

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: habit.isActive ? AppColors.habitCard : const Color(0xFFB8B8C8),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Row(
                children: [
                  HabitIcon(habit.iconKey, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          habit.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (motto.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            motto,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ShareStat(
                      label: '累计坚持',
                      value: '${stats.totalDays}',
                      unit: stats.totalDays == 1 ? 'Day' : 'Days',
                    ),
                  ),
                  Expanded(
                    child: _ShareStat(
                      label: '当前连续',
                      value: '${stats.currentStreak}',
                      unit: streakUnit,
                    ),
                  ),
                  Expanded(
                    child: _ShareStat(
                      label: '开始日期',
                      value: startLabel,
                      compactValue: true,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20, thickness: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      '关闭',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shareText));
                      onShared?.call();
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(content: Text('已复制分享文案')));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('复制分享文案', style: TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShareStat extends StatelessWidget {
  const _ShareStat({
    required this.label,
    required this.value,
    this.unit,
    this.compactValue = false,
  });

  final String label;
  final String value;
  final String? unit;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compactValue ? 13 : 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (unit != null) ...[
          const SizedBox(height: 2),
          Text(
            unit!,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
