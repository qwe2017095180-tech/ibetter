import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:material_ui/material_ui.dart';

import '../../../app/app_brand.dart';
import '../../../app/theme/app_colors.dart';
import '../../../domain/services/achievement_service.dart';
import '../../icon_picker/icon_registry.dart';

/// Opens a shareable "成绩单" report card dialog summarizing overall stats.
Future<void> showReportCardSheet(
  BuildContext context, {
  required OverallStats stats,
  required DateTime today,
  VoidCallback? onShared,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ReportCardDialog(
      stats: stats,
      today: today,
      onCopy: (text) async {
        await Clipboard.setData(ClipboardData(text: text));
        onShared?.call();
        if (!dialogContext.mounted) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('已复制成绩单')));
      },
    ),
  );
}

class _ReportCardDialog extends StatelessWidget {
  const _ReportCardDialog({
    required this.stats,
    required this.today,
    required this.onCopy,
  });

  final OverallStats stats;
  final DateTime today;
  final Future<void> Function(String text) onCopy;

  String _buildShareText() {
    final topHabit = stats.topHabitName ?? '暂无';
    return [
      '${AppBrand.name} ${today.year} 年度成绩单',
      '项目数：${stats.projectCount}',
      '记录天数：${stats.recordedDays} 天',
      '达成次数：${stats.totalCompletions} 次',
      '最长连续：${stats.longestStreak} 天',
      '完成最多的项目：$topHabit',
      '获得成就次数：${stats.totalAchievementCount} 次',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final topHabit = stats.topHabitName ?? '暂无';
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF6DF),
                      shape: BoxShape.circle,
                    ),
                    child: const HabitIcon('achievement/sports_medal', size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '我的成绩单',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${today.year} 年度总结',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${today.year}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _MetricTile(label: '项目数', value: '${stats.projectCount}')),
                        Expanded(child: _MetricTile(label: '记录天数', value: '${stats.recordedDays}')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(label: '达成次数', value: '${stats.totalCompletions}'),
                        ),
                        Expanded(child: _MetricTile(label: '最长连续', value: '${stats.longestStreak}')),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1, color: AppColors.divider),
                    ),
                    _DetailRow(label: '完成最多的项目', value: topHabit),
                    const SizedBox(height: 8),
                    _DetailRow(label: '获得成就次数', value: '${stats.totalAchievementCount} 次'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onCopy(_buildShareText()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('复制成绩单'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A4A4A),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}
