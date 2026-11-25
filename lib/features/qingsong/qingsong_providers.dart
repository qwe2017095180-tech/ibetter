import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'qingsong_client.dart';
import 'qingsong_config.dart';
import 'qingsong_sync_service.dart';

final qingsongConfigStoreProvider = Provider<QingsongConfigStore>(
  (ref) => FileQingsongConfigStore(),
);

/// 供测试注入假客户端。
typedef QingsongApiFactory = QingsongApi Function(Uri baseUri, String token);

final qingsongApiFactoryProvider = Provider<QingsongApiFactory>(
  (ref) => (baseUri, token) => QingsongClient(baseUri: baseUri, token: token),
);

class QingsongConfigNotifier extends AsyncNotifier<QingsongConfig> {
  @override
  Future<QingsongConfig> build() => ref.watch(qingsongConfigStoreProvider).load();

  Future<void> _update(QingsongConfig Function(QingsongConfig current) fn) async {
    final current = state.asData?.value ?? await ref.read(qingsongConfigStoreProvider).load();
    final updated = fn(current);
    state = AsyncData(updated);
    await ref.read(qingsongConfigStoreProvider).save(updated);
  }

  Future<void> setAddress(String address) =>
      _update((c) => c.copyWith(address: address.trim()));

  Future<void> setToken(String token) =>
      _update((c) => c.copyWith(token: token.trim().toUpperCase()));

  Future<void> setAutoSync(bool enabled) =>
      _update((c) => c.copyWith(autoSync: enabled));

  Future<void> recordSyncSuccess(int timestampMs) =>
      _update((c) => c.copyWith(lastSyncAt: timestampMs));

  Future<void> clearConnection() => _update(
        (c) => c.copyWith(address: '', token: '', clearLastSyncAt: true),
      );
}

final qingsongConfigProvider =
    AsyncNotifierProvider<QingsongConfigNotifier, QingsongConfig>(
  QingsongConfigNotifier.new,
);

/// 同步运行态（用于 UI 展示进度与最近结果）。
class QingsongSyncState {
  const QingsongSyncState({
    this.syncing = false,
    this.lastSummary,
    this.lastError,
  });

  final bool syncing;
  final String? lastSummary;
  final String? lastError;

  QingsongSyncState copyWith({
    bool? syncing,
    String? lastSummary,
    bool clearLastSummary = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return QingsongSyncState(
      syncing: syncing ?? this.syncing,
      lastSummary: clearLastSummary ? null : (lastSummary ?? this.lastSummary),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

class QingsongSyncOutcome {
  const QingsongSyncOutcome({
    required this.ok,
    required this.message,
    this.result,
  });

  final bool ok;
  final String message;
  final SyncResult? result;
}

class QingsongSyncController extends Notifier<QingsongSyncState> {
  @override
  QingsongSyncState build() => const QingsongSyncState();

  Future<QingsongSyncOutcome> testConnection() async {
    final config = await ref.read(qingsongConfigProvider.future);
    final uri = config.baseUri;
    if (uri == null) {
      return const QingsongSyncOutcome(ok: false, message: '请先填写电脑地址（如 192.168.1.8:7790）');
    }
    if (config.token.trim().isEmpty) {
      return const QingsongSyncOutcome(ok: false, message: '请先填写配对码');
    }
    final api = ref.read(qingsongApiFactoryProvider)(uri, config.token);
    try {
      final ping = await api.ping();
      return QingsongSyncOutcome(
        ok: true,
        message: '已连上轻松日程 v${ping.version}',
      );
    } on QingsongException catch (e) {
      return QingsongSyncOutcome(ok: false, message: e.message);
    } catch (e) {
      return QingsongSyncOutcome(ok: false, message: '测试连接失败：$e');
    }
  }

  /// 执行一次双向同步；[silent] 为 true 时跳过未配置或正在同步的情况且不弹窗。
  Future<QingsongSyncOutcome> sync({bool silent = false}) async {
    if (state.syncing) {
      return const QingsongSyncOutcome(ok: false, message: '正在同步中');
    }
    final config = await ref.read(qingsongConfigProvider.future);
    final uri = config.baseUri;
    if (uri == null || config.token.trim().isEmpty) {
      return const QingsongSyncOutcome(ok: false, message: '尚未配置轻松日程连接');
    }
    if (silent && !config.autoSync) {
      return const QingsongSyncOutcome(ok: false, message: '已关闭自动同步');
    }

    state = state.copyWith(syncing: true, clearLastError: true);
    try {
      final api = ref.read(qingsongApiFactoryProvider)(uri, config.token);
      final service = QingsongSyncService(
        api: api,
        repository: ref.read(agendaRepositoryProvider),
      );
      final result = await service.sync();
      final now = DateTime.now().millisecondsSinceEpoch;
      await ref.read(qingsongConfigProvider.notifier).recordSyncSuccess(now);
      final msg = result.warnings.isEmpty
          ? '同步完成：${result.summary}'
          : '同步完成：${result.summary}（${result.warnings.first}）';
      state = state.copyWith(syncing: false, lastSummary: result.summary, clearLastError: true);
      return QingsongSyncOutcome(ok: true, message: msg, result: result);
    } on QingsongException catch (e) {
      state = state.copyWith(syncing: false, lastError: e.message);
      return QingsongSyncOutcome(ok: false, message: e.message);
    } catch (e) {
      final msg = '同步失败：$e';
      state = state.copyWith(syncing: false, lastError: msg);
      return QingsongSyncOutcome(ok: false, message: msg);
    }
  }
}

final qingsongSyncProvider =
    NotifierProvider<QingsongSyncController, QingsongSyncState>(
  QingsongSyncController.new,
);
