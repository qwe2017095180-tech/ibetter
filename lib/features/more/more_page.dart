import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_brand.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../icon_picker/icon_registry.dart';
import '../qingsong/qingsong_client.dart';
import '../qingsong/qingsong_config.dart';
import '../qingsong/qingsong_providers.dart';
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
  bool _testingQingsong = false;

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
    final saved = await _showTextPromptDialog(
      title: '配置 GitHub 仓库',
      description: '填写托管 APK Release 的公开仓库名称，格式为 owner/repo：',
      initialValue: initialRepo,
      hintText: '例如：yourname/ibetter',
    );
    if (saved == null || !mounted) return;
    if (saved.isNotEmpty && !UpdateConfig.isValidRepo(saved)) {
      _showSnack('仓库格式应为 owner/repo');
      return;
    }
    await ref.read(updateConfigProvider.notifier).setRepo(saved);
    _showSnack(saved.isEmpty ? '已清除仓库配置' : '已保存仓库：$saved');
  }

  Future<void> _editMirrorDialog(String initialMirror) async {
    final saved = await _showTextPromptDialog(
      title: '下载加速前缀（默认开启镜像）',
      description: '默认已使用 gh-proxy.com 镜像源并支持自动切换/回退；也可点选下方常用线路或清空恢复直连 GitHub。',
      initialValue: initialMirror,
      hintText: '例如：https://gh-proxy.com/（留空为直连）',
      clearLabel: '切换为直连',
      presets: [
        for (final preset in UpdateConfig.mirrorPresets)
          (label: preset.label, value: preset.prefix),
      ],
    );
    if (saved == null || !mounted) return;
    await ref.read(updateConfigProvider.notifier).setMirrorPrefix(saved);
    _showSnack(saved.isEmpty ? '已恢复直连下载' : '已保存下载加速前缀');
  }

  Future<void> _editQingsongAddressDialog(String initialAddress) async {
    final saved = await _showTextPromptDialog(
      title: '电脑地址（轻松日程）',
      description: '在电脑浏览器打开轻松日程的「连接轻松打卡」页面，开启后把显示的局域网地址填在这里：',
      initialValue: initialAddress,
      hintText: '例如：192.168.1.8:7790',
      fieldKey: const ValueKey('qingsong_address_input'),
      clearLabel: initialAddress.isNotEmpty ? '清除' : null,
    );
    if (saved == null || !mounted) return;
    if (saved.isNotEmpty && normalizeQingsongAddress(saved) == null) {
      _showSnack('地址格式不对，请填写如 192.168.1.8:7790');
      return;
    }
    await ref.read(qingsongConfigProvider.notifier).setAddress(saved);
    _showSnack(saved.isEmpty ? '已清除电脑地址' : '已保存地址：$saved');
  }

  Future<void> _editQingsongTokenDialog(String initialToken) async {
    final saved = await _showTextPromptDialog(
      title: '配对码（轻松日程）',
      description: '填写电脑「连接轻松打卡」页面上显示的 8 位配对码（不区分大小写）：',
      initialValue: initialToken,
      hintText: '8 位配对码',
      fieldKey: const ValueKey('qingsong_token_input'),
      uppercase: true,
    );
    if (saved == null || !mounted) return;
    await ref.read(qingsongConfigProvider.notifier).setToken(saved);
    _showSnack(saved.isEmpty ? '已清除配对码' : '已保存配对码');
  }

  Future<String?> _showTextPromptDialog({
    required String title,
    required String description,
    required String initialValue,
    required String hintText,
    Key? fieldKey,
    String? clearLabel,
    bool uppercase = false,
    List<({String label, String value})> presets = const [],
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(
        title: title,
        description: description,
        initialValue: initialValue,
        hintText: hintText,
        fieldKey: fieldKey,
        clearLabel: clearLabel,
        uppercase: uppercase,
        presets: presets,
      ),
    );
  }

  Future<void> _testQingsongConnection() async {
    if (_testingQingsong) return;
    setState(() => _testingQingsong = true);
    try {
      final outcome = await ref.read(qingsongSyncProvider.notifier).testConnection();
      _showSnack(outcome.message);
    } finally {
      if (mounted) setState(() => _testingQingsong = false);
    }
  }

  Future<void> _syncQingsongNow() async {
    final outcome = await ref.read(qingsongSyncProvider.notifier).sync();
    _showSnack(outcome.message);
  }

  String _formatSyncSubtitle(QingsongConfig config, QingsongSyncState syncState) {
    if (syncState.syncing) return '正在与电脑同步…';
    if (syncState.lastError != null) return '上次失败：${syncState.lastError}';
    if (config.lastSyncAt == null) {
      return config.isConfigured ? '尚未同步，点击立即同步' : '请先填写电脑地址和配对码';
    }
    final d = DateTime.fromMillisecondsSinceEpoch(config.lastSyncAt!);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final summary = syncState.lastSummary;
    final timeStr = '${d.month}月${d.day}日 $hh:$mm';
    return summary == null ? '上次同步：$timeStr' : '上次同步：$timeStr（$summary）';
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
    final qsConfig = ref.watch(qingsongConfigProvider).asData?.value ?? const QingsongConfig();
    final qsSync = ref.watch(qingsongSyncProvider);

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
                        '${AppBrand.name} · 人生养成计划',
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
              '轻松日程同步（局域网）',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          SectionCard(
            child: Column(
              children: [
                _MoreRow(
                  key: const ValueKey('more_qingsong_board_row'),
                  icon: Icons.event_note_outlined,
                  title: '查看全部日程',
                  subtitle: '按全部 / 待办 / 分类 / 归档浏览轻松日程',
                  onTap: () => context.push(Routes.qingsongBoard),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  key: const ValueKey('more_qingsong_address_row'),
                  icon: Icons.computer_outlined,
                  title: '电脑地址',
                  subtitle: qsConfig.address.isEmpty
                      ? '未配置，如 192.168.1.8:7790'
                      : qsConfig.address,
                  onTap: () => _editQingsongAddressDialog(qsConfig.address),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  key: const ValueKey('more_qingsong_token_row'),
                  icon: Icons.vpn_key_outlined,
                  title: '配对码',
                  subtitle: qsConfig.token.isEmpty ? '未配置，在电脑配对页查看' : qsConfig.token,
                  onTap: () => _editQingsongTokenDialog(qsConfig.token),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  key: const ValueKey('more_qingsong_test_row'),
                  icon: Icons.wifi_tethering_outlined,
                  title: '测试连接',
                  trailing: _testingQingsong
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          qsConfig.isConfigured ? '检测' : '未配对',
                          style: TextStyle(
                            color: qsConfig.isConfigured
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                  onTap: _testingQingsong ? null : _testQingsongConnection,
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  key: const ValueKey('more_qingsong_sync_row'),
                  icon: Icons.sync,
                  title: '立即同步日程',
                  subtitle: _formatSyncSubtitle(qsConfig, qsSync),
                  trailing: qsSync.syncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: qsSync.syncing ? null : _syncQingsongNow,
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  key: const ValueKey('more_qingsong_autosync_row'),
                  icon: Icons.autorenew,
                  title: '打开首页自动同步',
                  trailing: Switch(
                    value: qsConfig.autoSync,
                    onChanged: (v) =>
                        ref.read(qingsongConfigProvider.notifier).setAutoSync(v),
                  ),
                  onTap: () => ref
                      .read(qingsongConfigProvider.notifier)
                      .setAutoSync(!qsConfig.autoSync),
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
            child: Column(
              children: [
                _MoreRow(
                  key: const ValueKey('more_settings_row'),
                  icon: Icons.tune,
                  title: '应用设置',
                  subtitle: '项目排序、卡片风格布局、日历颜色、密码与备份',
                  onTap: () => context.push(Routes.settings),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _MoreRow(
                  icon: Icons.info_outline,
                  title: '开源图标与数据说明',
                  onTap: _showAttributionDialog,
                ),
              ],
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

/// Owns its [TextEditingController] so disposal waits until the dialog exit animation finishes.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.description,
    required this.initialValue,
    required this.hintText,
    this.fieldKey,
    this.clearLabel,
    this.uppercase = false,
    this.presets = const [],
  });

  final String title;
  final String description;
  final String initialValue;
  final String hintText;
  final Key? fieldKey;
  final String? clearLabel;
  final bool uppercase;
  final List<({String label, String value})> presets;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          if (widget.presets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final preset in widget.presets)
                  ActionChip(
                    label: Text(preset.label, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.inputFill,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _controller.text = preset.value;
                      _controller.selection = TextSelection.collapsed(offset: preset.value.length);
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: widget.fieldKey,
            controller: _controller,
            autofocus: true,
            textCapitalization:
                widget.uppercase ? TextCapitalization.characters : TextCapitalization.none,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        if (widget.clearLabel != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(widget.clearLabel!),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            Navigator.of(context).pop(widget.uppercase ? value.toUpperCase() : value);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
