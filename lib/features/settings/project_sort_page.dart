import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/habit.dart';
import '../icon_picker/icon_registry.dart';

/// "我的项目排序" page allowing drag-and-drop reordering of habits.
class ProjectSortPage extends ConsumerStatefulWidget {
  const ProjectSortPage({super.key});

  @override
  ConsumerState<ProjectSortPage> createState() => _ProjectSortPageState();
}

class _ProjectSortPageState extends ConsumerState<ProjectSortPage> {
  List<Habit>? _workingOrder;
  bool _saving = false;

  Future<void> _save() async {
    final list = _workingOrder;
    if (_saving) return;
    if (list == null || list.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(habitRepositoryProvider)
          .reorder([for (final h in list) h.id]);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '我的项目排序',
        leading: PillIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
        ),
        trailing: DoneButton(onPressed: _saving ? null : _save),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败：$err')),
        data: (habits) {
          final items = _workingOrder ??= List<Habit>.of(habits);
          if (items.isEmpty) {
            return const Center(
              child: Text(
                '暂无可排序的项目',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '长按项目右端的 ',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.menu, size: 15, color: AppColors.textHint),
                    ),
                    const Text(
                      ' 进行排序喔',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final moved = items.removeAt(oldIndex);
                      items.insert(newIndex, moved);
                    });
                  },
                  itemBuilder: (context, index) {
                    final habit = items[index];
                    return Container(
                      key: ValueKey('sort_habit_${habit.id}'),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: const [
                          BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          HabitIcon(habit.iconKey, size: 38),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              habit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.menu,
                                color: Color(0xFFCCCCCC),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
