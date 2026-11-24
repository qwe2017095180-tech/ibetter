import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/habit.dart';
import 'editor_controller.dart';
import 'schedule_page.dart';
import 'widgets/editor_row.dart';
import 'widgets/icon_section.dart';
import 'widgets/picker_sheets.dart';
import 'widgets/reminder_section.dart';

/// Create or edit a habit project.
/// [habitId] null = create, otherwise load habit + reminders and edit.
class ProjectEditorPage extends ConsumerStatefulWidget {
  const ProjectEditorPage({super.key, this.habitId});

  final int? habitId;

  @override
  ConsumerState<ProjectEditorPage> createState() => _ProjectEditorPageState();
}

class _ProjectEditorPageState extends ConsumerState<ProjectEditorPage> {
  final _nameController = TextEditingController();
  final _mottoController = TextEditingController();
  bool _allowPop = false;
  bool _isConfirmingDiscard = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(editorControllerProvider(widget.habitId));
    _syncTextControllers(initial);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mottoController.dispose();
    super.dispose();
  }

  void _syncTextControllers(EditorState state) {
    if (!_nameController.value.isComposingRangeValid && _nameController.text != state.name) {
      _nameController.value = TextEditingValue(
        text: state.name,
        selection: TextSelection.collapsed(offset: state.name.length),
      );
    }
    if (!_mottoController.value.isComposingRangeValid && _mottoController.text != state.motto) {
      _mottoController.value = TextEditingValue(
        text: state.motto,
        selection: TextSelection.collapsed(offset: state.motto.length),
      );
    }
  }

  Future<void> _handleBack(EditorState state) async {
    if (!state.isDirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await _confirmDiscardAndPop();
  }

  Future<void> _confirmDiscardAndPop() async {
    if (_isConfirmingDiscard) return;
    _isConfirmingDiscard = true;
    try {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('放弃修改'),
          content: const Text('当前有未保存的更改，确定要离开吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('继续编辑'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.badge),
              child: const Text('放弃'),
            ),
          ],
        ),
      );
      if (discard == true && mounted) {
        setState(() => _allowPop = true);
        Navigator.of(context).pop();
      }
    } finally {
      _isConfirmingDiscard = false;
    }
  }

  Future<void> _handleSave() async {
    final controller = ref.read(editorControllerProvider(widget.habitId).notifier);
    final ok = await controller.save();
    if (ok && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  Future<void> _openSchedulePage(Schedule current) async {
    final next = await Navigator.of(context).push<Schedule>(
      MaterialPageRoute(
        builder: (_) => SchedulePage(initialSchedule: current),
      ),
    );
    if (next != null && mounted) {
      ref.read(editorControllerProvider(widget.habitId).notifier).setSchedule(next);
    }
  }

  Future<void> _openGoalPicker(int? currentGoalDays) async {
    final result = await showGoalPickerSheet(
      context,
      initialGoalDays: currentGoalDays,
    );
    if (result != null && mounted) {
      ref
          .read(editorControllerProvider(widget.habitId).notifier)
          .setGoalDays(result.goalDays);
    }
  }

  Future<void> _openStartDatePicker(DateTime currentStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null && mounted) {
      ref.read(editorControllerProvider(widget.habitId).notifier).setStartDate(picked);
    }
  }

  Future<void> _shuffleQuote() async {
    await ref.read(editorControllerProvider(widget.habitId).notifier).nextQuote();
  }

  Future<void> _openTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && mounted) {
      await ref
          .read(editorControllerProvider(widget.habitId).notifier)
          .addReminder(picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _openDailyTargetPicker(int currentTarget) async {
    final picked = await showDailyTargetPickerSheet(
      context,
      initialTarget: currentTarget,
    );
    if (picked != null && mounted) {
      ref.read(editorControllerProvider(widget.habitId).notifier).setDailyTarget(picked);
    }
  }

  Future<void> _confirmAndDelete(EditorState state) async {
    final displayName = state.name.trim().isEmpty ? '该项目' : state.name.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除项目'),
        content: Text('确定要删除“$displayName”吗？相关打卡和提醒记录也会被清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.badge),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted =
        await ref.read(editorControllerProvider(widget.habitId).notifier).deleteHabit();
    if (deleted && mounted) {
      setState(() => _allowPop = true);
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go(Routes.projects);
      } else {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = editorControllerProvider(widget.habitId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen(provider, (_, next) {
      _syncTextControllers(next);
    });

    final title = widget.habitId == null ? '创建项目' : '编辑项目';

    return PopScope(
      canPop: _allowPop || (!state.isDirty && !state.isSaving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmDiscardAndPop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          title: title,
          leading: PillIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: state.isSaving ? null : () => _handleBack(state),
          ),
          trailing: DoneButton(
            onPressed: state.canSave ? _handleSave : null,
          ),
        ),
        body: _buildBody(state, controller),
      ),
    );
  }

  Widget _buildBody(EditorState state, EditorController controller) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.notFound) {
      return const Center(
        child: Text(
          '未找到该项目',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 6, bottom: 32),
      children: [
        _buildBasicInfoCard(state, controller),
        ReminderSectionCard(
          reminders: state.reminders,
          onAddTap: _openTimePicker,
          onRemoveAt: controller.removeReminderAt,
        ),
        _buildOptionsCard(state, controller),
        IconSectionCard(
          selectedKey: state.iconKey,
          onSelected: controller.setIconKey,
        ),
        if (state.isEditMode)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 16),
            child: Center(
              child: TextButton(
                onPressed: state.isSaving ? null : () => _confirmAndDelete(state),
                style: TextButton.styleFrom(foregroundColor: AppColors.badge),
                child: const Text(
                  '删除项目',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfoCard(EditorState state, EditorController controller) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    maxLength: 20,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textInputAction: TextInputAction.done,
                    onChanged: controller.setName,
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: '输入你想坚持的事情',
                      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 16),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          EditorFormRow(
            icon: Icons.calendar_today_outlined,
            label: '时间规划',
            valueText: state.schedule.label,
            onTap: () => _openSchedulePage(state.schedule),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          EditorFormRow(
            icon: Icons.flag_outlined,
            label: '设置坚持目标',
            valueText: state.goalLabel,
            onTap: () => _openGoalPicker(state.goalDays),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          EditorFormRow(
            icon: Icons.date_range_outlined,
            label: '起始日期',
            valueText: DateFormat('yyyy.MM.dd').format(state.startDate),
            onTap: () => _openStartDatePicker(state.startDate),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.format_quote_outlined, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '写一句话鼓励自己',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),
                OutlinedButton(
                  onPressed: _shuffleQuote,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('换一句', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _mottoController,
              maxLength: 40,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              minLines: 1,
              maxLines: 3,
              onChanged: controller.setMotto,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '写一句话鼓励自己...',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              buildCounter: (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) {
                final remaining = (maxLength ?? 40) - currentLength;
                return Text(
                  '$remaining',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard(EditorState state, EditorController controller) {
    return SectionCard(
      child: Column(
        children: [
          EditorFormRow(
            icon: Icons.star_border_rounded,
            label: '给自己打分',
            trailing: Switch(
              value: state.enableScore,
              onChanged: controller.setEnableScore,
            ),
            onTap: () => controller.setEnableScore(!state.enableScore),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          EditorFormRow(
            icon: Icons.sentiment_satisfied_outlined,
            label: '记录心情',
            trailing: Switch(
              value: state.enableMood,
              onChanged: controller.setEnableMood,
            ),
            onTap: () => controller.setEnableMood(!state.enableMood),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          EditorFormRow(
            icon: Icons.check_circle_outline,
            label: '每日打卡次数',
            valueText: state.dailyTargetLabel,
            onTap: () => _openDailyTargetPicker(state.dailyTarget),
          ),
        ],
      ),
    );
  }
}
