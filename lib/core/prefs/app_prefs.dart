import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// Card visual style on Home page.
enum CardStyle {
  colorful,
  white;

  String get label => switch (this) {
        CardStyle.colorful => '彩色',
        CardStyle.white => '纯白',
      };
}

/// Card grid layout on Home page.
enum CardLayout {
  standard,
  compact,
  ultraCompact;

  String get label => switch (this) {
        CardLayout.standard => '标准',
        CardLayout.compact => '紧凑',
        CardLayout.ultraCompact => '超紧凑',
      };
}

/// All-done calendar cell highlight color/style on Home page.
enum CalendarDoneTheme {
  green,
  pink,
  blue,
  orange,
  cyan,
  goldStar;

  String get label => switch (this) {
        CalendarDoneTheme.green => '默认 · 绿色',
        CalendarDoneTheme.pink => '樱花粉',
        CalendarDoneTheme.blue => '天空蓝',
        CalendarDoneTheme.orange => '活力橙',
        CalendarDoneTheme.cyan => '薄荷青',
        CalendarDoneTheme.goldStar => '星光金',
      };

  Color get color => switch (this) {
        CalendarDoneTheme.green => const Color(0xFF34B853),
        CalendarDoneTheme.pink => const Color(0xFFFF78A5),
        CalendarDoneTheme.blue => const Color(0xFF4C9AFF),
        CalendarDoneTheme.orange => const Color(0xFFFF9F29),
        CalendarDoneTheme.cyan => const Color(0xFF56CCF2),
        CalendarDoneTheme.goldStar => const Color(0xFFFFE066),
      };

  Color get textColor =>
      this == CalendarDoneTheme.goldStar ? const Color(0xFF8A5A00) : Colors.white;
}

/// Presentation style for achievements, perfect day, and report notifications.
enum CelebrationStyle {
  card,
  banner;

  String get label => switch (this) {
        CelebrationStyle.card => '卡片',
        CelebrationStyle.banner => '横幅',
      };
}

/// Lightweight local preferences & user profile persisted outside SQLite.
class AppPrefs {
  const AppPrefs({
    this.shareCount = 0,
    this.lastShareDate,
    this.seenAchievementCount = 0,
    this.nickname = '打卡达人',
    this.handle = '@qingsong',
    this.bio = '每一天都在变得更好。',
    this.avatarPreset = 'achievement/star',
    this.avatarImagePath,
    this.coverPreset = 'sunset_harbor',
    this.coverImagePath,
    this.readInboxIds = const [],
    this.cardStyle = CardStyle.colorful,
    this.cardLayout = CardLayout.standard,
    this.calendarDoneTheme = CalendarDoneTheme.green,
    this.weekStartsOnMonday = false,
    this.soundEnabled = true,
    this.achievementDisplayStyle = CelebrationStyle.card,
    this.perfectDayDisplayStyle = CelebrationStyle.card,
    this.reportDisplayStyle = CelebrationStyle.card,
    this.reportReminderEnabled = false,
    this.reportReminderMinutes = 690, // 11:30
    this.passcodeEnabled = false,
    this.passcode,
  });

  /// Number of times the user shared a habit, report card, or achievement.
  final int shareCount;

  /// Latest `yyyy-MM-dd` when the user shared something (for 友谊勋章).
  final String? lastShareDate;

  /// Total achievement count already viewed on the Achievements tab (drives Trophy red badge).
  final int seenAchievementCount;

  // Profile
  final String nickname;
  final String handle;
  final String bio;
  final String avatarPreset;
  final String? avatarImagePath;
  final String coverPreset;
  final String? coverImagePath;
  final List<String> readInboxIds;

  // Appearance & layout
  final CardStyle cardStyle;
  final CardLayout cardLayout;
  final CalendarDoneTheme calendarDoneTheme;
  final bool weekStartsOnMonday;
  final bool soundEnabled;

  // Display styles
  final CelebrationStyle achievementDisplayStyle;
  final CelebrationStyle perfectDayDisplayStyle;
  final CelebrationStyle reportDisplayStyle;

  // Notifications & privacy
  final bool reportReminderEnabled;
  final int reportReminderMinutes;
  final bool passcodeEnabled;
  final String? passcode;

