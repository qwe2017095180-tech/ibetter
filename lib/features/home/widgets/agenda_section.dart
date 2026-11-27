import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/platform/native_bridge.dart';
import '../../../core/prefs/app_prefs.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/date_key.dart' as dk;
import '../../../domain/models/agenda_item.dart';
import '../../qingsong/qingsong_providers.dart';
import '../home_providers.dart';
import 'add_agenda_sheet.dart';

/// 首页「今日日程」区块（跟随选中日期）：展示本地新建 + 轻松日程同步过来的事项。
class AgendaSection extends ConsumerWidget {
  const AgendaSection({super.key});

  Future<void> _toggleDone(WidgetRef ref, AgendaItem item) async {
    final prefs = ref.read(appPrefsProvider).asData?.value ?? const AppPrefs();
    if (prefs.soundEnabled) {
      unawaited(
        ref.read(nativeBridgeProvider).playSound(
              !item.isDone ? AppSound.checkIn : AppSound.uncheck,
            ),
      );
      unawaited(HapticFeedback.lightImpact());
    }
    await ref.read(agendaRepositoryProvider).setDone(item.id, !item.isDone);
    final config = ref.read(qingsongConfigProvider).asData?.value;
    if (item.isLinked && config != null && config.isConfigured) {
      unawaited(ref.read(qingsongSyncProvider.notifier).sync(silent: true));
    }
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, AgendaItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除日程'),
        content: Text(
          item.isFromQingsong
              ? '确定在手机上隐藏「${item.title}」吗？（不会删除电脑轻松日程里的原卡片）'
              : '确定删除「${item.title}」吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(agendaRepositoryProvider).delete(item.id);
    }
  }

  void _showDetail(BuildContext context, WidgetRef ref, AgendaItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardShadow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _CategoryTag(label: item.category),
                const SizedBox(width: 8),
                Text(
                  '${item.date} ${item.timeLabel ?? '全天'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (item.isFromQingsong)
                  const _SourceBadge(label: '轻松日程')
                else if (item.isLinked)
                  const _SourceBadge(label: '已同步电脑'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (item.origin.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '来源：${item.origin}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.note,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _deleteItem(context, ref, item);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(item.isFromQingsong ? '隐藏' : '删除'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _toggleDone(ref, item);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: item.isDone ? AppColors.textSecondary : AppColors.done,
                    ),
                    icon: Icon(item.isDone ? Icons.undo : Icons.done_rounded, size: 18),
                    label: Text(item.isDone ? '标为未完成' : '标为已完成'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manualSync(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(qingsongSyncProvider.notifier).sync();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(outcome.message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dk.dateOnly(ref.watch(todayProvider));
    final selectedDate = dk.dateOnly(ref.watch(selectedDateProvider));
    final selectedKey = dk.dateKey(selectedDate);
    final items = ref.watch(agendaByDateProvider(selectedKey)).asData?.value ?? const <AgendaItem>[];
    final config = ref.watch(qingsongConfigProvider).asData?.value;
    final syncState = ref.watch(qingsongSyncProvider);

    final isToday = dk.isSameDay(selectedDate, today);
    final heading = isToday ? '今日日程' : '${selectedDate.month}月${selectedDate.day}日日程';
    final pendingCount = items.where((i) => !i.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 16, 4),
          child: Row(
            children: [
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  pendingCount == 0 ? '已全部完成' : '待办 $pendingCount/${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: pendingCount == 0 ? AppColors.done : AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              if (config != null && config.isConfigured)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    key: const ValueKey('home_qingsong_sync_button'),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: syncState.syncing ? null : () => _manualSync(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: syncState.syncing
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync, size: 18, color: AppColors.primary),
                    ),
                  ),
                ),
              InkWell(
                key: const ValueKey('add_agenda_button'),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => showAddAgendaSheet(context, initialDate: selectedDate),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 2))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_calendar_outlined, size: 15, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        '添加日程',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: items.isEmpty
              ? InkWell(
                  key: const ValueKey('agenda_empty_prompt'),
                  onTap: () => showAddAgendaSheet(context, initialDate: selectedDate),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 20,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isToday ? '今天还没有日程，点这里记一条' : '这天还没有日程，点这里添加',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, thickness: 1, color: AppColors.divider),
                      _AgendaTile(
                        item: items[i],
                        onToggle: () => _toggleDone(ref, items[i]),
                        onTap: () => _showDetail(context, ref, items[i]),
                        onLongPress: () => _deleteItem(context, ref, items[i]),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({
    required this.item,
    required this.onToggle,
    required this.onTap,
    required this.onLongPress,
  });

  final AgendaItem item;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('agenda_tile_${item.id}'),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              key: ValueKey('agenda_checkbox_${item.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 1, right: 12, bottom: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.isDone ? AppColors.done : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: item.isDone ? AppColors.done : AppColors.textHint,
                      width: 2,
                    ),
                  ),
                  child: item.isDone
                      ? const Icon(Icons.done_rounded, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: item.isDone ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _TimeChip(label: item.timeLabel ?? '全天', hasTime: item.minutesOfDay != null),
                      _CategoryTag(label: item.category),
                      if (item.isFromQingsong)
                        _SourceBadge(
                          label: item.origin.isNotEmpty ? item.origin : '轻松日程',
                          isComputer: true,
                        )
                      else if (item.syncToRemote)
                        _SourceBadge(
                          label: item.isLinked ? '已同步' : '待同步',
                          isComputer: false,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.hasTime});

  final String label;
  final bool hasTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: hasTime ? AppColors.primary.withValues(alpha: 0.12) : AppColors.inputFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: hasTime ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.habitCard.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.habitCardShadow,
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label, this.isComputer = true});

  final String label;
  final bool isComputer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isComputer ? Icons.computer : Icons.sync_alt,
          size: 12,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
