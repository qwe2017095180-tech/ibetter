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

## Phase 3 Additions (GitHub Releases In-App Auto-Updater & More Page) — done
- Android native: added `INTERNET` & `REQUEST_INSTALL_PACKAGES` permissions, `FileProvider` (`res/xml/update_file_paths.xml`), and `MethodChannel('com.ibetter.clone.ibetter/updater')` in `MainActivity.kt` (`getAppVersion`, `installApk` with Android 8+ unknown-app-sources flow).
- Flutter updater: `lib/features/updates/{update_models,update_service,update_providers,update_dialog}.dart` supporting GitHub `/releases/latest` checks, optional download mirror prefix, streaming APK download with progress bar, ignore-tag support, and silent startup check in `_Shell`.
- More page: replaced placeholder with `lib/features/more/more_page.dart` (version info, manual check, auto-check toggle, editable GitHub repo & mirror prefix, attribution dialog).
- Release automation: `scripts/release.sh` and `.github/workflows/release-apk.yml`.
- Tests: `test/features/updates/update_test.dart`.

## Phase 4 Additions (Qingsong-Rili Integration & Today Agenda) — done
- Architecture doc: `docs/QINGSONG_INTEGRATION.md` covering LAN bridge protocol (`/bridge/v1/*`), SQLite schema v2, bidirectional push-then-pull sync rules, and UI design.
- PC side (`/Users/jvok8721/Desktop/study/wechat-schedule`): added opt-in LAN bridge server (`lib/bridge.mjs` on port `7790` with 8-char Bearer token & rate limit), mounted `/api/bridge/*` and lifecycle hooks in `server.mjs`, added `bridgeEnabled`/`bridgeToken` defaults in `lib/store.mjs`, and created `public/bridge.html` pairing page (linked from `public/index.html`).
- iBetter data & domain: added `AgendaItem`/`AgendaDraft` (`lib/domain/models/agenda_item.dart`), `QingsongNotice` (`lib/domain/models/qingsong_notice.dart`), pure sync rules (`lib/domain/services/agenda_sync_rules.dart`), Drift `AgendaItems` table + schema v1→v2 migration (`lib/core/db/`), and `AgendaRepository`/`DriftAgendaRepository` (`lib/data/repositories/`).
- iBetter sync & UI: implemented `QingsongClient`, `QingsongConfig`/`FileQingsongConfigStore`, `QingsongSyncService`, and Riverpod providers (`lib/features/qingsong/`), HomePage「今日日程」section +「添加今日日程」bottom sheet (`lib/features/home/widgets/{agenda_section,add_agenda_sheet}.dart`), MorePage pairing/sync settings (`lib/features/more/more_page.dart`), and Android `network_security_config.xml` for LAN cleartext HTTP.
- Verified: `flutter analyze` (0 issues), `flutter test` (98/98 passed including unit, DB migration, widget, and E2E tests), and live Node `bridge.mjs` ↔ Dart `QingsongSyncService` round-trip test.

## 品牌统一与打卡详情
- 轻松打卡 1.2.0+3 更新 Android、iOS、Web 的显示名和启动图标，Android 应用 ID 与 SQLite 文件名沿用已有值。
- 今日卡片打开评分、心情与备注记录，仍可从详情编辑项目；取消打卡时保留已有记录内容。
- 轻松日程 1.3.0 的改动在独立仓库，包含按日查看、直接添加和 GitHub Releases 应用内更新。

## 轻松打卡 1.2.1
- 恢复原有配色与「更多」品牌卡片。点击首页打卡卡片直接编辑项目，长按可打开当日已保存的评分、心情和备注。保留新应用名称和启动图标。

