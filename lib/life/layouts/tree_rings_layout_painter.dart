import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/life_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/tree_rings_center_text.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';

/// Life as the rings of a tree trunk, one ring per year.
class TreeRingsLayoutPainter extends LifeLayoutPainter {
  TreeRingsLayoutPainter({
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
    this.boundaryEmphasis = 0,
  });

  /// 0..1: how strongly the "now" ring (lived boundary) stands out; 0 is
  /// the static boundary. Driven by a few calm breaths, then back to 0.
  final double boundaryEmphasis;

  /// Smallest centre-text font scale; below it text gets too small to read.
  static const double minCenterTextScale = 0.6;

  /// The outer ring's radius is the shorter canvas side divided by this.
  static const double _sizeToRadius = 2.2;

  /// Share of the outer radius the centre text may always use, even when
  /// the lived disc is smaller.
  static const double _minCenterTextRadiusShare = 0.3;
  static const double _mainFontSize = 18;
  static const double _percentFontSize = 14;

  // Wood background.
  static final Color _trunkColor = const Color(0xFF8B4513)
      .withValues(alpha: 0.2); // Saddle brown
  static final Color _grainColor = const Color(0xFF654321)
      .withValues(alpha: 0.1);
  static const int _grainLines = 8;
  static const double _grainStep = 10;
  static const double _grainWaveLength = 30;
  static const double _grainAmplitude = 3;

  // Rings.
  static const double _livedRingAlpha = 0.8;
  static const double _remainingRingAlpha = 0.3;
  static const double _ringBaseWidth = 2.5;
  static const double _ringWidthVariation = 0.8;
  static const double _ringAgeVariation = 0.5;
  static const double _ringMinWidth = 1.0;
  static const double _ringMaxWidth = 4.0;
  static const double _boundaryAlpha = 0.6;
  static const double _boundaryWidth = 3.0;
  static const double _emphasizedBoundaryAlpha = 0.9;
  static const double _emphasizedBoundaryWidth = 4.0;

  /// Wood tint blended into lived rings per season (ring % 4) when
  /// seasons are enabled: spring lighter, summer rich, autumn darker,
  /// winter very dark.
  static const List<(Color, double)> _seasonTints = [
    (Color(0xFFDEB887), 0.3), // Burlywood
    (Color(0xFF8B4513), 0.2), // Saddle brown
    (Color(0xFF4A2F20), 0.4), // Dark brown
    (Color(0xFF3C1810), 0.3), // Very dark brown
  ];

  // Wood-grain dots on lived rings.
  static const double _textureAlpha = 0.2;
  static const double _textureDotSpacing = 5;
  static const double _textureDotRadius = 0.8;
  static const double _textureAmplitude = 2;

  // Decade rings and labels.
  static const double _decadeRingAlpha = 0.6;
  static const double _decadeRingWidth = 3.0;
  static const double _decadeFontSize = 10;
  static const double _pillHorizontalPadding = 8;
  static const double _pillVerticalPadding = 2;

  /// Radius of the ring at [years] of life: linear from 0 at the centre to
  /// [maxRadius] at [lifeExpectancyYears]. Rings, the lived boundary and
  /// decade labels all use it, so ring 40, label "40" and the fill at age
  /// 40 coincide.
  static double radiusForYears(
    double years,
    double maxRadius,
    int lifeExpectancyYears,
  ) {
    if (lifeExpectancyYears <= 0) return 0;
    return (years / lifeExpectancyYears).clamp(0.0, 1.0) * maxRadius;
  }

  /// Font scale that makes centre text whose bounding disc has
  /// [textRadius] (at scale 1) fit in a disc of [discRadius]; 1 when it
  /// already fits, never below [minCenterTextScale].
  static double centerTextScale(double textRadius, double discRadius) {
    if (textRadius <= discRadius) return 1;
    return (discRadius / textRadius).clamp(minCenterTextScale, 1.0);
  }

  double _radiusFor(double years, double maxRadius) =>
      radiusForYears(years, maxRadius, lifeExpectancyYears);

  @override
  void paint(Canvas canvas, Size size) {
    final theme = resolvedColors;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / _sizeToRadius;
    _drawTrunk(canvas, size);
    _drawRings(canvas, center, maxRadius, theme);
    _drawCenterAndDecades(canvas, center, maxRadius, theme);
  }

  /// Centre disc, decade markers and centre text. Decade labels that
  /// would cover the centre text are skipped, their rings stay; the text
  /// is painted last, so nothing is painted over it.
  void _drawCenterAndDecades(
    Canvas canvas,
    Offset center,
    double maxRadius,
    ColorTheme theme,
  ) {
    final centerText = _layoutCenterText(theme, maxRadius);
    _drawCenterDisc(canvas, center, centerText, maxRadius, theme);
    if (visualSettings.enableMilestones) {
      _drawDecades(canvas, center, maxRadius, centerText.boundsAt(center));
    }
    centerText.paint(canvas, center);
    centerText.dispose();
  }

