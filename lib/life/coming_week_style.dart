import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// How the coming week (the first week not yet lived, the grid's only
/// emphasis) is drawn on every weeks grid: a light [fill], a dark ink
/// [frame] inside the cell and a gold [ring] around it. The same inside
/// and outside a phase, on the Life tab and in the weekly moment.
@immutable
class ComingWeekStyle {
  const ComingWeekStyle({
    required this.fill,
    required this.frame,
    required this.ring,
  });

  /// The style of the ambient theme: surface fill, onSurface frame and
  /// the phase gold made readable on the surface.
  factory ComingWeekStyle.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ComingWeekStyle(
      fill: scheme.surface,
      frame: scheme.onSurface,
      ring: PhaseColors.of(context).comingRingOn(scheme.surface),
    );
  }

  final Color fill;
  final Color frame;
  final Color ring;

  /// Frame and ring widths as a share of the cell width.
  static const double frameShare = 0.12;
  static const double ringShare = 0.14;

  /// Thinnest frame and ring, so they read on tiny week cells.
  static const double minFrame = 1;
  static const double minRing = 1.5;

  /// Width of the ink frame inside a cell of [cellWidth].
  static double frameWidthOf(double cellWidth) =>
      math.max(minFrame, cellWidth * frameShare);

  /// Width of the gold ring around a cell of [cellWidth].
  static double ringWidthOf(double cellWidth) =>
      math.max(minRing, cellWidth * ringShare);

  /// The stroke of [width] inside [cell] (centred on the inset outline).
  static RRect innerStroke(Rect cell, double radius, double width) =>
      RRect.fromRectAndRadius(
        cell.deflate(width / 2),
        Radius.circular(math.max(0.0, radius - width / 2)),
      );

  /// The stroke of [width] just outside [cell].
  static RRect outerStroke(Rect cell, double radius, double width) =>
      RRect.fromRectAndRadius(
        cell.inflate(width / 2),
        Radius.circular(math.max(0.0, radius) + width / 2),
      );

  /// Paints the coming week into [cell] with corner [radius], all three
  /// layers faded by [opacity].
  void paint(Canvas canvas, Rect cell, double radius, {double opacity = 1}) {
    if (opacity <= 0) return;
    final ringWidth = ringWidthOf(cell.width);
    final frameWidth = frameWidthOf(cell.width);
    final rounded = RRect.fromRectAndRadius(
      cell,
      Radius.circular(math.max(0.0, radius)),
    );
    canvas
      ..drawRRect(rounded, Paint()..color = _faded(fill, opacity))
      ..drawRRect(
        innerStroke(cell, radius, frameWidth),
        _stroke(frame, frameWidth, opacity),
      )
      ..drawRRect(
        outerStroke(cell, radius, ringWidth),
        _stroke(ring, ringWidth, opacity),
      );
  }

  static Paint _stroke(Color color, double width, double opacity) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = _faded(color, opacity);

  static Color _faded(Color color, double opacity) =>
      color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0));

  @override
  bool operator ==(Object other) =>
      other is ComingWeekStyle &&
      other.fill == fill &&
      other.frame == frame &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(fill, frame, ring);
}

/// A static coming-week cell: [style] painted into the whole canvas.
class ComingWeekPainter extends CustomPainter {
  ComingWeekPainter({
    required this.style,
    required this.radius,
    this.inset = 0,
    this.opacity = 1,
  });

  final ComingWeekStyle style;
  final double radius;

  /// Space around the cell in the canvas (room for the ring and a halo).
  final double inset;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = (Offset.zero & size).deflate(inset);
    style.paint(canvas, cell, radius, opacity: opacity);
  }

  @override
  bool shouldRepaint(ComingWeekPainter old) =>
      old.style != style ||
      old.radius != radius ||
      old.inset != inset ||
      old.opacity != opacity;
}
