import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'update_models.dart';

/// Persistence abstraction for [UpdateConfig] so tests can run in memory.
abstract class UpdateConfigStore {
  Future<UpdateConfig> load();
  Future<void> save(UpdateConfig config);
}

class FileUpdateConfigStore implements UpdateConfigStore {
  static const _fileName = 'update_config.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<UpdateConfig> load() async {
    if (kIsWeb) return const UpdateConfig();
    try {
      final f = await _file();
      if (!await f.exists()) return const UpdateConfig();
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map<String, dynamic>) {
        return UpdateConfig.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Failed to load update config: $e');
    }
    return const UpdateConfig();
  }

  @override
  Future<void> save(UpdateConfig config) async {
    if (kIsWeb) return;
    final f = await _file();
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode(config.toJson()));
  }
}

/// Platform bridge abstraction (MethodChannel on Android, injectable for tests).
abstract class UpdatePlatformAdapter {
  bool get isAndroid;
  Future<AppVersion> getAppVersion();
  Future<InstallResult> installApk(String filePath);
  Future<Directory> getUpdatesCacheDir();
}

class MethodChannelUpdatePlatform implements UpdatePlatformAdapter {
  static const _channel = MethodChannel('com.ibetter.clone.ibetter/updater');

  @override
  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<AppVersion> getAppVersion() async {
    if (!isAndroid) return AppVersion.fallback;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getAppVersion');
      if (map != null) {
        final name = (map['versionName'] as String?) ?? '1.0.0';
        final code = (map['versionCode'] as num?)?.toInt();
        return AppVersion.tryParse(name, overrideBuildNumber: code) ?? AppVersion.fallback;
      }
    } catch (e) {
      debugPrint('getAppVersion failed: $e');
    }
    return AppVersion.fallback;
  }

  @override
  Future<InstallResult> installApk(String filePath) async {
    if (!isAndroid) return InstallResult.unsupported;
    try {
      final res = await _channel.invokeMethod<String>('installApk', {'path': filePath});
      return switch (res) {
        'launched' => InstallResult.launched,
        'permission_required' => InstallResult.permissionRequired,
        _ => InstallResult.failed,
      };
    } catch (e) {
      debugPrint('installApk failed: $e');
      return InstallResult.failed;
    }
  }

  @override
  Future<Directory> getUpdatesCacheDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/updates');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

/// Checks GitHub Releases, downloads APK with progress, and triggers Android install.
class UpdateService {
  UpdateService({
    UpdatePlatformAdapter? platform,
    HttpClient Function()? httpClientFactory,
  })  : _platform = platform ?? MethodChannelUpdatePlatform(),
        _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final UpdatePlatformAdapter _platform;
  final HttpClient Function() _httpClientFactory;

  bool get supportsInAppInstall => _platform.isAndroid;

  Future<AppVersion> getCurrentVersion() => _platform.getAppVersion();

  /// Queries GitHub's latest release API for [config.repo].
  Future<UpdateCheckResult> checkForUpdate(UpdateConfig config) async {
    final current = await getCurrentVersion();
    if (!config.hasValidRepo) {
      return UpdateCheckResult(
        status: UpdateCheckStatus.notConfigured,
        currentVersion: current,
        message: '请先在「更多」中配置 GitHub 仓库（如 用户名/ibetter）',
      );
    }

    final repo = config.repo.trim();
    final uri = Uri.https('api.github.com', '/repos/$repo/releases/latest');
    final client = _httpClientFactory()..connectionTimeout = const Duration(seconds: 12);

    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      req.headers.set(HttpHeaders.userAgentHeader, 'iBetter-Flutter/${current.displayName}');
      final resp = await req.close().timeout(const Duration(seconds: 15));
      final body = await resp.transform(utf8.decoder).join();

      if (resp.statusCode == 404) {
        return UpdateCheckResult(
          status: UpdateCheckStatus.error,
          currentVersion: current,
          message: '仓库暂无已发布的 Release，或仓库名称不正确',
        );
      }
      if (resp.statusCode == 403) {
        return UpdateCheckResult(
          status: UpdateCheckStatus.error,
          currentVersion: current,
          message: 'GitHub 接口请求受限，请稍后再试',
        );
      }
      if (resp.statusCode != 200) {
        return UpdateCheckResult(
          status: UpdateCheckStatus.error,
          currentVersion: current,
          message: '检查更新失败（HTTP ${resp.statusCode}）',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return UpdateCheckResult(
          status: UpdateCheckStatus.error,
          currentVersion: current,
          message: '返回数据格式异常',
        );
      }

      final release = ReleaseInfo.fromGitHubJson(decoded);
      if (release == null) {
        return UpdateCheckResult(
          status: UpdateCheckStatus.error,
          currentVersion: current,
          message: '最新 Release 中未找到可安装的 APK 文件',
        );
      }

      if (release.version.isNewerThan(current)) {
        return UpdateCheckResult(
          status: UpdateCheckStatus.updateAvailable,
          currentVersion: current,
          release: release,
        );
      }

      return UpdateCheckResult(
        status: UpdateCheckStatus.upToDate,
        currentVersion: current,
        release: release,
        message: '当前已是最新版本（${current.fullLabel}）',
      );
    } on TimeoutException {
      return UpdateCheckResult(
        status: UpdateCheckStatus.error,
        currentVersion: current,
        message: '检查更新超时，请检查网络连接',
      );
    } on SocketException {
      return UpdateCheckResult(
        status: UpdateCheckStatus.error,
        currentVersion: current,
        message: '无法连接到 GitHub，请检查网络或代理设置',
      );
    } catch (e) {
      return UpdateCheckResult(
        status: UpdateCheckStatus.error,
        currentVersion: current,
        message: '检查更新失败：$e',
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads [release]'s APK into the app's `cache/updates/` folder.
  /// Reports progress via [onProgress] and returns the local APK file path.
  Future<String> downloadApk(
    ReleaseInfo release,
    UpdateConfig config, {
    void Function(int received, int total)? onProgress,
  }) async {
    final updatesDir = await _platform.getUpdatesCacheDir();
    // Clean older downloaded APKs to keep storage tidy.
    await for (final entity in updatesDir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }

    final safeName = release.assetName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final targetFile = File('${updatesDir.path}/$safeName');
    final partFile = File('${targetFile.path}.part');

    final urlStr = config.resolveDownloadUrl(release.apkUrl);
    final uri = Uri.parse(urlStr);
    final client = _httpClientFactory()..connectionTimeout = const Duration(seconds: 20);

    try {
      final req = await client.getUrl(uri);
      req.followRedirects = true;
      req.maxRedirects = 6;
      req.headers.set(HttpHeaders.userAgentHeader, 'iBetter-Flutter-Updater');

      final resp = await req.close().timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw HttpException('下载失败（HTTP ${resp.statusCode}）', uri: uri);
      }

      final total = resp.contentLength > 0 ? resp.contentLength : release.assetSizeBytes;
      var received = 0;
      final sink = partFile.openWrite();
      try {
        await for (final chunk in resp) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partFile.rename(targetFile.path);
      return targetFile.path;
    } catch (_) {
      if (await partFile.exists()) {
        try {
          await partFile.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<InstallResult> installApk(String filePath) => _platform.installApk(filePath);
}
