import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_brand.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers.dart';
import '../../../domain/models/habit.dart';
import '../../icon_picker/icon_registry.dart';
import '../../project_editor/quotes.dart';

/// One completed habit entry displayed inside the "完美的一天！" celebration card.
class PerfectDayHabitItem {
  const PerfectDayHabitItem({required this.habit, required this.totalDays});

  final Habit habit;
  final int totalDays;
}

/// Shows the "完美的一天！" celebration popup when all scheduled habits for [date]
/// are completed (or when opened from Achievements).
Future<void> showPerfectDayDialog(
  BuildContext context, {
  required DateTime date,
  required List<PerfectDayHabitItem> completedHabits,
  String? quote,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final resolvedQuote = (quote != null && quote.trim().isNotEmpty)
      ? quote.trim()
      : fallbackQuotes[(date.year + date.month + date.day) % fallbackQuotes.length];

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => _PerfectDayDialog(
      date: date,
      completedHabits: completedHabits,
      quote: resolvedQuote,
      messenger: messenger,
    ),
  );
}

class _PerfectDayDialog extends StatelessWidget {
  const _PerfectDayDialog({
    required this.date,
    required this.completedHabits,
    required this.quote,
    required this.messenger,
  });

  final DateTime date;
  final List<PerfectDayHabitItem> completedHabits;
  final String quote;
  final ScaffoldMessengerState? messenger;

  String _buildShareText() {
    final buffer = StringBuffer()
      ..writeln('我在 ${AppBrand.name} 达成了完美的一天！')
      ..writeln('日期：${date.year}年${date.month}月${date.day}日');
    if (completedHabits.isNotEmpty) {
      buffer.writeln('完成项目（${completedHabits.length}项）：');
      for (final item in completedHabits) {
        buffer.writeln('· ${item.habit.name}（累计${item.totalDays}天）');
      }
    }
    buffer.write('“ $quote ”');
    return buffer.toString();
  }

  Future<void> _onSaveTap(BuildContext dialogContext) async {
    final navigator = Navigator.of(dialogContext);
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(dialogContext, listen: false);
    } catch (_) {
      // Allows isolated widget tests without a ProviderScope.
    }
    try {
      await Clipboard.setData(ClipboardData(text: _buildShareText()));
    } catch (_) {}
    try {
      if (container != null) {
        await container.read(appPrefsProvider.future);
        await container.read(appPrefsProvider.notifier).recordShare(date);
      }
    } catch (_) {}
    if (dialogContext.mounted) {
      navigator.pop();
    }
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('已保存完美的一天')));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '我在 ${AppBrand.name} 完美的一天',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PerfectDayEmblem(
                          date: date,
                          completedHabits: completedHabits,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '“ $quote ”',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        if (completedHabits.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: completedHabits.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (_, index) =>
                                  _CompletedHabitTile(item: completedHabits[index]),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          '赢得日期：${date.year}年${date.month}月${date.day}日',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Tooltip(
                        message: '关闭',
                        child: Material(
                          color: const Color(0xFFBDBDBD),
                          shape: const CircleBorder(),
                          child: InkWell(
                            key: const ValueKey('perfect_day_close_button'),
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(context).pop(),
                            child: const SizedBox(
                              width: 28,
                              height: 28,
                              child: Icon(Icons.close, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA524),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFDF820C),
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    key: const ValueKey('perfect_day_save_button'),
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _onSaveTap(context),
                    child: const Center(
                      child: Text(
                        '🤩 保存完美的一天',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfectDayEmblem extends StatelessWidget {
  const _PerfectDayEmblem({
    required this.date,
    required this.completedHabits,
  });

  final DateTime date;
  final List<PerfectDayHabitItem> completedHabits;

  List<String> _floatingIcons() {
    final keys = <String>[];
    for (final item in completedHabits) {
      if (!keys.contains(item.habit.iconKey)) {
        keys.add(item.habit.iconKey);
      }
      if (keys.length >= 3) break;
    }
    const defaults = [
      'achievement/trophy',
      'achievement/sparkles',
      'achievement/star',
      'achievement/crown',
    ];
    for (final fallback in defaults) {
      if (keys.length >= 4) break;
      if (!keys.contains(fallback)) {
        keys.add(fallback);
      }
    }
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final floating = _floatingIcons();

    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            child: Container(
              width: 196,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFEE99).withValues(alpha: 0.75),
                    const Color(0xFFFFEE99).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          if (floating.isNotEmpty)
            Positioned(
              left: 16,
              top: 12,
              child: _FloatingHabitIcon(iconKey: floating[0], angle: -0.26),
            ),
          if (floating.length > 1)
            Positioned(
              right: 16,
              top: 12,
              child: _FloatingHabitIcon(iconKey: floating[1], angle: 0.26),
            ),
          if (floating.length > 2)
            Positioned(
              left: 6,
              top: 66,
              child: _FloatingHabitIcon(iconKey: floating[2], angle: -0.18),
            ),
          if (floating.length > 3)
            Positioned(
              right: 6,
              top: 66,
              child: _FloatingHabitIcon(iconKey: floating[3], angle: 0.18),
            ),
          Positioned(
            top: 28,
            child: CustomPaint(
              size: const Size(220, 90),
              painter: _WingsPainter(),
            ),
          ),
          Positioned(
            top: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE59B00),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF21963E),
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.month}月',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD43B), Color(0xFFFFA800)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFE68A00),
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '完美的一天！',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingHabitIcon extends StatelessWidget {
  const _FloatingHabitIcon({required this.iconKey, required this.angle});

  final String iconKey;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.42,
      child: Transform.rotate(
        angle: angle,
        child: HabitIcon(iconKey, size: 22),
      ),
    );
  }
}

class _WingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFFFFE79E)
      ..style = PaintingStyle.fill;
    final innerPaint = Paint()
      ..color = const Color(0xFFFFF3C9)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    void drawWing(double dir) {
      final outer = Path()
        ..moveTo(cx + dir * 32, cy - 10)
        ..quadraticBezierTo(cx + dir * 76, cy - 34, cx + dir * 102, cy - 18)
        ..quadraticBezierTo(cx + dir * 94, cy - 2, cx + dir * 82, cy + 2)
        ..quadraticBezierTo(cx + dir * 90, cy + 12, cx + dir * 74, cy + 18)
        ..quadraticBezierTo(cx + dir * 78, cy + 28, cx + dir * 58, cy + 28)
        ..quadraticBezierTo(cx + dir * 42, cy + 26, cx + dir * 32, cy + 14)
        ..close();
      canvas.drawPath(outer, fillPaint);

      final inner = Path()
        ..moveTo(cx + dir * 36, cy - 4)
        ..quadraticBezierTo(cx + dir * 68, cy - 20, cx + dir * 86, cy - 10)
        ..quadraticBezierTo(cx + dir * 72, cy + 10, cx + dir * 50, cy + 16)
        ..close();
      canvas.drawPath(inner, innerPaint);
    }

    drawWing(-1);
    drawWing(1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompletedHabitTile extends StatelessWidget {
  const _CompletedHabitTile({required this.item});

  final PerfectDayHabitItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          HabitIcon(item.habit.iconKey, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.totalDays}天',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.done,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
