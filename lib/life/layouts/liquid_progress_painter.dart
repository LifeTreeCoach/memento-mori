import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/life_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/phase_layout_colors.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';

/// Life as a container filling with liquid, decades marked on its side.
class LiquidProgressPainter extends LifeLayoutPainter {
  LiquidProgressPainter({
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

  /// Gap between the canvas edges and the container.
  static const double inset = 20;

  /// Strip right of the container that holds the decade axis (ticks and
  /// labels), so labels sit on the page background, never on the fill.
  static const double axisWidth = 40;

  static const double _tickGap = 3;
  static const double _tickLength = 6;
  static const double _tickThickness = 2;
  static const double _labelGap = 4;
  static const double _axisFontSize = 12;

  static const Radius _containerCorner = Radius.circular(20);
  static const double _borderWidth = 3.0;

  /// Alpha of the liquid's top when gradients are enabled.
  static const double _gradientTopAlpha = 0.7;

  static const double _waveAlpha = 0.8;
  static const double _waveStep = 2;
  static const double _waveLength = 20;
  static const double _waveAmplitude = 3;

  /// Space between the progress text and the wave crests.
  static const double _surfaceGap = 4;

  static const double _percentFontSize = 24;
  static const double _yearsFontSize = 16;

  /// Distance of the years line below the percent line (centre to centre).
  static const double _yearsLineOffset = 40;

  /// The container the liquid fills.
  static Rect containerRect(Size size) =>
      Rect.fromLTRB(inset, inset, size.width - axisWidth, size.height - inset);

  /// Left edge of the decade labels: right of the container and its ticks.
  static double axisLabelLeft(Size size) =>
      containerRect(size).right + _tickGap + _tickLength + _labelGap;

  /// Top of the liquid surface for [progress] inside the container.
  static double liquidTopFor(Size size, double progress) =>
      size.height - inset - (size.height - 2 * inset) * progress;

  /// What is drawn behind a text centred at height [y]: the liquid below
  /// its surface, the empty container above it.
  static Color backgroundAt(
    double y,
    Size size,
    double progress,
    ColorTheme theme,
  ) => y >= liquidTopFor(size, progress)
      ? theme.livedColor
      : theme.remainingColor;

  /// The filled part of the container for [progress].
  static Rect _liquidRect(Size size, double progress) {
    final container = containerRect(size);
    return Rect.fromLTRB(
      container.left,
      liquidTopFor(size, progress),
      container.right,
      container.bottom,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final theme = resolvedColors;
    _drawContainer(canvas, size, theme);
    _drawLiquid(canvas, size, theme);
    if (visualSettings.enableAnimations) _drawWave(canvas, size, theme);
    _drawProgressText(canvas, size, theme);
    if (visualSettings.enableMilestones) _drawDecadeAxis(canvas, size);
  }

  void _drawContainer(Canvas canvas, Size size, ColorTheme theme) {
    final fill = Paint()
      ..color = theme.remainingColor
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = theme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;
    final rrect = RRect.fromRectAndRadius(
      containerRect(size),
      _containerCorner,
    );
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, border);
  }

  void _drawLiquid(Canvas canvas, Size size, ColorTheme theme) {
    final liquid = _liquidRect(size, progress);
    final paint = Paint()..style = PaintingStyle.fill;
    if (visualSettings.enableGradients) {
      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          theme.livedColor,
          theme.livedColor.withValues(alpha: _gradientTopAlpha),
        ],
      ).createShader(liquid);
    } else {
      paint.color = theme.livedColor;
    }
    canvas.drawRect(liquid, paint);
    _drawPhaseBands(canvas, size);
  }

  /// Life phases stacked in the liquid, the planned rest above it.
  void _drawPhaseBands(Canvas canvas, Size size) {
    final phases = phaseColors;
    if (phases == null) return;
    final container = containerRect(size);
    final paint = Paint()..style = PaintingStyle.fill;
    for (final band in phases.bands(progress)) {
      final rect = Rect.fromLTRB(
        container.left,
        liquidTopFor(size, band.to),
        container.right,
        liquidTopFor(size, band.from),
      );
      canvas.drawRect(rect, paint..color = band.color);
    }
  }

  /// Colour at the top of the liquid: the current phase, else lived.
  Color _surfaceColor(ColorTheme theme) =>
      colorForItem(itemsCompleted) ?? theme.livedColor;

  void _drawWave(Canvas canvas, Size size, ColorTheme theme) {
    final liquid = _liquidRect(size, progress);
    if (liquid.height <= 0) return;
    final wavePaint = Paint()
      ..color = _surfaceColor(theme).withValues(alpha: _waveAlpha)
      ..style = PaintingStyle.fill;
    // With phases only the surface waves, so the bands below keep their
    // colours.
    final bottom = phaseColors == null
        ? liquid.bottom
        : math.min(liquid.bottom, liquid.top + _waveAmplitude);
    canvas.drawPath(_wavePath(liquid, bottom), wavePaint);
  }

  /// [liquid] with a sine wave as its surface, shifted by the animation,
  /// down to [bottom].
  Path _wavePath(Rect liquid, double bottom) {
    final path = Path()..moveTo(liquid.left, liquid.top);
    for (double x = liquid.left; x <= liquid.right; x += _waveStep) {
      final phase = (x / _waveLength) + (animationValue * 4 * math.pi);
      path.lineTo(x, liquid.top + math.sin(phase) * _waveAmplitude);
    }
    return path
      ..lineTo(liquid.right, bottom)
      ..lineTo(liquid.left, bottom)
      ..close();
  }

