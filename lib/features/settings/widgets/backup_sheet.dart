import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/providers.dart';

/// Opens the JSON backup export / restore modal sheet.
Future<void> showBackupSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _BackupSheet(),
  );
}

class _BackupSheet extends ConsumerStatefulWidget {
  const _BackupSheet();

  @override
  ConsumerState<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends ConsumerState<_BackupSheet> {
  final _pasteController = TextEditingController();
  bool _busy = false;
  bool _showPasteBox = false;
  String? _statusMessage;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _exportAndCopy() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final result = await ref.read(backupServiceProvider).exportJson();
      await Clipboard.setData(ClipboardData(text: result.jsonText));
      if (!mounted) return;
      final s = result.summary;
      setState(() {
        _statusMessage =
            '已导出并复制备份（${s.habitCount} 个项目，${s.checkInCount} 条打卡记录）'
            '${s.filePath != null ? '\n本地文件：${s.filePath}' : ''}';
      });
    } catch (e) {
      if (mounted) setState(() => _statusMessage = '导出失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromLocalFile() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final jsonText = await ref.read(backupServiceProvider).readLatestLocalBackup();
      if (!mounted) return;
      if (jsonText == null || jsonText.trim().isEmpty) {
        setState(() => _statusMessage = '未找到本地备份文件，请先点击「导出备份」或粘贴 JSON 恢复');
        return;
      }
      await _confirmAndRestore(jsonText);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromPastedText() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      setState(() => _statusMessage = '请先粘贴备份 JSON 内容');
      return;
    }
    await _confirmAndRestore(text);
  }

  Future<void> _confirmAndRestore(String jsonText) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认恢复备份'),
        content: const Text('恢复备份将覆盖当前的项目、打卡记录与偏好设置，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.badge),
            child: const Text('覆盖恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final summary = await ref.read(backupServiceProvider).importJson(jsonText);
      await ref.read(appPrefsProvider.notifier).reload();
      if (!mounted) return;
      setState(() {
        _showPasteBox = false;
        _statusMessage =
            '恢复成功：${summary.habitCount} 个项目，${summary.checkInCount} 条打卡，${summary.reminderCount} 条提醒';
      });
    } catch (e) {
      if (mounted) setState(() => _statusMessage = '恢复失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.backup_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '备份与恢复数据',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '导出所有习惯项目、历史打卡、提醒和个性化设置为 JSON 文本，支持本地存档及跨设备恢复。',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('backup_export_button'),
              onPressed: _busy ? null : _exportAndCopy,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('导出备份并复制 JSON'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('backup_restore_local_button'),
              onPressed: _busy ? null : _restoreFromLocalFile,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.restore),
              label: const Text('从最近本地备份恢复'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('backup_toggle_paste_button'),
              onPressed: _busy
                  ? null
                  : () => setState(() => _showPasteBox = !_showPasteBox),
              child: Text(_showPasteBox ? '收起粘贴框' : '粘贴 JSON 文本恢复'),
            ),
            if (_showPasteBox) ...[
              TextField(
                key: const ValueKey('backup_paste_input'),
                controller: _pasteController,
                minLines: 3,
                maxLines: 6,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '在此粘贴导出的 JSON 备份内容...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                key: const ValueKey('backup_restore_paste_button'),
                onPressed: _busy ? null : _restoreFromPastedText,
                style: FilledButton.styleFrom(backgroundColor: AppColors.done),
                child: const Text('确认从粘贴内容恢复'),
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
