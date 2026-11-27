import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight local preferences persisted outside SQLite (no schema bump needed).
class AppPrefs {
  const AppPrefs({
    this.shareCount = 0,
    this.lastShareDate,
    this.seenAchievementCount = 0,
  });

  /// Number of times the user shared a habit, report card, or achievement.
  final int shareCount;

  /// Latest `yyyy-MM-dd` when the user shared something (for 友谊勋章).
  final String? lastShareDate;

  /// Total achievement count already viewed on the Achievements tab (drives Trophy red badge).
  final int seenAchievementCount;

  AppPrefs copyWith({
    int? shareCount,
    String? lastShareDate,
    int? seenAchievementCount,
  }) =>
      AppPrefs(
        shareCount: shareCount ?? this.shareCount,
        lastShareDate: lastShareDate ?? this.lastShareDate,
        seenAchievementCount: seenAchievementCount ?? this.seenAchievementCount,
      );

  Map<String, dynamic> toJson() => {
        'shareCount': shareCount,
        'lastShareDate': lastShareDate,
        'seenAchievementCount': seenAchievementCount,
      };

  factory AppPrefs.fromJson(Map<String, dynamic> json) => AppPrefs(
        shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
        lastShareDate: json['lastShareDate'] as String?,
        seenAchievementCount: (json['seenAchievementCount'] as num?)?.toInt() ?? 0,
      );
}

abstract class AppPrefsStore {
  Future<AppPrefs> load();
  Future<void> save(AppPrefs prefs);
}

class MemoryAppPrefsStore implements AppPrefsStore {
  MemoryAppPrefsStore([this._prefs = const AppPrefs()]);
  AppPrefs _prefs;

  @override
  Future<AppPrefs> load() async => _prefs;

  @override
  Future<void> save(AppPrefs prefs) async => _prefs = prefs;
}

class FileAppPrefsStore implements AppPrefsStore {
  static const _fileName = 'app_prefs.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<AppPrefs> load() async {
    if (kIsWeb) return const AppPrefs();
    try {
      final f = await _file();
      if (!await f.exists()) return const AppPrefs();
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map<String, dynamic>) {
        return AppPrefs.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Failed to load app prefs: $e');
    }
    return const AppPrefs();
  }

  @override
  Future<void> save(AppPrefs prefs) async {
    if (kIsWeb) return;
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(prefs.toJson()));
    } catch (e) {
      debugPrint('Failed to save app prefs: $e');
    }
  }
}
