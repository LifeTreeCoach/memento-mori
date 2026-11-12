import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/life_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/visualization_effects.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';

typedef _Dot = ({Color color, double radius});

/// A spiral dot: fill colour, radius and an optional outline ([ring]) that
/// marks a decade or the current item when life phases colour the dots.
typedef SpiralDot = ({Color color, double radius, Color? ring});

/// Life as a spiral of dots from the centre outwards, one dot per item.
class SpiralLayoutPainter extends LifeLayoutPainter {
  SpiralLayoutPainter({
    required super.totalItems,
    required super.itemsCompleted,
    required super.colorTheme,
    super.colors,
    required super.visualSettings,
    super.animationValue,
    super.lifeExpectancyYears,
    super.labels,
    super.ageYears,
    super.layoutText,
    super.milestoneColor,
    super.phaseColors,
  });

  /// Angle the spiral sweeps from centre to rim: 6 full rotations.
  static const double _sweep = 12 * math.pi;

  /// The spiral's outer radius is the shorter canvas side divided by this.
  static const double _sizeToRadius = 2.5;

  static const double _pathAngleStep = 0.1;
  static const double _pathStrokeWidth = 1.0;
  static const double _pathAlpha = 0.3;
  static const double _dotRadius = 3.0;
  static const double _milestoneDotRadius = 5.0;
  static const double _centerRadius = 8.0;
  static const double _centerBorderWidth = 2.0;

  /// With phases: a small hollow start mark, drawn below the dots, so the
  /// first years (and their phase colour) stay visible.
  static const double phaseCenterRadius = 3.0;
  static const double _phaseCenterBorderWidth = 1.0;
  static const double _phaseCenterAlpha = 0.6;

  /// Decade outline around a normal-sized phase dot.
  static const double decadeRingGap = 1.2;
  static const double _decadeRingWidth = 1.0;

