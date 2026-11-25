# 轻松打卡

习惯养成与打卡 App，离线本地 SQLite 存储。架构与任务拆分详见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 已实现功能（MVP）

- **首页（今日打卡）**：顶部可折叠月历（周日起始、1 日双语标注、完成绿点、左右滑动翻页、时钟键回今天），当日已计划的进行中项目列表、单次与多次打卡、长按卡片记录评分／心情／备注、防未来打卡保护、待打卡红点角标。
- **我的项目**：累计天数、本月完成天数、连续天数/周/月、坚持目标及进度条、项目启停开关、筛选与排序、长按编辑/删除。
- **创建 / 编辑项目**：名称、时间规划（每天 / 每周指定星期 / 每周 x 天 / 每月 x 天）、坚持目标滚轮、起始日期、鼓励语及「换一句」（64 条内置语录）、定时提醒、打分/心情/每日次数设置、图标选择。
- **图标库**：160 个开源 Microsoft Fluent Emoji 3D 图标（MIT 许可，来源见 [assets/ATTRIBUTION.md](assets/ATTRIBUTION.md)），分 6 类。
- **本地提醒**：基于 `flutter_local_notifications` + `timezone`，按项目启停/编辑/删除自动同步和清理通知。

## 环境与运行

本机已安装的 Flutter SDK 位于 `~/development/flutter/bin`：

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter pub get
```

### 常用命令

```bash
# 代码生成（仅修改 Drift 表结构后需要）
dart run build_runner build --delete-conflicting-outputs

# 静态检查与全量测试
flutter analyze
flutter test

# 运行（连接 iOS / Android 真机或模拟器后）
flutter run
```

### 打包说明

- **Android**：需安装 Android SDK 与 JDK 17，执行 `flutter build apk --release`（若启用 R8 资源压缩，请保留 `@mipmap/ic_launcher` 通知图标）。
- **iOS**：需安装完整版 Xcode 与 CocoaPods，在 `ios/` 执行 `pod install` 后运行 `flutter build ipa`。
