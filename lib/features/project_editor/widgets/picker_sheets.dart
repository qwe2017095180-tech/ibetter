import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';

/// Preset goal-day choices shown in the goal wheel picker (`null` means 永远).
const List<int?> goalDayOptions = [
  null,
  3,
  4,
  7,
  10,
  14,
  21,
  30,
  60,
  100,
  180,
  365,
];

/// Preset daily check-in target choices (1–10).
const List<int> dailyTargetOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

/// Shows the bottom sheet wheel picker for `设置坚持目标`.
/// Returns a record `({int? goalDays})` on confirm, or `null` if cancelled/dismissed.
Future<({int? goalDays})?> showGoalPickerSheet(
  BuildContext context, {
  required int? initialGoalDays,
}) {
  final foundIndex = goalDayOptions.indexOf(initialGoalDays);
  final initialIndex = foundIndex >= 0 ? foundIndex : 0;

  return showModalBottomSheet<({int? goalDays})>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (ctx) => _WheelPickerSheet<int?>(
      title: '设置坚持目标',
      items: goalDayOptions,
      initialIndex: initialIndex,
      labelBuilder: (v) => v == null ? '永远' : '$v天',
      onConfirm: (v) => Navigator.of(ctx).pop((goalDays: v)),
    ),
  );
}

/// Shows the bottom sheet wheel picker for `每日打卡次数` (1–10).
Future<int?> showDailyTargetPickerSheet(
  BuildContext context, {
  required int initialTarget,
}) {
  final foundIndex = dailyTargetOptions.indexOf(initialTarget);
  final initialIndex = foundIndex >= 0 ? foundIndex : 0;

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (ctx) => _WheelPickerSheet<int>(
      title: '每日打卡次数',
      items: dailyTargetOptions,
      initialIndex: initialIndex,
      labelBuilder: (v) => '$v次',
      onConfirm: (v) => Navigator.of(ctx).pop(v),
    ),
  );
}

class _WheelPickerSheet<T> extends StatefulWidget {
  const _WheelPickerSheet({
    required this.title,
    required this.items,
    required this.initialIndex,
    required this.labelBuilder,
    required this.onConfirm,
  });

  final String title;
  final List<T> items;
  final int initialIndex;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onConfirm;

  @override
  State<_WheelPickerSheet<T>> createState() => _WheelPickerSheetState<T>();
}

class _WheelPickerSheetState<T> extends State<_WheelPickerSheet<T>> {
  late int _selectedIndex;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _scrollController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 290,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onConfirm(widget.items[_selectedIndex]),
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Expanded(
              child: CupertinoPicker(
                scrollController: _scrollController,
                itemExtent: 42,
                onSelectedItemChanged: (idx) => setState(() => _selectedIndex = idx),
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    Center(
                      child: Text(
                        widget.labelBuilder(widget.items[i]),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: i == _selectedIndex ? FontWeight.w600 : FontWeight.w400,
                          color: i == _selectedIndex ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
