/// Models for GitHub Releases in-app update checks and configuration.
library;

/// Semantic version with optional build number (e.g. `1.0.1+2` or `v1.2.0`).
class AppVersion implements Comparable<AppVersion> {
  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.buildNumber,
  });

  final int major;
  final int minor;
  final int patch;
  final int? buildNumber;

  /// Fallback version when native platform metadata is unavailable (e.g. unit tests).
  static const fallback = AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1);

  /// Parses tags like `v1.2.3`, `1.2.3+4`, `v1.2`, `1.2.3-beta+5`.
  static AppVersion? tryParse(String raw, {int? overrideBuildNumber}) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }

    int? parsedBuild = overrideBuildNumber;
    final plusIdx = s.indexOf('+');
    if (plusIdx >= 0) {
      final buildStr = s.substring(plusIdx + 1).trim();
      parsedBuild ??= int.tryParse(buildStr);
      s = s.substring(0, plusIdx);
    }

    // Strip pre-release suffix if present (e.g. `-rc.1`).
    final dashIdx = s.indexOf('-');
    if (dashIdx >= 0) {
      s = s.substring(0, dashIdx);
    }

    final parts = s.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final major = int.tryParse(parts[0]);
    final minor = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    final patch = parts.length > 2 ? int.tryParse(parts[2]) : 0;
    if (major == null || minor == null || patch == null) return null;
    return AppVersion(
      major: major,
      minor: minor,
      patch: patch,
      buildNumber: parsedBuild,
    );
  }

  String get displayName => '$major.$minor.$patch';
  String get fullLabel =>
      buildNumber == null ? 'v$displayName' : 'v$displayName ($buildNumber)';

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    // Only compare buildNumber when BOTH specify one (tags like `v1.0.0` have null buildNumber).
    if (buildNumber != null && other.buildNumber != null) {
      return buildNumber!.compareTo(other.buildNumber!);
    }
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      other.buildNumber == buildNumber;

  @override
  int get hashCode => Object.hash(major, minor, patch, buildNumber);

  @override
  String toString() => fullLabel;
}

/// Metadata for a GitHub Release containing an Android APK asset.
class ReleaseInfo {
  const ReleaseInfo({
    required this.tagName,
    required this.version,
    required this.title,
    required this.changelog,
    required this.apkUrl,
    required this.assetName,
    required this.assetSizeBytes,
    this.htmlUrl,
  });

  final String tagName;
  final AppVersion version;
  final String title;
  final String changelog;
  final String apkUrl;
  final String assetName;
  final int assetSizeBytes;
  final String? htmlUrl;

  /// Parses GitHub's `/repos/{owner}/{repo}/releases/latest` JSON payload.
  /// Returns null if the release has no valid version tag or no `.apk` asset.
  static ReleaseInfo? fromGitHubJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String?)?.trim() ?? '';
    final version = AppVersion.tryParse(tag);
    if (version == null) return null;

    final assetsRaw = json['assets'];
    if (assetsRaw is! List) return null;

    Map<String, dynamic>? apkAsset;
    for (final item in assetsRaw) {
      if (item is Map<String, dynamic>) {
        final name = (item['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkAsset = item;
          // Prefer universal or arm64 release apk if multiple exist.
          if (name.contains('release') || name.contains('arm64')) break;
        }
      }
    }
    if (apkAsset == null) return null;

    final apkUrl = (apkAsset['browser_download_url'] as String?)?.trim() ?? '';
    if (apkUrl.isEmpty) return null;

    final name = (json['name'] as String?)?.trim();
    final body = (json['body'] as String?)?.trim();
    return ReleaseInfo(
      tagName: tag,
      version: version,
      title: (name != null && name.isNotEmpty) ? name : tag,
      changelog: (body != null && body.isNotEmpty) ? body : '常规优化与问题修复',
      apkUrl: apkUrl,
      assetName: (apkAsset['name'] as String?) ?? 'ibetter-$tag.apk',
      assetSizeBytes: (apkAsset['size'] as num?)?.toInt() ?? 0,
      htmlUrl: json['html_url'] as String?,
    );
  }
}

/// Persisted user/build update settings.
class UpdateConfig {
  const UpdateConfig({
    this.repo = defaultRepo,
    this.mirrorPrefix = defaultMirrorPrefix,
    this.autoCheck = true,
    this.ignoredTag,
  });

  /// Baked-in defaults via `--dart-define=UPDATE_REPO=owner/repo` at build time.
  static const String defaultRepo = String.fromEnvironment('UPDATE_REPO', defaultValue: '');
  static const String defaultMirrorPrefix =
      String.fromEnvironment('UPDATE_MIRROR', defaultValue: '');

  /// GitHub repository in `owner/repo` format.
  final String repo;

  /// Optional download mirror prefix (e.g. `https://gh-proxy.com/`).
  final String mirrorPrefix;

  /// Whether to check silently on app launch.
  final bool autoCheck;

  /// Release tag the user chose to ignore for startup prompts.
  final String? ignoredTag;

  bool get hasValidRepo => isValidRepo(repo);

  static bool isValidRepo(String raw) {
    final trimmed = raw.trim();
    final parts = trimmed.split('/');
    return parts.length == 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty &&
        !trimmed.contains(' ');
  }

  /// Applies [mirrorPrefix] to a raw GitHub release download URL if configured.
  String resolveDownloadUrl(String rawUrl) {
    final prefix = mirrorPrefix.trim();
    if (prefix.isEmpty) return rawUrl;
    final normalized = prefix.endsWith('/') ? prefix : '$prefix/';
    return '$normalized$rawUrl';
  }

  UpdateConfig copyWith({
    String? repo,
    String? mirrorPrefix,
    bool? autoCheck,
    String? ignoredTag,
    bool clearIgnoredTag = false,
  }) =>
      UpdateConfig(
        repo: repo ?? this.repo,
        mirrorPrefix: mirrorPrefix ?? this.mirrorPrefix,
        autoCheck: autoCheck ?? this.autoCheck,
        ignoredTag: clearIgnoredTag ? null : (ignoredTag ?? this.ignoredTag),
      );

  Map<String, dynamic> toJson() => {
        'repo': repo,
        'mirrorPrefix': mirrorPrefix,
        'autoCheck': autoCheck,
        'ignoredTag': ignoredTag,
      };

  factory UpdateConfig.fromJson(Map<String, dynamic> json) {
    final savedRepo = (json['repo'] as String?)?.trim();
    final savedMirror = (json['mirrorPrefix'] as String?)?.trim();
    return UpdateConfig(
      repo: (savedRepo != null && savedRepo.isNotEmpty) ? savedRepo : defaultRepo,
      mirrorPrefix:
          (savedMirror != null && savedMirror.isNotEmpty) ? savedMirror : defaultMirrorPrefix,
      autoCheck: json['autoCheck'] as bool? ?? true,
      ignoredTag: json['ignoredTag'] as String?,
    );
  }
}

enum UpdateCheckStatus {
  updateAvailable,
  upToDate,
  notConfigured,
  error,
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    required this.currentVersion,
    this.release,
    this.message,
  });

  final UpdateCheckStatus status;
  final AppVersion currentVersion;
  final ReleaseInfo? release;
  final String? message;
}

enum InstallResult {
  launched,
  permissionRequired,
  unsupported,
  failed,
}
