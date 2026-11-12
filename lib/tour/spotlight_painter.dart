import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_geometry.dart';

/// Dims the screen with the scrim colour and leaves a rounded [hole]
/// with a thin ring around it.
class SpotlightPainter extends CustomPainter {
  const SpotlightPainter({
    required this.hole,
    required this.scrim,
    required this.ring,
    this.radius = TourGeometry.holeRadius,
  });

  /// Theme-derived painter: scrim at [scrimAlphaFor] and a primary ring.
  factory SpotlightPainter.themed(ColorScheme scheme, {required Rect? hole}) {
    return SpotlightPainter(
      hole: hole,
      scrim: scheme.scrim.withValues(alpha: scrimAlphaFor(scheme.brightness)),
      ring: scheme.primary,
    );
  }

  final Rect? hole;
  final Color scrim;
  final Color ring;
  final double radius;

  static const double ringWidth = 2;

  /// 0.62 in light mode, 0.72 in dark mode.
  static double scrimAlphaFor(Brightness brightness) =>
      brightness == Brightness.dark ? 0.72 : 0.62;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final hole = this.hole;
    if (hole == null) {
      canvas.drawRect(screen, Paint()..color = scrim);
      return;
    }
    final rounded = RRect.fromRectAndRadius(hole, Radius.circular(radius));
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screen)
      ..addRRect(rounded);
    canvas.drawPath(dim, Paint()..color = scrim);
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.scrim != scrim ||
      oldDelegate.ring != ring ||
      oldDelegate.radius != radius;
}
