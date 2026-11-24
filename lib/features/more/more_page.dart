import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../icon_picker/icon_registry.dart';
import '../updates/update_dialog.dart';
import '../updates/update_models.dart';
import '../updates/update_providers.dart';

/// "更多" tab: app info, GitHub Releases in-app update settings, and manual check.
class MorePage extends ConsumerStatefulWidget {
  const MorePage({super.key});

  @override
  ConsumerState<MorePage> createState() => _MorePageState();
}

class _MorePageState extends ConsumerState<MorePage> {
  bool _checking = false;

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    late final UpdateConfig config;
    late final UpdateCheckResult result;
    try {
      config = await ref.read(updateConfigProvider.future);
      result = await ref.read(updateServiceProvider).checkForUpdate(config);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
    if (!mounted) return;

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        await showUpdateDialog(
          context,
          release: result.release!,
          currentVersion: result.currentVersion,
          allowIgnore: false,
        );
      case UpdateCheckStatus.upToDate:
        _showSnack(result.message ?? '当前已是最新版本');
      case UpdateCheckStatus.notConfigured:
        _showSnack(result.message ?? '请先配置 GitHub 仓库');
        await _editRepoDialog(config.repo);
      case UpdateCheckStatus.error:
        _showSnack(result.message ?? '检查更新失败');
    }
  }

  Future<void> _editRepoDialog(String initialRepo) async {
    final controller = TextEditingController(text: initialRepo);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('配置 GitHub 仓库'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '填写托管 APK Release 的公开仓库名称，格式为 owner/repo：',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '例如：yourname/ibetter',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null || !mounted) return;
    if (saved.isNotEmpty && !UpdateConfig.isValidRepo(saved)) {
      _showSnack('仓库格式应为 owner/repo');
      return;
    }
    await ref.read(updateConfigProvider.notifier).setRepo(saved);
    _showSnack(saved.isEmpty ? '已清除仓库配置' : '已保存仓库：$saved');
  }

  Future<void> _editMirrorDialog(String initialMirror) async {
    final controller = TextEditingController(text: initialMirror);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('下载加速前缀（可选）'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '留空则直连 GitHub 下载；若国内网络下载较慢，可填入自定义 GitHub 文件代理前缀（如 https://gh-proxy.com/）。',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '留空表示直连',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: const Text('恢复直连'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null || !mounted) return;
    await ref.read(updateConfigProvider.notifier).setMirrorPrefix(saved);
    _showSnack(saved.isEmpty ? '已恢复直连下载' : '已保存下载加速前缀');
  }

  void _showAttributionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('开源许可说明'),
        content: const Text(
          '本应用内置习惯图标基于 Microsoft Fluent Emoji（MIT License, Copyright (c) Microsoft Corporation）制作。\n\n'
          '所有打卡记录与提醒数据均保存在本机 SQLite 数据库中。',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(currentAppVersionProvider).asData?.value ?? AppVersion.fallback;
    final config = ref.watch(updateConfigProvider).asData?.value ?? const UpdateConfig();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: '更多'),
      body: ListView(
        padding: const EdgeInsets.only(top: 6, bottom: 28),
        children: [
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                const HabitIcon('achievement/trophy', size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'iBetter · 人生养成计划',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '当前版本 ${version.fullLabel}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '应用更新',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          SectionCard(
            child: Column(
              children: [
                _MoreRow(
                  key: const ValueKey('more_check_update_row'),
                  icon: Icons.system_update_outlined,
                  title: '检查更新',
                  trailing: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          version.displayName,
                          style: const TextStyle(color: AppColors.primary, fontSize: 14),
                        ),
                  onTap: _checking ? null : _checkUpdate,
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  key: const ValueKey('more_auto_check_row'),
                  icon: Icons.autorenew,
                  title: '启动时自动检查更新',
                  trailing: Switch(
                    value: config.autoCheck,
                    onChanged: (v) => ref.read(updateConfigProvider.notifier).setAutoCheck(v),
                  ),
                  onTap: () =>
                      ref.read(updateConfigProvider.notifier).setAutoCheck(!config.autoCheck),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  key: const ValueKey('more_repo_row'),
                  icon: Icons.code,
                  title: 'GitHub 仓库',
                  subtitle: config.hasValidRepo ? config.repo : '未配置，点击填写 owner/repo',
                  onTap: () => _editRepoDialog(config.repo),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  key: const ValueKey('more_mirror_row'),
                  icon: Icons.bolt_outlined,
                  title: '下载加速前缀',
                  subtitle: config.mirrorPrefix.isEmpty ? '直连 GitHub' : config.mirrorPrefix,
                  onTap: () => _editMirrorDialog(config.mirrorPrefix),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '关于',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          SectionCard(
            child: _MoreRow(
              icon: Icons.info_outline,
              title: '开源图标与数据说明',
              onTap: _showAttributionDialog,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ?trailing,
            if (trailing == null)
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 22),
          ],
        ),
      ),
    );
  }
}