  String get reportReminderTimeLabel {
    final m = reportReminderMinutes.clamp(0, 1439);
    final hh = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool get hasActivePasscode =>
      passcodeEnabled && passcode != null && passcode!.length == 4;

  AppPrefs copyWith({
    int? shareCount,
    String? lastShareDate,
    int? seenAchievementCount,
    String? nickname,
    String? handle,
    String? bio,
    String? avatarPreset,
    String? avatarImagePath,
    bool clearAvatarImage = false,
    String? coverPreset,
    String? coverImagePath,
    bool clearCoverImage = false,
    List<String>? readInboxIds,
    CardStyle? cardStyle,
    CardLayout? cardLayout,
    CalendarDoneTheme? calendarDoneTheme,
    bool? weekStartsOnMonday,
    bool? soundEnabled,
    CelebrationStyle? achievementDisplayStyle,
    CelebrationStyle? perfectDayDisplayStyle,
    CelebrationStyle? reportDisplayStyle,
    bool? reportReminderEnabled,
    int? reportReminderMinutes,
    bool? passcodeEnabled,
    String? passcode,
    bool clearPasscode = false,
  }) =>
      AppPrefs(
        shareCount: shareCount ?? this.shareCount,
        lastShareDate: lastShareDate ?? this.lastShareDate,
        seenAchievementCount: seenAchievementCount ?? this.seenAchievementCount,
        nickname: nickname ?? this.nickname,
        handle: handle ?? this.handle,
        bio: bio ?? this.bio,
        avatarPreset: avatarPreset ?? this.avatarPreset,
        avatarImagePath:
            clearAvatarImage ? null : (avatarImagePath ?? this.avatarImagePath),
        coverPreset: coverPreset ?? this.coverPreset,
        coverImagePath:
            clearCoverImage ? null : (coverImagePath ?? this.coverImagePath),
        readInboxIds: readInboxIds ?? this.readInboxIds,
        cardStyle: cardStyle ?? this.cardStyle,
        cardLayout: cardLayout ?? this.cardLayout,
        calendarDoneTheme: calendarDoneTheme ?? this.calendarDoneTheme,
        weekStartsOnMonday: weekStartsOnMonday ?? this.weekStartsOnMonday,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        achievementDisplayStyle:
            achievementDisplayStyle ?? this.achievementDisplayStyle,
        perfectDayDisplayStyle:
            perfectDayDisplayStyle ?? this.perfectDayDisplayStyle,
        reportDisplayStyle: reportDisplayStyle ?? this.reportDisplayStyle,
        reportReminderEnabled:
            reportReminderEnabled ?? this.reportReminderEnabled,
        reportReminderMinutes:
            reportReminderMinutes ?? this.reportReminderMinutes,
        passcodeEnabled: passcodeEnabled ?? this.passcodeEnabled,
        passcode: clearPasscode ? null : (passcode ?? this.passcode),
      );

  Map<String, dynamic> toJson() => {
        'shareCount': shareCount,
        'lastShareDate': lastShareDate,
        'seenAchievementCount': seenAchievementCount,
        'nickname': nickname,
        'handle': handle,
        'bio': bio,
        'avatarPreset': avatarPreset,
        'avatarImagePath': avatarImagePath,
        'coverPreset': coverPreset,
        'coverImagePath': coverImagePath,
        'readInboxIds': readInboxIds,
        'cardStyle': cardStyle.name,
        'cardLayout': cardLayout.name,
        'calendarDoneTheme': calendarDoneTheme.name,
        'weekStartsOnMonday': weekStartsOnMonday,
        'soundEnabled': soundEnabled,
        'achievementDisplayStyle': achievementDisplayStyle.name,
        'perfectDayDisplayStyle': perfectDayDisplayStyle.name,
        'reportDisplayStyle': reportDisplayStyle.name,
        'reportReminderEnabled': reportReminderEnabled,
        'reportReminderMinutes': reportReminderMinutes,
        'passcodeEnabled': passcodeEnabled,
        'passcode': passcode,
      };

  static T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
    if (raw is String) {
      for (final v in values) {
        if (v.name == raw) return v;
      }
    }
    return fallback;
  }

  factory AppPrefs.fromJson(Map<String, dynamic> json) {
    final readRaw = json['readInboxIds'];
    final readIds = readRaw is List
        ? readRaw.whereType<String>().toList()
        : const <String>[];
    final rawNick = (json['nickname'] as String?)?.trim();
    final rawHandle = (json['handle'] as String?)?.trim();
    return AppPrefs(
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      lastShareDate: json['lastShareDate'] as String?,
      seenAchievementCount: (json['seenAchievementCount'] as num?)?.toInt() ?? 0,
      nickname: (rawNick != null && rawNick.isNotEmpty) ? rawNick : '打卡达人',
      handle: (rawHandle != null && rawHandle.isNotEmpty) ? rawHandle : '@qingsong',
      bio: (json['bio'] as String?) ?? '每一天都在变得更好。',
      avatarPreset: (json['avatarPreset'] as String?) ?? 'achievement/star',
      avatarImagePath: json['avatarImagePath'] as String?,
      coverPreset: (json['coverPreset'] as String?) ?? 'sunset_harbor',
      coverImagePath: json['coverImagePath'] as String?,
      readInboxIds: readIds,
      cardStyle:
          _enumByName(CardStyle.values, json['cardStyle'], CardStyle.colorful),
      cardLayout:
          _enumByName(CardLayout.values, json['cardLayout'], CardLayout.standard),
      calendarDoneTheme: _enumByName(CalendarDoneTheme.values,
          json['calendarDoneTheme'], CalendarDoneTheme.green),
      weekStartsOnMonday: json['weekStartsOnMonday'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      achievementDisplayStyle: _enumByName(CelebrationStyle.values,
          json['achievementDisplayStyle'], CelebrationStyle.card),
      perfectDayDisplayStyle: _enumByName(CelebrationStyle.values,
          json['perfectDayDisplayStyle'], CelebrationStyle.card),
      reportDisplayStyle: _enumByName(CelebrationStyle.values,
          json['reportDisplayStyle'], CelebrationStyle.card),
      reportReminderEnabled: json['reportReminderEnabled'] as bool? ?? false,
      reportReminderMinutes:
          ((json['reportReminderMinutes'] as num?)?.toInt() ?? 690)
              .clamp(0, 1439),
      passcodeEnabled: json['passcodeEnabled'] as bool? ?? false,
      passcode: json['passcode'] as String?,
    );
  }
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
