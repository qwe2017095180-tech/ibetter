import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_models.dart';
import 'update_service.dart';

final updateConfigStoreProvider = Provider<UpdateConfigStore>(
  (ref) => FileUpdateConfigStore(),
);

final updateServiceProvider = Provider<UpdateService>(
  (ref) => UpdateService(),
);

final currentAppVersionProvider = FutureProvider<AppVersion>(
  (ref) => ref.watch(updateServiceProvider).getCurrentVersion(),
);

class UpdateConfigNotifier extends AsyncNotifier<UpdateConfig> {
  @override
  Future<UpdateConfig> build() => ref.watch(updateConfigStoreProvider).load();

  Future<void> setRepo(String repo) async {
    final current = state.asData?.value ?? const UpdateConfig();
    final updated = current.copyWith(repo: repo.trim(), clearIgnoredTag: true);
    state = AsyncData(updated);
    await ref.read(updateConfigStoreProvider).save(updated);
  }

  Future<void> setMirrorPrefix(String prefix) async {
    final current = state.asData?.value ?? const UpdateConfig();
    final updated = current.copyWith(mirrorPrefix: prefix.trim());
    state = AsyncData(updated);
    await ref.read(updateConfigStoreProvider).save(updated);
  }

  Future<void> setAutoCheck(bool enabled) async {
    final current = state.asData?.value ?? const UpdateConfig();
    final updated = current.copyWith(autoCheck: enabled);
    state = AsyncData(updated);
    await ref.read(updateConfigStoreProvider).save(updated);
  }

  Future<void> ignoreTag(String tag) async {
    final current = state.asData?.value ?? const UpdateConfig();
    final updated = current.copyWith(ignoredTag: tag);
    state = AsyncData(updated);
    await ref.read(updateConfigStoreProvider).save(updated);
  }
}

final updateConfigProvider = AsyncNotifierProvider<UpdateConfigNotifier, UpdateConfig>(
  UpdateConfigNotifier.new,
);
