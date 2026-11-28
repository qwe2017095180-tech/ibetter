import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../domain/services/achievement_service.dart';
import '../../icon_picker/icon_registry.dart';

/// Renders the styled achievement emblem (gold star, 1/2/3 DAY ribbon, blue
/// scalloped streak badge, bronze/blue/gold trophy, hidden gradient circle, or
/// grey locked `?` badge).
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.item,
    this.size = 62,
  });

  final AchievementItem item;
  final double size;

  static const _lockedGrey = Color(0xFFE6E6E6);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: SizedBox.square(
        dimension: size,
        child: item.unlocked ? _buildUnlocked() : _buildLocked(),
      ),
    );
  }

  Widget _buildLocked() {
    switch (item.badgeStyle) {
      case AchievementBadgeStyle.streakScallop:
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: const _ScallopPainter(unlocked: false),
            ),
            _lockedQuestionMark(size * 0.44),
          ],
        );
      case AchievementBadgeStyle.trophy:
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: const _TrophyPainter(
                baseColor: _lockedGrey,
                highlightColor: _lockedGrey,
                shadowColor: _lockedGrey,
                unlocked: false,
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.24),
              child: _lockedQuestionMark(size * 0.34),
            ),
          ],
        );
      case AchievementBadgeStyle.singleDayRibbon:
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: const _HexShieldPainter(
                fillTop: _lockedGrey,
                fillBottom: _lockedGrey,
                borderColor: _lockedGrey,
              ),
            ),
            _lockedQuestionMark(size * 0.44),
          ],
        );
      case AchievementBadgeStyle.starCircle:
      case AchievementBadgeStyle.hiddenCircle:
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: _lockedGrey,
            shape: BoxShape.circle,
          ),
          child: Center(child: _lockedQuestionMark(size * 0.44)),
        );
    }
  }

  Widget _lockedQuestionMark(double fontSize) {
    return Text(
      '?',
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.0,
      ),
    );
  }

  Widget _buildUnlocked() {
    switch (item.badgeStyle) {
      case AchievementBadgeStyle.starCircle:
        return Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7669F8), Color(0xFF5455D8)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x2E5455D8),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                size: size * 0.68,
                color: const Color(0xFFE67E00),
              ),
              Icon(
                Icons.star_rounded,
                size: size * 0.58,
                color: const Color(0xFFFFD43B),
                shadows: const [
                  Shadow(
                    color: Color(0x88D96B00),
                    offset: Offset(0, 1.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ],
          ),
        );

      case AchievementBadgeStyle.singleDayRibbon:
        final days = item.milestoneDays ?? 1;
        final palette = _SingleDayPalette.forDays(days);
        final ribbonText = days <= 2 ? '$days DAY' : '$days DAYS';
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _HexShieldPainter(
                fillTop: palette.fillTop,
                fillBottom: palette.fillBottom,
                borderColor: palette.border,
              ),
            ),
            Positioned(
              top: size * 0.14,
              child: HabitIcon(item.iconKey, size: size * 0.42),
            ),
            Positioned(
              bottom: size * 0.08,
              left: 0,
              right: 0,
              child: CustomPaint(
                painter: _RibbonBannerPainter(
                  color: palette.ribbon,
                  foldColor: palette.ribbonFold,
                ),
                child: Container(
                  height: size * 0.27,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: size * 0.1),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      ribbonText,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case AchievementBadgeStyle.streakScallop:
        final days = item.milestoneDays ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: const _ScallopPainter(unlocked: true),
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.15),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$days',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.34,
                        fontWeight: FontWeight.w800,
                        height: 0.98,
                      ),
                    ),
                    Text(
                      'DAYS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.135,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case AchievementBadgeStyle.trophy:
        final (base, highlight, shadow) = switch (item.id) {
          'three_habits' => (
            const Color(0xFFE68A3E),
            const Color(0xFFF3AA6A),
            const Color(0xFFC26C25),
          ),
          'friendship_medal' => (
            const Color(0xFF58A6FF),
            const Color(0xFF88C2FF),
            const Color(0xFF317FD9),
          ),
          _ => (
            const Color(0xFFFFB830),
            const Color(0xFFFFD666),
            const Color(0xFFE09612),
          ),
        };
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _TrophyPainter(
                baseColor: base,
                highlightColor: highlight,
                shadowColor: shadow,
                unlocked: true,
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.25),
              child: _buildTrophyEmblem(),
            ),
          ],
        );

      case AchievementBadgeStyle.hiddenCircle:
        return Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C7BFF), Color(0xFF3B87D6)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x283B87D6),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: HabitIcon(item.iconKey, size: size * 0.56),
        );
    }
  }

  Widget _buildTrophyEmblem() {
    if (item.id == 'three_habits') {
      return Text(
        '3',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.27,
          fontWeight: FontWeight.w800,
          height: 1.0,
          shadows: const [
            Shadow(
              color: Color(0x3D000000),
              offset: Offset(0, 1),
              blurRadius: 1,
            ),
          ],
        ),
      );
    }
    if (item.id == 'friendship_medal') {
      return Transform.rotate(
        angle: -0.35,
        child: Icon(
          Icons.send,
          color: Colors.white,
          size: size * 0.23,
        ),
      );
    }
    return Icon(
      Icons.star_rounded,
      color: Colors.white.withValues(alpha: 0.92),
      size: size * 0.24,
    );
  }
}

