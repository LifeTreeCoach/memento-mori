import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';

/// Indices of the grid cells in [mode] that hold at least one of
/// [moments], for a life born on [birthDate]. Moments before birth or
/// beyond [totalCells] have no cell.
Set<int> momentCellIndices({
  required Iterable<Moment> moments,
  required LifeMode mode,
  required DateTime birthDate,
  required int totalCells,
}) {
  final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
  final cells = <int>{};
  for (final moment in moments) {
    if (moment.date.isBefore(birth)) continue;
    final calc = LifeCalculator(birthDate: birthDate, now: moment.date);
    final index = mode.livedCells(calc);
    if (index < totalCells) cells.add(index);
  }
  return cells;
}

/// Paints a small dot in the centre of every cell in [cells]. Lives in its
/// own layer above the static grid, so new moments never repaint the grid.
///
/// Week cells are tiny, so in weeks mode the dot is larger relative to the
/// cell, never smaller than [minWeekDotRadius], and sits on a thin halo of
/// [haloColor] (the surface colour) that sets it apart from the cell; a rim
/// of the cell stays visible around the halo.
class MomentMarksPainter extends CustomPainter {
  MomentMarksPainter({
    required this.geometry,
    required this.cells,
    required this.color,
    this.haloColor,
  });

  final LifeGridGeometry geometry;
  final Set<int> cells;
  final Color color;

  /// Ring behind each dot in weeks mode; null = no ring.
  final Color? haloColor;

  /// Dot radius as a share of the cell size (months, years).
  static const double dotRatio = 0.22;

  /// Dot radius as a share of the cell size in weeks mode.
  static const double weekDotRatio = 0.3;

  /// Smallest dot radius in weeks mode (logical pixels).
  static const double minWeekDotRadius = 1.5;

  /// Halo width as a share of the cell size, at least [minHaloWidth].
  static const double haloRatio = 0.08;
  static const double minHaloWidth = 0.5;

  /// The dot and its halo stay within this share of the cell's half size,
  /// so the cell's own colour still shows around them.
  static const double maxMarkRatio = 0.86;

  bool get _isWeeks => geometry.mode == LifeMode.weeks;

  double get _maxMarkRadius => geometry.cellSize / 2 * maxMarkRatio;

  double get haloWidth => _isWeeks && haloColor != null
      ? math.max(geometry.cellSize * haloRatio, minHaloWidth)
      : 0;

  double get dotRadius {
    final cell = geometry.cellSize;
    if (!_isWeeks) return cell * dotRatio;
    final wanted = math.max(cell * weekDotRatio, minWeekDotRadius);
    return math.max(0, math.min(wanted, _maxMarkRadius - haloWidth));
  }

  /// Outer radius of the mark (dot plus halo).
  double get markRadius => dotRadius + haloWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty) return;
    final dots = Path();
    final halos = Path();
    for (final index in cells) {
      final center = geometry.cellRect(index).center;
      dots.addOval(Rect.fromCircle(center: center, radius: dotRadius));
      halos.addOval(Rect.fromCircle(center: center, radius: markRadius));
    }
    final halo = haloColor;
    if (halo != null && haloWidth > 0) {
      canvas.drawPath(halos, Paint()..color = halo);
    }
    canvas.drawPath(dots, Paint()..color = color);
  }

  @override
  bool shouldRepaint(MomentMarksPainter old) {
    return old.color != color ||
        old.haloColor != haloColor ||
        !setEquals(old.cells, cells) ||
        old.geometry.mode != geometry.mode ||
        old.geometry.totalCells != geometry.totalCells ||
        old.geometry.pitch != geometry.pitch ||
        old.geometry.gutterWidth != geometry.gutterWidth;
  }
}