## 轻松打卡 1.4.0
- 新增「我的」个人主页（`lib/features/me/`）：顶部封面与重叠头像（支持预设配色/图标及 Android 相册选图）、昵称/账号 ID/个性签名编辑（同步显示于底部导航栏头像）、4 项核心 KPI 统计，以及本地「我的收件箱」（未读计数、`NEW` 徽标与详情弹窗）。
- 新增完整「设置」中心（`lib/features/settings/`）：
  - 项目：`我的项目排序`（`ReorderableListView` 拖拽排序并持久化至 SQLite `sortOrder`）、`选择卡片风格`（`彩色` / `纯白`）、`选择卡片布局`（`标准` / `紧凑` 2 列 / `超紧凑` 3 列）、6 款`日历达成颜色`（含金色星标 `goldStar` 主题）。
  - 隐私与安全：`密码保护`（4 位 PIN 设置/修改/关闭与 `AppLockGate` 冷启动锁屏）。
  - 通知：`每周/月成绩单提醒`开关、提醒时间选择，以及`收不到推送？排查方案`弹窗与 2 秒测试通知触发。
  - 挂件：`调整桌面小部件`预览引导页与 Android 原生桌面挂件（`CheckInWidgetProvider.kt`、`widget_checkin.xml`）。
  - 显示和效果：`每周第一天为`（星期日 / 星期一，联动首页及项目详情月历）、`音效`开关、`成就 / 完美的一天 / 新成绩单`显示样式（`卡片`弹窗 vs `横幅`顶部浮动提醒）。
  - 数据：`备份与恢复`（全量习惯、打卡记录、提醒与 `AppPrefs` 偏好 JSON 导出/剪贴板复制/本地备份及覆盖恢复）。
- 扩展 Android 原生通道（`MainActivity.kt` 注册 `com.ibetter.clone.ibetter/native_bridge`，提供 `pickImage` 与 `updateHomeWidget`），保留原有 `UPDATER_CHANNEL` 与轻松日程局域网同步功能。
- 验证：`flutter analyze` 0 issues；`flutter test --timeout=30s` 125/125 全部通过。

## 轻松打卡 1.4.1
- 新增原生 `SoundPool` 音效反馈（`SoundEffectsPlayer.kt` + 4 个合成 PCM WAV 音效资源 `res/raw/sfx_{checkin,uncheck,perfect_day,achievement}.wav` + `keep.xml` 防混淆裁剪）：首页打卡/取消打卡、完美一天弹窗、成就解锁弹窗、今日日程勾选以及设置页开启「音效」开关均触发对应清晰音效（受 `AppPrefs.soundEnabled` 控制，采用媒体音量通道，不受系统触控音开关限制）。
- 升级「我的」个人主页为直接自选图片壁纸体验：
  - Android `MainActivity.kt` 升级 `pickImage` 优先调用 Android 13+ 系统照片选择器（`MediaStore.ACTION_PICK_IMAGES`）与老版本 `Intent.ACTION_PICK` 相册选择，支持保留 png/webp/jpg 后缀；
  - `MePage` 顶部封面壁纸与重叠圆形头像支持直接点击调起相册更换，并新增「自选壁纸 / 更换壁纸」胶囊按钮；`EditProfileSheet` 顶部展示壁纸实时预览与选图入口，大尺寸照片加载加设 `cacheWidth` 限制内存占用。
- 应用内更新默认启用镜像源：`UpdateConfig.defaultMirrorPrefix` 改为 `https://gh-proxy.com/`，预设线路优先展示加速镜像并新增 `mirrorSchemaVersion: 2`（自动迁移旧版空镜像配置为 `gh-proxy.com`，同时保留用户显式选择的「直连 GitHub」）；失败时按所选镜像 → 其他加速镜像 → 直连 GitHub 自动回退，并在更新弹窗展示当前下载线路。
- 新增 `nowProvider` 消除跨午夜测试时钟抖动（`23:00–03:00` / `04:00–07:00` 隐藏成就受现实时间影响），补充/更新音效、壁纸直选与默认镜像测试；`flutter analyze` 0 issues，`flutter test --timeout=30s` 127/127 全部通过。
