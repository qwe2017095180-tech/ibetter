import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/drift_repositories.dart';
import '../data/repositories/repositories.dart';
import '../domain/date_key.dart' as dk;
import '../domain/models/check_in.dart';
import '../domain/models/habit.dart';
import '../domain/services/schedule_service.dart';
import '../domain/services/stats_service.dart';
import '../domain/services/streak_service.dart';
import 'db/app_database.dart';

/// Shared, app-wide providers. Feature-specific providers live in their feature folder.

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final habitRepositoryProvider =
    Provider<HabitRepository>((ref) => DriftHabitRepository(ref.watch(databaseProvider)));
final checkInRepositoryProvider =
    Provider<CheckInRepository>((ref) => DriftCheckInRepository(ref.watch(databaseProvider)));
final reminderRepositoryProvider =
    Provider<ReminderRepository>((ref) => DriftReminderRepository(ref.watch(databaseProvider)));

final scheduleServiceProvider = Provider((ref) => const ScheduleService());
final streakServiceProvider = Provider((ref) => const StreakService());
final statsServiceProvider = Provider((ref) => const StatsService());

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
