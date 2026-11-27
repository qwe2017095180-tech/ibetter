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
  Future<bool> openUrl(String url);
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

  @override
  Future<bool> openUrl(String url) async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
    } catch (e) {
      debugPrint('openUrl failed: $e');
      return false;
    }
  }
}

/// Converts raw HTTP/network exceptions into short, user-friendly Chinese messages
/// without leaking long signed GitHub/Azure redirect URLs or JWT tokens.
String formatUpdateError(Object error) {
  if (error is TimeoutException) {
    return '连接或下载超时，网络较慢或不稳定，建议切换加速镜像或用浏览器下载';
  }
  if (error is HandshakeException || error is TlsException) {
    return '安全连接（TLS）失败，请检查网络或代理设置后重试';
  }
  if (error is SocketException) {
    return '网络连接失败，请检查网络状态或切换加速镜像后重试';
  }
  if (error is HttpException) {
    final msg = error.message;
    final lower = msg.toLowerCase();
    if (lower.contains('connection closed') ||
        lower.contains('connection reset') ||
        lower.contains('unexpected end')) {
      return '下载连接中途断开（GitHub 直连不稳定），建议切换下方加速镜像或用浏览器下载';
    }
    final statusMatch = RegExp(r'HTTP\s+(\d{3})').firstMatch(msg);
    if (statusMatch != null) {
      return '服务器返回异常（HTTP ${statusMatch.group(1)}），请稍后或切换镜像重试';
    }
    if (msg.contains('镜像返回了非安装包内容')) {
      return msg;
    }
    if (msg.contains('安装包下载不完整')) {
      return msg;
    }
    final sanitized = _stripUrls(msg);
    return sanitized.isEmpty ? '网络传输异常，请重试或切换加速镜像' : sanitized;
  }
  if (error is FileSystemException) {
    return '保存安装包失败，请检查手机存储空间后重试';
  }
  final cleaned = _stripUrls(error.toString());
  if (cleaned.length > 100) {
    return '${cleaned.substring(0, 100)}…';
  }
  return cleaned.isEmpty ? '下载失败，请稍后重试' : cleaned;
}

