import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_brand.dart';
import '../../../core/providers.dart';
import '../../../domain/date_key.dart' as dk;
import '../../../domain/services/achievement_service.dart';
import '../../icon_picker/icon_registry.dart';
import 'achievement_badge.dart';

/// Shows the swipeable orange achievement unlock celebration popup(s) with
/// "立即分享给朋友" button.
Future<void> showAchievementUnlockDialog(
  BuildContext context, {
  required List<AchievementItem> items,
}) async {
  if (items.isEmpty) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => _AchievementUnlockDialog(
      items: items,
      messenger: messenger,
    ),
  );
}

class _AchievementUnlockDialog extends StatefulWidget {
  const _AchievementUnlockDialog({
    required this.items,
    required this.messenger,
  });

  final List<AchievementItem> items;
  final ScaffoldMessengerState? messenger;

  @override
  State<_AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<_AchievementUnlockDialog> {
  late final PageController _pageController =
      PageController(viewportFraction: 0.88);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _resolveDate(AchievementItem item) {
    final raw = item.latestDate;
    if (raw != null && raw.isNotEmpty) {
      try {
        return dk.parseDateKey(raw);
      } catch (_) {}
    }
    return dk.today();
  }

  String _formatChineseDate(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日';

  Future<void> _onShareTap(
    BuildContext dialogContext,
    AchievementItem item,
  ) async {
    final navigator = Navigator.of(dialogContext);
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(dialogContext, listen: false);
    } catch (_) {
      // Allows isolated widget tests without a ProviderScope.
    }
    final shareDate = _resolveDate(item);
    final formattedDate = _formatChineseDate(shareDate);
    final habitSuffix =
        item.habitName != null ? '（项目：${item.habitName}）' : '';
    final shareText =
        '我在${AppBrand.name}解锁了成就「${item.displayTitle}」：${item.displaySubtitle}$habitSuffix！赢得日期：$formattedDate';

    try {
      await Clipboard.setData(ClipboardData(text: shareText));
    } catch (_) {}
    try {
      if (container != null) {
        await container.read(appPrefsProvider.future);
        await container.read(appPrefsProvider.notifier).recordShare(shareDate);
      }
    } catch (_) {}
    if (dialogContext.mounted) {
      navigator.pop();
    }
    widget.messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制分享文案，快去分享给朋友吧')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: widget.items.length == 1
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 368),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SingleChildScrollView(
                    child: _AchievementUnlockCardColumn(
                      item: widget.items.first,
                      formattedDate:
                          _formatChineseDate(_resolveDate(widget.items.first)),
                      onClose: () => Navigator.of(context).pop(),
                      onShare: () => _onShareTap(context, widget.items.first),
                    ),
                  ),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final pageHeight =
                    (constraints.maxHeight - 44).clamp(360.0, 530.0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: pageHeight,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.items.length,
                        onPageChanged: (index) =>
                            setState(() => _currentIndex = index),
                        itemBuilder: (pageContext, index) {
                          final item = widget.items[index];
                          return Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: SingleChildScrollView(
                                child: _AchievementUnlockCardColumn(
                                  item: item,
                                  formattedDate:
                                      _formatChineseDate(_resolveDate(item)),
                                  onClose: () => Navigator.of(context).pop(),
                                  onShare: () => _onShareTap(context, item),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _AchievementUnlockCardColumn extends StatelessWidget {
  const _AchievementUnlockCardColumn({
    required this.item,
    required this.formattedDate,
    required this.onClose,
    required this.onShare,
  });

  final AchievementItem item;
  final String formattedDate;
  final VoidCallback onClose;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF9E3B), Color(0xFFFF7526)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD95A14).withValues(alpha: 0.35),
                offset: const Offset(0, 6),
                blurRadius: 14,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 142,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SunburstSparklesPainter(),
                          ),
                        ),
                        AchievementBadge(item: item, size: 112),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.displayTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.displaySubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  if (item.displayLore != null &&
                      item.displayLore!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.displayLore!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                  Divider(
                    height: 28,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  Row(
                    children: [
                      HabitIcon(item.habitIconKey ?? item.iconKey, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.habitName ?? AppBrand.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '赢得日期：$formattedDate',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Tooltip(
                  message: '关闭',
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onClose,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFFF7E2B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF3E9BFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF237DE0),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onShare,
              child: const Center(
                child: Text(
                  '立即分享给朋友',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SunburstSparklesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.56;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF4B8).withValues(alpha: 0.45),
          const Color(0xFFFFF4B8).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, glowPaint);

    final rayPaint = Paint()
      ..color = const Color(0xFFFFE590).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    const rayCount = 10;
    for (var i = 0; i < rayCount; i++) {
      final a1 = (i * 2 * math.pi) / rayCount - 0.1;
      final a2 = a1 + 0.16;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(a1) * maxR,
          center.dy + math.sin(a1) * maxR,
        )
        ..lineTo(
          center.dx + math.cos(a2) * maxR,
          center.dy + math.sin(a2) * maxR,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    void drawFourPointStar(Offset c, double r) {
      final inner = r * 0.28;
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + inner, c.dy - inner, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + inner, c.dy + inner, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - inner, c.dy + inner, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - inner, c.dy - inner, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, starPaint);
    }

    drawFourPointStar(Offset(center.dx - 70, center.dy - 36), 8);
    drawFourPointStar(Offset(center.dx + 68, center.dy - 32), 7);
    drawFourPointStar(Offset(center.dx - 78, center.dy + 22), 6);
    drawFourPointStar(Offset(center.dx + 76, center.dy + 28), 8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
