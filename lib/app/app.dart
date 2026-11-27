import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/passcode_page.dart';
import 'app_brand.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class IBetterApp extends ConsumerWidget {
  const IBetterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
