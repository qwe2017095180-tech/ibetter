import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/date_key.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/reminder.dart';
import '../icon_picker/icon_registry.dart';
import '../reminders/notification_service.dart';
import 'quotes.dart';

const _unset = Object();

/// Snapshot of initial form values used to detect unsaved edits.
@immutable
class EditorSnapshot {
  const EditorSnapshot({
    required this.name,
    required this.iconKey,
    required this.schedule,
    required this.goalDays,
    required this.startDate,
    required this.motto,
    required this.reminders,
    required this.enableScore,
    required this.enableMood,
    required this.dailyTarget,
  });

  final String name;
  final String iconKey;
  final Schedule schedule;
  final int? goalDays;
  final DateTime startDate;
  final String motto;
  final List<ReminderDraft> reminders;
  final bool enableScore;
  final bool enableMood;
  final int dailyTarget;
}

/// Immutable state for creating or editing a habit.
@immutable
class EditorState {
  const EditorState({
    required this.habitId,
    this.existingHabit,
    this.isLoading = false,
    this.notFound = false,
    this.isSaving = false,
    this.name = '',
    this.iconKey = IconRegistry.defaultKey,
    this.schedule = const Schedule.daily(),
    this.goalDays,
    required this.startDate,
    this.motto = '',
    this.reminders = const [],
    this.enableScore = false,
    this.enableMood = false,
    this.dailyTarget = 1,
    this.isActive = true,
    this.initialSnapshot,
  });

  final int? habitId;
  final Habit? existingHabit;
  final bool isLoading;
  final bool notFound;
  final bool isSaving;

  final String name;
  final String iconKey;
  final Schedule schedule;
  final int? goalDays;
  final DateTime startDate;
  final String motto;
  final List<ReminderDraft> reminders;
  final bool enableScore;
  final bool enableMood;
  final int dailyTarget;
  final bool isActive;
  final EditorSnapshot? initialSnapshot;

  bool get isEditMode => habitId != null;
  bool get canSave => name.trim().isNotEmpty && !isLoading && !isSaving && !notFound;

  String get goalLabel => goalDays == null ? '永远' : '$goalDays天';
  String get dailyTargetLabel => '$dailyTarget次';

  bool get isDirty {
    final snap = initialSnapshot;
    if (snap == null) return false;
    return name != snap.name ||
        iconKey != snap.iconKey ||
        schedule != snap.schedule ||
        goalDays != snap.goalDays ||
        !isSameDay(startDate, snap.startDate) ||
        motto != snap.motto ||
        enableScore != snap.enableScore ||
        enableMood != snap.enableMood ||
        dailyTarget != snap.dailyTarget ||
        !_remindersEqual(reminders, snap.reminders);
  }

  /// Builds a normalized [HabitDraft] from the current form values.
  HabitDraft buildDraft() => HabitDraft(
        name: name.trim(),
        iconKey: iconKey,
        schedule: schedule,
        goalDays: goalDays,
        startDate: dateOnly(startDate),
        motto: motto,
        enableScore: enableScore,
        enableMood: enableMood,
        dailyTarget: dailyTarget.clamp(1, 10),
        isActive: isActive,
      );

  EditorState copyWith({
    Object? existingHabit = _unset,
    bool? isLoading,
    bool? notFound,
    bool? isSaving,
    String? name,
    String? iconKey,
    Schedule? schedule,
    Object? goalDays = _unset,
    DateTime? startDate,
    String? motto,
    List<ReminderDraft>? reminders,
    bool? enableScore,
    bool? enableMood,
    int? dailyTarget,
    bool? isActive,
    Object? initialSnapshot = _unset,
  }) {
    return EditorState(
      habitId: habitId,
      existingHabit:
          identical(existingHabit, _unset) ? this.existingHabit : existingHabit as Habit?,
      isLoading: isLoading ?? this.isLoading,
      notFound: notFound ?? this.notFound,
      isSaving: isSaving ?? this.isSaving,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      schedule: schedule ?? this.schedule,
      goalDays: identical(goalDays, _unset) ? this.goalDays : goalDays as int?,
      startDate: startDate ?? this.startDate,
      motto: motto ?? this.motto,
      reminders: reminders ?? this.reminders,
      enableScore: enableScore ?? this.enableScore,
      enableMood: enableMood ?? this.enableMood,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      isActive: isActive ?? this.isActive,
      initialSnapshot: identical(initialSnapshot, _unset)
          ? this.initialSnapshot
          : initialSnapshot as EditorSnapshot?,
    );
  }
}

