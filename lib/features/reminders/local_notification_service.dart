import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/date_key.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/reminder.dart';
import 'notification_service.dart';

const String habitRemindersChannelId = 'habit_reminders';
const String habitRemindersChannelName = '打卡提醒';
const String habitRemindersChannelDescription = '习惯定时打卡提醒';
const String defaultReminderBody = '该打卡啦！';
const String habitPayloadPrefix = 'habit:';

/// Sentinel `weekdayIdx` representing a single daily repeating notification
/// (`weekdaysMask == 127`).
const int dailyWeekdayIdx = 7;

/// Maximum enabled reminders per habit within a 100-ID block (`0..11` => offsets `0..95`).
const int maxRemindersPerHabit = 12;

/// Maximum [habitId] keeping `habitId * 100 + 99` within signed 32-bit int (`<= 2^31 - 1`).
const int maxSafeHabitId = 21474835;

/// Deterministic, int32-safe notification ID scheme:
///
/// `id = habitId * 100 + reminderIndex * 8 + weekdayIdx`
///
/// - `habitId`: `0..21474835` (each habit owns a 100-ID block `habitId*100 .. habitId*100+99`).
/// - `reminderIndex`: `0..11` (up to 12 enabled reminders per habit; offsets `0..95` fit in `0..99`).
/// - `weekdayIdx`: `0..6` (`0` = Sunday .. `6` = Saturday), or `7` for a single daily repeat.
int notificationId(int habitId, int reminderIndex, int weekdayIdx) {
  RangeError.checkValueInInterval(habitId, 0, maxSafeHabitId, 'habitId');
  RangeError.checkValueInInterval(
    reminderIndex,
    0,
    maxRemindersPerHabit - 1,
    'reminderIndex',
  );
  RangeError.checkValueInInterval(weekdayIdx, 0, dailyWeekdayIdx, 'weekdayIdx');
  return habitId * 100 + reminderIndex * 8 + weekdayIdx;
}

/// Payload attached to scheduled notifications for [habitId].
String habitPayload(int habitId) => '$habitPayloadPrefix$habitId';

/// Computes the next scheduled [tz.TZDateTime] strictly after [now] for
/// [minutesOfDay] (`0..1439`) in [now]'s [tz.Location].
///
/// When [weekdayIdx] is `null` or `7` ([dailyWeekdayIdx]), returns the next
/// daily occurrence (today if still in the future, otherwise tomorrow).
/// When [weekdayIdx] is `0..6` (`0` = Sunday .. `6` = Saturday), returns the
/// next occurrence on that weekday (wrapping to next week when needed).
tz.TZDateTime nextInstance(
  tz.TZDateTime now,
  int minutesOfDay, [
  int? weekdayIdx,
]) {
  RangeError.checkValueInInterval(minutesOfDay, 0, 1439, 'minutesOfDay');
  if (weekdayIdx != null) {
    RangeError.checkValueInInterval(
      weekdayIdx,
      0,
      dailyWeekdayIdx,
      'weekdayIdx',
    );
  }

  final hour = minutesOfDay ~/ 60;
  final minute = minutesOfDay % 60;

  if (weekdayIdx == null || weekdayIdx == dailyWeekdayIdx) {
    var scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  final currentWeekdayIdx = now.weekday % 7;
  final daysAhead = (weekdayIdx - currentWeekdayIdx + 7) % 7;
  var scheduled = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + daysAhead,
    hour,
    minute,
  );
  if (!scheduled.isAfter(now)) {
    scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + daysAhead + 7,
      hour,
      minute,
    );
  }
  return scheduled;
}

/// Injectable adapter around [FlutterLocalNotificationsPlugin] so scheduling
/// behavior can be tested without platform channels.
abstract class NotificationSchedulerAdapter {
  Future<void> initialize({required InitializationSettings settings});

  Future<void> createAndroidChannel(AndroidNotificationChannel channel);

  Future<bool> requestAndroidNotificationsPermission();

  Future<bool> requestDarwinPermissions({
    required bool alert,
    required bool badge,
    required bool sound,
  });

  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  });

  Future<void> cancel({required int id});

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();
}

/// Default [NotificationSchedulerAdapter] backed by [FlutterLocalNotificationsPlugin].
class FlutterLocalNotificationsAdapter implements NotificationSchedulerAdapter {
  FlutterLocalNotificationsAdapter([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize({required InitializationSettings settings}) =>
      _plugin.initialize(settings: settings);

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  Future<bool> requestAndroidNotificationsPermission() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<bool> requestDarwinPermissions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: alert, badge: badge, sound: sound);
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: alert, badge: badge, sound: sound);
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) =>
      _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );

  @override
  Future<void> cancel({required int id}) => _plugin.cancel(id: id);

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() =>
      _plugin.pendingNotificationRequests();
}

