import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/rendering.dart';
import 'package:memento_mori_life_in_weeks/life/coming_week_style.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';
import 'package:memento_mori_life_in_weeks/week_moment/year_block_layout.dart';

/// Colours of the year block: [lived], [remaining], the [coming] week's
/// style (the current week, in the block as on the grid) and [target] =
/// the colour a grid cell has in the grid layer the block morphs into.
class YearCellColors {
  const YearCellColors({
    required this.lived,
    required this.remaining,
    required this.coming,
    required this.target,
  });

  final Color lived;
  final Color remaining;
  final ComingWeekStyle coming;
  final Color Function(int gridCell) target;
}

/// Where the grid cells are on screen: their rect and corner radius.
class GridCellPlacement {
  const GridCellPlacement({required this.rectOf, required this.radius});

  final Rect Function(int gridCell) rectOf;
  final double radius;
}

/// One cell of the year as painted: rect, corner radius and colour; the
/// coming week carries its [coming] style instead (frame and ring scale
/// with the rect while it morphs).
@immutable
class YearCellPaint {
  const YearCellPaint(this.rect, this.radius, this.color, {this.coming});

  final Rect rect;
  final double radius;
  final Color color;
  final ComingWeekStyle? coming;
}

/// The cells of the year of life between the block and the grid. Pure.
class YearCells {
  const YearCells({
    required this.year,
    required this.block,
    required this.colors,
    required this.grid,
  });

  final YearMoment year;
  final YearBlockLayout block;
  final YearCellColors colors;
  final GridCellPlacement grid;

  /// Spread of the fill stagger across the just-passed weeks.
  static const double fillSpread = 0.5;

  /// All cells at block fill [fill] and morph progress [morph] (0 = in the
  /// block, 1 = at the grid places).
  List<YearCellPaint> at({required double fill, required double morph}) => [
    for (var i = 0; i < year.length; i++) _cell(i, fill, morph),
  ];

  YearCellPaint _cell(int index, double fill, double morph) {
    final cell = year.yearStart + index;
    final p = morphProgress(index, morph, year.length);
    final rect = morphRect(block.cellRect(index), grid.rectOf(cell), p);
    final radius = lerpDouble(block.radius, grid.radius, p)!;
    if (cell == year.nowCell) {
      return YearCellPaint(rect, radius, colors.coming.fill,
          coming: colors.coming);
    }
    return YearCellPaint(
      rect,
      radius,
      Color.lerp(blockColorOf(cell, fill), colors.target(cell), p)!,
    );
  }

  /// The colour of grid [cell] in the block at fill progress [fill].
  Color blockColorOf(int cell, double fill) {
    if (cell < year.passedFrom) return colors.lived;
    if (cell < year.passedTo) {
      return Color.lerp(colors.remaining, colors.lived, _fillOf(cell, fill))!;
    }
    if (cell == year.nowCell) return colors.coming.fill;
    return colors.remaining;
  }

  double _fillOf(int cell, double fill) => morphProgress(
    cell - year.passedFrom,
    fill.clamp(0.0, 1.0),
    year.passedCount,
    spread: fillSpread,
    curve: Curves.easeOutCubic,
  );
}

/// Paints [cells] with [opacity]; cheap enough to repaint every frame.
class YearCellsPainter extends CustomPainter {
  YearCellsPainter({required this.cells, this.opacity = 1});

  final List<YearCellPaint> cells;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final cell in cells) {
      final coming = cell.coming;
      if (coming != null) {
        coming.paint(canvas, cell.rect, cell.radius, opacity: opacity);
        continue;
      }
      paint.color = cell.color.withValues(alpha: cell.color.a * opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cell.rect, Radius.circular(cell.radius)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(YearCellsPainter old) =>
      old.opacity != opacity || !_sameCells(old.cells);

  bool _sameCells(List<YearCellPaint> other) {
    if (other.length != cells.length) return false;
    for (var i = 0; i < cells.length; i++) {
      final a = cells[i];
      final b = other[i];
      if (a.rect != b.rect ||
          a.radius != b.radius ||
          a.color != b.color ||
          a.coming != b.coming) {
        return false;
      }
    }
    return true;
  }
}
