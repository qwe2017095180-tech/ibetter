/// 连接轻松日程的 HTTP 客户端（`/bridge/v1`）。只用 dart:io，不依赖 Flutter，便于单测和脚本联调。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/models/agenda_item.dart';
import '../../domain/models/qingsong_notice.dart';

const int qingsongDefaultPort = 7790;

/// 把用户输入的地址规范成 `http://host:port`；不合法返回 null。
/// 支持 `192.168.1.8`、`192.168.1.8:7790`、`http://192.168.1.8:7790/`。
Uri? normalizeQingsongAddress(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (!s.contains('://')) s = 'http://$s';
  final u = Uri.tryParse(s);
  if (u == null || u.host.isEmpty || (u.scheme != 'http' && u.scheme != 'https')) return null;
  return Uri(scheme: u.scheme, host: u.host, port: u.hasPort ? u.port : qingsongDefaultPort);
}

class QingsongException implements Exception {
  const QingsongException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class QingsongPing {
  const QingsongPing({required this.version, required this.protocol});

  final String version;
  final int protocol;
}

/// 同步服务依赖的接口，测试里可替换成假实现。
abstract class QingsongApi {
  Future<QingsongPing> ping();
  Future<List<QingsongNotice>> fetchNotices();

  /// 返回 clientId → 远端 id。
  Future<Map<String, String>> createItems(List<AgendaItem> items);
  Future<void> setStatus(String remoteId, {required bool done});
}

class QingsongClient implements QingsongApi {
  QingsongClient({
    required this.baseUri,
    required this.token,
    HttpClient Function()? httpClientFactory,
    this.timeout = const Duration(seconds: 6),
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final Uri baseUri;
  final String token;
  final Duration timeout;
  final HttpClient Function() _httpClientFactory;

  Uri _uri(String path) => baseUri.replace(path: '/bridge/v1$path');

  Future<Map<String, dynamic>> _request(String method, String path, [Object? body]) async {
    final client = _httpClientFactory()..connectionTimeout = timeout;
    try {
      final req = await client.openUrl(method, _uri(path)).timeout(timeout);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${token.trim().toUpperCase()}');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        final bytes = utf8.encode(jsonEncode(body));
        req.headers.contentType = ContentType.json;
        req.contentLength = bytes.length;
        req.add(bytes);
      }
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      Map<String, dynamic>? json;
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {}
      if (res.statusCode == 401) {
        throw const QingsongException('配对码不对，请在电脑的「连接 iBetter」页面核对', statusCode: 401);
      }
      if (res.statusCode == 429) {
        throw QingsongException(json?['error'] as String? ?? '尝试次数太多，请稍后再试', statusCode: 429);
      }
      if (res.statusCode != 200 || json == null || json['ok'] != true) {
        final msg = json?['error'] as String? ?? '电脑返回错误（HTTP ${res.statusCode}）';
        throw QingsongException(msg, statusCode: res.statusCode);
      }
      return json;
    } on QingsongException {
      rethrow;
    } on TimeoutException {
      throw const QingsongException('连接电脑超时：确认手机和电脑在同一 Wi-Fi，且电脑上已开启「连接 iBetter」');
    } on SocketException {
      throw const QingsongException('连不上电脑：确认地址正确、电脑上轻松日程正在运行并已开启「连接 iBetter」');
    } on HttpException catch (e) {
      throw QingsongException('网络错误：${e.message}');
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<QingsongPing> ping() async {
    final json = await _request('GET', '/ping');
    if (json['app'] != 'qingsong-rili') {
      throw const QingsongException('这个地址不是轻松日程');
    }
    return QingsongPing(
      version: json['version'] as String? ?? '?',
      protocol: (json['protocol'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<QingsongNotice>> fetchNotices() async {
    final json = await _request('GET', '/notices');
    final list = json['notices'];
    if (list is! List) return const [];
    return list.map(QingsongNotice.tryParse).whereType<QingsongNotice>().toList();
  }

  @override
  Future<Map<String, String>> createItems(List<AgendaItem> items) async {
    if (items.isEmpty) return const {};
    final json = await _request('POST', '/notices', {
      'items': [
        for (final it in items)
          {
            'clientId': it.clientId,
            'title': it.title,
            'date': it.date,
            'time': it.timeLabel,
            'note': it.note,
            'category': it.category,
          },
      ],
    });
    final out = <String, String>{};
    final results = json['items'];
    if (results is List) {
      for (final r in results) {
        if (r is Map && r['clientId'] is String && r['id'] is String) {
          out[r['clientId'] as String] = r['id'] as String;
        }
      }
    }
    return out;
  }

  @override
  Future<void> setStatus(String remoteId, {required bool done}) async {
    await _request('POST', '/notices/status', {'id': remoteId, 'status': done ? 'done' : 'todo'});
  }
}
