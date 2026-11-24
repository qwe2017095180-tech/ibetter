# Progress Log

## Foundation (coordinator) — done
- Flutter 3.50.1 project `ibetter` (ios / android / web), deps: flutter_riverpod 3, go_router 18, drift 2.35 + drift_flutter, flutter_local_notifications 23, timezone, flutter_timezone, intl.
- WP0 scaffold, WP1 data layer (`lib/core/db`, `lib/data/repositories`), WP2 domain (`lib/domain`), WP3 theme + shell (`lib/app`, `lib/core/widgets/common.dart`), shared providers (`lib/core/providers.dart`).
- Contracts/stubs for feature agents: `features/home/home_page.dart`, `features/projects/projects_page.dart`, `features/project_editor/project_editor_page.dart`, `features/icon_picker/icon_registry.dart`, `features/reminders/notification_service.dart`.
- Tests: `test/domain/domain_services_test.dart`, `test/data/repositories_test.dart`.

Flutter binary: `export PATH="$HOME/development/flutter/bin:$PATH"`

<!-- Feature agents: append your WP section below -->


## WP7 Icons — done
- Downloaded and resized (128×128 PNG) 160 open-source Microsoft Fluent Emoji 3D icons across 6 categories (`achievement`: 28, `health`: 28, `study`: 26, `sport`: 25, `life`: 27, `mind`: 26); total asset size 2.24 MB (2,345,989 bytes, < 4 MB limit). Removed `.gitkeep` files.
- Recorded source, copyright (`Copyright (c) Microsoft Corporation`), and MIT License text in `assets/ATTRIBUTION.md`.
- Generated `lib/features/icon_picker/icon_catalog.g.dart` from disk and implemented `IconRegistry` (with `achievement/star` fallback + `study/book` default + `errorBuilder` safety), `HabitIcon`, `IconPickerGrid` (5 columns, category headers with grey parenthesized subtitles, light-blue rounded selection + 2px `AppColors.primary` border, tap scale feedback), and `IconPickerPage` (`Navigator.pop` return).
- Added unit & widget tests in `test/features/icon_picker/icon_registry_test.dart`; `flutter analyze` and `flutter test test/features/icon_picker` pass.


## WP5 Projects — done
- Implemented `lib/features/projects/projects_page.dart`, `lib/features/projects/projects_providers.dart`, and widgets (`project_card.dart`, `project_sheets.dart`, `projects_empty_state.dart`).
- Added widget tests in `test/features/projects/projects_page_test.dart`.


## WP4 Home — done
- Files: `lib/features/home/home_page.dart`, `lib/features/home/home_providers.dart`, `lib/features/home/widgets/calendar_section.dart`, `lib/features/home/widgets/habit_check_in_card.dart`, `lib/features/home/widgets/home_empty_state.dart`, `lib/features/home/widgets/home_footer.dart`, `test/features/home/home_page_test.dart`.
- Notes: Implemented collapsible 5-row/1-row Sunday-first calendar with `AnimatedSize`, rolling 35-day window anchored 1 week before the selected week, horizontal swipe (`±5` weeks expanded, `±1` week collapsed), bilingual 1st-of-month labels (`DEC` + `12月`), `StatsService.dayCompletion` green dots, clock jump-to-today, scheduled habit check-in cards (`RaisedCard` + `HabitIcon`), multi-target increment/long-press decrement, future date guard (`SnackBar` `'不能为未来打卡'` + `0.5` opacity), empty states, and brand footer.
- Known gaps: Check-in detail modal/sheet (`score` / `mood` / `note` via `CheckInRepository.saveDetail`) is not yet wired on home cards (MVP check-in count toggle/increment works); calendar golden tests not added yet (functional widget tests in `test/features/home/home_page_test.dart` cover all behaviors).



