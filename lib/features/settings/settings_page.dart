import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/platform/native_bridge.dart';
import '../../core/prefs/app_prefs.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../me/edit_profile_sheet.dart';
import '../reminders/notification_service.dart';
import 'widgets/backup_sheet.dart';
import 'widgets/style_preview_widgets.dart';

/// Full "设置" center matching screenshots 2, 4, 5, 7, 8, 9.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _cardStyleExpanded = false;
  bool _achievementStyleExpanded = true;
  bool _perfectDayStyleExpanded = true;
  bool _reportStyleExpanded = true;

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickReportTime(AppPrefs prefs) async {
    final initial = TimeOfDay(
      hour: prefs.reportReminderMinutes ~/ 60,
      minute: prefs.reportReminderMinutes % 60,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    await ref.read(appPrefsProvider.notifier).setReportReminder(minutesOfDay: minutes);
    await ref.read(notificationServiceProvider).syncReportReminder(
          enabled: prefs.reportReminderEnabled,
          minutesOfDay: minutes,
        );
  }

  Future<void> _toggleReportReminder(bool enabled, AppPrefs prefs) async {
    final notif = ref.read(notificationServiceProvider);
    if (enabled) {
      await notif.requestPermission();
    }
    await ref.read(appPrefsProvider.notifier).setReportReminder(enabled: enabled);
    await notif.syncReportReminder(
      enabled: enabled,
      minutesOfDay: prefs.reportReminderMinutes,
    );
  }

  Future<void> _pickWeekStartDay(AppPrefs prefs) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                '每周第一天为',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('星期日'),
              trailing: !prefs.weekStartsOnMonday
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('星期一'),
              trailing: prefs.weekStartsOnMonday
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    await ref.read(appPrefsProvider.notifier).setWeekStartsOnMonday(chosen);
  }

  Future<void> _toggleSound(bool enabled) async {
    await ref.read(appPrefsProvider.notifier).setSoundEnabled(enabled);
    if (enabled) {
      unawaited(ref.read(nativeBridgeProvider).playSound(AppSound.checkIn));
    }
  }

  Future<void> _showNotificationTroubleshoot() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('收不到推送？排查方案'),
        content: const Text(
          '1. 系统设置 → 应用管理 → 轻松打卡 → 通知权限：确认已开启允许通知。\n'
          '2. 电池管理：将「轻松打卡」设为「无限制 / 允许后台运行」，避免后台被系统清理。\n'
          '3. 开机自启动：开启自启动权限，确保手机重启后自动恢复所有习惯提醒。\n\n'
          '可点击下方「发送测试通知」，2 秒后检查状态栏是否收到通知。',
          style: TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await ref.read(notificationServiceProvider).showTestNotification();
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              _showSnack(ok ? '测试通知将在 2 秒后送达，请留意顶部通知栏' : '请先在系统设置中授予通知权限');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('发送测试通知'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPrefsProvider).asData?.value ?? const AppPrefs();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '设置',
        leading: PillIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 6, bottom: 32),
        children: [
          // Top profile summary card
          SectionCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      ProfileAvatar(prefs: prefs, size: 50, borderWidth: 1.5),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prefs.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              prefs.handle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => showBackupSheet(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.divider),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: const Size(0, 34),
                        ),
                        child: const Text('备份数据', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => showEditProfileSheet(context, ref),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, size: 16, color: AppColors.textHint),
                                SizedBox(width: 6),
                                Text(
                                  '修改资料',
                                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push(Routes.passcode),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_outlined, size: 16, color: AppColors.textHint),
                                SizedBox(width: 6),
                                Text(
                                  '隐私与安全',
                                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 项目 section
          const _SectionHeader('项目'),
          _GroupContainer(
            children: [
              _SettingsRow(
                key: const ValueKey('settings_sort_row'),
                title: '我的项目排序',
                onTap: () => context.push(Routes.projectSort),
              ),
              const _HairlineDivider(),
              _SettingsRow(
                key: const ValueKey('settings_card_style_row'),
                title: '选择卡片风格',
                valueText: prefs.cardStyle.label,
                expanded: _cardStyleExpanded,
                onTap: () => setState(() => _cardStyleExpanded = !_cardStyleExpanded),
              ),
              if (_cardStyleExpanded)
                CardStyleChoiceRow(
                  selected: prefs.cardStyle,
                  onSelected: (s) => ref.read(appPrefsProvider.notifier).setCardStyle(s),
                ),
              const _HairlineDivider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '选择卡片布局',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),
              ),
              CardLayoutChoiceRow(
                selected: prefs.cardLayout,
                onSelected: (l) => ref.read(appPrefsProvider.notifier).setCardLayout(l),
              ),
              const _HairlineDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '日历达成颜色',
                          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const Spacer(),
                        Text(
                          prefs.calendarDoneTheme.label,
                          style: const TextStyle(fontSize: 15, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final theme in CalendarDoneTheme.values)
                          _ColorThemeSwatch(
                            key: ValueKey('calendar_theme_${theme.name}'),
                            theme: theme,
                            selected: prefs.calendarDoneTheme == theme,
                            onTap: () => ref
                                .read(appPrefsProvider.notifier)
                                .setCalendarDoneTheme(theme),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 隐私 section
          const _SectionHeader('隐私'),
          _GroupContainer(
            children: [
              _SettingsRow(
                key: const ValueKey('settings_passcode_row'),
                title: '密码保护',
                valueText: prefs.hasActivePasscode ? '已开启' : '未开启',
                valueColor:
                    prefs.hasActivePasscode ? AppColors.primary : AppColors.textSecondary,
                onTap: () => context.push(Routes.passcode),
              ),
            ],
          ),

          // 通知 section
          const _SectionHeader('通知'),
          _GroupContainer(
            children: [
              _SettingsRow(
                key: const ValueKey('settings_report_reminder_row'),
                title: '每周/月成绩单提醒',
                trailing: Switch(
                  value: prefs.reportReminderEnabled,
                  onChanged: (v) => _toggleReportReminder(v, prefs),
                ),
                onTap: () => _toggleReportReminder(!prefs.reportReminderEnabled, prefs),
              ),
              const _HairlineDivider(),
              _SettingsRow(
                key: const ValueKey('settings_report_time_row'),
                title: '提醒时间',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prefs.reportReminderTimeLabel,
                      style: const TextStyle(fontSize: 16, color: AppColors.primary),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  ],
                ),
                onTap: () => _pickReportTime(prefs),
              ),
              const _HairlineDivider(),
              _SettingsRow(
                key: const ValueKey('settings_troubleshoot_row'),
                title: '收不到推送？点此查看解决方案',
                onTap: _showNotificationTroubleshoot,
              ),
            ],
          ),

          // 挂件 section
          const _SectionHeader('挂件'),
          _GroupContainer(
            children: [
              _SettingsRow(
                key: const ValueKey('settings_widget_row'),
                title: '调整桌面小部件',
                onTap: () => context.push(Routes.widgetGuide),
              ),
            ],
          ),

          // 显示和效果 section
          const _SectionHeader('显示和效果'),
          _GroupContainer(
            children: [
              _SettingsRow(
                key: const ValueKey('settings_week_start_row'),
                title: '每周第一天为',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prefs.weekStartsOnMonday ? '星期一' : '星期日',
                      style: const TextStyle(fontSize: 16, color: AppColors.primary),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  ],
                ),
                onTap: () => _pickWeekStartDay(prefs),
              ),
              const _HairlineDivider(),
              _SettingsRow(
                key: const ValueKey('settings_sound_row'),
                title: '音效',
                trailing: Switch(
                  value: prefs.soundEnabled,
                  onChanged: _toggleSound,
                ),
                onTap: () => _toggleSound(!prefs.soundEnabled),
              ),
              const _HairlineDivider(),
              _SettingsRow(
                key: const ValueKey('settings_achievement_style_row'),
                title: '成就显示样式',
                valueText: prefs.achievementDisplayStyle.label,
                expanded: _achievementStyleExpanded,
                onTap: () => setState(
                    () => _achievementStyleExpanded = !_achievementStyleExpanded),
              ),
              if (_achievementStyleExpanded)
                CelebrationStyleChoiceRow(
                  prefixKey: 'achievement_style',
                  selected: prefs.achievementDisplayStyle,
                  onSelected: (s) => ref
                      .read(appPrefsProvider.notifier)
                      .setAchievementDisplayStyle(s),
                ),
              const _HairlineDivider(),
              _SettingsRow(
                key: const ValueKey('settings_perfect_day_style_row'),
                title: '完美的一天显示样式',
                valueText: prefs.perfectDayDisplayStyle.label,
                expanded: _perfectDayStyleExpanded,
                onTap: () => setState(
                    () => _perfectDayStyleExpanded = !_perfectDayStyleExpanded),
              ),
              if (_perfectDayStyleExpanded)
                CelebrationStyleChoiceRow(
                  prefixKey: 'perfect_day_style',
                  selected: prefs.perfectDayDisplayStyle,
                  onSelected: (s) => ref
                      .read(appPrefsProvider.notifier)
                      .setPerfectDayDisplayStyle(s),
                ),
              const _HairlineDivider(),
              _SettingsRow(
                key: const ValueKey('settings_report_style_row'),
                title: '新成绩单显示样式',
                valueText: prefs.reportDisplayStyle.label,
                expanded: _reportStyleExpanded,
                onTap: () =>
                    setState(() => _reportStyleExpanded = !_reportStyleExpanded),
              ),
              if (_reportStyleExpanded)
                CelebrationStyleChoiceRow(
                  prefixKey: 'report_style',
                  selected: prefs.reportDisplayStyle,
                  onSelected: (s) =>
                      ref.read(appPrefsProvider.notifier).setReportDisplayStyle(s),
                ),
            ],
          ),

          // 数据 section
          const _SectionHeader('数据'),
          _GroupContainer(
            children: [
              _SettingsRow(
                key: const ValueKey('settings_backup_row'),
                title: '备份数据',
                onTap: () => showBackupSheet(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

class _GroupContainer extends StatelessWidget {
  const _GroupContainer({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.7, color: AppColors.divider);
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.title,
    this.valueText,
    this.valueColor,
    this.trailing,
    this.expanded,
    this.onTap,
  });

  final String title;
  final String? valueText;
  final Color? valueColor;
  final Widget? trailing;
  final bool? expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (valueText != null)
                Text(
                  valueText!,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? AppColors.primary,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                expanded == null
                    ? Icons.chevron_right
                    : (expanded! ? Icons.keyboard_arrow_down : Icons.chevron_right),
                color: expanded == true ? AppColors.primary : const Color(0xFFD0D0D0),
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorThemeSwatch extends StatelessWidget {
  const _ColorThemeSwatch({
    super.key,
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final CalendarDoneTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGoldStar = theme == CalendarDoneTheme.goldStar;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.color,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: AppColors.primary, width: 2.5)
              : null,
        ),
        alignment: Alignment.center,
        child: isGoldStar
            ? Icon(
                Icons.star_rounded,
                size: 28,
                color: selected ? const Color(0xFF8A5A00) : const Color(0xFFFFB300),
              )
            : (selected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null),
      ),
    );
  }
}
