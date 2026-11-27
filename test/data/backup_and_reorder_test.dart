import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/core/db/app_database.dart';
import 'package:ibetter/core/prefs/app_prefs.dart';
import 'package:ibetter/data/backup_service.dart';
import 'package:ibetter/data/repositories/drift_repositories.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/models/reminder.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('AppPrefs JSON round-trip', () {
    test('preserves all profile, appearance, notification, and PIN fields', () {
      const original = AppPrefs(
        seenAchievementCount: 5,
        lastShareDate: '2026-11-26',
        nickname: '昔日',
        handle: '@forever_our',
        bio: 'The earth revolves around me.',
        avatarPreset: 'achievement/crown',
        avatarImagePath: '/tmp/avatar.png',
        coverPreset: 'starry_night',
        coverImagePath: '/tmp/cover.png',
        readInboxIds: ['msg_welcome_sync', 'msg_icons_160'],
        cardStyle: CardStyle.white,
        cardLayout: CardLayout.ultraCompact,
        calendarDoneTheme: CalendarDoneTheme.goldStar,
        weekStartsOnMonday: true,
        soundEnabled: false,
        achievementDisplayStyle: CelebrationStyle.banner,
        perfectDayDisplayStyle: CelebrationStyle.banner,
        reportDisplayStyle: CelebrationStyle.banner,
        reportReminderEnabled: true,
        reportReminderMinutes: 20 * 60 + 30,
        passcodeEnabled: true,
        passcode: '2580',
      );

      final roundTrip = AppPrefs.fromJson(original.toJson());
      expect(roundTrip.seenAchievementCount, 5);
      expect(roundTrip.lastShareDate, '2026-11-26');
      expect(roundTrip.nickname, '昔日');
      expect(roundTrip.handle, '@forever_our');
      expect(roundTrip.bio, 'The earth revolves around me.');
      expect(roundTrip.avatarPreset, 'achievement/crown');
      expect(roundTrip.avatarImagePath, '/tmp/avatar.png');
      expect(roundTrip.coverPreset, 'starry_night');
      expect(roundTrip.coverImagePath, '/tmp/cover.png');
      expect(roundTrip.readInboxIds, ['msg_welcome_sync', 'msg_icons_160']);
      expect(roundTrip.cardStyle, CardStyle.white);
      expect(roundTrip.cardLayout, CardLayout.ultraCompact);
      expect(roundTrip.calendarDoneTheme, CalendarDoneTheme.goldStar);
      expect(roundTrip.weekStartsOnMonday, isTrue);
      expect(roundTrip.soundEnabled, isFalse);
      expect(roundTrip.achievementDisplayStyle, CelebrationStyle.banner);
      expect(roundTrip.perfectDayDisplayStyle, CelebrationStyle.banner);
      expect(roundTrip.reportDisplayStyle, CelebrationStyle.banner);
      expect(roundTrip.reportReminderEnabled, isTrue);
      expect(roundTrip.reportReminderMinutes, 1230);
      expect(roundTrip.passcode, '2580');
      expect(roundTrip.hasActivePasscode, isTrue);
    });
  });

  group('HabitRepository.reorder', () {
    late AppDatabase db;
    late DriftHabitRepository habitRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      habitRepo = DriftHabitRepository(db);
    });

    tearDown(() async => db.close());

    test('persists reordered sortOrder in watchAll', () async {
      final idA = await habitRepo.create(
        HabitDraft(name: '应付作业', iconKey: 'study/book', startDate: DateTime(2026, 11, 20)),
      );
      final idB = await habitRepo.create(
        HabitDraft(name: '计算机常识学习', iconKey: 'study/code', startDate: DateTime(2026, 11, 20)),
      );
      final idC = await habitRepo.create(
        HabitDraft(name: '背单词', iconKey: 'study/english', startDate: DateTime(2026, 11, 20)),
      );

      await habitRepo.reorder([idC, idA, idB]);
      final ordered = await habitRepo.watchAll().first;
      expect(ordered.map((h) => h.name).toList(), ['背单词', '应付作业', '计算机常识学习']);
    });
  });

  group('BackupService export & restore', () {
    test('exports full DB + AppPrefs JSON and restores into a fresh database', () async {
      final db1 = AppDatabase(NativeDatabase.memory());
      final prefs1 = MemoryAppPrefsStore(
        const AppPrefs(
          nickname: '备份测试',
          handle: '@backup',
          cardStyle: CardStyle.white,
          cardLayout: CardLayout.compact,
          calendarDoneTheme: CalendarDoneTheme.pink,
          weekStartsOnMonday: true,
          passcodeEnabled: true,
          passcode: '1357',
        ),
      );

      final habits1 = DriftHabitRepository(db1);
      final checkIns1 = DriftCheckInRepository(db1);
      final reminders1 = DriftReminderRepository(db1);

      final id1 = await habits1.create(
        HabitDraft(
          name: '早睡早起',
          iconKey: 'health/crescent_moon',
          goalDays: 21,
          startDate: DateTime(2026, 11, 1),
          motto: '规律作息',
          dailyTarget: 1,
        ),
      );
      final id2 = await habits1.create(
        HabitDraft(
          name: '喝水',
          iconKey: 'health/droplet',
          startDate: DateTime(2026, 11, 1),
          dailyTarget: 4,
          enableScore: true,
        ),
      );
      await habits1.reorder([id2, id1]);
      await checkIns1.setCount(id2, '2026-11-24', 3);
      await checkIns1.saveDetail(id2, '2026-11-24', score: 90, mood: 4, note: '半日完成');
      await reminders1.replaceForHabit(id1, const [ReminderDraft(minutesOfDay: 1320)]);

      final exported = await BackupService(db1, prefs1).exportJson();
      expect(exported.summary.habitCount, 2);
      expect(exported.summary.checkInCount, 1);
      expect(exported.summary.reminderCount, 1);

      await db1.close();

      final db2 = AppDatabase(NativeDatabase.memory());
      final prefs2 = MemoryAppPrefsStore();
      try {
        final summary = await BackupService(db2, prefs2).importJson(exported.jsonText);
        expect(summary.habitCount, 2);
        expect(summary.checkInCount, 1);
        expect(summary.reminderCount, 1);

        final loadedHabits = await DriftHabitRepository(db2).watchAll().first;
        expect(loadedHabits.map((h) => h.name).toList(), ['喝水', '早睡早起']);

        final loadedCheckIns = await DriftCheckInRepository(db2).watchAll().first;
        expect(loadedCheckIns, hasLength(1));
        expect(loadedCheckIns.single.count, 3);
        expect(loadedCheckIns.single.score, 90);
        expect(loadedCheckIns.single.mood, 4);
        expect(loadedCheckIns.single.note, '半日完成');

        final restoredPrefs = await prefs2.load();
        expect(restoredPrefs.nickname, '备份测试');
        expect(restoredPrefs.cardStyle, CardStyle.white);
        expect(restoredPrefs.cardLayout, CardLayout.compact);
        expect(restoredPrefs.calendarDoneTheme, CalendarDoneTheme.pink);
        expect(restoredPrefs.weekStartsOnMonday, isTrue);
        expect(restoredPrefs.passcodeEnabled, isTrue);
        expect(restoredPrefs.passcode, '1357');
      } finally {
        await db2.close();
      }
    });

    test('importJson throws FormatException on invalid payload', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final service = BackupService(db, MemoryAppPrefsStore());
      try {
        await expectLater(service.importJson('{invalid'), throwsFormatException);
        await expectLater(service.importJson('{"habits": []}'), throwsFormatException);
      } finally {
        await db.close();
      }
    });
  });
}
