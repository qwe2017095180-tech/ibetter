import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../../domain/services/achievement_service.dart';

/// "每周打卡记录" card with year stepper, smooth Bezier area chart, and week selection.
class WeeklyChartCard extends StatefulWidget {
  const WeeklyChartCard({
    super.key,
    required this.selectedYear,
    required this.maxYear,
    required this.weeks,
    required this.onYearChanged,
  });

  final int selectedYear;
  final int maxYear;
  final List<WeeklyRecord> weeks;
  final ValueChanged<int> onYearChanged;

  @override
  State<WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends State<WeeklyChartCard> {
  static const int _windowSize = 7;
  static const double _leftAxisWidth = 28.0;
  static const double _rightMargin = 8.0;

  late int _windowEnd;
  int? _selectedWeekNumber;
  double _dragDeltaX = 0;

  @override
  void initState() {
    super.initState();
    _resetWindowToLatest();
  }

  @override
  void didUpdateWidget(covariant WeeklyChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear) {
      _resetWindowToLatest();
    } else if (oldWidget.weeks.length != widget.weeks.length) {
      final minEnd = math.min(_windowSize, widget.weeks.length);
      _windowEnd = _windowEnd.clamp(minEnd, widget.weeks.length);
      if (widget.weeks.isEmpty) {
        _selectedWeekNumber = null;
      } else if (_selectedWeekNumber == null ||
          !_visibleWeeks.any((w) => w.weekNumber == _selectedWeekNumber)) {
        _selectedWeekNumber = _visibleWeeks.last.weekNumber;
      }
    }
  }

  void _resetWindowToLatest() {
    _windowEnd = widget.weeks.length;
    _selectedWeekNumber = widget.weeks.isEmpty ? null : widget.weeks.last.weekNumber;
  }

  List<WeeklyRecord> get _visibleWeeks {
    if (widget.weeks.isEmpty) return const [];
    final int minEnd = math.min(_windowSize, widget.weeks.length);
    final int end = _windowEnd.clamp(minEnd, widget.weeks.length).toInt();
    final int start = math.max(0, end - _windowSize);
    return widget.weeks.sublist(start, end);
  }

  void _shiftWindow(int stepWeeks) {
    if (widget.weeks.isEmpty) return;
    final visible = _visibleWeeks;
    if (widget.weeks.length <= _windowSize) {
      // Pan highlighted week within the single available window.
      final curIdx = visible.indexWhere((w) => w.weekNumber == _selectedWeekNumber);
      final base = curIdx < 0 ? visible.length - 1 : curIdx;
      final nextIdx = (base + (stepWeeks > 0 ? 1 : -1)).clamp(0, visible.length - 1);
      setState(() => _selectedWeekNumber = visible[nextIdx].weekNumber);
      return;
    }

    final minEnd = math.min(_windowSize, widget.weeks.length);
    final nextEnd = (_windowEnd + stepWeeks).clamp(minEnd, widget.weeks.length);
    if (nextEnd == _windowEnd) return;
    setState(() {
      _windowEnd = nextEnd;
      final updated = _visibleWeeks;
      if (!updated.any((w) => w.weekNumber == _selectedWeekNumber)) {
        _selectedWeekNumber = updated.last.weekNumber;
      }
    });
  }

