import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/date_key.dart' as dk;
import '../../../domain/models/agenda_item.dart';
import '../../qingsong/qingsong_providers.dart';

const _agendaCategories = ['日程', '作业', '活动', '比赛', '志愿', '兼职', '其他'];

/// 底部弹层：添加今日日程（或指定日期的日程）。
Future<bool> showAddAgendaSheet(
  BuildContext context, {
  required DateTime initialDate,
}) async {
  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddAgendaSheet(initialDate: dk.dateOnly(initialDate)),
  );
  return added ?? false;
}

class _AddAgendaSheet extends ConsumerStatefulWidget {
  const _AddAgendaSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  ConsumerState<_AddAgendaSheet> createState() => _AddAgendaSheetState();
}

class _AddAgendaSheetState extends ConsumerState<_AddAgendaSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _date;
  int? _minutesOfDay;
  String _category = defaultAgendaCategory;
  bool _syncToRemote = false;
  bool _syncInitialized = false;
  bool _saving = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dk.dateOnly(ref.read(todayProvider));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 3),
    );
    if (picked != null && mounted) {
      setState(() => _date = dk.dateOnly(picked));
    }
  }

  Future<void> _pickTime() async {
    final initial = _minutesOfDay != null
        ? TimeOfDay(hour: _minutesOfDay! ~/ 60, minute: _minutesOfDay! % 60)
        : const TimeOfDay(hour: 18, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() => _minutesOfDay = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = '请输入日程标题');
      return;
    }
    setState(() {
      _saving = true;
      _titleError = null;
    });
    try {
      await ref.read(agendaRepositoryProvider).create(
            AgendaDraft(
              date: dk.dateKey(_date),
              minutesOfDay: _minutesOfDay,
              title: title,
              note: _noteController.text.trim(),
              category: _category,
              syncToRemote: _syncToRemote,
            ),
          );
      final config = ref.read(qingsongConfigProvider).asData?.value;
      if (_syncToRemote && config != null && config.isConfigured) {
        unawaited(ref.read(qingsongSyncProvider.notifier).sync(silent: true));
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _dateLabel(DateTime today) {
    final tomorrow = dk.addDays(today, 1);
    if (dk.isSameDay(_date, today)) return '今天 (${_date.month}月${_date.day}日)';
    if (dk.isSameDay(_date, tomorrow)) return '明天 (${_date.month}月${_date.day}日)';
    return '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final today = dk.dateOnly(ref.watch(todayProvider));
    final tomorrow = dk.addDays(today, 1);
    final config = ref.watch(qingsongConfigProvider).asData?.value;
    final isConfigured = config?.isConfigured ?? false;

    if (!_syncInitialized && config != null) {
      _syncInitialized = true;
      _syncToRemote = isConfigured;
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardShadow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '添加今日日程',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SectionCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const ValueKey('agenda_title_input'),
                    controller: _titleController,
                    autofocus: true,
                    maxLength: agendaTitleMaxLength,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_titleError != null) setState(() => _titleError = null);
                    },
                    decoration: InputDecoration(
                      hintText: '今天要做什么？（例如：交设计表达作业）',
                      errorText: _titleError,
                      filled: true,
                      fillColor: AppColors.inputFill,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('agenda_note_input'),
                    controller: _noteController,
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: '备注（地点、要求、联系人等，可选）',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SectionCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Text('日期', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                      const Spacer(),
                      _QuickChip(
                        label: '今天',
                        selected: dk.isSameDay(_date, today),
                        onTap: () => setState(() => _date = today),
                      ),
                      const SizedBox(width: 6),
                      _QuickChip(
                        label: '明天',
                        selected: dk.isSameDay(_date, tomorrow),
                        onTap: () => setState(() => _date = tomorrow),
                      ),
                      const SizedBox(width: 6),
                      _QuickChip(
                        key: const ValueKey('agenda_pick_date'),
                        label: _dateLabel(today),
                        selected: !dk.isSameDay(_date, today) && !dk.isSameDay(_date, tomorrow),
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1, color: AppColors.divider),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Text('时间', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                      const Spacer(),
                      _QuickChip(
                        label: '全天',
                        selected: _minutesOfDay == null,
                        onTap: () => setState(() => _minutesOfDay = null),
                      ),
                      const SizedBox(width: 6),
                      _QuickChip(
                        key: const ValueKey('agenda_pick_time'),
                        label: _minutesOfDay == null
                            ? '指定时间'
                            : formatMinutesOfDay(_minutesOfDay!),
                        selected: _minutesOfDay != null,
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1, color: AppColors.divider),
                  const Text('分类', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _agendaCategories)
                        _QuickChip(
                          label: c,
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SectionCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.sync_alt, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '同步到电脑「轻松日程」',
                          style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        ),
                        Text(
                          isConfigured
                              ? '添加后自动出现在电脑端的待办里'
                              : '配对后生效（更多 → 轻松日程）',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const ValueKey('agenda_sync_switch'),
                    value: _syncToRemote,
                    onChanged: (v) => setState(() {
                      _syncInitialized = true;
                      _syncToRemote = v;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DoneButton(
              key: const ValueKey('agenda_submit_button'),
              label: _saving ? '保存中…' : '添加日程',
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
