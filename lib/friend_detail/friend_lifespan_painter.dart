import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/theme/layout_text.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// A friend's life as a container filling with liquid up to their current
/// age, with an age scale on the right.
class FriendLifespanPainter extends CustomPainter {
  final Friend friend;
  final LifePalette palette;

  /// Container border.
  final Color outline;

  /// Label of the current-age indicator.
  final Color labelColor;

  /// Age labels on the scale, coloured by the fill beneath each label.
  final LayoutText scaleText;

  /// Fill of the current-age indicator.
  final Color indicatorFill;
  final double animationValue;
  final bool enableAnimation;

  FriendLifespanPainter({
    required this.friend,
    required this.palette,
    required this.outline,
    required this.labelColor,
    required this.scaleText,
    required this.indicatorFill,
    this.animationValue = 0.0,
    this.enableAnimation = true,
  });

  /// Gap between the canvas edges and the container.
  static const double _inset = 16;
  static const Radius _corner = Radius.circular(16);
  static const double _borderWidth = 1.0;

  /// Alpha of the liquid's top (gradient from the full lived colour).
  static const double _gradientTopAlpha = 0.8;

  static const double _waveAlpha = 0.6;
  static const double _waveStep = 2;
  static const double _waveLength = 30;
  static const double _waveAmplitude = 4;

  /// Years between two scale markers.
  static const int _scaleStepYears = 10;

  /// Scale ticks: distance of their left edge from the canvas's right edge.
  static const double _tickRightOffset = 12;
  static const double _tickLength = 8;
  static const double _tickThickness = 2;

  /// Scale labels: distance of their left edge from the canvas's right edge.
  static const double _labelRightOffset = 28;
  static const double _scaleFontSize = 10;

  static const double _indicatorRadius = 8;
  static const double _indicatorBorderWidth = 2.0;
  static const double _indicatorFontSize = 12;

  @override
  void paint(Canvas canvas, Size size) {
    // Painted only for friends with a birth year (see the lifespan section).
    final currentAge = friend.getCurrentAge() ?? 0;
    final lifespan = friend.customLifespan;
    final progress = lifespan <= 0
        ? 1.0
        : (currentAge / lifespan).clamp(0.0, 1.0);

    _drawContainer(canvas, size);
    _drawLiquidProgress(canvas, size, progress);
    if (enableAnimation) {
      _drawWaveAnimation(canvas, size, progress);
    }
    _drawMilestoneMarkers(canvas, size, lifespan, progress);
    _drawProgressIndicator(canvas, size, progress, currentAge);
  }

  /// Height of the container's inside.
  static double _innerHeight(Size size) => size.height - 2 * _inset;

  /// Height at [share] (0 = bottom, 1 = top) of the container.
  static double _levelY(Size size, double share) =>
      size.height - _inset - (_innerHeight(size) * share);

  void _drawContainer(Canvas canvas, Size size) {
    final containerPaint = Paint()
      ..color = palette.remaining
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;
    final rect = Rect.fromLTWH(
        _inset, _inset, size.width - 2 * _inset, size.height - 2 * _inset);
    final rrect = RRect.fromRectAndRadius(rect, _corner);
    canvas.drawRRect(rrect, containerPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  /// Whether the container holds any liquid at [progress].
  static bool _hasLiquid(Size size, double progress) =>
      _innerHeight(size) * progress > 0;

  /// The filled part of the container for [progress].
  static Rect _liquidRect(Size size, double progress) {
    final liquidHeight = _innerHeight(size) * progress;
    final liquidTop = size.height - _inset - liquidHeight;
    return Rect.fromLTWH(
        _inset, liquidTop, size.width - 2 * _inset, liquidHeight);
  }

  void _drawLiquidProgress(Canvas canvas, Size size, double progress) {
    if (!_hasLiquid(size, progress)) return;
    final liquid = _liquidRect(size, progress);
    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        palette.lived,
        palette.lived.withValues(alpha: _gradientTopAlpha),
      ],
    );
    final paint = Paint()..shader = gradient.createShader(liquid);
    canvas.drawRRect(RRect.fromRectAndRadius(liquid, _corner), paint);
  }