bool _remindersEqual(List<ReminderDraft> a, List<ReminderDraft> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].minutesOfDay != b[i].minutesOfDay ||
        a[i].weekdaysMask != b[i].weekdaysMask ||
        a[i].enabled != b[i].enabled) {
      return false;
    }
  }
  return true;
}

class EditorController extends Notifier<EditorState> {
  EditorController(this.habitId);

  final int? habitId;
  bool _disposed = false;
  bool _permissionRequested = false;
  List<String>? _cachedQuotes;

  @override
  EditorState build() {
    _disposed = false;
    _permissionRequested = false;
    ref.onDispose(() => _disposed = true);

    final today = dateOnly(ref.read(todayProvider));
    if (habitId == null) {
      return EditorState(
        habitId: null,
        startDate: today,
        initialSnapshot: EditorSnapshot(
          name: '',
          iconKey: IconRegistry.defaultKey,
          schedule: const Schedule.daily(),
          goalDays: null,
          startDate: today,
          motto: '',
          reminders: const [],
          enableScore: false,
          enableMood: false,
          dailyTarget: 1,
        ),
      );
    }

    Future.microtask(() => _loadHabit(habitId!));
    return EditorState(
      habitId: habitId,
      isLoading: true,
      startDate: today,
    );
  }

  Future<void> _loadHabit(int id) async {
    final habit = await ref.read(habitRepositoryProvider).getById(id);
    if (_disposed) return;

    if (habit == null) {
      state = state.copyWith(isLoading: false, notFound: true);
      return;
    }

    final reminders = await ref.read(reminderRepositoryProvider).getByHabit(id);
    if (_disposed) return;

    final draftReminders = reminders
        .map((r) => ReminderDraft(
              minutesOfDay: r.minutesOfDay,
              weekdaysMask: r.weekdaysMask,
              enabled: r.enabled,
            ))
        .toList(growable: false);

    final start = dateOnly(habit.startDate);
    state = state.copyWith(
      existingHabit: habit,
      isLoading: false,
      notFound: false,
      name: habit.name,
      iconKey: habit.iconKey,
      schedule: habit.schedule,
      goalDays: habit.goalDays,
      startDate: start,
      motto: habit.motto,
      reminders: draftReminders,
      enableScore: habit.enableScore,
      enableMood: habit.enableMood,
      dailyTarget: habit.dailyTarget.clamp(1, 10),
      isActive: habit.isActive,
      initialSnapshot: EditorSnapshot(
        name: habit.name,
        iconKey: habit.iconKey,
        schedule: habit.schedule,
        goalDays: habit.goalDays,
        startDate: start,
        motto: habit.motto,
        reminders: draftReminders,
        enableScore: habit.enableScore,
        enableMood: habit.enableMood,
        dailyTarget: habit.dailyTarget.clamp(1, 10),
      ),
    );
  }

  void setName(String value) {
    final clipped = value.length > 20 ? value.substring(0, 20) : value;
    state = state.copyWith(name: clipped);
  }

  void setSchedule(Schedule schedule) {
    state = state.copyWith(schedule: schedule);
  }

