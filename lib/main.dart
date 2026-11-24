import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'features/reminders/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  final container = ProviderContainer();
  // Best effort: notification init must never block app start.
  try {
    await container.read(notificationServiceProvider).init();
  } catch (e, st) {
    debugPrint('Notification init failed: $e\n$st');
  }
  runApp(UncontrolledProviderScope(container: container, child: const IBetterApp()));
}
