import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bundled sound effects played via Android SoundPool when `soundEnabled` is true.
enum AppSound {
  checkIn('checkin'),
  uncheck('uncheck'),
  perfectDay('perfect_day'),
  achievement('achievement');

  const AppSound(this.wireName);

  final String wireName;
}

/// Platform bridge for Android gallery image picking, native SoundPool SFX, & home-screen widget sync.
class NativeBridge {
  const NativeBridge();

  static const _channel = MethodChannel('com.ibetter.clone.ibetter/native_bridge');

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether the current runtime supports picking custom photos directly from a gallery.
  bool get supportsGalleryPicker => _isAndroid;

  /// Opens the Android system photo picker for [slot] (`avatar` or `cover`),
  /// copies the selected file into app-private storage, and returns its path.
  Future<String?> pickImage(String slot) async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('pickImage', {'slot': slot});
    } catch (e) {
      debugPrint('NativeBridge.pickImage failed: $e');
      return null;
    }
  }

  /// Plays a bundled short feedback sound on Android (`SoundPool`).
  Future<void> playSound(AppSound sound) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('playSound', {'type': sound.wireName});
    } catch (e) {
      debugPrint('NativeBridge.playSound failed: $e');
    }
  }

  /// Pushes today's habit summary to the Android home-screen AppWidget.
  Future<void> updateHomeWidget({
    required String title,
    required List<String> lines,
    required int doneCount,
    required int totalCount,
  }) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('updateHomeWidget', {
        'title': title,
        'lines': lines,
        'doneCount': doneCount,
        'totalCount': totalCount,
      });
    } catch (e) {
      debugPrint('NativeBridge.updateHomeWidget failed: $e');
    }
  }
}

final nativeBridgeProvider = Provider<NativeBridge>((ref) => const NativeBridge());