  void _drawWaveAnimation(Canvas canvas, Size size, double progress) {
    if (!_hasLiquid(size, progress)) return;
    final liquid = _liquidRect(size, progress);
    final wavePaint = Paint()
      ..color = palette.lived.withValues(alpha: _waveAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_wavePath(size, liquid), wavePaint);
  }

  /// [liquid] with a sine wave as its surface, shifted by the animation.
  Path _wavePath(Size size, Rect liquid) {
    final right = size.width - _inset;
    final path = Path()..moveTo(_inset, liquid.top);
    for (double x = _inset; x <= right; x += _waveStep) {
      final phase = (x / _waveLength) + (animationValue * 4 * math.pi);
      path.lineTo(x, liquid.top + math.sin(phase) * _waveAmplitude);
    }
    return path
      ..lineTo(right, liquid.bottom)
      ..lineTo(_inset, liquid.bottom)
      ..close();
  }

  /// A tick and an age label every [_scaleStepYears] years.
  void _drawMilestoneMarkers(
    Canvas canvas,
    Size size,
    int lifespan,
    double progress,
  ) {
    final markerPaint = Paint()
      ..color = palette.milestone
      ..style = PaintingStyle.fill;
    final liquidTop = _levelY(size, progress);
    for (var age = _scaleStepYears; age <= lifespan; age += _scaleStepYears) {
      final y = _levelY(size, age / lifespan);
      canvas.drawRect(_scaleTick(size, y), markerPaint);
      _paintText(
        canvas,
        '$age',
        scaleLabelStyle(y, liquidTop),
        (painter) =>
            Offset(size.width - _labelRightOffset, y - painter.height / 2),
      );
    }
  }

  static Rect _scaleTick(Size size, double y) => Rect.fromLTWH(
        size.width - _tickRightOffset,
        y - _tickThickness / 2,
        _tickLength,
        _tickThickness,
      );

  /// The fill behind a scale label at [labelY]: lived below the liquid
  /// surface at [liquidTop], remaining above it.
  Color scaleLabelBackground(double labelY, double liquidTop) =>
      labelY >= liquidTop ? palette.lived : palette.remaining;

  /// A legible, haloed style for a scale label at [labelY].
  TextStyle scaleLabelStyle(double labelY, double liquidTop) =>
      scaleText.styleOn(
        scaleLabelBackground(labelY, liquidTop),
        fontSize: _scaleFontSize,
        fontWeight: FontWeight.w600,
      );

  /// A ring at the liquid surface labelled with [currentAge].
  void _drawProgressIndicator(
    Canvas canvas,
    Size size,
    double progress,
    int currentAge,
  ) {
    final center = Offset(size.width / 2, _levelY(size, progress));
    final fillPaint = Paint()
      ..color = indicatorFill
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = palette.now
      ..style = PaintingStyle.stroke
      ..strokeWidth = _indicatorBorderWidth;
    canvas.drawCircle(center, _indicatorRadius, fillPaint);
    canvas.drawCircle(center, _indicatorRadius, borderPaint);
    _paintText(
      canvas,
      '$currentAge',
      TextStyle(
        color: labelColor,
        fontSize: _indicatorFontSize,
        fontWeight: FontWeight.w600,
      ),
      (painter) => center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset Function(TextPainter painter) position,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position(painter));
    painter.dispose();
  }

  @override
  bool shouldRepaint(FriendLifespanPainter oldDelegate) {
    return oldDelegate.friend != friend ||
        oldDelegate.palette != palette ||
        oldDelegate.outline != outline ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.scaleText != scaleText ||
        oldDelegate.indicatorFill != indicatorFill ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.enableAnimation != enableAnimation;
  }
}