  void _selectAtOffset(double localDx, double totalWidth, List<WeeklyRecord> visible) {
    if (visible.isEmpty) return;
    final plotWidth = totalWidth - _leftAxisWidth - _rightMargin;
    if (plotWidth <= 0) return;
    final relX = (localDx - _leftAxisWidth).clamp(0.0, plotWidth - 0.001);
    final idx = ((relX / plotWidth) * visible.length).floor().clamp(0, visible.length - 1);
    setState(() => _selectedWeekNumber = visible[idx].weekNumber);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleWeeks;
    final selectedIdx = visible.isEmpty
        ? -1
        : math.max(0, visible.indexWhere((w) => w.weekNumber == _selectedWeekNumber));
    final canGoNext = widget.selectedYear < widget.maxYear;
    final canGoPrev = widget.selectedYear > 1900;

    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                '每周打卡记录',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _YearStepper(
                year: widget.selectedYear,
                canGoPrev: canGoPrev,
                canGoNext: canGoNext,
                onPrev: canGoPrev ? () => widget.onYearChanged(widget.selectedYear - 1) : null,
                onNext: canGoNext ? () => widget.onYearChanged(widget.selectedYear + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  '暂无每周数据',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final selectedRecord = visible[selectedIdx];
                return GestureDetector(
                  key: const ValueKey('weekly_chart_canvas'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      _selectAtOffset(details.localPosition.dx, constraints.maxWidth, visible),
                  onHorizontalDragStart: (_) => _dragDeltaX = 0,
                  onHorizontalDragUpdate: (details) => _dragDeltaX += details.delta.dx,
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    // Swipe right shows earlier weeks; swipe left advances toward latest week.
                    if (velocity > 200 || _dragDeltaX > 40) {
                      _shiftWindow(-_windowSize);
                    } else if (velocity < -200 || _dragDeltaX < -40) {
                      _shiftWindow(_windowSize);
                    }
                    _dragDeltaX = 0;
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        label: '第${selectedRecord.weekNumber}周 ${selectedRecord.completions}次',
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: 164,
                          child: CustomPaint(
                            painter: _WeeklyChartPainter(
                              weeks: visible,
                              selectedIndex: selectedIdx,
                              leftMargin: _leftAxisWidth,
                              rightMargin: _rightMargin,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: _leftAxisWidth, right: _rightMargin),
                        child: Row(
                          children: [
                            for (var i = 0; i < visible.length; i++)
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      setState(() => _selectedWeekNumber = visible[i].weekNumber),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '第${visible[i].weekNumber}周',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: i == selectedIdx
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: i == selectedIdx
                                              ? AppColors.primary
                                              : AppColors.textHint,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _YearStepper extends StatelessWidget {
  const _YearStepper({
    required this.year,
    required this.canGoPrev,
    required this.canGoNext,
    this.onPrev,
    this.onNext,
  });

  final int year;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkResponse(
          key: const ValueKey('weekly_prev_year'),
          radius: 18,
          onTap: onPrev,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_left,
              size: 20,
              color: canGoPrev ? AppColors.textSecondary : AppColors.textHint,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '$year',
            key: const ValueKey('weekly_selected_year'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        InkResponse(
          key: const ValueKey('weekly_next_year'),
          radius: 18,
          onTap: onNext,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: canGoNext ? AppColors.textSecondary : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  const _WeeklyChartPainter({
    required this.weeks,
    required this.selectedIndex,
    required this.leftMargin,
    required this.rightMargin,
  });

  final List<WeeklyRecord> weeks;
  final int selectedIndex;
  final double leftMargin;
  final double rightMargin;

  static const _lineColor = Color(0xFF8CC4F5);
  static const _accentBlue = Color(0xFF389BFF);
  static const _gridColor = Color(0xFFF0EDED);

  int _computeNiceStep(int maxCount) {
    if (maxCount <= 4) return 1;
    final rawStep = (maxCount / 4.0).ceil();
    final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor()).toInt();
    final norm = rawStep / magnitude;
    final int niceNorm;
    if (norm <= 1) {
      niceNorm = 1;
    } else if (norm <= 2) {
      niceNorm = 2;
    } else if (norm <= 3 && magnitude == 1) {
      niceNorm = 3;
    } else if (norm <= 5) {
      niceNorm = 5;
    } else {
      niceNorm = 10;
    }
    return niceNorm * magnitude;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (weeks.isEmpty) return;

    const topMargin = 34.0;
    const bottomMargin = 8.0;
    final plotLeft = leftMargin;
    final plotRight = size.width - rightMargin;
    final plotTop = topMargin;
    final plotBottom = size.height - bottomMargin;
    final plotWidth = plotRight - plotLeft;
    final plotHeight = plotBottom - plotTop;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final maxCount = weeks.map((w) => w.completions).fold<int>(0, math.max);
    final step = _computeNiceStep(maxCount);
    final topTick = step * 4;

    // 1. Horizontal grid lines & Y-axis ticks (0..topTick in 4 intervals).
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 1.0;

    for (var i = 0; i <= 4; i++) {
      final tickVal = i * step;
      final y = plotBottom - (i / 4.0) * plotHeight;
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$tickVal',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(plotLeft - tp.width - 8, y - tp.height / 2));
    }

    // 2. Compute data point positions aligned with equal column slots.
    final n = weeks.length;
    final points = List<Offset>.generate(n, (i) {
      final x = plotLeft + plotWidth * (i + 0.5) / n;
      final ratio = (weeks[i].completions / topTick).clamp(0.0, 1.0);
      final y = plotBottom - ratio * plotHeight;
      return Offset(x, y);
    });

    // 3. Smooth monotone-safe cubic Bezier curve & vertical gradient fill.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, plotBottom)
      ..lineTo(points.first.dx, plotBottom)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _lineColor.withValues(alpha: 0.35),
          _lineColor.withValues(alpha: 0.03),
        ],
      ).createShader(Rect.fromLTRB(plotLeft, plotTop, plotRight, plotBottom));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // 4. Solid blue circle markers.
    final dotPaint = Paint()..color = _accentBlue;
    final haloPaint = Paint()..color = _accentBlue.withValues(alpha: 0.22);
    for (var i = 0; i < points.length; i++) {
      if (i == selectedIndex) {
        canvas.drawCircle(points[i], 8.5, haloPaint);
        canvas.drawCircle(points[i], 5.0, dotPaint);
      } else {
        canvas.drawCircle(points[i], 3.8, dotPaint);
      }
    }

    // 5. Floating blue pill callout above the highlighted point.
    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final anchor = points[selectedIndex];
      final valueText = '${weeks[selectedIndex].completions}';
      final labelPainter = TextPainter(
        text: TextSpan(
          text: valueText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillWidth = math.max(30.0, labelPainter.width + 16);
      const pillHeight = 22.0;
      final pillLeft = (anchor.dx - pillWidth / 2).clamp(4.0, size.width - pillWidth - 4.0);
      final pillTop = math.max(2.0, anchor.dy - 11.0 - pillHeight);
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillLeft, pillTop, pillWidth, pillHeight),
        const Radius.circular(11),
      );

      canvas.drawRRect(pillRect, dotPaint);
      labelPainter.paint(
        canvas,
        Offset(
          pillLeft + (pillWidth - labelPainter.width) / 2,
          pillTop + (pillHeight - labelPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) {
    if (oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.leftMargin != leftMargin ||
        oldDelegate.rightMargin != rightMargin ||
        oldDelegate.weeks.length != weeks.length) {
      return true;
    }
    for (var i = 0; i < weeks.length; i++) {
      if (oldDelegate.weeks[i].weekNumber != weeks[i].weekNumber ||
          oldDelegate.weeks[i].completions != weeks[i].completions) {
        return true;
      }
    }
    return false;
  }
}