  /// Outline of the current item with phases (a bit stronger than decades).
  static const double _currentRingWidth = 1.6;
  static const double _captionFontSize = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final theme = resolvedColors;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / _sizeToRadius;
    _drawSpiralPath(canvas, center, maxRadius, theme);
    if (phaseColors != null) _drawPhaseCenterIndicator(canvas, center, theme);
    _drawLifeDots(canvas, center, maxRadius, theme);
    if (phaseColors == null) _drawCenterIndicator(canvas, center, theme);
    _drawProgressCaption(canvas, size, center.dy + maxRadius);
  }

  /// The point at [fraction] of the way out (radius) and [angle].
  static Offset _spiralPoint(
    Offset center,
    double maxRadius,
    double fraction,
    double angle,
  ) {
    final radius = fraction * maxRadius;
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  void _drawSpiralPath(
    Canvas canvas,
    Offset center,
    double maxRadius,
    ColorTheme theme,
  ) {
    final pathPaint = Paint()
      ..color = theme.borderColor.withValues(alpha: _pathAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _pathStrokeWidth;
    final path = Path();
    for (double t = 0; t <= _sweep; t += _pathAngleStep) {
      final point = _spiralPoint(center, maxRadius, t / _sweep, t);
      if (t == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, pathPaint);
  }

  /// One dot per item along the spiral. No outline: thousands of dots
  /// overlap, and outlines in the grid-line colour would drown the
  /// lived/remaining colours.
  void _drawLifeDots(
    Canvas canvas,
    Offset center,
    double maxRadius,
    ColorTheme theme,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _decadeRingWidth;
    for (var i = 0; i < totalItems; i++) {
      final fraction = i / totalItems; // loop only runs when totalItems > 0
      final position = _spiralPoint(
        center,
        maxRadius,
        fraction,
        fraction * _sweep,
      );
      final dot = dotFor(i, theme);
      canvas.drawCircle(position, dot.radius, paint..color = dot.color);
      final ring = dot.ring;
      if (ring != null) {
        ringPaint
          ..color = ring
          ..strokeWidth =
              i == itemsCompleted ? _currentRingWidth : _decadeRingWidth;
        canvas.drawCircle(position, dot.radius + decadeRingGap, ringPaint);
      }
    }
  }

  /// A dot's colour, size and outline. Without phases: lived/remaining,
  /// decades larger and gold. With phases a phase colour replaces the
  /// lived/remaining colour (and seasons); a decade keeps the normal size and
  /// its first item gets an outline in [milestoneColor] instead of growing,
  /// and the current item an outline in the text colour (like the grid's
  /// current cell).
  @visibleForTesting
  SpiralDot dotFor(int index, ColorTheme theme) {
    final dot = phaseColors == null
        ? _plainDot(index, theme)
        : _phaseDot(index, theme);
    if (!visualSettings.enableAnimations || index != itemsCompleted) {
      return dot;
    }
    final pulse = VisualizationEffects.getPulseAnimation(
      animationValue,
      index,
      itemsCompleted,
    );
    return (color: dot.color, radius: dot.radius * pulse, ring: dot.ring);
  }

  SpiralDot _plainDot(int index, ColorTheme theme) {
    final base = index < itemsCompleted
        ? _livedDot(index, theme)
        : (color: theme.remainingColor, radius: _dotRadius);
    return (color: base.color, radius: base.radius, ring: null);
  }

  SpiralDot _phaseDot(int index, ColorTheme theme) {
    final lived = index < itemsCompleted;
    final isDecadeStart = lived &&
        visualSettings.enableMilestones &&
        VisualizationEffects.getMilestoneColor(index, itemsPerYear) != null &&
        index % itemsPerYear == 0;
    final fallback = lived
        ? _seasonal(theme.livedColor, index)
        : theme.remainingColor;
    final Color? ring = index == itemsCompleted
        ? layoutText.colorOn(layoutText.background)
        : isDecadeStart
            ? milestoneColor
            : null;
    return (
      color: colorForItem(index) ?? fallback,
      radius: _dotRadius,
      ring: ring,
    );
  }

  Color _seasonal(Color color, int index) => visualSettings.enableSeasons
      ? VisualizationEffects.getSeasonalColor(color, index, itemsPerYear)
      : color;

  /// A lived dot: decades in gold (and larger), tinted by season.
  _Dot _livedDot(int index, ColorTheme theme) {
    var dot = (color: theme.livedColor, radius: _dotRadius);
    final milestone = visualSettings.enableMilestones
        ? VisualizationEffects.getMilestoneColor(index, itemsPerYear)
        : null;
    if (milestone != null) {
      dot = (color: milestone, radius: _milestoneDotRadius);
    }
    if (!visualSettings.enableSeasons) return dot;
    final seasonal = VisualizationEffects.getSeasonalColor(
      dot.color,
      index,
      itemsPerYear,
    );
    return (color: seasonal, radius: dot.radius);
  }

  void _drawCenterIndicator(Canvas canvas, Offset center, ColorTheme theme) {
    final fill = Paint()
      ..color = theme.livedColor
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = theme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _centerBorderWidth;
    canvas.drawCircle(center, _centerRadius, fill);
    canvas.drawCircle(center, _centerRadius, border);
  }

  /// The start of the spiral with phases: a small thin ring below the
  /// dots, so it never hides the first phase.
  void _drawPhaseCenterIndicator(
      Canvas canvas, Offset center, ColorTheme theme) {
    final border = Paint()
      ..color = theme.borderColor.withValues(alpha: _phaseCenterAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _phaseCenterBorderWidth;
    canvas.drawCircle(center, phaseCenterRadius, border);
  }

  /// "{value} years lived · {value}%" centred below the spiral.
  void _drawProgressCaption(Canvas canvas, Size size, double spiralBottom) {
    final caption =
        '${labels.fill(labels.yearsLived, yearsLived)}'
        ' · ${labels.fill(labels.percent, percentLived)}';
    final painter = TextPainter(
      text: TextSpan(
        text: caption,
        style: layoutText.styleOn(
          layoutText.background,
          fontSize: _captionFontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width);
    final gap = (size.height - spiralBottom - painter.height) / 2;
    painter.paint(
      canvas,
      Offset((size.width - painter.width) / 2, spiralBottom + math.max(gap, 0)),
    );
    painter.dispose();
  }
}
