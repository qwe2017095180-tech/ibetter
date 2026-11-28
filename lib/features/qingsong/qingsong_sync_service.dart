/// 轻松日程双向同步：先推后拉（docs/QINGSONG_INTEGRATION.md §5）。不依赖 Flutter。
library;

import '../../data/repositories/repositories.dart';
import '../../domain/models/qingsong_notice.dart';
import '../../domain/services/agenda_sync_rules.dart';
import 'qingsong_client.dart';
import 'qingsong_notice_cache.dart';

class SyncResult {
  const SyncResult({
    this.uploaded = 0,
    this.statusPushed = 0,
    this.inserted = 0,
    this.updated = 0,
    this.removed = 0,
    this.warnings = const [],
    this.fetchedNotices = const [],
  });

  final int uploaded;
  final int statusPushed;
  final int inserted;
  final int updated;
  final int removed;

  /// 部分失败（不影响整体同步）的说明。
  final List<String> warnings;

  /// Full list of notices returned by `/bridge/v1/notices` in this sync pass.
  final List<QingsongNotice> fetchedNotices;

  String get summary {
    final parts = <String>[
      if (uploaded > 0) '上传 $uploaded 条',
      if (statusPushed > 0) '同步状态 $statusPushed 条',
      if (inserted > 0) '新增 $inserted 条',
      if (updated > 0) '更新 $updated 条',
      if (removed > 0) '移除 $removed 条',
    ];
    return parts.isEmpty ? '已是最新' : parts.join('，');
  }
}

class QingsongSyncService {
  const QingsongSyncService({
    required this.api,
    required this.repository,
    this.noticeCacheStore,
  });

  final QingsongApi api;
  final AgendaRepository repository;
  final QingsongNoticeCacheStore? noticeCacheStore;

  Future<SyncResult> sync() async {
    final warnings = <String>[];

    // 1. 上行新建
    var uploaded = 0;
    final uploads = await repository.pendingUploads();
    if (uploads.isNotEmpty) {
      final ids = await api.createItems(uploads);
      for (final item in uploads) {
        final remoteId = ids[item.clientId];
        if (remoteId == null) {
          warnings.add('「${item.title}」没能同步到电脑');
          continue;
        }
        await repository.markUploaded(item.id, remoteId);
        uploaded++;
        // 上传前就勾了完成：远端新建的是待办，补推一次完成状态
        if (item.isDone) {
          try {
            await api.setStatus(remoteId, done: true);
          } on QingsongException catch (e) {
            warnings.add('「${item.title}」完成状态未同步：${e.message}');
            await repository.setDone(item.id, false);
            await repository.setDone(item.id, true); // 标记 dirty，下次重试
          }
        }
      }
    }

    // 2. 上行完成状态
    var statusPushed = 0;
    for (final item in await repository.pendingStatusChanges()) {
      try {
        await api.setStatus(item.remoteId!, done: item.isDone);
        await repository.markStatusPushed(item.id, pushedDone: item.isDone);
        statusPushed++;
      } on QingsongException catch (e) {
        if (e.isNotFound) {
          // 电脑上已删除：清掉 dirty，下行合并时会断开关联
          await repository.markStatusPushed(item.id, pushedDone: item.isDone);
        } else {
          rethrow;
        }
      }
    }

    // 3. 下行合并
    final notices = await api.fetchNotices();
    if (noticeCacheStore != null) {
      await noticeCacheStore!.save(notices);
    }
    final plan = planRemoteMerge(await repository.getAll(), notices);
    await repository.applyMergePlan(plan);

    return SyncResult(
      uploaded: uploaded,
      statusPushed: statusPushed,
      inserted: plan.inserts.length,
      updated: plan.updates.length,
      removed: plan.deletes.length,
      warnings: warnings,
      fetchedNotices: notices,
    );
  }
}