class _SingleDayPalette {
  const _SingleDayPalette({
    required this.fillTop,
    required this.fillBottom,
    required this.border,
    required this.ribbon,
    required this.ribbonFold,
  });

  final Color fillTop;
  final Color fillBottom;
  final Color border;
  final Color ribbon;
  final Color ribbonFold;

  static const _goldPalette = _SingleDayPalette(
    fillTop: Color(0xFFFFF6DB),
    fillBottom: Color(0xFFFFE18D),
    border: Color(0xFFF59F00),
    ribbon: Color(0xFFF59F00),
    ribbonFold: Color(0xFFC97B00),
  );

  static const _legendDays = {30, 50, 180, 200, 300, 325, 360, 365};
  static const _cultJewelDays = {42, 64, 81, 86, 108, 127, 151, 233, 256, 314, 318};

  static const _cyclePalettes = <_SingleDayPalette>[
    _SingleDayPalette(
      fillTop: Color(0xFFFFF3DC),
      fillBottom: Color(0xFFFFE0AF),
      border: Color(0xFFFFA940),
      ribbon: Color(0xFFFFA940),
      ribbonFold: Color(0xFFD97B12),
    ),
    _SingleDayPalette(
      fillTop: Color(0xFFE7FAEC),
      fillBottom: Color(0xFFC4F0CF),
      border: Color(0xFF49C66D),
      ribbon: Color(0xFF49C66D),
      ribbonFold: Color(0xFF2D9C4D),
    ),
    _SingleDayPalette(
      fillTop: Color(0xFFE8F0FF),
      fillBottom: Color(0xFFC9DBFF),
      border: Color(0xFF4B89FF),
      ribbon: Color(0xFF4B89FF),
      ribbonFold: Color(0xFF2B62CC),
    ),
    _SingleDayPalette(
      fillTop: Color(0xFFF2EBFF),
      fillBottom: Color(0xFFDCCBFF),
      border: Color(0xFF8E63F5),
      ribbon: Color(0xFF8E63F5),
      ribbonFold: Color(0xFF683ED1),
    ),
    _SingleDayPalette(
      fillTop: Color(0xFFFFEBEE),
      fillBottom: Color(0xFFFFCDD2),
      border: Color(0xFFFF5E6C),
      ribbon: Color(0xFFFF5E6C),
      ribbonFold: Color(0xFFD63B49),
    ),
    _SingleDayPalette(
      fillTop: Color(0xFFE0F7F5),
      fillBottom: Color(0xFFB5ECE8),
      border: Color(0xFF26B5AC),
      ribbon: Color(0xFF26B5AC),
      ribbonFold: Color(0xFF178A83),
    ),
  ];

