import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/app/theme/app_theme.dart';
import 'package:ibetter/features/more/more_page.dart';
import 'package:ibetter/features/updates/update_models.dart';
import 'package:ibetter/features/updates/update_providers.dart';
import 'package:ibetter/features/updates/update_service.dart';
import 'package:material_ui/material_ui.dart';

class _MemoryConfigStore implements UpdateConfigStore {
  _MemoryConfigStore([this._config = const UpdateConfig()]);
  UpdateConfig _config;

  @override
  Future<UpdateConfig> load() async => _config;

  @override
  Future<void> save(UpdateConfig config) async {
    _config = config;
  }
}

class _FakePlatform implements UpdatePlatformAdapter {
  _FakePlatform({
    required this.cacheDir,
    this.installResult = InstallResult.launched,
  });

  final Directory cacheDir;
  InstallResult installResult;
  final List<String> installedPaths = [];

  @override
  bool get isAndroid => true;

  @override
  Future<AppVersion> getAppVersion() async =>
      const AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1);

  @override
  Future<Directory> getUpdatesCacheDir() async => cacheDir;

  @override
  Future<InstallResult> installApk(String filePath) async {
    installedPaths.add(filePath);
    return installResult;
  }
}

class _StubUpdateService extends UpdateService {
  _StubUpdateService({
    required this.checkResult,
    required this.downloadHandler,
    required super.platform,
  });

  final UpdateCheckResult checkResult;
  final Future<String> Function(
    ReleaseInfo release,
    UpdateConfig config,
    void Function(int received, int total)? onProgress,
  ) downloadHandler;

  @override
  Future<UpdateCheckResult> checkForUpdate(UpdateConfig config) async => checkResult;

  @override
  Future<String> downloadApk(
    ReleaseInfo release,
    UpdateConfig config, {
    void Function(int received, int total)? onProgress,
  }) =>
      downloadHandler(release, config, onProgress);
}

class _PassthroughHttpOverrides extends HttpOverrides {}