  /// Radius of the lived rings, the disc the centre text sits on.
  double _livedDiscRadius(double maxRadius) =>
      _radiusFor(yearsLived, maxRadius);

  /// The innermost rings sit behind the text: lived once life has begun.
  Color _centerBackground(ColorTheme theme) =>
      progress > 0 ? theme.livedColor : theme.remainingColor;

  /// Wood background with wavy grain lines.
  void _drawTrunk(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _trunkColor);
    final grainPaint = Paint()
      ..color = _grainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var line = 0; line < _grainLines; line++) {
      canvas.drawPath(_grainPath(size, line), grainPaint);
    }
  }

  static Path _grainPath(Size size, int line) {
    final y = size.height * (line / _grainLines);
    final path = Path()..moveTo(0, y);
    for (double x = 0; x <= size.width; x += _grainStep) {
      final waveOffset =
          math.sin(x / _grainWaveLength + line) * _grainAmplitude;
      path.lineTo(x, y + waveOffset);
    }
    return path;
  }

  void _drawRings(
    Canvas canvas,
    Offset center,
    double maxRadius,
    ColorTheme theme,
  ) {
    for (var ring = 1; ring <= lifeExpectancyYears; ring++) {
      _drawRing(canvas, center, ring, maxRadius, theme);
    }
    if (yearsLived < lifeExpectancyYears) {
      _drawLivedBoundary(canvas, center, maxRadius, theme);
    }
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    int ring,
    double maxRadius,
    ColorTheme theme,
  ) {
    final radius = _radiusFor(ring.toDouble(), maxRadius);
    final isLived = ring <= yearsLived;
    final color = _ringColor(ring, isLived, theme);
    final paint = Paint()
      ..color = color.withValues(
        alpha: isLived ? _livedRingAlpha : _remainingRingAlpha,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth(ring);
    canvas.drawCircle(center, radius, paint);
    if (isLived) _drawRingTexture(canvas, center, radius, ring, color);
  }

  /// The ring's phase colour (by the year it starts), else lived (tinted
  /// by season) or remaining.
  Color _ringColor(int ring, bool isLived, ColorTheme theme) {
    final phase = phaseColors?.colorForItem(ring - 1, lifeExpectancyYears);
    if (phase != null) return phase;
    if (!isLived) return theme.remainingColor;
    if (!visualSettings.enableSeasons) return theme.livedColor;
    final (tint, ratio) = _seasonTints[ring % _seasonTints.length];
    return Color.lerp(theme.livedColor, tint, ratio)!;
  }

  /// Ring width varies to simulate natural growth; rings get thinner as
  /// the tree ages.
  double _ringWidth(int ring) {
    final variation = math.sin(ring * 0.5) * _ringWidthVariation;
    final ageVariation = (1 - (ring / lifeExpectancyYears)) * _ringAgeVariation;
    return (_ringBaseWidth + variation + ageVariation).clamp(
      _ringMinWidth,
      _ringMaxWidth,
    );
  }

  /// Subtle dots along a lived ring that simulate wood grain.
  void _drawRingTexture(
    Canvas canvas,
    Offset center,
    double radius,
    int ring,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: _textureAlpha)
      ..style = PaintingStyle.fill;
    final dots = (radius / _textureDotSpacing).floor();
    for (var i = 0; i < dots; i++) {
      final angle = (i / dots) * 2 * math.pi;
      final dotRadius =
          radius + (math.sin(angle * 3 + ring) * _textureAmplitude);
      canvas.drawCircle(
        _pointOnCircle(center, dotRadius, angle),
        _textureDotRadius,
        paint,
      );
    }
  }

  static Offset _pointOnCircle(Offset center, double radius, double angle) =>
      Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

  /// The current growth ring at the exact age, raised by
  /// [boundaryEmphasis].
  void _drawLivedBoundary(
    Canvas canvas,
    Offset center,
    double maxRadius,
    ColorTheme theme,
  ) {
    final emphasis = boundaryEmphasis.clamp(0.0, 1.0);
    final alpha =
        _lerp(_boundaryAlpha, _emphasizedBoundaryAlpha, emphasis);
    final paint = Paint()
      ..color = theme.livedColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          _lerp(_boundaryWidth, _emphasizedBoundaryWidth, emphasis);
    canvas.drawCircle(center, _radiusFor(yearsLived, maxRadius), paint);
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;

  @override
  bool shouldRepaint(LifeLayoutPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      (oldDelegate is TreeRingsLayoutPainter &&
          oldDelegate.boundaryEmphasis != boundaryEmphasis);

  /// The lived disc is often smaller than the text needs (early in life);
  /// then a solid disc in the text's background colour is drawn behind it,
  /// so the text never spills onto rings of another colour.
  void _drawCenterDisc(
    Canvas canvas,
    Offset center,
    TreeRingsCenterText text,
    double maxRadius,
    ColorTheme theme,
  ) {
    final needed = text.radius + TreeRingsCenterText.discPadding;
    if (needed <= _livedDiscRadius(maxRadius)) return;
    canvas.drawCircle(
      center,
      needed,
      Paint()..color = _centerBackground(theme),
    );
  }

  /// Centre text scaled to fit the lived disc (at most full size, at
  /// least [minCenterTextScale]), in a colour legible on what lies behind.
  TreeRingsCenterText _layoutCenterText(ColorTheme theme, double maxRadius) {
    final fullSize = _centerTextAt(1, [_centerBackground(theme)]);
    final backgrounds = centerBackgrounds(theme, maxRadius, fullSize.radius);
    fullSize.dispose();
    final scaled = _centerTextAt(1, backgrounds);
    final scale = centerTextScale(
      scaled.radius,
      // Fit into the lived disc, but never shrink below what the canvas
      // allows (the text then gets its own disc, see _drawCenterDisc).
      math.max(
            _livedDiscRadius(maxRadius),
            maxRadius * _minCenterTextRadiusShare,
          ) -
          TreeRingsCenterText.discPadding,
    );
    if (scale == 1) return scaled;
    scaled.dispose();
    return _centerTextAt(scale, backgrounds);
  }

  /// Colours behind centre text of [textRadius]: its own disc
  /// ([_drawCenterDisc]) when the lived rings are too small for it, else
  /// the colours of the rings it covers (phases differ ring by ring).
  List<Color> centerBackgrounds(
    ColorTheme theme,
    double maxRadius,
    double textRadius,
  ) {
    final needed = textRadius + TreeRingsCenterText.discPadding;
    final ownDisc = needed > _livedDiscRadius(maxRadius);
    if (phaseColors == null || ownDisc || maxRadius <= 0) {
      return [_centerBackground(theme)];
    }
    final rings = (needed / maxRadius * lifeExpectancyYears).ceil().clamp(
      1,
      lifeExpectancyYears,
    );
    return {
      for (var ring = 1; ring <= rings; ring++) _ringColor(ring, true, theme),
    }.toList();
  }

  TreeRingsCenterText _centerTextAt(double scale, List<Color> backgrounds) =>
      TreeRingsCenterText(
        main: layoutPainterText(
          labels.fill(labels.yearsStacked, yearsLived),
          layoutText.styleOnAll(backgrounds, fontSize: _mainFontSize * scale),
          textAlign: TextAlign.center,
        ),
        percent: layoutPainterText(
          labels.fill(labels.grown, percentLived),
          layoutText.styleOnAll(
            backgrounds,
            fontSize: _percentFontSize * scale,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        scale: scale,
      );

  /// A ring per decade, labelled at its top unless the label would cover
  /// [centerTextRect].
  void _drawDecades(
    Canvas canvas,
    Offset center,
    double maxRadius,
    Rect centerTextRect,
  ) {
    final ringPaint = Paint()
      ..color = milestoneColor.withValues(alpha: _decadeRingAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _decadeRingWidth;
    for (final decade in decades) {
      final radius = _radiusFor(decade.toDouble(), maxRadius);
      canvas.drawCircle(center, radius, ringPaint);
      _drawDecadeLabel(
        canvas,
        '$decade',
        Offset(center.dx, center.dy - radius),
        avoid: centerTextRect,
      );
    }
  }

  /// Draws [text] centred on [anchor] (a point on the ring line) over a
  /// small pill in the page background, outlined in [milestoneColor], so
  /// it stays legible on top of the rings.
  /// Skipped when the pill would overlap [avoid] (the centre text).
  void _drawDecadeLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    required Rect avoid,
  }) {
    final label = layoutPainterText(text, _decadeLabelStyle());
    final pillRect = Rect.fromCenter(
      center: anchor,
      width: label.width + _pillHorizontalPadding,
      height: label.height + _pillVerticalPadding,
    );
    if (!pillRect.overlaps(avoid)) {
      _drawPill(canvas, pillRect);
      label.paint(canvas, anchor - Offset(label.width / 2, label.height / 2));
    }
    label.dispose();
  }

  TextStyle _decadeLabelStyle() => TextStyle(
    color: layoutText.colorOn(layoutText.background),
    fontFamily: layoutText.fontFamily,
    fontSize: _decadeFontSize,
    fontWeight: FontWeight.bold,
  );

  void _drawPill(Canvas canvas, Rect rect) {
    final pill = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    canvas.drawRRect(pill, Paint()..color = layoutText.background);
    canvas.drawRRect(
      pill,
      Paint()
        ..color = milestoneColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