/// Local notification scheduler powered by `flutter_local_notifications` and
/// `timezone`. No-ops on web and unsupported desktop targets.
class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    NotificationSchedulerAdapter? adapter,
    Future<String> Function()? getLocalTimezone,
    tz.Location Function()? locationProvider,
    tz.TZDateTime Function()? nowProvider,
    bool? isSupportedPlatformOverride,
  })  : _adapter = adapter ?? FlutterLocalNotificationsAdapter(),
        _getLocalTimezone = getLocalTimezone ?? _defaultGetLocalTimezone,
        _now = nowProvider ??
            (() => tz.TZDateTime.now((locationProvider ?? _defaultLocalLocation)())),
        _isSupportedPlatformCheck = isSupportedPlatformOverride == null
            ? _defaultIsSupportedPlatform
            : (() => isSupportedPlatformOverride);

  final NotificationSchedulerAdapter _adapter;
  final Future<String> Function() _getLocalTimezone;
  final tz.TZDateTime Function() _now;
  final bool Function() _isSupportedPlatformCheck;

  bool _initialized = false;

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      habitRemindersChannelId,
      habitRemindersChannelName,
      channelDescription: habitRemindersChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  static Future<String> _defaultGetLocalTimezone() async {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier;
  }

  static tz.Location _defaultLocalLocation() {
    if (!tz.timeZoneDatabase.isInitialized) return tz.UTC;
    return tz.local;
  }

  static bool _defaultIsSupportedPlatform() {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        true,
      TargetPlatform.linux ||
      TargetPlatform.windows ||
      TargetPlatform.fuchsia =>
        false,
    };
  }

  bool get _isSupportedPlatform => _isSupportedPlatformCheck();

  @override
  Future<void> init() async {
    if (!_isSupportedPlatform || _initialized) return;

    tz.initializeTimeZones();
    try {
      final tzName = await _getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e, st) {
      debugPrint('Failed to resolve local timezone, falling back to UTC: $e\n$st');
      tz.setLocalLocation(tz.UTC);
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _adapter.initialize(settings: initSettings);
    await _adapter.createAndroidChannel(
      const AndroidNotificationChannel(
        habitRemindersChannelId,
        habitRemindersChannelName,
        description: habitRemindersChannelDescription,
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isSupportedPlatform) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _adapter.requestAndroidNotificationsPermission();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _adapter.requestDarwinPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    return false;
  }

  @override
  Future<void> cancelHabit(int habitId) async {
    if (!_isSupportedPlatform) return;
    final pending = await _adapter.pendingNotificationRequests();
    final payload = habitPayload(habitId);
    final hasSafeRange = habitId >= 0 && habitId <= maxSafeHabitId;
    final blockStart = habitId * 100;
    final blockEnd = blockStart + 99;

    for (final req in pending) {
      final matchesPayload = req.payload == payload;
      final matchesRange =
          hasSafeRange && req.id >= blockStart && req.id <= blockEnd;
      if (matchesPayload || matchesRange) {
        await _adapter.cancel(id: req.id);
      }
    }
  }

  @override
  Future<void> syncHabit(Habit habit, List<Reminder> reminders) async {
    if (!_isSupportedPlatform) return;
    await cancelHabit(habit.id);
    if (!habit.isActive) return;
    if (habit.id < 0 || habit.id > maxSafeHabitId) {
      debugPrint('Skipping reminders for out-of-range habitId=${habit.id}');
      return;
    }

    final enabledReminders =
        reminders.where((r) => r.habitId == habit.id && r.enabled).toList();
    if (enabledReminders.isEmpty) return;

    final now = _now();
    final title = habit.name;
    final body = habit.motto.isEmpty ? defaultReminderBody : habit.motto;
    final payload = habitPayload(habit.id);

    final count = enabledReminders.length > maxRemindersPerHabit
        ? maxRemindersPerHabit
        : enabledReminders.length;

    for (var reminderIndex = 0; reminderIndex < count; reminderIndex++) {
      final reminder = enabledReminders[reminderIndex];
      final minutes = reminder.minutesOfDay.clamp(0, 1439);
      if (reminder.weekdaysMask == allWeekdaysMask) {
        await _adapter.zonedSchedule(
          id: notificationId(habit.id, reminderIndex, dailyWeekdayIdx),
          title: title,
          body: body,
          scheduledDate: nextInstance(now, minutes),
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } else {
        for (var weekdayIdx = 0; weekdayIdx < 7; weekdayIdx++) {
          if (!maskHas(reminder.weekdaysMask, weekdayIdx)) continue;
          await _adapter.zonedSchedule(
            id: notificationId(habit.id, reminderIndex, weekdayIdx),
            title: title,
            body: body,
            scheduledDate: nextInstance(now, minutes, weekdayIdx),
            notificationDetails: _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
        }
      }
    }
  }

  @override
  Future<void> resyncAll(List<Habit> habits, List<Reminder> reminders) async {
    if (!_isSupportedPlatform) return;

    final byHabit = <int, List<Reminder>>{};
    for (final reminder in reminders) {
      byHabit.putIfAbsent(reminder.habitId, () => <Reminder>[]).add(reminder);
    }

    final knownHabitIds = <int>{};
    for (final habit in habits) {
      knownHabitIds.add(habit.id);
      await syncHabit(habit, byHabit[habit.id] ?? const <Reminder>[]);
    }

    final pending = await _adapter.pendingNotificationRequests();
    for (final req in pending) {
      final payloadHabitId = _parseHabitIdFromPayload(req.payload);
      if (payloadHabitId != null) {
        if (!knownHabitIds.contains(payloadHabitId)) {
          await _adapter.cancel(id: req.id);
        }
      } else if ((req.payload == null || req.payload!.isEmpty) && req.id >= 0) {
        final blockHabitId = req.id ~/ 100;
        if (!knownHabitIds.contains(blockHabitId)) {
          await _adapter.cancel(id: req.id);
        }
      }
    }
  }

  int? _parseHabitIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(habitPayloadPrefix)) {
      return null;
    }
    return int.tryParse(payload.substring(habitPayloadPrefix.length));
  }
}
