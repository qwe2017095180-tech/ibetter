import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/models/check_in.dart';
import '../../../domain/models/habit.dart';

Future<void> showCheckInDetailSheet(
  BuildContext context, {
  required Habit habit,
  required String date,
  required CheckIn? checkIn,
  required bool canEditRecord,
  required Future<void> Function({int? score, int? mood, String? note}) save,
  required VoidCallback editHabit,
}) async {
  final openEditor = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _CheckInDetailSheet(
      habit: habit,
      date: date,
      checkIn: checkIn,
      canEditRecord: canEditRecord,
      save: save,
    ),
  );
  if (openEditor == true && context.mounted) editHabit();
}

class _CheckInDetailSheet extends StatefulWidget {
  const _CheckInDetailSheet({
    required this.habit,
    required this.date,
    required this.checkIn,
    required this.canEditRecord,
    required this.save,
  });

  final Habit habit;
  final String date;
  final CheckIn? checkIn;
  final bool canEditRecord;
  final Future<void> Function({int? score, int? mood, String? note}) save;

  @override
  State<_CheckInDetailSheet> createState() => _CheckInDetailSheetState();
}

class _CheckInDetailSheetState extends State<_CheckInDetailSheet> {
  static const moods = ['很差', '较差', '一般', '不错', '很好'];
  final _form = GlobalKey<FormState>();
  late final _score = TextEditingController(
    text: widget.checkIn?.score?.toString() ?? '',
  );
  late final _note = TextEditingController(text: widget.checkIn?.note ?? '');
  late int? _mood = widget.checkIn?.mood;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _score.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save(
        score: widget.habit.enableScore
            ? int.tryParse(_score.text)
            : widget.checkIn?.score,
        mood: widget.habit.enableMood ? _mood : widget.checkIn?.mood,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '保存失败，请重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = widget.habit;
    final editable = widget.canEditRecord && !_saving;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('打卡详情', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('${habit.name} · ${widget.date}'),
              const SizedBox(height: 6),
              Text('已打卡 ${widget.checkIn?.count ?? 0}/${habit.dailyTarget} 次'),
              if (!widget.canEditRecord) ...[
                const SizedBox(height: 8),
                const Text('到达计划日期后可以填写记录'),
              ],
              if (habit.enableScore) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _score,
                  enabled: editable,
                  decoration: const InputDecoration(
                    labelText: '评分',
                    hintText: '0–100',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final number = int.tryParse(value);
                    if (number == null || number > 100) return '请输入 0–100 的整数';
                    return null;
                  },
                ),
              ],
              if (habit.enableMood) ...[
                const SizedBox(height: 16),
                const Text('心情'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (index, mood) in moods.indexed)
                      ChoiceChip(
                        label: Text(mood),
                        selected: _mood == index,
                        onSelected: editable
                            ? (selected) => setState(
                                () => _mood = selected ? index : null,
                              )
                            : null,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                enabled: editable,
                decoration: const InputDecoration(labelText: '备注'),
                minLines: 2,
                maxLines: 4,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(true),
                    child: const Text('编辑项目'),
                  ),
                  if (widget.canEditRecord)
                    FilledButton(
                      onPressed: editable ? _save : null,
                      child: Text(_saving ? '保存中…' : '保存记录'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
