import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/domain/date_key.dart';
import 'package:ibetter/domain/models/habit.dart';
import 'package:ibetter/domain/models/reminder.dart';
import 'package:ibetter/features/reminders/local_notification_service.dart';
import 'package:ibetter/features/reminders/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ScheduledCall {
  const ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.notificationDetails,
    required this.androidScheduleMode,
    required this.matchDateTimeComponents,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails notificationDetails;
  final AndroidScheduleMode androidScheduleMode;
  final DateTimeComponents? matchDateTimeComponents;
  final String? payload;
}

class FakeNotificationSchedulerAdapter implements NotificationSchedulerAdapter {
  bool initialized = false;
  InitializationSettings? lastInitSettings;
  final List<AndroidNotificationChannel> createdChannels = [];
  bool androidPermissionResult = true;
  bool darwinPermissionResult = true;
  int androidPermissionCalls = 0;
  int darwinPermissionCalls = 0;

  final List<ScheduledCall> scheduledCalls = [];
  final List<int> cancelledIds = [];
  final Map<int, PendingNotificationRequest> pending = {};

  void seedPending(PendingNotificationRequest req) {
    pending[req.id] = req;
  }

  @override
  Future<void> initialize({required InitializationSettings settings}) async {
    initialized = true;
    lastInitSettings = settings;
  }

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {
    createdChannels.add(channel);
  }

  @override
  Future<bool> requestAndroidNotificationsPermission() async {
    androidPermissionCalls++;
    return androidPermissionResult;
  }

