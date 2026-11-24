import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/models/habit.dart';
import '../../icon_picker/icon_registry.dart';
import '../projects_providers.dart';

/// Card displaying a single habit's summary stats and active toggle on "我的项目".
class ProjectCard extends ConsumerWidget {
  const ProjectCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onLongPress,
  });

  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const _pausedHeaderColor = Color(0xFFB8B8C8);
  static const _statNumberStyle = TextStyle(
    color: Color(0xFF4A4A4A),
    fontSize: 34,
    fontWeight: FontWeight.w500,
    height: 1.1,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(habitStatsProvider(habit.id));
    final headerColor = habit.isActive ? AppColors.habitCard : _pausedHeaderColor;
    final motto = habit.motto.trim();

    return SectionCard(
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ink(
                color: headerColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    HabitIcon(habit.iconKey, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            habit.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (motto.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              motto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stats.totalDays}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          stats.totalDays == 1 ? 'Day' : 'Days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: '本月完成天数',
                        value: Text('${stats.monthDays}', style: _statNumberStyle),
                        bottom: _UnitChip(stats.monthDays == 1 ? 'Day' : 'Days'),
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: '连续天数',
                        value: Text('${stats.currentStreak}', style: _statNumberStyle),
                        bottom: _UnitChip(_streakUnit(habit.schedule.type, stats.currentStreak)),
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: '坚持目标',
                        value: Text(
                          habit.goalLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                        ),
                        bottom: habit.goalDays != null
                            ? _GoalProgress(
                                progress: stats.goalProgress ?? (stats.goalReached ? 1.0 : 0.0),
                                reached: stats.goalReached,
                                isActive: habit.isActive,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            habit.isActive ? '项目进行中' : '项目已暂停',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: habit.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Since ${habit.startDate.month}月 ${habit.startDate.day}, ${habit.startDate.year}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: habit.isActive,
                      onChanged: (v) => ref.read(projectsActionsProvider).setActive(habit, v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _streakUnit(ScheduleType type, int streak) => switch (type) {
        ScheduleType.daily || ScheduleType.weekdays => streak == 1 ? 'Day' : 'Days',
        ScheduleType.timesPerWeek => '周',
        ScheduleType.timesPerMonth => '月',
      };
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    this.bottom,
  });

  final String label;
  final Widget value;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Center(child: value),
        ),
        if (bottom != null) ...[
          const SizedBox(height: 6),
          bottom!,
        ],
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  const _GoalProgress({
    required this.progress,
    required this.reached,
    required this.isActive,
  });

  final double progress;
  final bool reached;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final barColor = reached
        ? AppColors.done
        : (isActive ? AppColors.habitCard : const Color(0xFFB8B8C8));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 68,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFEAEAEA),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        if (reached) ...[
          const SizedBox(height: 4),
          const Text(
            '已达成',
            style: TextStyle(
              color: AppColors.done,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