  static _SingleDayPalette forDays(int days) {
    if (days == 1) return _cyclePalettes[0];
    if (days == 2) {
      return const _SingleDayPalette(
        fillTop: Color(0xFFE3F7F5),
        fillBottom: Color(0xFFFFE7BE),
        border: Color(0xFFFFB84D),
        ribbon: Color(0xFFFFB84D),
        ribbonFold: Color(0xFFD98E1F),
      );
    }
    if (days == 3) return _cyclePalettes[1];
    if (days == 5) return _cyclePalettes[2];
    if (days == 7 || days == 21) return _cyclePalettes[3];
    if (days == 10 || days == 100) return _cyclePalettes[4];
    if (days == 15) return _cyclePalettes[5];
    if (_legendDays.contains(days)) return _goldPalette;
    if (_cultJewelDays.contains(days)) {
      return switch (days % 3) {
        0 => const _SingleDayPalette(
            fillTop: Color(0xFFF3E8FF),
            fillBottom: Color(0xFFD8B4FE),
            border: Color(0xFF7C3AED),
            ribbon: Color(0xFF7C3AED),
            ribbonFold: Color(0xFF5B21B6),
          ),
        1 => const _SingleDayPalette(
            fillTop: Color(0xFFFFE4E6),
            fillBottom: Color(0xFFFECDD3),
            border: Color(0xFFE11D48),
            ribbon: Color(0xFFE11D48),
            ribbonFold: Color(0xFF9F1239),
          ),
        _ => const _SingleDayPalette(
            fillTop: Color(0xFFCCFBF1),
            fillBottom: Color(0xFF99F6E4),
            border: Color(0xFF0D9488),
            ribbon: Color(0xFF0D9488),
            ribbonFold: Color(0xFF115E59),
          ),
      };
    }
    return _cyclePalettes[days % _cyclePalettes.length];
  }
}

class _HexShieldPainter extends CustomPainter {
  const _HexShieldPainter({
    required this.fillTop,
    required this.fillBottom,
    required this.borderColor,
  });

  final Color fillTop;
  final Color fillBottom;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final vertices = <Offset>[
      Offset(w * 0.5, h * 0.04),
      Offset(w * 0.90, h * 0.23),
      Offset(w * 0.90, h * 0.69),
      Offset(w * 0.5, h * 0.90),
      Offset(w * 0.10, h * 0.69),
      Offset(w * 0.10, h * 0.23),
    ];

    final path = _roundedPolygon(vertices, cornerRadius: size.shortestSide * 0.07);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillTop, fillBottom],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fillPaint);

    if (borderColor != fillTop || borderColor != fillBottom) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.06
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, borderPaint);
    }
  }

  Path _roundedPolygon(List<Offset> pts, {required double cornerRadius}) {
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final prev = pts[(i - 1 + pts.length) % pts.length];
      final curr = pts[i];
      final next = pts[(i + 1) % pts.length];
      final vPrev = prev - curr;
      final vNext = next - curr;
      final lenPrev = vPrev.distance;
      final lenNext = vNext.distance;
      final r = math.min(cornerRadius, math.min(lenPrev, lenNext) / 2);
      final p1 = curr + (vPrev / lenPrev) * r;
      final p2 = curr + (vNext / lenNext) * r;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexShieldPainter oldDelegate) =>
      oldDelegate.fillTop != fillTop ||
      oldDelegate.fillBottom != fillBottom ||
      oldDelegate.borderColor != borderColor;
}

class _RibbonBannerPainter extends CustomPainter {
  const _RibbonBannerPainter({
    required this.color,
    required this.foldColor,
  });

  final Color color;
  final Color foldColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Subtle folded ribbon tails on left & right.
    final leftTail = Path()
      ..moveTo(w * 0.08, h * 0.25)
      ..lineTo(0, h * 0.35)
      ..lineTo(w * 0.04, h * 0.68)
      ..lineTo(0, h)
      ..lineTo(w * 0.14, h)
      ..close();
    final rightTail = Path()
      ..moveTo(w * 0.92, h * 0.25)
      ..lineTo(w, h * 0.35)
      ..lineTo(w * 0.96, h * 0.68)
      ..lineTo(w, h)
      ..lineTo(w * 0.86, h)
      ..close();
    final foldPaint = Paint()..color = foldColor;
    canvas.drawPath(leftTail, foldPaint);
    canvas.drawPath(rightTail, foldPaint);

    final bannerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, 0, w * 0.92, h * 0.92),
      Radius.circular(h * 0.25),
    );
    canvas.drawRRect(bannerRect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RibbonBannerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.foldColor != foldColor;
}

class _ScallopPainter extends CustomPainter {
  const _ScallopPainter({required this.unlocked});

  final bool unlocked;

