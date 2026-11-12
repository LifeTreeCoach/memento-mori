import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// The year of life as a block of square cells: 4 rows of 13 (like the
/// seasons); a 53rd cell starts a 5th row. Centred in [area].
class YearBlockLayout {
  YearBlockLayout(
    this.area, {
    required this.length,
    this.columns = 13,
    this.gapRatio = 0.18,
  }) : assert(length > 0 && columns > 0),
       pitch = _pitchFor(
         area.size,
         (length / columns).ceil(),
         columns,
         gapRatio,
       );

  final Rect area;
  final int length;
  final int columns;

  /// Gap between cells as a share of [pitch].
  final double gapRatio;

  /// Distance between the origins of two neighbouring cells.
  final double pitch;

  static double _pitchFor(Size area, int rows, int columns, double gapRatio) {
    final byWidth = math.max(0.0, area.width) / (columns - gapRatio);
    final byHeight = math.max(0.0, area.height) / (rows - gapRatio);
    return math.min(byWidth, byHeight);
  }

  int get rows => (length / columns).ceil();

  double get cellSize => pitch * (1 - gapRatio);

  double get gap => pitch - cellSize;

  /// Corner radius, like the life grid's cells.
  double get radius => cellSize * 0.2;

  Size get blockSize => Size(columns * pitch - gap, rows * pitch - gap);

  Offset get _origin =>
      area.center - Offset(blockSize.width / 2, blockSize.height / 2);

  Rect cellRect(int index) {
    final row = index ~/ columns;
    final col = index % columns;
    return Rect.fromLTWH(
      _origin.dx + col * pitch,
      _origin.dy + row * pitch,
      cellSize,
      cellSize,
    );
  }
}

/// Staggered, eased morph progress of cell [index] at overall progress [t]:
/// cell 0 starts first, the last starts at [spread], all reach 1 at t = 1.
double morphProgress(
  int index,
  double t,
  int length, {
  double spread = 0.35,
  Curve curve = Curves.easeInOutCubic,
}) {
  final share = length > 1 ? index / (length - 1) : 0.0;
  final start = spread * share;
  final local = ((t - start) / (1 - spread)).clamp(0.0, 1.0);
  return curve.transform(local);
}

/// The rect of a morphing cell between [from] (p = 0) and [to] (p = 1).
Rect morphRect(Rect from, Rect to, double p) => Rect.lerp(from, to, p)!;