void main() {
  group('AppVersion & ReleaseInfo', () {
    test('parses and compares semantic versions and build numbers', () {
      final v100 = AppVersion.tryParse('1.0.0+1')!;
      final v100Tag = AppVersion.tryParse('v1.0.0')!;
      final v100b2 = AppVersion.tryParse('v1.0.0+2')!;
      final v101 = AppVersion.tryParse('v1.0.1')!;
      final v120 = AppVersion.tryParse('v1.2.0-beta')!;

      expect(v100Tag.isNewerThan(v100), isFalse);
      expect(v100b2.isNewerThan(v100), isTrue);
      expect(v101.isNewerThan(v100), isTrue);
      expect(v120.isNewerThan(v101), isTrue);
      expect(AppVersion.tryParse('not-a-version'), isNull);
    });

    test('parses GitHub release JSON with APK asset', () {
      final info = ReleaseInfo.fromGitHubJson({
        'tag_name': 'v1.0.2',
        'name': 'iBetter v1.0.2',
        'body': '- 新增应用内更新',
        'assets': [
          {
            'name': 'checksums.txt',
            'size': 128,
            'browser_download_url': 'https://example.com/checksums.txt',
          },
          {
            'name': 'ibetter-v1.0.2.apk',
            'size': 25000000,
            'browser_download_url': 'https://example.com/ibetter-v1.0.2.apk',
          },
        ],
      });

      expect(info, isNotNull);
      expect(info!.tagName, 'v1.0.2');
      expect(info.version, const AppVersion(major: 1, minor: 0, patch: 2));
      expect(info.assetName, 'ibetter-v1.0.2.apk');
      expect(info.assetSizeBytes, 25000000);
      expect(info.changelog, '- 新增应用内更新');
    });

    test('UpdateConfig validates repo and applies mirror prefix', () {
      expect(UpdateConfig.isValidRepo('alice/ibetter'), isTrue);
      expect(UpdateConfig.isValidRepo('invalid'), isFalse);
      expect(UpdateConfig.isValidRepo('alice/i better'), isFalse);

      const cfg = UpdateConfig(repo: 'alice/ibetter', mirrorPrefix: 'https://gh-proxy.com');
      expect(
        cfg.resolveDownloadUrl('https://github.com/alice/ibetter/releases/download/v1.0.1/app.apk'),
        'https://gh-proxy.com/https://github.com/alice/ibetter/releases/download/v1.0.1/app.apk',
      );
    });
  });

  test('UpdateService downloads APK with progress via local HTTP server and cleans old APKs',
      () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final tmpDir = await Directory.systemTemp.createTemp('ibetter_update_test_');
      final oldApk = File('${tmpDir.path}/old.apk')..writeAsStringSync('old');
      final payload = List<int>.generate(16384, (i) => i % 256);

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentLength = payload.length
          ..add(payload);
        req.response.close();
      });

      try {
        final platform = _FakePlatform(cacheDir: tmpDir);
        final service = UpdateService(platform: platform);
        final release = ReleaseInfo(
          tagName: 'v1.1.0',
          version: const AppVersion(major: 1, minor: 1, patch: 0),
          title: 'v1.1.0',
          changelog: '更新日志',
          apkUrl: 'http://127.0.0.1:${server.port}/ibetter-v1.1.0.apk',
          assetName: 'ibetter-v1.1.0.apk',
          assetSizeBytes: payload.length,
        );

        final progressEvents = <(int, int)>[];
        final path = await service.downloadApk(
          release,
          const UpdateConfig(repo: 'alice/ibetter'),
          onProgress: (r, t) => progressEvents.add((r, t)),
        );

        expect(await oldApk.exists(), isFalse);
        expect(File(path).readAsBytesSync(), payload);
        expect(progressEvents, isNotEmpty);
        expect(progressEvents.last.$1, payload.length);

        final res = await service.installApk(path);
        expect(res, InstallResult.launched);
        expect(platform.installedPaths, [path]);
      } finally {
        await server.close(force: true);
        await tmpDir.delete(recursive: true);
      }
    }, _PassthroughHttpOverrides());
  });

  testWidgets('MorePage allows configuring repo, checking update, and running download + install',
      (tester) async {
    final tmpDir = Directory.systemTemp.createTempSync('ibetter_more_test_');
    addTearDown(() => tmpDir.deleteSync(recursive: true));

    final store = _MemoryConfigStore(const UpdateConfig(repo: 'alice/ibetter'));
    final platform = _FakePlatform(
      cacheDir: tmpDir,
      installResult: InstallResult.permissionRequired,
    );
    final release = ReleaseInfo(
      tagName: 'v1.2.0',
      version: const AppVersion(major: 1, minor: 2, patch: 0),
      title: 'iBetter v1.2.0',
      changelog: '1. 支持应用内更新\n2. 性能优化',
      apkUrl: 'https://example.com/ibetter-v1.2.0.apk',
      assetName: 'ibetter-v1.2.0.apk',
      assetSizeBytes: 2048,
    );
    final fakeApk = File('${tmpDir.path}/ibetter-v1.2.0.apk')
      ..writeAsBytesSync(utf8.encode('apk-data'));

    final service = _StubUpdateService(
      platform: platform,
      checkResult: UpdateCheckResult(
        status: UpdateCheckStatus.updateAvailable,
        currentVersion: const AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
        release: release,
      ),
      downloadHandler: (rel, cfg, onProgress) async {
        onProgress?.call(1024, 2048);
        onProgress?.call(2048, 2048);
        return fakeApk.path;
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateConfigStoreProvider.overrideWithValue(store),
          updateServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MorePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('更多'), findsOneWidget);
    expect(find.text('alice/ibetter'), findsOneWidget);

    // Tap manual update check -> update dialog pops up.
    await tester.tap(find.byKey(const ValueKey('more_check_update_row')));
    await tester.pumpAndSettle();

    expect(find.text('发现新版本 v1.2.0'), findsOneWidget);
    expect(find.textContaining('支持应用内更新'), findsOneWidget);

    // Tap 立即更新 -> downloads & prompts for unknown-sources permission.
    await tester.tap(find.text('立即更新'));
    await tester.pumpAndSettle();

    expect(find.text('继续安装'), findsOneWidget);
    expect(platform.installedPaths, [fakeApk.path]);

    // After permission granted, tap 继续安装 -> launched.
    platform.installResult = InstallResult.launched;
    await tester.tap(find.text('继续安装'));
    await tester.pumpAndSettle();
    expect(find.text('重新拉起安装'), findsOneWidget);
  });
}
