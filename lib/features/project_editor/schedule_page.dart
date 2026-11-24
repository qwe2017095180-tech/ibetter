import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../domain/date_key.dart';
import '../../domain/models/habit.dart';

/// Sub-page for configuring how often a habit repeats.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.initialSchedule});

  final Schedule initialSchedule;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const _weekdayLabels = ['日', '一', '二', '三', '四', '五', '六'];

  late ScheduleType _type;
  late int _weekdaysMask;
  late int _timesPerWeek;
  late int _timesPerMonth;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSchedule;
    _type = initial.type;
    _weekdaysMask = initial.type == ScheduleType.weekdays && initial.weekdaysMask != 0
        ? initial.weekdaysMask
        : allWeekdaysMask;
    _timesPerWeek = initial.type == ScheduleType.timesPerWeek ? initial.value.clamp(1, 6) : 3;
    _timesPerMonth = initial.type == ScheduleType.timesPerMonth ? initial.value.clamp(1, 30) : 10;
  }

  Schedule _buildSchedule() {
    switch (_type) {
      case ScheduleType.daily:
        return const Schedule.daily();
      case ScheduleType.weekdays:
        return Schedule.weekdays(_weekdaysMask);
      case ScheduleType.timesPerWeek:
        return Schedule.timesPerWeek(_timesPerWeek);
      case ScheduleType.timesPerMonth:
        return Schedule.timesPerMonth(_timesPerMonth);
    }
  }

  void _toggleWeekday(int index) {
    final bit = 1 << index;
    final nextMask = (_weekdaysMask & bit) != 0 ? (_weekdaysMask & ~bit) : (_weekdaysMask | bit);
    if (nextMask == 0) return; // Require at least 1 selected day.
    setState(() => _weekdaysMask = nextMask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '时间规划',
        leading: PillIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: DoneButton(
          onPressed: () => Navigator.of(context).pop(_buildSchedule()),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          SectionCard(
            child: Column(
              children: [
                _ScheduleRadioRow(
                  label: '每天',
                  selected: _type == ScheduleType.daily,
                  onTap: () => setState(() => _type = ScheduleType.daily),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _ScheduleRadioRow(
                  label: '每周',
                  selected: _type == ScheduleType.weekdays,
                  onTap: () => setState(() => _type = ScheduleType.weekdays),
                  expandedChild: _WeekdayChips(
                    labels: _weekdayLabels,
                    mask: _weekdaysMask,
                    onToggle: _toggleWeekday,
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _ScheduleRadioRow(
                  label: '每周 x 天',
                  selected: _type == ScheduleType.timesPerWeek,
                  onTap: () => setState(() => _type = ScheduleType.timesPerWeek),
                  expandedChild: _CountStepper(
                    value: _timesPerWeek,
                    min: 1,
                    max: 6,
                    unit: '天',
                    onChanged: (v) => setState(() => _timesPerWeek = v),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                _ScheduleRadioRow(
                  label: '每月 x 天',
                  selected: _type == ScheduleType.timesPerMonth,
                  onTap: () => setState(() => _type = ScheduleType.timesPerMonth),
                  expandedChild: _CountStepper(
                    value: _timesPerMonth,
                    min: 1,
                    max: 30,
                    unit: '天',
                    onChanged: (v) => setState(() => _timesPerMonth = v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRadioRow extends StatelessWidget {
  const _ScheduleRadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.expandedChild,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6E6E6),
                    shape: BoxShape.circle,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: AppColors.done, size: 17)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selected && expandedChild != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
            child: expandedChild!,
          ),
      ],
    );
  }
}

class _WeekdayChips extends StatelessWidget {
  const _WeekdayChips({
    required this.labels,
    required this.mask,
    required this.onToggle,
  });

  final List<String> labels;
  final int mask;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < labels.length; i++)
          _WeekdayChip(
            label: labels[i],
            selected: maskHas(mask, i),
            onTap: () => onToggle(i),
          ),
      ],
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.inputFill,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepperButton(
          icon: Icons.remove,
          enabled: value > min,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          enabled: value < max,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
