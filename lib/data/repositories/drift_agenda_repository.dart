import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../domain/models/agenda_item.dart';
import '../../domain/services/agenda_sync_rules.dart';
import 'repositories.dart';

AgendaItem _agendaFromRow(AgendaRow r) => AgendaItem(
      id: r.id,
      date: r.date,
      minutesOfDay: r.minutesOfDay,
      title: r.title,
      note: r.note,
      category: r.category,
      origin: r.origin,
      isDone: r.isDone,
      source: r.source == 1 ? AgendaSource.qingsong : AgendaSource.local,
      clientId: r.clientId,
      remoteId: r.remoteId,
      syncToRemote: r.syncToRemote,
      dirty: r.dirty,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );

final _random = Random.secure();

/// `ib-<时间戳36进制>-<8位随机>`，作为上行时的 externalId。
String newAgendaClientId() {
  final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final rand = List.generate(8, (_) => _random.nextInt(36).toRadixString(36)).join();
  return 'ib-$ts-$rand';
}

class DriftAgendaRepository implements AgendaRepository {
  DriftAgendaRepository(this._db, {int Function()? clock})
      : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final int Function() _clock;

  $AgendaItemsTable get _t => _db.agendaItems;

  @override
  Stream<List<AgendaItem>> watchByDate(String date) =>
      (_db.select(_t)..where((t) => t.date.equals(date) & t.isHidden.equals(false)))
          .watch()
          .map((rows) => rows.map(_agendaFromRow).toList()..sort(AgendaItem.compareForDisplay));

  @override
  Stream<List<AgendaItem>> watchAllVisible() =>
      (_db.select(_t)..where((t) => t.isHidden.equals(false)))
          .watch()
          .map((rows) => rows.map(_agendaFromRow).toList());

  @override
  Future<List<AgendaItem>> getAll() async =>
      (await _db.select(_t).get()).map(_agendaFromRow).toList();

  @override
  Future<AgendaItem?> getById(int id) async {
    final r = await (_db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _agendaFromRow(r);
  }

  @override
  Future<int> create(AgendaDraft d) {
    final title = d.title.trim();
    if (title.isEmpty) throw ArgumentError('标题不能为空');
    final now = _clock();
    return _db.into(_t).insert(AgendaItemsCompanion.insert(
          date: d.date,
          minutesOfDay: Value(d.minutesOfDay),
          title: title.length > agendaTitleMaxLength ? title.substring(0, agendaTitleMaxLength) : title,
          note: Value(d.note.trim()),
          category: Value(d.category),
          source: const Value(0),
          clientId: newAgendaClientId(),
          syncToRemote: Value(d.syncToRemote),
          createdAt: now,
          updatedAt: now,
        ));
  }

  @override
  Future<void> setDone(int id, bool done) async {
    final item = await getById(id);
    if (item == null || item.isDone == done) return;
    await (_db.update(_t)..where((t) => t.id.equals(id))).write(AgendaItemsCompanion(
      isDone: Value(done),
      dirty: Value(item.remoteId != null),
      updatedAt: Value(_clock()),
    ));
  }

  @override
  Future<void> delete(int id) async {
    final item = await getById(id);
    if (item == null) return;
    if (item.remoteId == null) {
      await (_db.delete(_t)..where((t) => t.id.equals(id))).go();
    } else {
      await (_db.update(_t)..where((t) => t.id.equals(id)))
          .write(AgendaItemsCompanion(isHidden: const Value(true), updatedAt: Value(_clock())));
    }
  }

  @override
  Future<List<AgendaItem>> pendingUploads() async => (await (_db.select(_t)
            ..where((t) => t.source.equals(0) & t.syncToRemote.equals(true) & t.remoteId.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get())
      .map(_agendaFromRow)
      .toList();

  @override
  Future<List<AgendaItem>> pendingStatusChanges() async => (await (_db.select(_t)
            ..where((t) => t.dirty.equals(true) & t.remoteId.isNotNull()))
          .get())
      .map(_agendaFromRow)
      .toList();

  @override
  Future<void> markUploaded(int id, String remoteId) async {
    await _db.transaction(() async {
      // 极端情况下远端 id 已被另一条本地记录占用（例如重复拉取），先让出唯一约束
      await (_db.update(_t)..where((t) => t.remoteId.equals(remoteId) & t.id.equals(id).not()))
          .write(const AgendaItemsCompanion(remoteId: Value(null)));
      await (_db.update(_t)..where((t) => t.id.equals(id)))
          .write(AgendaItemsCompanion(remoteId: Value(remoteId), updatedAt: Value(_clock())));
    });
  }

  @override
  Future<void> markStatusPushed(int id, {required bool pushedDone}) async {
    await (_db.update(_t)..where((t) => t.id.equals(id) & t.isDone.equals(pushedDone)))
        .write(const AgendaItemsCompanion(dirty: Value(false)));
  }

  @override
  Future<void> applyMergePlan(MergePlan plan) async {
    if (plan.isEmpty) return;
    final now = _clock();
    await _db.transaction(() async {
      if (plan.deletes.isNotEmpty) {
        await (_db.delete(_t)..where((t) => t.id.isIn(plan.deletes))).go();
      }
      for (final id in plan.detaches) {
        await (_db.update(_t)..where((t) => t.id.equals(id))).write(AgendaItemsCompanion(
          remoteId: const Value(null),
          syncToRemote: const Value(false),
          dirty: const Value(false),
          updatedAt: Value(now),
        ));
      }
      for (final u in plan.updates) {
        final c = u.content;
        await (_db.update(_t)..where((t) => t.id.equals(u.id))).write(AgendaItemsCompanion(
          remoteId: u.remoteId == null ? const Value.absent() : Value(u.remoteId),
          date: c == null ? const Value.absent() : Value(c.date),
          minutesOfDay: c == null ? const Value.absent() : Value(c.minutesOfDay),
          title: c == null ? const Value.absent() : Value(c.title),
          note: c == null ? const Value.absent() : Value(c.note),
          category: c == null ? const Value.absent() : Value(c.category),
          origin: c == null ? const Value.absent() : Value(c.origin),
          isDone: u.isDone == null ? const Value.absent() : Value(u.isDone!),
          updatedAt: Value(now),
        ));
      }
      for (final e in plan.inserts) {
        await _db.into(_t).insert(
              AgendaItemsCompanion.insert(
                date: e.date,
                minutesOfDay: Value(e.minutesOfDay),
                title: e.title,
                note: Value(e.note),
                category: Value(e.category),
                origin: Value(e.origin),
                isDone: Value(e.isDone),
                source: const Value(1),
                clientId: 'qs-${e.remoteId}',
                remoteId: Value(e.remoteId),
                createdAt: now,
                updatedAt: now,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }
}
