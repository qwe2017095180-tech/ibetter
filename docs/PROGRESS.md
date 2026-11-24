# Progress Log

## Foundation (coordinator) — done
- Flutter 3.50.1 project `ibetter` (ios / android / web), deps: flutter_riverpod 3, go_router 18, drift 2.35 + drift_flutter, flutter_local_notifications 23, timezone, flutter_timezone, intl.
- WP0 scaffold, WP1 data layer (`lib/core/db`, `lib/data/repositories`), WP2 domain (`lib/domain`), WP3 theme + shell (`lib/app`, `lib/core/widgets/common.dart`), shared providers (`lib/core/providers.dart`).
- Contracts/stubs for feature agents: `features/home/home_page.dart`, `features/projects/projects_page.dart`, `features/project_editor/project_editor_page.dart`, `features/icon_picker/icon_registry.dart`, `features/reminders/notification_service.dart`.
- Tests: `test/domain/domain_services_test.dart`, `test/data/repositories_test.dart`.

Flutter binary: `export PATH="$HOME/development/flutter/bin:$PATH"`

<!-- Feature agents: append your WP section below -->
