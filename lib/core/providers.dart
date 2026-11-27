import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_service.dart';
import '../data/repositories/drift_agenda_repository.dart';
import '../data/repositories/drift_repositories.dart';
import '../data/repositories/repositories.dart';
import '../domain/date_key.dart' as dk;
import '../domain/models/check_in.dart';
import '../domain/models/habit.dart';
import '../domain/services/achievement_service.dart';
import '../domain/services/history_service.dart';
import '../domain/services/schedule_service.dart';
import '../domain/services/stats_service.dart';
import '../domain/services/streak_service.dart';
import 'db/app_database.dart';
import 'prefs/app_prefs.dart';

/// Shared, app-wide providers. Feature-specific providers live in their feature folder.

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final habitRepositoryProvider =
    Provider<HabitRepository>((ref) => DriftHabitRepository(ref.watch(databaseProvider)));
final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => DriftCheckInRepository(
    ref.watch(databaseProvider),
    now: ref.watch(nowProvider),
  ),
);
final reminderRepositoryProvider =
    Provider<ReminderRepository>((ref) => DriftReminderRepository(ref.watch(databaseProvider)));
final agendaRepositoryProvider =
    Provider<AgendaRepository>((ref) => DriftAgendaRepository(ref.watch(databaseProvider)));

final scheduleServiceProvider = Provider((ref) => const ScheduleService());
final streakServiceProvider = Provider((ref) => const StreakService());
final statsServiceProvider = Provider((ref) => const StatsService());
final achievementServiceProvider = Provider((ref) => const AchievementService());
final historyServiceProvider = Provider((ref) => const HistoryService());

final appPrefsStoreProvider = Provider<AppPrefsStore>((ref) => FileAppPrefsStore());

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider), ref.watch(appPrefsStoreProvider)),
);

class AppPrefsNotifier extends AsyncNotifier<AppPrefs> {
  @override
  Future<AppPrefs> build() => ref.watch(appPrefsStoreProvider).load();

  Future<void> _commit(AppPrefs updated) async {
    state = AsyncData(updated);
    await ref.read(appPrefsStoreProvider).save(updated);
  }

  Future<void> reload() async {
    final loaded = await ref.read(appPrefsStoreProvider).load();
    state = AsyncData(loaded);
  }

  Future<void> recordShare(DateTime today) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(
      shareCount: current.shareCount + 1,
      lastShareDate: dk.dateKey(today),
    ));
  }

  Future<void> markAchievementsSeen(int totalCount) async {
    final current = state.asData?.value ?? const AppPrefs();
    if (totalCount <= current.seenAchievementCount) return;
    await _commit(current.copyWith(seenAchievementCount: totalCount));
  }

  Future<void> updateProfile({
    String? nickname,
    String? handle,
    String? bio,
    String? avatarPreset,
    String? avatarImagePath,
    bool clearAvatarImage = false,
    String? coverPreset,
    String? coverImagePath,
    bool clearCoverImage = false,
  }) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(
      nickname: nickname,
      handle: handle,
      bio: bio,
      avatarPreset: avatarPreset,
      avatarImagePath: avatarImagePath,
      clearAvatarImage: clearAvatarImage,
      coverPreset: coverPreset,
      coverImagePath: coverImagePath,
      clearCoverImage: clearCoverImage,
    ));
  }

  Future<void> markInboxRead(String id) async {
    final current = state.asData?.value ?? const AppPrefs();
    if (current.readInboxIds.contains(id)) return;
    await _commit(current.copyWith(readInboxIds: [...current.readInboxIds, id]));
  }

  Future<void> setCardStyle(CardStyle style) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(cardStyle: style));
  }

  Future<void> setCardLayout(CardLayout layout) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(cardLayout: layout));
  }

  Future<void> setCalendarDoneTheme(CalendarDoneTheme theme) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(calendarDoneTheme: theme));
  }

  Future<void> setWeekStartsOnMonday(bool value) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(weekStartsOnMonday: value));
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(soundEnabled: enabled));
  }

  Future<void> setAchievementDisplayStyle(CelebrationStyle style) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(achievementDisplayStyle: style));
  }

  Future<void> setPerfectDayDisplayStyle(CelebrationStyle style) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(perfectDayDisplayStyle: style));
  }

  Future<void> setReportDisplayStyle(CelebrationStyle style) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(reportDisplayStyle: style));
  }

  Future<void> setReportReminder({bool? enabled, int? minutesOfDay}) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(
      reportReminderEnabled: enabled,
      reportReminderMinutes: minutesOfDay,
    ));
  }

  Future<void> setPasscode(String pin) async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(passcodeEnabled: true, passcode: pin));
  }

  Future<void> disablePasscode() async {
    final current = state.asData?.value ?? const AppPrefs();
    await _commit(current.copyWith(passcodeEnabled: false, clearPasscode: true));
  }
}

final appPrefsProvider = AsyncNotifierProvider<AppPrefsNotifier, AppPrefs>(
  AppPrefsNotifier.new,
);

/// Overall achievement stats derived from habits, check-ins, and share prefs.
final overallStatsProvider = Provider<OverallStats>((ref) {
  final habits = ref.watch(habitsProvider).asData?.value ?? const <Habit>[];
  final checkIns = ref.watch(allCheckInsProvider).asData?.value ?? const <CheckIn>[];
  final prefs = ref.watch(appPrefsProvider).asData?.value ?? const AppPrefs();
  return ref.watch(achievementServiceProvider).compute(
        habits,
        checkIns,
        today: ref.watch(todayProvider),
        shareCount: prefs.shareCount,
        lastShareDate: prefs.lastShareDate,
      );
});

/// Unread achievement count shown as a red badge on the Trophy tab.
final unreadAchievementsCountProvider = Provider<int>((ref) {
  final stats = ref.watch(overallStatsProvider);
  final prefs = ref.watch(appPrefsProvider).asData?.value ?? const AppPrefs();
  final diff = stats.totalAchievementCount - prefs.seenAchievementCount;
  return diff > 0 ? diff : 0;
});

/// Current local date. Override in tests.
final todayProvider = Provider<DateTime>((ref) => dk.today());

/// All habits (active and paused), ordered.
final habitsProvider =
    StreamProvider<List<Habit>>((ref) => ref.watch(habitRepositoryProvider).watchAll());

/// All check-ins (fine for a local single-user DB; stats derive from this).
final allCheckInsProvider =
    StreamProvider<List<CheckIn>>((ref) => ref.watch(checkInRepositoryProvider).watchAll());

/// Stats for one habit, derived from [habitsProvider] + [allCheckInsProvider].
final habitStatsProvider = Provider.family<HabitStats, int>((ref, habitId) {
  final habits = ref.watch(habitsProvider).asData?.value ?? const <Habit>[];
  final checkIns = ref.watch(allCheckInsProvider).asData?.value ?? const <CheckIn>[];
  final habit = habits.where((h) => h.id == habitId).firstOrNull;
  if (habit == null) return HabitStats.empty;
  return ref.watch(statsServiceProvider).compute(habit, checkIns, today: ref.watch(todayProvider));
});

/// Selected day on the home calendar.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => ref.watch(todayProvider);

  void select(DateTime d) => state = dk.dateOnly(d);
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);
