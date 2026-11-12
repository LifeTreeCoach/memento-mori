import 'package:flutter/material.dart';

/// Colours of the [YearStripPainter] cells.
@immutable
class YearStripColors {
  const YearStripColors({
    required this.lived,
    required this.remaining,
    required this.now,
  });

  final Color lived;
  final Color remaining;
  final Color now;

  @override
  bool operator ==(Object other) =>
      other is YearStripColors &&
      other.lived == lived &&
      other.remaining == remaining &&
      other.now == now;

  @override
  int get hashCode => Object.hash(lived, remaining, now);
}

/// One year of life as [YearStripGeometry.cells] week squares in
/// [YearStripGeometry.rows] rows: [filled] lived weeks, then (when [nowIndex]
/// is set) the current week at [nowGlow] (0..1), the rest remaining.
class YearStripPainter extends CustomPainter {
  const YearStripPainter({
    required this.filled,
    required this.nowIndex,
    required this.nowGlow,
    required this.colors,
  });

  final int filled;
  final int? nowIndex;
  final double nowGlow;
  final YearStripColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = YearStripGeometry(size.width);
    for (var i = 0; i < YearStripGeometry.cells; i++) {
      final rect = geometry.cellRect(i);
      final radius = Radius.circular(geometry.cell * 0.25);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = _colorOf(i),
      );
    }
  }

  Color _colorOf(int index) {
    if (index == nowIndex) {
      return Color.lerp(colors.remaining, colors.now, 0.35 + 0.65 * nowGlow)!;
    }
    return index < filled ? colors.lived : colors.remaining;
  }

  @override
  bool shouldRepaint(YearStripPainter old) =>
      old.filled != filled ||
      old.nowIndex != nowIndex ||
      old.nowGlow != nowGlow ||
      old.colors != colors;
}

/// Cell size and positions of the strip for a given width: cells up to
/// [maxCell] dp with [gap] dp between them, left-aligned.
class YearStripGeometry {
  YearStripGeometry(double width)
    : cell = ((width - (perRow - 1) * gap) / perRow).clamp(2.0, maxCell);

  static const int cells = 52;
  static const int rows = 2;
  static const int perRow = cells ~/ rows;
  static const double gap = 3;
  static const double maxCell = 9;

  final double cell;

  double get height => rows * cell + (rows - 1) * gap;

  /// Height of the strip for [width].
  static double heightFor(double width) => YearStripGeometry(width).height;

  Rect cellRect(int index) {
    final row = index ~/ perRow;
    final column = index % perRow;
    return Rect.fromLTWH(column * (cell + gap), row * (cell + gap), cell, cell);
  }
}
