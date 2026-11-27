import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/db/app_database.dart';
import '../core/prefs/app_prefs.dart';

/// Summary returned after an export or import operation.
class BackupSummary {
  const BackupSummary({
    required this.habitCount,
    required this.checkInCount,
    required this.reminderCount,
    this.filePath,
  });

  final int habitCount;
  final int checkInCount;
  final int reminderCount;
  final String? filePath;
}

/// JSON backup / restore service for all local habits, check-ins, reminders, and prefs.
class BackupService {
  const BackupService(this._db, this._prefsStore);

  final AppDatabase _db;
  final AppPrefsStore _prefsStore;

  static const int formatVersion = 1;
  static const String _backupFileName = 'qingsong_backup_latest.json';

  /// Serializes all habits, check-ins, reminders, and preferences into pretty JSON.
  Future<({String jsonText, BackupSummary summary})> exportJson() async {
    final habits = await _db.select(_db.habits).get();
    final checkIns = await _db.select(_db.checkIns).get();
    final reminders = await _db.select(_db.reminders).get();
    final prefs = await _prefsStore.load();

    final payload = <String, dynamic>{
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'prefs': prefs.toJson(),
      'habits': [
        for (final h in habits)
          {
            'id': h.id,
            'name': h.name,
            'iconKey': h.iconKey,
            'scheduleType': h.scheduleType,
            'scheduleValue': h.scheduleValue,
            'weekdaysMask': h.weekdaysMask,
            'goalDays': h.goalDays,
            'startDate': h.startDate,
            'motto': h.motto,
            'enableScore': h.enableScore,
            'enableMood': h.enableMood,
            'dailyTarget': h.dailyTarget,
            'isActive': h.isActive,
            'sortOrder': h.sortOrder,
            'createdAt': h.createdAt,
          },
      ],
      'checkIns': [
        for (final c in checkIns)
          {
            'habitId': c.habitId,
            'date': c.date,
            'count': c.doneCount,
            'score': c.score,
            'mood': c.mood,
            'note': c.note,
            'updatedAt': c.updatedAt,
          },
      ],
      'reminders': [
        for (final r in reminders)
          {
            'habitId': r.habitId,
            'minutesOfDay': r.minutesOfDay,
            'weekdaysMask': r.weekdaysMask,
            'enabled': r.enabled,
          },
      ],
    };

    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    String? savedPath;
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$_backupFileName');
        await file.writeAsString(jsonText);
        savedPath = file.path;
      } catch (e) {
        debugPrint('Skipping local backup file write: $e');
      }
    }

    return (
      jsonText: jsonText,
      summary: BackupSummary(
        habitCount: habits.length,
        checkInCount: checkIns.length,
        reminderCount: reminders.length,
        filePath: savedPath,
      ),
    );
  }

  /// Reads the latest saved local backup file if present.
  Future<String?> readLatestLocalBackup() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_backupFileName');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  /// Restores all habits, check-ins, reminders, and prefs from a JSON backup string.
  /// Throws [FormatException] if the JSON is malformed.
  Future<BackupSummary> importJson(String jsonText) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份内容不是有效的 JSON 对象');
    }
    final habitsRaw = decoded['habits'];
    final checkInsRaw = decoded['checkIns'];
    final remindersRaw = decoded['reminders'];
    if (habitsRaw is! List || checkInsRaw is! List) {
      throw const FormatException('备份缺少 habits 或 checkIns 数据');
    }

    var insertedHabits = 0;
    var insertedCheckIns = 0;
    var insertedReminders = 0;

    await _db.transaction(() async {
      await _db.delete(_db.reminders).go();
      await _db.delete(_db.checkIns).go();
      await _db.delete(_db.habits).go();

      final idMap = <int, int>{};
      for (final raw in habitsRaw) {
        if (raw is! Map<String, dynamic>) continue;
        final oldId = (raw['id'] as num?)?.toInt();
        final newId = await _db.into(_db.habits).insert(
              HabitsCompanion.insert(
                name: (raw['name'] as String?) ?? '未命名',
                iconKey: (raw['iconKey'] as String?) ?? 'study/book',
                scheduleType: Value((raw['scheduleType'] as num?)?.toInt() ?? 0),
                scheduleValue: Value((raw['scheduleValue'] as num?)?.toInt() ?? 0),
                weekdaysMask: Value((raw['weekdaysMask'] as num?)?.toInt() ?? 127),
                goalDays: Value((raw['goalDays'] as num?)?.toInt()),
                startDate: (raw['startDate'] as String?) ?? '2026-01-01',
                motto: Value((raw['motto'] as String?) ?? ''),
                enableScore: Value(raw['enableScore'] as bool? ?? false),
                enableMood: Value(raw['enableMood'] as bool? ?? false),
                dailyTarget: Value(((raw['dailyTarget'] as num?)?.toInt() ?? 1).clamp(1, 99)),
                isActive: Value(raw['isActive'] as bool? ?? true),
                sortOrder: Value((raw['sortOrder'] as num?)?.toInt() ?? insertedHabits),
                createdAt: (raw['createdAt'] as num?)?.toInt() ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
            );
        if (oldId != null) idMap[oldId] = newId;
        insertedHabits++;
      }

      for (final raw in checkInsRaw) {
        if (raw is! Map<String, dynamic>) continue;
        final oldHabitId = (raw['habitId'] as num?)?.toInt();
        final mappedId = oldHabitId == null ? null : idMap[oldHabitId];
        if (mappedId == null) continue;
        final date = raw['date'] as String?;
        if (date == null || date.isEmpty) continue;
        await _db.into(_db.checkIns).insert(
              CheckInsCompanion.insert(
                habitId: mappedId,
                date: date,
                doneCount: Value((raw['count'] as num?)?.toInt() ?? 1),
                score: Value((raw['score'] as num?)?.toInt()),
                mood: Value((raw['mood'] as num?)?.toInt()),
                note: Value(raw['note'] as String?),
                updatedAt: (raw['updatedAt'] as num?)?.toInt() ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
              mode: InsertMode.insertOrReplace,
            );
        insertedCheckIns++;
      }

      if (remindersRaw is List) {
        for (final raw in remindersRaw) {
          if (raw is! Map<String, dynamic>) continue;
          final oldHabitId = (raw['habitId'] as num?)?.toInt();
          final mappedId = oldHabitId == null ? null : idMap[oldHabitId];
          if (mappedId == null) continue;
          await _db.into(_db.reminders).insert(
                RemindersCompanion.insert(
                  habitId: mappedId,
                  minutesOfDay: ((raw['minutesOfDay'] as num?)?.toInt() ?? 540).clamp(0, 1439),
                  weekdaysMask: Value((raw['weekdaysMask'] as num?)?.toInt() ?? 127),
                  enabled: Value(raw['enabled'] as bool? ?? true),
                ),
              );
          insertedReminders++;
        }
      }
    });

    final prefsRaw = decoded['prefs'];
    if (prefsRaw is Map<String, dynamic>) {
      await _prefsStore.save(AppPrefs.fromJson(prefsRaw));
    }

    return BackupSummary(
      habitCount: insertedHabits,
      checkInCount: insertedCheckIns,
      reminderCount: insertedReminders,
    );
  }
}
