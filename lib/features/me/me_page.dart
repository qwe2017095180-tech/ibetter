import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/platform/native_bridge.dart';
import '../../core/prefs/app_prefs.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../icon_picker/icon_registry.dart';
import 'edit_profile_sheet.dart';
import 'inbox_items.dart';

/// "我的" tab: cover banner, overlapping avatar, profile bio, KPI summary, and inbox.
class MePage extends ConsumerWidget {
  const MePage({super.key});

  Future<void> _openInboxMessage(
    BuildContext context,
    WidgetRef ref,
    InboxMessage msg,
  ) async {
    await ref.read(appPrefsProvider.notifier).markInboxRead(msg.id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const HabitIcon('achievement/sparkles', size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${msg.sender} (${msg.handle}) · ${msg.date}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              msg.body,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWallpaper(BuildContext context, WidgetRef ref) async {
    final bridge = ref.read(nativeBridgeProvider);
    if (!bridge.supportsGalleryPicker) {
      await showEditProfileSheet(context, ref);
      return;
    }
    final path = await bridge.pickImage('cover');
    if (!context.mounted) return;
    if (path != null && path.isNotEmpty) {
      await ref.read(appPrefsProvider.notifier).updateProfile(coverImagePath: path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('已更换背景壁纸')));
    }
  }

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final bridge = ref.read(nativeBridgeProvider);
    if (!bridge.supportsGalleryPicker) {
      await showEditProfileSheet(context, ref);
      return;
    }
    final path = await bridge.pickImage('avatar');
    if (!context.mounted) return;
    if (path != null && path.isNotEmpty) {
      await ref.read(appPrefsProvider.notifier).updateProfile(avatarImagePath: path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('已更新头像')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPrefsProvider).asData?.value ?? const AppPrefs();
    final stats = ref.watch(overallStatsProvider);
    final unreadCount = kInboxMessages
        .where((m) => !prefs.readInboxIds.contains(m.id))
        .length;

    const coverHeight = 184.0;
    const avatarSize = 112.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          SizedBox(
            height: coverHeight + avatarSize / 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  key: const ValueKey('me_cover_tap'),
                  onTap: () => _pickWallpaper(context, ref),
                  child: ProfileCoverBanner(
                    presetId: prefs.coverPreset,
                    imagePath: prefs.coverImagePath,
                    height: coverHeight,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: coverHeight - 40,
                  child: Material(
                    color: const Color(0x78000000),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      key: const ValueKey('me_change_cover_button'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _pickWallpaper(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              prefs.coverImagePath == null ? '自选壁纸' : '更换壁纸',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: coverHeight - avatarSize / 2,
                  child: Center(
                    child: GestureDetector(
                      key: const ValueKey('me_avatar_tap'),
                      onTap: () => _pickAvatar(context, ref),
                      child: ProfileAvatar(prefs: prefs, size: avatarSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  prefs.nickname,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prefs.handle,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '“ ',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: prefs.bio,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(
                        text: ' ”',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MeActionPill(
                      key: const ValueKey('me_edit_profile_button'),
                      onTap: () => showEditProfileSheet(context, ref),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 17, color: AppColors.textHint),
                          SizedBox(width: 6),
                          Text(
                            '修改资料',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MeActionPill(
                      key: const ValueKey('me_settings_button'),
                      tooltip: '设置',
                      horizontalPadding: 18,
                      onTap: () => context.push(Routes.settings),
                      child: const Icon(
                        Icons.settings,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _KpiItem(label: '项目数', value: '${stats.projectCount}')),
                Expanded(child: _KpiItem(label: '记录天数', value: '${stats.recordedDays}')),
                Expanded(child: _KpiItem(label: '达成次数', value: '${stats.totalCompletions}')),
                Expanded(child: _KpiItem(label: '最长连续', value: '${stats.longestStreak}')),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Text(
                  '我的收件箱',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  unreadCount > 0 ? '$unreadCount未读' : '全部已读',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (final msg in kInboxMessages)
            _InboxCard(
              message: msg,
              isUnread: !prefs.readInboxIds.contains(msg.id),
              onTap: () => _openInboxMessage(context, ref, msg),
            ),
        ],
      ),
    );
  }
}

class _MeActionPill extends StatelessWidget {
  const _MeActionPill({
    super.key,
    required this.onTap,
    required this.child,
    this.tooltip,
    this.horizontalPadding = 20,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? tooltip;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                offset: Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.message,
    required this.isUnread,
    required this.onTap,
  });

  final InboxMessage message;
  final bool isUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: InkWell(
        key: ValueKey('inbox_card_${message.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const HabitIcon('achievement/sparkles', size: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.sender,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          message.handle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    message.date,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (isUnread) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.badge,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
