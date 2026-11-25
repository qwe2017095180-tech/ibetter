import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'qingsong_client.dart';

/// 手机端保存的「轻松日程」连接配置（docs/QINGSONG_INTEGRATION.md §6）。
class QingsongConfig {
  const QingsongConfig({
    this.address = '',
    this.token = '',
    this.autoSync = true,
    this.lastSyncAt,
  });

  /// 电脑地址，如 `192.168.1.8:7790`。
  final String address;

  /// 8 位配对码。
  final String token;

  /// 进入首页、增删改日程后自动尝试同步。
  final bool autoSync;

  /// 上次同步成功的时间戳（epoch ms）。
  final int? lastSyncAt;

  Uri? get baseUri => normalizeQingsongAddress(address);

  bool get isConfigured => baseUri != null && token.trim().isNotEmpty;

  QingsongConfig copyWith({
    String? address,
    String? token,
    bool? autoSync,
    int? lastSyncAt,
    bool clearLastSyncAt = false,
  }) {
    return QingsongConfig(
      address: address ?? this.address,
      token: token ?? this.token,
      autoSync: autoSync ?? this.autoSync,
      lastSyncAt: clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'token': token,
        'autoSync': autoSync,
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt,
      };

  factory QingsongConfig.fromJson(Map<String, dynamic> json) {
    final last = json['lastSyncAt'];
    return QingsongConfig(
      address: (json['address'] as String?)?.trim() ?? '',
      token: (json['token'] as String?)?.trim().toUpperCase() ?? '',
      autoSync: json['autoSync'] is bool ? json['autoSync'] as bool : true,
      lastSyncAt: last is num ? last.toInt() : null,
    );
  }
}

/// 持久化抽象，测试里用内存实现替代。
abstract class QingsongConfigStore {
  Future<QingsongConfig> load();
  Future<void> save(QingsongConfig config);
}

class FileQingsongConfigStore implements QingsongConfigStore {
  static const _fileName = 'qingsong_config.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<QingsongConfig> load() async {
    if (kIsWeb) return const QingsongConfig();
    try {
      final f = await _file();
      if (!await f.exists()) return const QingsongConfig();
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map<String, dynamic>) {
        return QingsongConfig.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Failed to load qingsong config: $e');
    }
    return const QingsongConfig();
  }

  @override
  Future<void> save(QingsongConfig config) async {
    if (kIsWeb) return;
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(config.toJson()));
    } catch (e) {
      debugPrint('Failed to save qingsong config: $e');
    }
  }
}

class InMemoryQingsongConfigStore implements QingsongConfigStore {
  InMemoryQingsongConfigStore([this._config = const QingsongConfig()]);

  QingsongConfig _config;

  @override
  Future<QingsongConfig> load() async => _config;

  @override
  Future<void> save(QingsongConfig config) async {
    _config = config;
  }
}
