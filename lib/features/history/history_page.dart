import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../domain/date_key.dart' as dk;
import '../../domain/models/check_in.dart';
import '../../domain/models/habit.dart';
import '../../domain/services/history_service.dart';

const _weekdayLabels = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

/// Chronological reverse-sorted timeline of completed habit check-ins grouped by month & day.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    final historyService = ref.watch(historyServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '历史记录',
        leading: PillIconButton(
          icon: Icons.arrow_back_ios_new,
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _buildBody(
        context,
        habitsAsync: habitsAsync,
        checkInsAsync: checkInsAsync,
        historyService: historyService,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required AsyncValue<List<Habit>> habitsAsync,
    required AsyncValue<List<CheckIn>> checkInsAsync,
    required HistoryService historyService,
  }) {
    if (habitsAsync.hasError) {
      return Center(child: Text('加载失败：${habitsAsync.error}'));
    }
    if (checkInsAsync.hasError) {
      return Center(child: Text('加载失败：${checkInsAsync.error}'));
    }
    final habits = habitsAsync.asData?.value;
    final checkIns = checkInsAsync.asData?.value;
    if (habits == null || checkIns == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final months = historyService.buildTimeline(habits, checkIns);
    if (months.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 54,
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            const Text(
              '还没有打卡记录',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 24),
      itemCount: months.length,
      itemBuilder: (context, index) => _HistoryMonthCard(month: months[index]),
    );
  }
}

class _HistoryMonthCard extends StatelessWidget {
  const _HistoryMonthCard({required this.month});

  final HistoryMonthGroup month;

  static const _hairlineColor = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                month.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _hairlineColor),
          for (var i = 0; i < month.days.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: _hairlineColor),
            _HistoryDayRow(day: month.days[i]),
          ],
        ],
      ),
    );
  }
}

class _HistoryDayRow extends StatelessWidget {
  const _HistoryDayRow({required this.day});

  final HistoryDayGroup day;

  static const _hairlineColor = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdayLabels[dk.weekdayIndex(day.date)];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 68,
            color: const Color(0xFFFAFAFA),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.date.day}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A7A7A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weekday,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: _hairlineColor),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < day.entries.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, thickness: 1, color: _hairlineColor),
                  _HistoryEntryRow(entry: day.entries[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryRow extends StatelessWidget {
  const _HistoryEntryRow({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('history_entry_${entry.habit.id}_${entry.checkIn.date}'),
      onTap: () => context.push(Routes.projectDetail(entry.habit.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.timeLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.check,
              size: 20,
              color: Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }
}