  @override
  Future<bool> requestDarwinPermissions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) async {
    darwinPermissionCalls++;
    return darwinPermissionResult;
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
  }) async {
    scheduledCalls.add(
      ScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      ),
    );
    pending[id] = PendingNotificationRequest(id, title, body, payload);
  }

  @override
  Future<void> cancel({required int id}) async {
    cancelledIds.add(id);
    pending.remove(id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      pending.values.toList();
}

Habit _makeHabit({
  required int id,
  String name = '早起喝水',
  String motto = '',
  bool isActive = true,
}) =>
    Habit(
      id: id,
      name: name,
      iconKey: 'health/water',
      startDate: DateTime(2026, 11, 1),
      motto: motto,
      isActive: isActive,
      createdAt: DateTime(2026, 11, 1),
    );

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('nextInstance', () {
    test('daily: today later time returns same day', () {
      // 2026-11-24 08:30 UTC
      final now = tz.TZDateTime.utc(2026, 11, 24, 8, 30);
      final next = nextInstance(now, 9 * 60 + 15);
      expect(next, tz.TZDateTime.utc(2026, 11, 24, 9, 15));
    });

    test('daily: today passed (and exact match) rolls over to tomorrow', () {
      final passed = tz.TZDateTime.utc(2026, 11, 24, 10, 0);
      expect(
        nextInstance(passed, 9 * 60 + 15),
        tz.TZDateTime.utc(2026, 11, 25, 9, 15),
      );

      final exact = tz.TZDateTime.utc(2026, 11, 24, 9, 15);
      expect(
        nextInstance(exact, 9 * 60 + 15),
        tz.TZDateTime.utc(2026, 11, 25, 9, 15),
      );

      // Month/year rollover on Dec 31 passed -> Jan 1
      final yearEnd = tz.TZDateTime.utc(2026, 12, 31, 22, 0);
      expect(
        nextInstance(yearEnd, 8 * 60),
        tz.TZDateTime.utc(2027, 1, 1, 8, 0),
      );
    });

    test('weekday rollover including week wrap (0 = Sun .. 6 = Sat)', () {
      // 2026-11-24 is Tuesday (weekdayIdx = 2), 10:00 UTC.
      final tuesday = tz.TZDateTime.utc(2026, 11, 24, 10, 0);

      // Same weekday later today -> today
      expect(
        nextInstance(tuesday, 11 * 60, 2),
        tz.TZDateTime.utc(2026, 11, 24, 11, 0),
      );

      // Same weekday already passed -> wraps 7 days to next Tuesday
      expect(
        nextInstance(tuesday, 9 * 60, 2),
        tz.TZDateTime.utc(2026, 12, 1, 9, 0),
      );

      // Later this week: Friday (5) -> Nov 27
      expect(
        nextInstance(tuesday, 8 * 60, 5),
        tz.TZDateTime.utc(2026, 11, 27, 8, 0),
      );

      // Earlier weekday wraps across Sunday to next Monday (1) -> Nov 30
      expect(
        nextInstance(tuesday, 8 * 60, 1),
        tz.TZDateTime.utc(2026, 11, 30, 8, 0),
      );

      // Saturday (6) -> Sunday (0) wraps across week start
      final saturday = tz.TZDateTime.utc(2026, 11, 28, 21, 0);
      expect(
        nextInstance(saturday, 7 * 60 + 30, 0),
        tz.TZDateTime.utc(2026, 11, 29, 7, 30),
      );
    });

    test('works identically with a fixed-offset non-UTC location', () {
      final shanghai = tz.getLocation('Asia/Shanghai');
      final now = tz.TZDateTime(shanghai, 2026, 11, 24, 23, 50);
      final next = nextInstance(now, 7 * 60);
      expect(next, tz.TZDateTime(shanghai, 2026, 11, 25, 7, 0));
      expect(next.location, shanghai);
    });
  });

  group('notificationId scheme', () {
    test('is unique for 3 reminders x 7 weekdays and daily index', () {
      const habitId = 7;
      final ids = <int>{};
      for (var r = 0; r < 3; r++) {
        for (var w = 0; w <= dailyWeekdayIdx; w++) {
          final id = notificationId(habitId, r, w);
          expect(id, greaterThanOrEqualTo(habitId * 100));
          expect(id, lessThanOrEqualTo(habitId * 100 + 99));
          expect(ids.add(id), isTrue, reason: 'Duplicate id $id for r=$r w=$w');
        }
      }
      expect(ids.length, 3 * 8);
      // Distinct from adjacent habit blocks
      expect(notificationId(habitId + 1, 0, 0), greaterThan(notificationId(habitId, 11, 7)));
    });
  });

  group('LocalNotificationService', () {
    late FakeNotificationSchedulerAdapter adapter;
    late LocalNotificationService service;
    final fixedNow = tz.TZDateTime.utc(2026, 11, 24, 8, 0);

    setUp(() {
      adapter = FakeNotificationSchedulerAdapter();
      service = LocalNotificationService(
        adapter: adapter,
        getLocalTimezone: () async => 'UTC',
        locationProvider: () => tz.UTC,
        nowProvider: () => fixedNow,
        isSupportedPlatformOverride: true,
      );
    });

    test('init configures timezone, plugin without permission prompt, and Android channel', () async {
      await service.init();

      expect(adapter.initialized, isTrue);
      expect(adapter.lastInitSettings?.android?.defaultIcon, '@mipmap/ic_launcher');
      expect(adapter.lastInitSettings?.iOS?.requestAlertPermission, isFalse);
      expect(adapter.lastInitSettings?.iOS?.requestBadgePermission, isFalse);
      expect(adapter.lastInitSettings?.iOS?.requestSoundPermission, isFalse);
      expect(adapter.androidPermissionCalls, 0);
      expect(adapter.darwinPermissionCalls, 0);
      expect(adapter.createdChannels, hasLength(1));
      expect(adapter.createdChannels.single.id, 'habit_reminders');
      expect(adapter.createdChannels.single.name, '打卡提醒');
    });

    test('inactive habit cancels existing notifications and schedules nothing', () async {
      const habitId = 4;
      adapter.seedPending(
        const PendingNotificationRequest(407, 'Old', 'Old body', 'habit:4'),
      );
      adapter.seedPending(
        const PendingNotificationRequest(507, 'Other', 'Other body', 'habit:5'),
      );

      final inactiveHabit = _makeHabit(id: habitId, isActive: false);
      final reminders = [
        const Reminder(
          id: 1,
          habitId: habitId,
          minutesOfDay: 9 * 60,
          weekdaysMask: allWeekdaysMask,
          enabled: true,
        ),
      ];

      await service.syncHabit(inactiveHabit, reminders);

      expect(adapter.scheduledCalls, isEmpty);
      expect(adapter.cancelledIds, [407]);
      expect(adapter.pending.keys, [507]);
    });

    test('syncHabit schedules daily and per-weekday reminders with fallback body and inexact mode', () async {
      final habit = _makeHabit(id: 2, name: '阅读', motto: '');
      // Mon(1) + Wed(3) + Fri(5) = 0x2A
      const mwfMask = (1 << 1) | (1 << 3) | (1 << 5);
      final reminders = [
        const Reminder(
          id: 10,
          habitId: 2,
          minutesOfDay: 9 * 60,
          weekdaysMask: allWeekdaysMask,
          enabled: true,
        ),
        const Reminder(
          id: 11,
          habitId: 2,
          minutesOfDay: 20 * 60,
          weekdaysMask: allWeekdaysMask,
          enabled: false,
        ),
        const Reminder(
          id: 12,
          habitId: 2,
          minutesOfDay: 21 * 60 + 30,
          weekdaysMask: mwfMask,
          enabled: true,
        ),
      ];

      await service.syncHabit(habit, reminders);

      // 1 daily (index 0 -> id 207) + 3 weekday (index 1 -> ids 209, 211, 213)
      expect(adapter.scheduledCalls, hasLength(4));
      expect(adapter.scheduledCalls.map((c) => c.id), [207, 209, 211, 213]);

      final dailyCall = adapter.scheduledCalls.first;
      expect(dailyCall.title, '阅读');
      expect(dailyCall.body, '该打卡啦！');
      expect(dailyCall.payload, 'habit:2');
      expect(dailyCall.androidScheduleMode, AndroidScheduleMode.inexactAllowWhileIdle);
      expect(dailyCall.matchDateTimeComponents, DateTimeComponents.time);
      expect(dailyCall.scheduledDate, tz.TZDateTime.utc(2026, 11, 24, 9, 0));

      for (final weekdayCall in adapter.scheduledCalls.skip(1)) {
        expect(weekdayCall.matchDateTimeComponents, DateTimeComponents.dayOfWeekAndTime);
        expect(weekdayCall.androidScheduleMode, AndroidScheduleMode.inexactAllowWhileIdle);
        expect(weekdayCall.payload, 'habit:2');
      }
    });

    test('resyncAll syncs active habits, clears paused habits, and cancels orphans', () async {
      adapter.seedPending(
        const PendingNotificationRequest(9907, 'Deleted', 'Orphan', 'habit:99'),
      );
      adapter.seedPending(
        const PendingNotificationRequest(207, 'Paused', 'Old', 'habit:2'),
      );

      final habits = [
        _makeHabit(id: 1, name: '跑步', motto: '跑起来', isActive: true),
        _makeHabit(id: 2, name: '冥想', isActive: false),
      ];
      final reminders = [
        const Reminder(
          id: 1,
          habitId: 1,
          minutesOfDay: 7 * 60,
          weekdaysMask: allWeekdaysMask,
          enabled: true,
        ),
        const Reminder(
          id: 2,
          habitId: 2,
          minutesOfDay: 22 * 60,
          weekdaysMask: allWeekdaysMask,
          enabled: true,
        ),
      ];

      await service.resyncAll(habits, reminders);

      expect(adapter.pending.keys, [107]);
      expect(adapter.pending[107]?.body, '跑起来');
      expect(adapter.cancelledIds, containsAll([207, 9907]));
    });

    test('unsupported platform makes all operations no-ops', () async {
      final webOrDesktopService = LocalNotificationService(
        adapter: adapter,
        isSupportedPlatformOverride: false,
      );

      await webOrDesktopService.init();
      expect(await webOrDesktopService.requestPermission(), isFalse);
      await webOrDesktopService.syncHabit(
        _makeHabit(id: 1),
        const [Reminder(id: 1, habitId: 1, minutesOfDay: 540)],
      );
      await webOrDesktopService.cancelHabit(1);
      await webOrDesktopService.resyncAll(
        [_makeHabit(id: 1)],
        const [Reminder(id: 1, habitId: 1, minutesOfDay: 540)],
      );

      expect(adapter.initialized, isFalse);
      expect(adapter.scheduledCalls, isEmpty);
      expect(adapter.cancelledIds, isEmpty);
    });

    test('requestPermission routes to Darwin on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final granted = await service.requestPermission();
        expect(granted, isTrue);
        expect(adapter.darwinPermissionCalls, 1);
        expect(adapter.androidPermissionCalls, 0);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('requestPermission routes to Android notifications permission', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final granted = await service.requestPermission();
        expect(granted, isTrue);
        expect(adapter.androidPermissionCalls, 1);
        expect(adapter.darwinPermissionCalls, 0);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('init falls back to UTC if timezone lookup fails', () async {
      final fallbackService = LocalNotificationService(
        adapter: adapter,
        getLocalTimezone: () async => throw Exception('tz lookup failed'),
        isSupportedPlatformOverride: true,
      );

      await fallbackService.init();

      expect(adapter.initialized, isTrue);
      expect(tz.local, tz.UTC);
    });

    test('notificationServiceProvider resolves to LocalNotificationService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(notificationServiceProvider),
        isA<LocalNotificationService>(),
      );
    });
  });
}
