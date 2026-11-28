import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/platform/native_bridge.dart';
import '../../core/prefs/app_prefs.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../domain/date_key.dart' as dk;
import '../../domain/models/agenda_item.dart';
import '../../domain/models/qingsong_notice.dart';
import '../../domain/services/qingsong_board_rules.dart';
import '../home/widgets/add_agenda_sheet.dart';
import 'qingsong_config.dart';
import 'qingsong_providers.dart';

/// Full-screen 「轻松日程」 schedule & notification board mirrored from PC web UI.
class QingsongBoardPage extends ConsumerStatefulWidget {
  const QingsongBoardPage({super.key});

  @override
  ConsumerState<QingsongBoardPage> createState() => _QingsongBoardPageState();
}

class _QingsongBoardPageState extends ConsumerState<QingsongBoardPage> {
  String _selectedTab = 'all';

  Future<void> _syncNow() async {
    final outcome = await ref.read(qingsongSyncProvider.notifier).sync();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(outcome.message)));
  }

  Future<void> _changeStatus(QingsongNotice notice, String nextStatus) async {
    final prefs = ref.read(appPrefsProvider).asData?.value ?? const AppPrefs();
    if (prefs.soundEnabled) {
      final sfx = (nextStatus == 'done' || nextStatus == 'todo')
          ? AppSound.checkIn
          : AppSound.uncheck;
      unawaited(ref.read(nativeBridgeProvider).playSound(sfx));
      unawaited(HapticFeedback.lightImpact());
    }
    final hint =
        await ref.read(qingsongNoticesProvider.notifier).updateNoticeStatus(notice, nextStatus);
    if (!mounted || hint == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(hint)));
  }

  Future<void> _deleteLocal(QingsongNotice notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除本地日程'),
        content: Text('确定删除「${notice.title}」吗？'),
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
      await ref.read(qingsongNoticesProvider.notifier).deleteLocalNotice(notice);
    }
  }

  String _syncCaption(QingsongConfig? config, int activeCount) {
    if (config == null || !config.isConfigured) {
      return activeCount > 0 ? '本地 · 共 $activeCount 条活跃日程' : '未连接电脑';
    }
    if (config.lastSyncAt == null) {
      return '已配对 · 共 $activeCount 条活跃日程';
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(config.lastSyncAt!);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '同步于 ${dt.month}月${dt.day}日 $hh:$mm';
  }

  Future<void> _openDetailSheet(QingsongNotice notice, DateTime now) async {
    final style = _categoryStyle(notice.category);
    final countdown = computeNoticeCountdown(notice.deadline, now);
    final deadlineStr = formatNoticeDeadline(notice.deadline, now);
    final bodyText = notice.detail.isNotEmpty
        ? notice.detail
        : (notice.summary.isNotEmpty ? notice.summary : '暂无详细正文');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                    _CategoryBadge(category: notice.category, style: style),
                    if (notice.isTodo) ...[
                      const SizedBox(width: 8),
                      const _TodoFlag(),
                    ],
                    const Spacer(),
                    Flexible(
                      child: Text(
                        notice.group.isNotEmpty ? notice.group : '来源未知',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    bodyText,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF334155),
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 17, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deadlineStr,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      if (notice.isArchived)
                        _ArchiveStatusPill(isDone: notice.isDone)
                      else
                        _CountdownPill(countdown: countdown, isTodo: notice.isTodo),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _NoticeActionRow(
                  notice: notice,
                  fullWidth: true,
                  onAction: (nextStatus) {
                    Navigator.of(ctx).pop();
                    _changeStatus(notice, nextStatus);
                  },
                  onDeleteLocal: () {
                    Navigator.of(ctx).pop();
                    _deleteLocal(notice);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider)();
    final today = dk.dateOnly(ref.watch(todayProvider));
    final config = ref.watch(qingsongConfigProvider).asData?.value;
    final syncState = ref.watch(qingsongSyncProvider);
    final cachedNotices =
        ref.watch(qingsongNoticesProvider).asData?.value ?? const <QingsongNotice>[];
    final localVisible =
        ref.watch(allVisibleAgendaProvider).asData?.value ?? const <AgendaItem>[];

    final allItems = mergeBoardItems(cachedNotices, localVisible);
    final counts = computeBoardTabCounts(allItems);
    final visible = filterAndSortBoardNotices(allItems, _selectedTab, now);
    final activeCount = counts['all'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BoardHeader(
              caption: _syncCaption(config, activeCount),
              syncing: syncState.syncing,
              onBack: () => Navigator.of(context).maybePop(),
              onSync: syncState.syncing ? null : _syncNow,
              onAdd: () => showAddAgendaSheet(context, initialDate: today),
            ),
            if (config != null && !config.isConfigured)
              _UnpairedHintBanner(
                onPairTap: () => context.go(Routes.more),
              ),
            _CategoryFilterBar(
              selectedTab: _selectedTab,
              counts: counts,
              onSelect: (tabId) => setState(() => _selectedTab = tabId),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _syncNow,
                child: visible.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
                        children: [
                          _EmptyBoardState(
                            selectedTab: _selectedTab,
                            isConfigured: config?.isConfigured ?? false,
                            onAdd: () => showAddAgendaSheet(context, initialDate: today),
                            onSync: syncState.syncing ? null : _syncNow,
                          ),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final cols = width >= 980 ? 3 : (width >= 620 ? 2 : 1);
                          if (cols == 1) {
                            return ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                              itemCount: visible.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final item = visible[idx];
                                return _NoticeBoardCard(
                                  notice: item,
                                  now: now,
                                  onTap: () => _openDetailSheet(item, now),
                                  onStatusAction: (s) => _changeStatus(item, s),
                                  onDeleteLocal: () => _deleteLocal(item),
                                );
                              },
                            );
                          }

                          final rows = (visible.length / cols).ceil();
                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                            itemCount: rows,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (ctx, rowIdx) {
                              final start = rowIdx * cols;
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (var c = 0; c < cols; c++) ...[
                                      if (c > 0) const SizedBox(width: 14),
                                      Expanded(
                                        child: start + c < visible.length
                                            ? _NoticeBoardCard(
                                                notice: visible[start + c],
                                                now: now,
                                                onTap: () =>
                                                    _openDetailSheet(visible[start + c], now),
                                                onStatusAction: (s) =>
                                                    _changeStatus(visible[start + c], s),
                                                onDeleteLocal: () =>
                                                    _deleteLocal(visible[start + c]),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({
    required this.caption,
    required this.syncing,
    required this.onBack,
    required this.onSync,
    required this.onAdd,
  });

  final String caption;
  final bool syncing;
  final VoidCallback onBack;
  final VoidCallback? onSync;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      child: Row(
        children: [
          PillIconButton(
            icon: Icons.arrow_back_ios_new,
            tooltip: '返回',
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '轻松日程',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              key: const ValueKey('qingsong_board_sync_btn'),
              borderRadius: BorderRadius.circular(20),
              onTap: onSync,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (syncing)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(Icons.sync, size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    const Text(
                      '立即同步',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              key: const ValueKey('qingsong_board_add_btn'),
              borderRadius: BorderRadius.circular(20),
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDCE3EE)),
                ),
                child: const Text(
                  '+ 添加',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnpairedHintBanner extends StatelessWidget {
  const _UnpairedHintBanner({required this.onPairTap});

  final VoidCallback onPairTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.desktop_windows_outlined, size: 17, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '配对电脑「轻松日程」后，可同步微信群通知卡片到手机',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF1E3A8A)),
            ),
          ),
          TextButton(
            onPressed: onPairTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('去配对', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedTab,
    required this.counts,
    required this.onSelect,
  });

  final String selectedTab;
  final Map<String, int> counts;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            for (var idx = 0; idx < kQingsongBoardTabs.length; idx++) ...[
              if (idx > 0) const SizedBox(width: 8),
              Builder(
                builder: (ctx) {
                  final tab = kQingsongBoardTabs[idx];
                  final active = tab.id == selectedTab;
                  final count = counts[tab.id] ?? 0;

                  return Material(
                    color: active ? const Color(0xFFE8F1FF) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      key: ValueKey('board_tab_${tab.id}'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onSelect(tab.id),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? const Color(0xFF93C5FD) : const Color(0xFFE5E9F2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tab.emoji.isNotEmpty) ...[
                              Text(tab.emoji, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                color: active ? const Color(0xFF2563EB) : const Color(0xFF475569),
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: active ? Colors.white : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        active ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoticeBoardCard extends StatelessWidget {
  const _NoticeBoardCard({
    required this.notice,
    required this.now,
    required this.onTap,
    required this.onStatusAction,
    required this.onDeleteLocal,
  });

  final QingsongNotice notice;
  final DateTime now;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusAction;
  final VoidCallback onDeleteLocal;

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle(notice.category);
    final countdown = computeNoticeCountdown(notice.deadline, now);
    final deadlineStr = formatNoticeDeadline(notice.deadline, now);
    final preview = notice.summary.isNotEmpty ? notice.summary : notice.detail;

    return Container(
      key: ValueKey('notice_card_${notice.id}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _CategoryBadge(category: notice.category, style: style),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        notice.group.isNotEmpty ? notice.group : '来源未知',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        notice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (notice.isTodo) ...[
                      const SizedBox(width: 8),
                      const _TodoFlag(),
                    ],
                  ],
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.7, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deadlineStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: noticeDeadlineHasTime(notice.deadline) ||
                                  parseNoticeDeadline(notice.deadline) != null
                              ? const Color(0xFF475569)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (notice.isArchived)
                      _ArchiveStatusPill(isDone: notice.isDone)
                    else
                      _CountdownPill(countdown: countdown, isTodo: notice.isTodo),
                  ],
                ),
                const SizedBox(height: 12),
                _NoticeActionRow(
                  notice: notice,
                  fullWidth: false,
                  onAction: onStatusAction,
                  onDeleteLocal: onDeleteLocal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeActionRow extends StatelessWidget {
  const _NoticeActionRow({
    required this.notice,
    required this.fullWidth,
    required this.onAction,
    required this.onDeleteLocal,
  });

  final QingsongNotice notice;
  final bool fullWidth;
  final ValueChanged<String> onAction;
  final VoidCallback onDeleteLocal;

  Widget _pillButton({
    Key? key,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons;

    if (notice.isArchived) {
      buttons = [
        _pillButton(
          key: ValueKey('notice_restore_${notice.id}'),
          label: '↩ 恢复到列表',
          bg: const Color(0xFFE4F8ED),
          fg: const Color(0xFF15803D),
          onTap: () => onAction('todo'),
        ),
        if (notice.isLocalOnly)
          _pillButton(
            key: ValueKey('notice_delete_${notice.id}'),
            label: '删除',
            bg: const Color(0xFFF1F5F9),
            fg: const Color(0xFF64748B),
            onTap: onDeleteLocal,
          ),
      ];
    } else if (notice.isTodo) {
      buttons = [
        _pillButton(
          key: ValueKey('notice_done_${notice.id}'),
          label: '✓ 完成',
          bg: const Color(0xFFE4F8ED),
          fg: const Color(0xFF15803D),
          onTap: () => onAction('done'),
        ),
        if (notice.isLocalOnly)
          _pillButton(
            key: ValueKey('notice_delete_${notice.id}'),
            label: '删除',
            bg: const Color(0xFFF1F5F9),
            fg: const Color(0xFF64748B),
            onTap: onDeleteLocal,
          )
        else
          _pillButton(
            key: ValueKey('notice_new_${notice.id}'),
            label: '移回通知',
            bg: const Color(0xFFF1F5F9),
            fg: const Color(0xFF475569),
            onTap: () => onAction('new'),
          ),
      ];
    } else {
      buttons = [
        _pillButton(
          key: ValueKey('notice_todo_${notice.id}'),
          label: '加入待办',
          bg: const Color(0xFFE4F8ED),
          fg: const Color(0xFF15803D),
          onTap: () => onAction('todo'),
        ),
        InkWell(
          key: ValueKey('notice_skip_${notice.id}'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => onAction('skip'),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              '不参加 / 忽略',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
        ),
      ];
    }

    if (fullWidth && buttons.length == 2) {
      return Row(
        children: [
          Expanded(child: buttons[0]),
          const SizedBox(width: 10),
          Expanded(child: buttons[1]),
        ],
      );
    }
    return Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: buttons);
  }
}

class _CategoryStyle {
  const _CategoryStyle({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}

_CategoryStyle _categoryStyle(String category) => switch (category) {
      '作业' => const _CategoryStyle(bg: Color(0xFFE6F4FE), fg: Color(0xFF0369A1)),
      '兼职' => const _CategoryStyle(bg: Color(0xFFFFF1E6), fg: Color(0xFFC2410C)),
      '比赛' => const _CategoryStyle(bg: Color(0xFFF3E8FF), fg: Color(0xFF7E22CE)),
      '活动' => const _CategoryStyle(bg: Color(0xFFE6FBF3), fg: Color(0xFF047857)),
      '志愿' => const _CategoryStyle(bg: Color(0xFFFFEAF0), fg: Color(0xFFBE123C)),
      '通知' => const _CategoryStyle(bg: Color(0xFFFEF5E6), fg: Color(0xFFB45309)),
      _ => const _CategoryStyle(bg: Color(0xFFF1F5F9), fg: Color(0xFF475569)),
    };

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category, required this.style});

  final String category;
  final _CategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final norm = normalizeNoticeCategory(category);
    final emoji = kQingsongCategoryEmojis[norm] ?? '📎';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            norm,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: style.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoFlag extends StatelessWidget {
  const _TodoFlag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F8ED),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '待办中',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF16A34A),
        ),
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.countdown, required this.isTodo});

  final NoticeCountdown countdown;
  final bool isTodo;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (countdown.urgency) {
      case CountdownUrgency.none:
        bg = Colors.transparent;
        fg = const Color(0xFF64748B);
      case CountdownUrgency.ok:
        bg = isTodo ? const Color(0xFF34C785) : const Color(0xFFE4F8ED);
        fg = isTodo ? Colors.white : const Color(0xFF15803D);
      case CountdownUrgency.soon:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
      case CountdownUrgency.urgent:
      case CountdownUrgency.expired:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: countdown.urgency == CountdownUrgency.none ? 4 : 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        countdown.text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _ArchiveStatusPill extends StatelessWidget {
  const _ArchiveStatusPill({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFE4F8ED) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isDone ? '🗃️ 已完成' : '🗃️ 已忽略',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDone ? const Color(0xFF15803D) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _EmptyBoardState extends StatelessWidget {
  const _EmptyBoardState({
    required this.selectedTab,
    required this.isConfigured,
    required this.onAdd,
    required this.onSync,
  });

  final String selectedTab;
  final bool isConfigured;
  final VoidCallback onAdd;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final isArchive = selectedTab == 'archive';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          Icon(
            isArchive ? Icons.inventory_2_outlined : Icons.event_available_outlined,
            size: 44,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            isArchive ? '归档还是空的' : '该分类暂无日程',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isConfigured
                ? '可以切换上方分类、点击「立即同步」拉取最新群通知，或手动添加一条日程。'
                : '可以点击「+ 添加」新建本地日程，或到「更多」配对电脑端轻松日程同步全部通知。',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: const Text('+ 添加日程'),
              ),
              if (isConfigured)
                OutlinedButton(
                  onPressed: onSync,
                  child: const Text('立即同步'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
