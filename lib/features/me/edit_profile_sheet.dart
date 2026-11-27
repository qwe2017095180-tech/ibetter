import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../core/platform/native_bridge.dart';
import '../../core/prefs/app_prefs.dart';
import '../../core/providers.dart';
import '../icon_picker/icon_registry.dart';

/// Preset cover definitions used when no custom cover photo is selected.
class CoverPreset {
  const CoverPreset({
    required this.id,
    required this.label,
    required this.colors,
    required this.accentColor,
  });

  final String id;
  final String label;
  final List<Color> colors;
  final Color accentColor;
}

const List<CoverPreset> kCoverPresets = [
  CoverPreset(
    id: 'sunset_harbor',
    label: '海湾暮光',
    colors: [Color(0xFF1F2A44), Color(0xFF3E4E6C), Color(0xFF7D5A50)],
    accentColor: Color(0xFFFFB74D),
  ),
  CoverPreset(
    id: 'starry_night',
    label: '深空星夜',
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    accentColor: Color(0xFF81D4FA),
  ),
  CoverPreset(
    id: 'mint_dawn',
    label: '晴空初晓',
    colors: [Color(0xFF2B5876), Color(0xFF4E4376), Color(0xFF6B77B4)],
    accentColor: Color(0xFFA5F3FC),
  ),
  CoverPreset(
    id: 'peach_sky',
    label: '暖阳云海',
    colors: [Color(0xFF4A3B59), Color(0xFF9E5A63), Color(0xFFE08E6D)],
    accentColor: Color(0xFFFFE082),
  ),
];

const List<String> kAvatarPresets = [
  'achievement/star',
  'achievement/trophy',
  'achievement/rocket',
  'achievement/crown',
  'mind/smiling_face_with_hearts',
  'mind/butterfly',
  'study/book',
  'health/crescent_moon',
];

CoverPreset resolveCoverPreset(String id) {
  for (final p in kCoverPresets) {
    if (p.id == id) return p;
  }
  return kCoverPresets.first;
}

/// Renders the profile header cover banner (local photo if available, else scenic preset).
class ProfileCoverBanner extends StatelessWidget {
  const ProfileCoverBanner({
    super.key,
    required this.presetId,
    this.imagePath,
    this.height = 176,
  });

  final String presetId;
  final String? imagePath;
  final double height;

  @override
  Widget build(BuildContext context) {
    final preset = resolveCoverPreset(presetId);
    final file = (!kIsWeb && imagePath != null && imagePath!.isNotEmpty)
        ? File(imagePath!)
        : null;
    final hasFile = file != null && file.existsSync();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: hasFile
          ? Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PresetCoverArtwork(preset: preset),
            )
          : _PresetCoverArtwork(preset: preset),
    );
  }
}

class _PresetCoverArtwork extends StatelessWidget {
  const _PresetCoverArtwork({required this.preset});

  final CoverPreset preset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: preset.colors,
        ),
      ),
      child: CustomPaint(
        painter: _HarborHorizonPainter(accentColor: preset.accentColor),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HarborHorizonPainter extends CustomPainter {
  const _HarborHorizonPainter({required this.accentColor});

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Warm glowing dome/moon reflection on the left-center.
    final center = Offset(size.width * 0.28, size.height * 0.62);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.9),
          accentColor.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.25));
    canvas.drawCircle(center, size.width * 0.25, glowPaint);

    // Silhouette horizon + water line.
    final waterY = size.height * 0.72;
    canvas.drawRect(
      Rect.fromLTWH(0, waterY, size.width, size.height - waterY),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    final shorePath = Path()
      ..moveTo(0, waterY)
      ..quadraticBezierTo(size.width * 0.14, waterY - 14, size.width * 0.28, waterY)
      ..lineTo(size.width * 0.28, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(shorePath, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _HarborHorizonPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}

/// Renders the user's circular avatar from custom photo or preset HabitIcon.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.prefs,
    this.size = 112,
    this.borderWidth = 3.5,
    this.borderColor = Colors.white,
  });

  final AppPrefs prefs;
  final double size;
  final double borderWidth;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final path = prefs.avatarImagePath;
    final file = (!kIsWeb && path != null && path.isNotEmpty) ? File(path) : null;
    final hasFile = file != null && file.existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1D2C4D),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasFile
            ? Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: HabitIcon(prefs.avatarPreset, size: size * 0.62),
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF283E6B), Color(0xFF14213D)],
                  ),
                ),
                alignment: Alignment.center,
                child: HabitIcon(prefs.avatarPreset, size: size * 0.62),
              ),
      ),
    );
  }
}

