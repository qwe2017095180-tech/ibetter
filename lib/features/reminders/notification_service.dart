import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/habit.dart';
import '../../domain/models/reminder.dart';
import 'local_notification_service.dart';

/// ===== Contract (WP8 owns the implementation, keep this public API stable) =====
abstract class NotificationService {
  /// Initialise plugin + timezone. Safe to call once at startup.
  Future<void> init();

  /// Ask OS permission. Returns true if granted.
  Future<bool> requestPermission();

  /// Cancel all of [habit]'s scheduled notifications, then schedule [reminders]
  /// (only if habit.isActive and reminder.enabled).
  Future<void> syncHabit(Habit habit, List<Reminder> reminders);

  /// Cancel every notification of [habitId] (habit paused / deleted).
  Future<void> cancelHabit(int habitId);

  /// Re-sync everything (e.g. app start / timezone change).
  Future<void> resyncAll(List<Habit> habits, List<Reminder> reminders);
}

/// STUB no-op — WP8 replaces the provider body with the real implementation.
class NoopNotificationService implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> syncHabit(Habit habit, List<Reminder> reminders) async {}
  @override
  Future<void> cancelHabit(int habitId) async {}
  @override
  Future<void> resyncAll(List<Habit> habits, List<Reminder> reminders) async {}
}

final notificationServiceProvider = Provider<NotificationService>((ref) => LocalNotificationService());