  Path _buildScallopPath(Offset center, double outerRadius) {
    const lobes = 8;
    const step = (2 * math.pi) / lobes;
    final valleyR = outerRadius * 0.85;
    final ctrlR = outerRadius * 1.13;

    final path = Path()
      ..moveTo(center.dx + valleyR, center.dy);
    for (var i = 0; i < lobes; i++) {
      final midAngle = (i + 0.5) * step;
      final nextAngle = (i + 1) * step;
      path.quadraticBezierTo(
        center.dx + ctrlR * math.cos(midAngle),
        center.dy + ctrlR * math.sin(midAngle),
        center.dx + valleyR * math.cos(nextAngle),
        center.dy + valleyR * math.sin(nextAngle),
      );
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide * 0.46;
    final outerPath = _buildScallopPath(center, outerRadius);

    if (!unlocked) {
      canvas.drawPath(outerPath, Paint()..color = const Color(0xFFE6E6E6));
      return;
    }

    // Outer bright sky-blue scalloped border (#55C4FF) + deep sky-blue inner fill (#1E88E5).
    canvas.drawPath(outerPath, Paint()..color = const Color(0xFF55C4FF));
    final innerPath = _buildScallopPath(center, outerRadius * 0.84);
    canvas.drawPath(innerPath, Paint()..color = const Color(0xFF1E88E5));
  }

  @override
  bool shouldRepaint(covariant _ScallopPainter oldDelegate) =>
      oldDelegate.unlocked != unlocked;
}

class _TrophyPainter extends CustomPainter {
  const _TrophyPainter({
    required this.baseColor,
    required this.highlightColor,
    required this.shadowColor,
    required this.unlocked,
  });

  final Color baseColor;
  final Color highlightColor;
  final Color shadowColor;
  final bool unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final handlePaint = Paint()
      ..color = unlocked ? shadowColor : baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    // Left & right handles.
    final leftHandle = Path()
      ..moveTo(w * 0.27, h * 0.20)
      ..cubicTo(w * 0.08, h * 0.20, w * 0.09, h * 0.45, w * 0.29, h * 0.47);
    final rightHandle = Path()
      ..moveTo(w * 0.73, h * 0.20)
      ..cubicTo(w * 0.92, h * 0.20, w * 0.91, h * 0.45, w * 0.71, h * 0.47);
    canvas.drawPath(leftHandle, handlePaint);
    canvas.drawPath(rightHandle, handlePaint);

    // Stem & pedestal base.
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.43, h * 0.56, w * 0.14, h * 0.20),
      Radius.circular(w * 0.03),
    );
    final basePaint = Paint()..color = unlocked ? shadowColor : baseColor;
    canvas.drawRRect(stemRect, basePaint);

    final pedestalPath = Path()
      ..moveTo(w * 0.30, h * 0.75)
      ..lineTo(w * 0.70, h * 0.75)
      ..lineTo(w * 0.75, h * 0.87)
      ..lineTo(w * 0.25, h * 0.87)
      ..close();
    canvas.drawPath(pedestalPath, basePaint);

    final bottomFoot = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.85, w * 0.56, h * 0.06),
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(bottomFoot, Paint()..color = baseColor);

    // Cup bowl.
    final cupPath = Path()
      ..moveTo(w * 0.24, h * 0.14)
      ..lineTo(w * 0.76, h * 0.14)
      ..cubicTo(w * 0.76, h * 0.46, w * 0.65, h * 0.61, w * 0.50, h * 0.61)
      ..cubicTo(w * 0.35, h * 0.61, w * 0.24, h * 0.46, w * 0.24, h * 0.14)
      ..close();

    final cupPaint = Paint();
    if (unlocked) {
      cupPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlightColor, baseColor, shadowColor],
      ).createShader(Rect.fromLTWH(w * 0.24, h * 0.14, w * 0.52, h * 0.47));
    } else {
      cupPaint.color = baseColor;
    }
    canvas.drawPath(cupPath, cupPaint);

    // Top rim highlight.
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.21, h * 0.11, w * 0.58, h * 0.06),
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(
      rimRect,
      Paint()..color = unlocked ? highlightColor : baseColor,
    );
  }

  @override
  bool shouldRepaint(covariant _TrophyPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.unlocked != unlocked;
}