  void _drawProgressText(Canvas canvas, Size size, ColorTheme theme) {
    final centerX = containerRect(size).center.dx;
    final percentText = labels.fill(labels.percent, percentLived);
    final yearsText = labels.fill(labels.yearsLived, yearsLived);
    final percentHeight = _textHeight(percentText, theme, _percentFontSize);
    final yearsHeight = _textHeight(yearsText, theme, _yearsFontSize);
    final percentY = size.height / 2;
    final yearsY = percentY + _yearsLineOffset;
    final shift = textShiftOffSurface(
      top: percentY - percentHeight / 2,
      bottom: yearsY + yearsHeight / 2,
      surface: liquidTopFor(size, progress),
      plannedTop: _plannedTop(size),
    );
    _paintCentered(
      canvas,
      percentText,
      _textStyleAt(
        percentY + shift,
        percentHeight,
        size,
        theme,
        fontSize: _percentFontSize,
      ),
      Offset(centerX, percentY + shift),
    );
    _paintCentered(
      canvas,
      yearsText,
      _textStyleAt(
        yearsY + shift,
        yearsHeight,
        size,
        theme,
        fontSize: _yearsFontSize,
      ),
      Offset(centerX, yearsY + shift),
    );
  }

  /// Top edge of the planned band above the liquid, or null without one.
  double? _plannedTop(Size size) {
    final bands = phaseColors?.bands(progress) ?? const <PhaseBand>[];
    final reach = bands.fold<double>(progress, (top, b) => math.max(top, b.to));
    return reach > progress ? liquidTopFor(size, reach) : null;
  }

  /// Vertical shift that keeps the text block [top]..[bottom] clear of the
  /// liquid [surface] and its wave, and of the planned band above it (up to
  /// [plannedTop]); 0 when it already is. Moves the block the shorter way,
  /// so it stays fully on the liquid or above the planned band.
  static double textShiftOffSurface({
    required double top,
    required double bottom,
    required double surface,
    double? plannedTop,
  }) {
    const clearance = _waveAmplitude + _surfaceGap;
    final upper = math.min(plannedTop ?? surface, surface);
    if (surface < top - clearance || upper > bottom + clearance) return 0;
    final up = upper - clearance - bottom;
    final down = surface + clearance - top;
    return up.abs() <= down.abs() ? up : down;
  }

  double _textHeight(String text, ColorTheme theme, double fontSize) {
    final painter = layoutPainterText(
      text,
      layoutText.styleOn(theme.remainingColor, fontSize: fontSize),
    );
    final height = painter.height;
    painter.dispose();
    return height;
  }

  static void _paintCentered(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset center,
  ) {
    final painter = layoutPainterText(text, style);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  /// Style of a text line centred at [y], [height] tall: legible on every
  /// band or fill it crosses (a line can straddle two phase bands).
  TextStyle _textStyleAt(
    double y,
    double height,
    Size size,
    ColorTheme theme, {
    required double fontSize,
  }) {
    final backgrounds = backgroundsBetween(
      y - height / 2,
      y + height / 2,
      size,
      theme,
    );
    return layoutText.styleOnAll(backgrounds, fontSize: fontSize);
  }

  /// Samples per text line in [backgroundsBetween].
  static const int _backgroundSamples = 9;

  /// The distinct colours behind the heights [top]..[bottom]: phase bands,
  /// the liquid or the empty container.
  List<Color> backgroundsBetween(
    double top,
    double bottom,
    Size size,
    ColorTheme theme,
  ) {
    final colors = <Color>{};
    for (var i = 0; i < _backgroundSamples; i++) {
      final y = top + (bottom - top) * i / (_backgroundSamples - 1);
      colors.add(
        _phaseBackgroundAt(y, size) ?? backgroundAt(y, size, progress, theme),
      );
    }
    return colors.toList();
  }

  /// The phase band behind height [y], or null.
  Color? _phaseBackgroundAt(double y, Size size) {
    final phases = phaseColors;
    if (phases == null) return null;
    final container = containerRect(size);
    final share = (container.bottom - y) / container.height;
    for (final band in phases.bands(progress)) {
      if (share >= band.from && share < band.to) return band.color;
    }
    return null;
  }

  /// Decade ticks on the container's right edge, labels beside them on
  /// the page background (one colour for all, no halo needed).
  void _drawDecadeAxis(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = milestoneColor
      ..style = PaintingStyle.fill;
    final labelStyle = _axisLabelStyle();
    for (final decade in decades) {
      final y = liquidTopFor(size, decade / lifeExpectancyYears);
      _drawDecadeTick(canvas, size, y, tickPaint);
      _drawDecadeLabel(canvas, size, '$decade', y, labelStyle);
    }
  }

  TextStyle _axisLabelStyle() => TextStyle(
    color: layoutText.colorOn(layoutText.background),
    fontFamily: layoutText.fontFamily,
    fontSize: _axisFontSize,
    fontWeight: FontWeight.w600,
  );

  void _drawDecadeTick(Canvas canvas, Size size, double y, Paint paint) {
    final left = containerRect(size).right + _tickGap;
    canvas.drawRect(
      Rect.fromLTWH(left, y - _tickThickness / 2, _tickLength, _tickThickness),
      paint,
    );
  }

  void _drawDecadeLabel(
    Canvas canvas,
    Size size,
    String text,
    double y,
    TextStyle style,
  ) {
    final label = layoutPainterText(text, style);
    label.paint(canvas, Offset(axisLabelLeft(size), y - label.height / 2));
    label.dispose();
  }
}
