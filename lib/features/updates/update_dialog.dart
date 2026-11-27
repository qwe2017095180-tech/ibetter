import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import 'update_models.dart';
import 'update_providers.dart';
import 'update_service.dart';

/// Displays an interactive update dialog with changelog, live download progress,
/// and direct Android installer handoff.
Future<void> showUpdateDialog(
  BuildContext context, {
  required ReleaseInfo release,
  required AppVersion currentVersion,
  bool allowIgnore = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(
      release: release,
      currentVersion: currentVersion,
      allowIgnore: allowIgnore,
    ),
  );
}

enum _DownloadPhase {
  prompt,
  downloading,
  awaitingPermission,
  readyToInstall,
  error,
}

class _UpdateDialog extends ConsumerStatefulWidget {
  const _UpdateDialog({
    required this.release,
    required this.currentVersion,
    required this.allowIgnore,
  });

  final ReleaseInfo release;
  final AppVersion currentVersion;
  final bool allowIgnore;

  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  _DownloadPhase _phase = _DownloadPhase.prompt;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _downloadedPath;
  String? _statusText;
  String? _errorText;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _startDownloadAndInstall({UpdateConfig? overrideConfig}) async {
    final service = ref.read(updateServiceProvider);
    final config =
        overrideConfig ?? ref.read(updateConfigProvider).asData?.value ?? const UpdateConfig();

    setState(() {
      _phase = _DownloadPhase.downloading;
      _receivedBytes = 0;
      _totalBytes = widget.release.assetSizeBytes;
      _statusText = null;
      _errorText = null;
    });

    try {
      final path = await service.downloadApk(
        widget.release,
        config,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _receivedBytes = received;
            if (total > 0) _totalBytes = total;
          });
        },
        onStatus: (status) {
          if (!mounted) return;
          setState(() => _statusText = status);
        },
      );
      if (!mounted) return;
      _downloadedPath = path;
      await _triggerInstall();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _DownloadPhase.error;
        _statusText = null;
        _errorText = formatUpdateError(e);
      });
    }
  }

  Future<void> _switchMirrorAndRetry(String prefix) async {
    await ref.read(updateConfigProvider.notifier).setMirrorPrefix(prefix);
    if (!mounted) return;
    final updated = (ref.read(updateConfigProvider).asData?.value ?? const UpdateConfig())
        .copyWith(mirrorPrefix: prefix);
    await _startDownloadAndInstall(overrideConfig: updated);
  }

  Future<void> _openInBrowser() async {
    final service = ref.read(updateServiceProvider);
    final config = ref.read(updateConfigProvider).asData?.value ?? const UpdateConfig();
    final opened = await service.openInBrowser(widget.release, config);
    if (!mounted || opened) return;
    setState(() {
      _errorText = '无法打开系统浏览器，请手动访问 GitHub Release 页面下载';
    });
  }

  Future<void> _triggerInstall() async {
    final path = _downloadedPath;
    if (path == null) return;
    final service = ref.read(updateServiceProvider);
    final result = await service.installApk(path);
    if (!mounted) return;

    switch (result) {
      case InstallResult.launched:
        setState(() => _phase = _DownloadPhase.readyToInstall);
      case InstallResult.permissionRequired:
        setState(() => _phase = _DownloadPhase.awaitingPermission);
      case InstallResult.unsupported:
        setState(() {
          _phase = _DownloadPhase.error;
          _errorText = '当前平台不支持应用内直接安装 APK';
        });
      case InstallResult.failed:
        setState(() {
          _phase = _DownloadPhase.error;
          _errorText = '拉起系统安装器失败，请重试';
        });
    }
  }

  Future<void> _ignoreVersion() async {
    await ref.read(updateConfigProvider.notifier).ignoreTag(widget.release.tagName);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final config = ref.watch(updateConfigProvider).asData?.value ?? const UpdateConfig();
    final currentMirror = UpdateConfig.normalizeMirrorPrefix(config.mirrorPrefix);
    final progress = _totalBytes > 0 ? (_receivedBytes / _totalBytes).clamp(0.0, 1.0) : null;

    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.system_update, color: AppColors.primary, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '发现新版本 ${release.tagName}',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前版本：${widget.currentVersion.fullLabel}'
              '${release.assetSizeBytes > 0 ? ' · 安装包 ${_formatBytes(release.assetSizeBytes)}' : ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '下载线路：${currentMirror.isEmpty ? '直连 GitHub' : (Uri.tryParse(currentMirror)?.host ?? currentMirror)}',
              key: const ValueKey('update_current_mirror_label'),
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  release.changelog,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.45),
                ),
              ),
            ),
            if (_phase == _DownloadPhase.downloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _totalBytes > 0
                    ? '正在下载 ${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)}'
                    : '正在下载 ${_formatBytes(_receivedBytes)}...',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (_statusText != null) ...[
                const SizedBox(height: 4),
                Text(
                  _statusText!,
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.35),
                ),
              ],
            ],
            if (_phase == _DownloadPhase.awaitingPermission) ...[
              const SizedBox(height: 14),
              const Text(
                '请在系统设置中开启「允许来自此来源的应用」，返回后点击「继续安装」即可完成升级。',
                style: TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
              ),
            ],
            if (_phase == _DownloadPhase.readyToInstall) ...[
              const SizedBox(height: 14),
              const Text(
                '安装包已就绪，请按系统提示点击「更新」完成安装。',
                style: TextStyle(fontSize: 13, color: AppColors.done, height: 1.4),
              ),
            ],
            if (_phase == _DownloadPhase.error && _errorText != null) ...[
              const SizedBox(height: 14),
              Container(
                key: const ValueKey('update_error_box'),
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 110),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.badge.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _errorText!,
                    style: const TextStyle(fontSize: 13, color: AppColors.badge, height: 1.4),
                  ),
                ),
              ),
              if (_downloadedPath == null) ...[
                const SizedBox(height: 10),
                const Text(
                  '点击下方线路切换并重试：',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final preset in UpdateConfig.mirrorPresets)
                      ActionChip(
                        label: Text(
                          preset.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: currentMirror == preset.prefix
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: currentMirror == preset.prefix
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.inputFill,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _switchMirrorAndRetry(preset.prefix),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    switch (_phase) {
      case _DownloadPhase.prompt:
        return [
          if (widget.allowIgnore)
            TextButton(
              onPressed: _ignoreVersion,
              child: const Text('忽略此版本', style: TextStyle(color: AppColors.textSecondary)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: _startDownloadAndInstall,
            style: FilledButton.styleFrom(backgroundColor: AppColors.done),
            child: const Text('立即更新'),
          ),
        ];

      case _DownloadPhase.downloading:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('后台取消'),
          ),
        ];

      case _DownloadPhase.awaitingPermission:
      case _DownloadPhase.readyToInstall:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: _triggerInstall,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(_phase == _DownloadPhase.awaitingPermission ? '继续安装' : '重新拉起安装'),
          ),
        ];

      case _DownloadPhase.error:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          if (_downloadedPath == null)
            TextButton(
              key: const ValueKey('update_browser_download_btn'),
              onPressed: _openInBrowser,
              child: const Text('浏览器下载'),
            ),
          FilledButton(
            onPressed: _downloadedPath != null ? _triggerInstall : _startDownloadAndInstall,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('重试'),
          ),
        ];
    }
  }
}