## WP8 Reminders — done
- Implemented `LocalNotificationService` (`lib/features/reminders/local_notification_service.dart`) with injectable `NotificationSchedulerAdapter` / `FlutterLocalNotificationsAdapter`, deterministic int32-safe IDs (`habitId * 100 + reminderIndex * 8 + weekdayIdx`, `weekdayIdx = 7` for daily repeat), pure `nextInstance`, Android channel `'habit_reminders'` / `'打卡提醒'`, `AndroidScheduleMode.inexactAllowWhileIdle`, `requestPermission` for Android 13+ / iOS / macOS, `cancelHabit`, `syncHabit`, `resyncAll` (incl. orphan cleanup), and no-op behavior on web/unsupported platforms.
- Wired `notificationServiceProvider` in `lib/features/reminders/notification_service.dart` to return `LocalNotificationService()`, and added non-blocking startup `resyncAll` in `lib/main.dart`.
- Configured Android (`android/app/build.gradle.kts`: `compileSdk = 37`, `multiDexEnabled = true`, core library desugaring `desugar_jdk_libs:2.1.4`; `AndroidManifest.xml`: `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`, `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`) and iOS (`ios/Runner/AppDelegate.swift`: `UNUserNotificationCenter.current().delegate`).
- Added unit tests in `test/features/reminders/notification_scheduling_test.dart`; `flutter analyze` (0 issues) and `flutter test test/features/reminders` (14/14 passed) pass. `flutter build apk --debug` skipped (no Android SDK installed).
- Remaining: manual verification on physical Android/iOS devices (and adding `res/raw/keep.xml` if release builds use R8 resource shrinking with `@mipmap/ic_launcher`).


## WP6 Editor — done
- Implemented `ProjectEditorPage` (`lib/features/project_editor/project_editor_page.dart`) supporting both create (`habitId == null`) and edit (`habitId != null`) flows with dirty-check discard confirmation, validation, save/reminder sync, and edit-mode delete confirmation (`context.go(Routes.projects)`).
- Implemented `EditorController` + immutable `EditorState` / `EditorSnapshot` (`lib/features/project_editor/editor_controller.dart`) as an auto-dispose Riverpod 3 `Notifier` family keyed by `int? habitId`.
- Implemented `SchedulePage` (`lib/features/project_editor/schedule_page.dart`) with 4 radio modes (`每天`, `每周` with 7 weekday chips `日一二三四五六`, `每周 x 天` 1–6 stepper, `每月 x 天` 1–30 stepper).
- Implemented quotes loader (`lib/features/project_editor/quotes.dart` with fallback list) and `assets/quotes.json` (64 original Chinese motivational lines, each ≤ 20 chars).
- Implemented modular widgets in `lib/features/project_editor/widgets/`: `editor_row.dart`, `picker_sheets.dart` (`CupertinoPicker` bottom sheets for `设置坚持目标` and `每日打卡次数`), `reminder_section.dart` (`showTimePicker`, `'HH:mm'` chips, first-add permission request), and `icon_section.dart` (`IconPickerGrid` integration).
- Added unit and widget tests in `test/features/project_editor/editor_test.dart`; `flutter analyze` (0 issues) and `flutter test test/features/project_editor` (10/10 passed) pass.

## WP9 Integration & QA — done
- Scoped `GoRouter`'s root `GlobalKey<NavigatorState>` inside `routerProvider` to prevent duplicate-key issues across rebuilds/tests.
- Added end-to-end integration tests in `test/integration/app_e2e_test.dart` covering the full MVP acceptance checklist (create daily habit → today & yesterday check-in → project stats & streak → pause hides from Home & cancels notifications → future start-date guard → 5-tab navigation → file-backed SQLite reopen persistence).
- Updated `README.md` with run/test/packaging instructions.

## Phase 2 Additions (Project Detail Stats, Today All-Done Badge, Achievements) — done
- Domain: `lib/domain/services/achievement_service.dart` (`OverallStats`, `WeeklyRecord`, `AchievementItem`, 10 unlockable achievements) + `test/domain/achievement_service_test.dart`.
- Shell: `lib/app/router.dart` added `/projects/:id` (`Routes.projectDetail`), wired `AchievementsPage`, and upgraded the Today tab badge to show a green checkmark circle when all scheduled habits for today are done.
- Project Detail & Stats: `lib/features/projects/project_detail_page.dart` + `widgets/detail_{stats_tabs,monthly_calendar,yearly_stats,bottom_actions}.dart` (monthly interactive blue calendar, yearly 12-month heatmap + completion rate, bottom Edit & Share dialog with copyable text) + `test/features/projects/project_detail_page_test.dart`.
- Achievements (`我的成就`): `lib/features/achievements/achievements_page.dart` + `widgets/{weekly_chart,achievement_list_sheet,report_card_sheet,achievement_utils}.dart` (4 KPIs, year progress banner, 我的记录 + 3-month green heatmap, custom-painted smooth Bezier weekly check-in chart with year switcher, latest achievement, full achievements sheet, shareable 成绩单) + `test/features/achievements/achievements_page_test.dart`.
- Verified: `flutter analyze` (0 issues), `flutter test` (79/79 passed), rebuilt Release APK.


