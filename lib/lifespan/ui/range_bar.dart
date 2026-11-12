import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Horizontal bar: a quiet track, the middle half (p25..p75) as a band and
/// the mean as a dot, with the three ages as labels.
class RangeBar extends StatelessWidget {
  const RangeBar({
    super.key,
    required this.p25,
    required this.mean,
    required this.p75,
  });

  final double p25;
  final double mean;
  final double p75;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LifePalette.of(context);
    final label = theme.textTheme.labelMedium!;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: RangeBarPainter(
            p25: p25,
            mean: mean,
            p75: p75,
            track: palette.remaining,
            band: palette.lived,
            marker: palette.now,
            markerRing: theme.colorScheme.surface,
            labelStyle: label.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            meanStyle: label.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class RangeBarPainter extends CustomPainter {
  RangeBarPainter({
    required this.p25,
    required this.mean,
    required this.p75,
    required this.track,
    required this.band,
    required this.marker,
    required this.markerRing,
    required this.labelStyle,
    required this.meanStyle,
  });

  final double p25;
  final double mean;
  final double p75;
  final Color track;
  final Color band;
  final Color marker;
  final Color markerRing;
  final TextStyle labelStyle;
  final TextStyle meanStyle;

  static const double _trackHeight = 6;
  static const double _bandHeight = 12;
  static const double _dotRadius = 7;

  /// The visible age range: a decade of margin around the band, on whole
  /// decades (e.g. 70..100 for 79..94).
  (double, double) get domain {
    final low = ((math.min(p25, mean) - 5) / 10).floor() * 10.0;
    final high = ((math.max(p75, mean) + 5) / 10).ceil() * 10.0;
    return (low, math.max(high, low + 10));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (low, high) = domain;
    double x(double age) =>
        _dotRadius +
        (age.clamp(low, high) - low) /
            (high - low) *
            (size.width - 2 * _dotRadius);
    final centerY = size.height / 2;

    final trackPaint = Paint()..color = track;
    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        centerY - _trackHeight / 2,
        size.width,
        centerY + _trackHeight / 2,
        const Radius.circular(_trackHeight / 2),
      ),
      trackPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        x(p25),
        centerY - _bandHeight / 2,
        x(p75),
        centerY + _bandHeight / 2,
        const Radius.circular(_bandHeight / 2),
      ),
      Paint()..color = band,
    );
    final meanCenter = Offset(x(mean), centerY);
    canvas.drawCircle(meanCenter, _dotRadius + 2, Paint()..color = markerRing);
    canvas.drawCircle(meanCenter, _dotRadius, Paint()..color = marker);

    _label(canvas, size, '${p25.round()}', x(p25), centerY + 12, labelStyle);
    _label(canvas, size, '${p75.round()}', x(p75), centerY + 12, labelStyle);
    _label(canvas, size, '${mean.round()}', meanCenter.dx, 0, meanStyle);
  }

  /// Draws [text] centred on [centerX], kept inside the canvas.
  void _label(
    Canvas canvas,
    Size size,
    String text,
    double centerX,
    double top,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final left = (centerX - painter.width / 2)
        .clamp(0.0, math.max(0.0, size.width - painter.width))
        .toDouble();
    painter.paint(canvas, Offset(left, top));
    painter.dispose();
  }

  @override
  bool shouldRepaint(RangeBarPainter old) =>
      old.p25 != p25 ||
      old.mean != mean ||
      old.p75 != p75 ||
      old.track != track ||
      old.band != band ||
      old.marker != marker ||
      old.markerRing != markerRing ||
      old.labelStyle != labelStyle ||
      old.meanStyle != meanStyle;
}
