import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/qingsong_notice.dart';

/// Persists full PC 「轻松日程」 notices locally for offline viewing in the schedule board.
abstract class QingsongNoticeCacheStore {
  Future<List<QingsongNotice>> load();
  Future<void> save(List<QingsongNotice> notices);
}

class FileQingsongNoticeCacheStore implements QingsongNoticeCacheStore {
  static const _fileName = 'qingsong_notices_cache.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<List<QingsongNotice>> load() async {
    if (kIsWeb) return const [];
    try {
      final f = await _file();
      if (!await f.exists()) return const [];
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is List) {
        return decoded.map(QingsongNotice.tryParse).whereType<QingsongNotice>().toList();
      }
    } catch (e) {
      debugPrint('Failed to load qingsong notice cache: $e');
    }
    return const [];
  }

  @override
  Future<void> save(List<QingsongNotice> notices) async {
    if (kIsWeb) return;
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      final encoded = jsonEncode([for (final n in notices) n.toJson()]);
      await f.writeAsString(encoded);
    } catch (e) {
      debugPrint('Failed to save qingsong notice cache: $e');
    }
  }
}

class MemoryQingsongNoticeCacheStore implements QingsongNoticeCacheStore {
  MemoryQingsongNoticeCacheStore([List<QingsongNotice>? initial])
      : _notices = List<QingsongNotice>.of(initial ?? const []);

  List<QingsongNotice> _notices;

  @override
  Future<List<QingsongNotice>> load() async => List<QingsongNotice>.unmodifiable(_notices);

  @override
  Future<void> save(List<QingsongNotice> notices) async {
    _notices = List<QingsongNotice>.of(notices);
  }
}