  void setGoalDays(int? goalDays) {
    state = state.copyWith(goalDays: goalDays);
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: dateOnly(date));
  }

  void setMotto(String value) {
    final clipped = value.length > 40 ? value.substring(0, 40) : value;
    state = state.copyWith(motto: clipped);
  }

  Future<String> nextQuote() async {
    _cachedQuotes ??= await ref.read(quotesLoaderProvider)();
    if (_disposed) return state.motto;
    final picked = pickRandomQuote(_cachedQuotes!, current: state.motto);
    setMotto(picked);
    return picked;
  }

  Future<void> addReminder(int minutesOfDay) async {
    final normalized = minutesOfDay.clamp(0, 1439);
    final wasEmpty = state.reminders.isEmpty;

    if (!state.reminders.any((r) => r.minutesOfDay == normalized)) {
      final updated = [...state.reminders, ReminderDraft(minutesOfDay: normalized)]
        ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
      state = state.copyWith(reminders: List.unmodifiable(updated));
    }

    if (wasEmpty && !_permissionRequested) {
      _permissionRequested = true;
      try {
        await ref.read(notificationServiceProvider).requestPermission();
      } catch (e, st) {
        debugPrint('Notification permission request failed: $e\n$st');
      }
    }
  }

  void removeReminderAt(int index) {
    if (index < 0 || index >= state.reminders.length) return;
    final updated = [...state.reminders]..removeAt(index);
    state = state.copyWith(reminders: List.unmodifiable(updated));
  }

  void setEnableScore(bool value) {
    state = state.copyWith(enableScore: value);
  }

  void setEnableMood(bool value) {
    state = state.copyWith(enableMood: value);
  }

  void setDailyTarget(int value) {
    state = state.copyWith(dailyTarget: value.clamp(1, 10));
  }

  void setIconKey(String key) {
    state = state.copyWith(iconKey: key);
  }

  /// Validates, persists habit and reminders, syncs notifications, and returns true on success.
  Future<bool> save() async {
    if (!state.canSave) return false;

    state = state.copyWith(isSaving: true);
    try {
      final habitRepo = ref.read(habitRepositoryProvider);
      final reminderRepo = ref.read(reminderRepositoryProvider);
      final notifications = ref.read(notificationServiceProvider);
      final draft = state.buildDraft();

      final int targetId;
      Habit? savedHabit;

      if (habitId == null) {
        targetId = await habitRepo.create(draft);
        await reminderRepo.replaceForHabit(targetId, state.reminders);
        savedHabit = await habitRepo.getById(targetId);
      } else {
        final existing = state.existingHabit;
        if (existing == null) return false;
        final updated = existing.copyWithDraft(draft);
        targetId = updated.id;
        await habitRepo.update(updated);
        await reminderRepo.replaceForHabit(targetId, state.reminders);
        savedHabit = (await habitRepo.getById(targetId)) ?? updated;
      }

      final savedReminders = await reminderRepo.getByHabit(targetId);
      if (savedHabit != null) {
        try {
          await notifications.syncHabit(savedHabit, savedReminders);
        } catch (e, st) {
          debugPrint('Notification sync failed: $e\n$st');
        }
      }
      if (!_disposed) {
        state = state.copyWith(
          existingHabit: savedHabit ?? state.existingHabit,
          initialSnapshot: EditorSnapshot(
            name: draft.name,
            iconKey: draft.iconKey,
            schedule: draft.schedule,
            goalDays: draft.goalDays,
            startDate: draft.startDate,
            motto: draft.motto,
            reminders: state.reminders,
            enableScore: draft.enableScore,
            enableMood: draft.enableMood,
            dailyTarget: draft.dailyTarget,
          ),
        );
      }
      return true;
    } finally {
      if (!_disposed) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  /// Cancels scheduled notifications and deletes the habit in edit mode.
  Future<bool> deleteHabit() async {
    final id = habitId;
    if (id == null || state.isSaving) return false;

    state = state.copyWith(isSaving: true);
    try {
      try {
        await ref.read(notificationServiceProvider).cancelHabit(id);
      } catch (e, st) {
        debugPrint('Notification cancel failed: $e\n$st');
      }
      await ref.read(habitRepositoryProvider).delete(id);
      return true;
    } finally {
      if (!_disposed) {
        state = state.copyWith(isSaving: false);
      }
    }
  }
}

final editorControllerProvider = NotifierProvider.autoDispose
    .family<EditorController, EditorState, int?>(EditorController.new);
