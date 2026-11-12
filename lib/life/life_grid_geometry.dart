import 'dart:math' as math;
import 'dart:ui';

import 'package:memento_mori_life_in_weeks/life/life_mode.dart';

/// Pure layout maths of the life grid: square cells, a left gutter for
/// decade labels, and the inverse mapping from a position to a cell.
class LifeGridGeometry {
  LifeGridGeometry({
    required this.mode,
    required this.totalCells,
    required double maxWidth,
    this.gutterWidth = 24,
  }) : pitch = _pitchFor(mode, maxWidth - gutterWidth);

  final LifeMode mode;
  final int totalCells;
  final double gutterWidth;

  /// Distance between the origins of two neighbouring cells.
  final double pitch;

  static const Map<LifeMode, double> _maxPitch = {
    LifeMode.weeks: 14,
    LifeMode.months: 18,
    LifeMode.years: 40,
  };

  static const Map<LifeMode, double> _gapRatio = {
    LifeMode.weeks: 0.22,
    LifeMode.months: 0.18,
    LifeMode.years: 0.14,
  };

  static double _pitchFor(LifeMode mode, double gridWidth) {
    final fitted = math.max(0.0, gridWidth) / mode.columns;
    return math.min(fitted, _maxPitch[mode]!);
  }

  int get columns => mode.columns;

  int get rows => (totalCells / columns).ceil();

  double get cellSize => pitch * (1 - _gapRatio[mode]!);

  double get gap => pitch - cellSize;

  double get cellRadius => cellSize * 0.2;

  Size get size => Size(gutterWidth + columns * pitch - gap, rows * pitch - gap);

  /// Grid rows that start a new decade of life (row 0 excluded).
  int get rowsPerDecade => 10 ~/ mode.yearsPerRow;

  /// Age in years at the start of [row].
  int ageAtRow(int row) => row * mode.yearsPerRow;

  /// Whether [row] gets a decade label in the gutter.
  bool isLabelledRow(int row) => row % rowsPerDecade == 0;

  Rect cellRect(int index) {
    final row = index ~/ columns;
    final col = index % columns;
    return Rect.fromLTWH(
      gutterWidth + col * pitch,
      row * pitch,
      cellSize,
      cellSize,
    );
  }

  /// Index of the cell under [position] (gaps belong to the preceding
  /// cell), or null outside the grid.
  int? indexAt(Offset position) {
    final x = position.dx - gutterWidth;
    final y = position.dy;
    if (x < 0 || y < 0 || pitch <= 0) return null;
    final col = (x / pitch).floor();
    final row = (y / pitch).floor();
    if (col >= columns || row >= rows) return null;
    final index = row * columns + col;
    return index < totalCells ? index : null;
  }
}
