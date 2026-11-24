import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/providers.dart';
import 'features/reminders/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  final container = ProviderContainer();
  // Best effort: notification init must never block app start.
  try {
    final notifications = container.read(notificationServiceProvider);
    await notifications.init();
    unawaited(_resyncReminders(container, notifications));
  } catch (e, st) {
    debugPrint('Notification init failed: $e\n$st');
  }
  runApp(UncontrolledProviderScope(container: container, child: const IBetterApp()));
}

Future<void> _resyncReminders(
  ProviderContainer container,
  NotificationService notifications,
) async {
  try {
    final habits = await container.read(habitRepositoryProvider).watchAll().first;
    final reminders = await container.read(reminderRepositoryProvider).getAll();
    await notifications.resyncAll(habits, reminders);
  } catch (e, st) {
    debugPrint('Notification resync failed: $e\n$st');
  }
}