String _stripUrls(String raw) {
  var s = raw
      .replaceAll(RegExp(r',?\s*uri\s*=\s*\S+', caseSensitive: false), '')
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceFirst(RegExp(r'^[A-Za-z_]+Exception:\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (s.endsWith(',') || s.endsWith(':')) {
    s = s.substring(0, s.length - 1).trim();
  }
  return s;
}

/// Checks GitHub Releases, downloads APK with retry & Range resume, and triggers Android install.
class UpdateService {
  UpdateService({
    UpdatePlatformAdapter? platform,
    HttpClient Function()? httpClientFactory,
    this.maxAttemptsPerSource = 3,
    this.retryDelay = const Duration(milliseconds: 900),
    this.chunkTimeout = const Duration(seconds: 30),
    List<String>? fallbackMirrors,
  })  : _platform = platform ?? MethodChannelUpdatePlatform(),
        _httpClientFactory = httpClientFactory ?? HttpClient.new,
        _fallbackMirrors = fallbackMirrors ?? UpdateConfig.fallbackMirrorPrefixes;

  final UpdatePlatformAdapter _platform;
  final HttpClient Function() _httpClientFactory;
  final int maxAttemptsPerSource;
  final Duration retryDelay;
  final Duration chunkTimeout;
  final List<String> _fallbackMirrors;

  bool get supportsInAppInstall => _platform.isAndroid;

  Future<AppVersion> getCurrentVersion() => _platform.getAppVersion();

  /// Queries GitHub's latest release API for [config.repo], retrying once on transient failure.
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

    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      final client = _httpClientFactory()..connectionTimeout = const Duration(seconds: 12);
      try {
        final req = await client.getUrl(uri);
        req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
        req.headers.set(
          HttpHeaders.userAgentHeader,
          'QingsongCheckin-Flutter/${current.displayName}',
        );
        final resp = await req.close().timeout(const Duration(seconds: 15));
        final body = await resp.transform(utf8.decoder).join().timeout(const Duration(seconds: 15));

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
      } on TimeoutException catch (e) {
        lastError = e;
      } on SocketException catch (e) {
        lastError = e;
      } on HttpException catch (e) {
        lastError = e;
      } catch (e) {
        return UpdateCheckResult(
          status: UpdateCheckStatus.error,
          currentVersion: current,
          message: '检查更新失败：${formatUpdateError(e)}',
        );
      } finally {
        client.close(force: true);
      }

      if (attempt < 2 && retryDelay > Duration.zero) {
        await Future<void>.delayed(retryDelay);
      }
    }

    return UpdateCheckResult(
      status: UpdateCheckStatus.error,
      currentVersion: current,
      message: '检查更新失败：${formatUpdateError(lastError ?? '网络异常')}',
    );
  }

  /// Downloads [release]'s APK into the app's `cache/updates/` folder with automatic
  /// retry, HTTP Range resume, and automatic mirror fallback for GitHub URLs.
  Future<String> downloadApk(
    ReleaseInfo release,
    UpdateConfig config, {
    void Function(int received, int total)? onProgress,
    void Function(String status)? onStatus,
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

    final prefixes = _buildCandidatePrefixes(release.apkUrl, config);
    Object? lastError;

    for (var sourceIdx = 0; sourceIdx < prefixes.length; sourceIdx++) {
      final prefix = prefixes[sourceIdx];
      final urlStr = UpdateConfig.applyMirrorPrefix(release.apkUrl, prefix);
      final uri = Uri.parse(urlStr);

      // Reset partial file when switching to a different host/mirror.
      if (sourceIdx > 0) {
        await _deleteQuietly(partFile);
        final hostLabel = Uri.tryParse(prefix)?.host ?? prefix;
        onStatus?.call(
          prefix.isEmpty
              ? '加速镜像受阻，正在尝试直连 GitHub…'
              : '当前线路受阻，正在切换加速镜像（$hostLabel）…',
        );
      } else if (prefix.isNotEmpty) {
        final hostLabel = Uri.tryParse(prefix)?.host ?? prefix;
        onStatus?.call('正在通过加速镜像（$hostLabel）下载…');
      }

      try {
        await _downloadFromUriWithResume(
          uri: uri,
          partFile: partFile,
          expectedSize: release.assetSizeBytes,
          onProgress: onProgress,
          onStatus: onStatus,
        );
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await partFile.rename(targetFile.path);
        return targetFile.path;
      } catch (e) {
        lastError = e;
        if (!_isRetryableNetworkError(e)) {
          await _deleteQuietly(partFile);
          rethrow;
        }
      }
    }

    await _deleteQuietly(partFile);
    throw lastError ?? const HttpException('下载失败');
  }

  List<String> _buildCandidatePrefixes(String rawUrl, UpdateConfig config) {
    final isGitHubUrl = rawUrl.startsWith('https://github.com/');
    if (!isGitHubUrl) return const [''];
    final explicit = UpdateConfig.normalizeMirrorPrefix(config.mirrorPrefix);
    if (explicit.isNotEmpty) {
      return [
        explicit,
        for (final m in _fallbackMirrors)
          if (m != explicit) m,
        '',
      ];
    }
    return ['', ..._fallbackMirrors];
  }

  bool _isRetryableNetworkError(Object error) =>
      error is HttpException ||
      error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is TlsException;

  Future<void> _downloadFromUriWithResume({
    required Uri uri,
    required File partFile,
    required int expectedSize,
    void Function(int received, int total)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttemptsPerSource; attempt++) {
      var existingBytes = await partFile.exists() ? await partFile.length() : 0;
      if (expectedSize > 0 && existingBytes > expectedSize) {
        await _deleteQuietly(partFile);
        existingBytes = 0;
      }

      if (attempt > 1) {
        onStatus?.call(
          existingBytes > 0
              ? '连接中断，正在断点续传（第 $attempt/$maxAttemptsPerSource 次）…'
              : '连接中断，正在重试（第 $attempt/$maxAttemptsPerSource 次）…',
        );
      }

      final client = _httpClientFactory()..connectionTimeout = const Duration(seconds: 20);
      try {
        final req = await client.getUrl(uri);
        req.followRedirects = true;
        req.maxRedirects = 8;
        req.headers.set(HttpHeaders.userAgentHeader, 'QingsongCheckin-Flutter-Updater');
        if (existingBytes > 0) {
          req.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
        }

        final resp = await req.close().timeout(const Duration(seconds: 30));

        // Handle 416 Range Not Satisfiable (already complete or stale partial file).
        if (resp.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
          await resp.drain<void>();
          if (expectedSize > 0 && existingBytes == expectedSize) {
            onProgress?.call(existingBytes, expectedSize);
            return;
          }
          await _deleteQuietly(partFile);
          lastError = HttpException('下载失败（HTTP 416）', uri: uri);
          continue;
        }

        final isPartial = resp.statusCode == HttpStatus.partialContent && existingBytes > 0;
        if (resp.statusCode != HttpStatus.ok && !isPartial) {
          await resp.drain<void>();
          throw HttpException('下载失败（HTTP ${resp.statusCode}）', uri: uri);
        }

        // Guard against mirror proxies returning an HTML rate-limit / error page with 200 OK.
        final contentType = resp.headers.contentType?.mimeType.toLowerCase() ?? '';
        if (contentType.startsWith('text/html')) {
          await resp.drain<void>();
          throw HttpException('镜像返回了非安装包内容，请切换其他镜像或直连重试', uri: uri);
        }

        var received = isPartial ? existingBytes : 0;
        final total = _resolveTotalBytes(
          resp: resp,
          isPartial: isPartial,
          existingBytes: existingBytes,
          fallbackSize: expectedSize,
        );

        final sink = partFile.openWrite(
          mode: isPartial ? FileMode.append : FileMode.write,
        );
        try {
          if (received > 0) {
            onProgress?.call(received, total);
          }
          await for (final chunk in resp.timeout(chunkTimeout)) {
            sink.add(chunk);
            received += chunk.length;
            onProgress?.call(received, total);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }

        if (total > 0 && received < total) {
          throw HttpException(
            'Connection closed while receiving data ($received/$total)',
            uri: uri,
          );
        }
        return;
      } catch (e) {
        lastError = e;
        if (!_isRetryableNetworkError(e) || attempt == maxAttemptsPerSource) {
          rethrow;
        }
      } finally {
        client.close(force: true);
      }

      if (retryDelay > Duration.zero) {
        await Future<void>.delayed(retryDelay * attempt);
      }
    }

    throw lastError ?? HttpException('下载失败', uri: uri);
  }

  int _resolveTotalBytes({
    required HttpClientResponse resp,
    required bool isPartial,
    required int existingBytes,
    required int fallbackSize,
  }) {
    if (isPartial) {
      final rangeHeader = resp.headers.value(HttpHeaders.contentRangeHeader);
      if (rangeHeader != null) {
        final match = RegExp(r'/(\d+)$').firstMatch(rangeHeader.trim());
        if (match != null) {
          final parsed = int.tryParse(match.group(1)!);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
      if (resp.contentLength > 0) return existingBytes + resp.contentLength;
      return fallbackSize;
    }
    return resp.contentLength > 0 ? resp.contentLength : fallbackSize;
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<InstallResult> installApk(String filePath) => _platform.installApk(filePath);

  /// Opens the APK download URL (applying mirror if configured) or release page in system browser.
  Future<bool> openInBrowser(ReleaseInfo release, UpdateConfig config) {
    final target = config.resolveDownloadUrl(release.apkUrl);
    return _platform.openUrl(target.isNotEmpty ? target : (release.htmlUrl ?? ''));
  }
}