/// Opens a modal bottom sheet to edit nickname, handle, bio, avatar, and cover.
Future<void> showEditProfileSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(appPrefsProvider).asData?.value ?? const AppPrefs();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditProfileSheet(initialPrefs: current),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.initialPrefs});

  final AppPrefs initialPrefs;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nickCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _bioCtrl;
  late String _avatarPreset;
  late String _coverPreset;
  String? _avatarImagePath;
  String? _coverImagePath;
  bool _clearAvatar = false;
  bool _clearCover = false;

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController(text: widget.initialPrefs.nickname);
    _handleCtrl = TextEditingController(text: widget.initialPrefs.handle);
    _bioCtrl = TextEditingController(text: widget.initialPrefs.bio);
    _avatarPreset = widget.initialPrefs.avatarPreset;
    _coverPreset = widget.initialPrefs.coverPreset;
    _avatarImagePath = widget.initialPrefs.avatarImagePath;
    _coverImagePath = widget.initialPrefs.coverImagePath;
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _handleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(String slot) async {
    final path = await ref.read(nativeBridgeProvider).pickImage(slot);
    if (!mounted || path == null || path.isEmpty) return;
    setState(() {
      if (slot == 'avatar') {
        _avatarImagePath = path;
        _clearAvatar = false;
      } else {
        _coverImagePath = path;
        _clearCover = false;
      }
    });
  }

  Future<void> _save() async {
    final nick = _nickCtrl.text.trim();
    var handle = _handleCtrl.text.trim();
    if (handle.isNotEmpty && !handle.startsWith('@')) {
      handle = '@$handle';
    }
    final bio = _bioCtrl.text.trim();

    await ref.read(appPrefsProvider.notifier).updateProfile(
          nickname: nick.isEmpty ? '打卡达人' : nick,
          handle: handle.isEmpty ? '@qingsong' : handle,
          bio: bio.isEmpty ? '每一天都在变得更好。' : bio,
          avatarPreset: _avatarPreset,
          avatarImagePath: _avatarImagePath,
          clearAvatarImage: _clearAvatar,
          coverPreset: _coverPreset,
          coverImagePath: _coverImagePath,
          clearCoverImage: _clearCover,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  '修改资料',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
                ),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('保存'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('profile_nickname_input'),
              controller: _nickCtrl,
              maxLength: 16,
              decoration: const InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('profile_handle_input'),
              controller: _handleCtrl,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: '账号 ID',
                hintText: '@qingsong',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('profile_bio_input'),
              controller: _bioCtrl,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: '个性签名',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('头像样式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_avatarImagePath != null && !_clearAvatar)
                  TextButton(
                    onPressed: () => setState(() {
                      _avatarImagePath = null;
                      _clearAvatar = true;
                    }),
                    child: const Text('恢复预设'),
                  ),
                TextButton.icon(
                  onPressed: () => _pickPhoto('avatar'),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('从相册选'),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final key in kAvatarPresets)
                  GestureDetector(
                    onTap: () => setState(() {
                      _avatarPreset = key;
                      _avatarImagePath = null;
                      _clearAvatar = true;
                    }),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1D2C4D),
                        border: (_avatarImagePath == null && _avatarPreset == key)
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: HabitIcon(key, size: 30),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('背景封面', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_coverImagePath != null && !_clearCover)
                  TextButton(
                    onPressed: () => setState(() {
                      _coverImagePath = null;
                      _clearCover = true;
                    }),
                    child: const Text('恢复预设'),
                  ),
                TextButton.icon(
                  onPressed: () => _pickPhoto('cover'),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('从相册选'),
                ),
              ],
            ),
            Row(
              children: [
                for (var i = 0; i < kCoverPresets.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _coverPreset = kCoverPresets[i].id;
                        _coverImagePath = null;
                        _clearCover = true;
                      }),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(colors: kCoverPresets[i].colors),
                          border: (_coverImagePath == null &&
                                  _coverPreset == kCoverPresets[i].id)
                              ? Border.all(color: AppColors.primary, width: 2.5)
                              : null,
                        ),
                        child: Text(
                          kCoverPresets[i].label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
