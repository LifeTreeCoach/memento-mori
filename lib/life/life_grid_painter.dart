import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/phase_slot_colors.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// Colours and options of the static grid layer.
@immutable
class LifeGridStyle {
  const LifeGridStyle({
    required this.lived,
    required this.remaining,
    required this.milestone,
    required this.label,
    this.showMilestones = true,
    this.showSeasons = false,
    this.phaseColors,
  });

  final Color lived;
  final Color remaining;
  final Color milestone;
  final TextStyle label;
  final bool showMilestones;
  final bool showSeasons;

  /// Colours of life phase runs; null paints no phases.
  final PhaseColors? phaseColors;

  @override
  bool operator ==(Object other) =>
      other is LifeGridStyle &&
      other.lived == lived &&
      other.remaining == remaining &&
      other.milestone == milestone &&
      other.label == label &&
      other.showMilestones == showMilestones &&
      other.showSeasons == showSeasons &&
      other.phaseColors == phaseColors;

  @override
  int get hashCode => Object.hash(lived, remaining, milestone, label,
      showMilestones, showSeasons, phaseColors);
}

/// What a grid cell is filled with.
enum CellFill { lived, remaining, phaseEarlier, phaseCurrent, phasePlanned }

/// The colour slot of a cell: its [fill] and an [index] (the season 0..3
/// of a lived cell with seasons on, the earlier-phase index of an earlier
/// phase cell, 0 otherwise). Cells of one slot share one path.
@immutable
class CellColorSlot {
  const CellColorSlot(this.fill, [this.index = 0]);

  final CellFill fill;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is CellColorSlot && other.fill == fill && other.index == index;

  @override
  int get hashCode => Object.hash(fill, index);

  @override
  String toString() => 'CellColorSlot(${fill.name}, $index)';
}

/// Paints all cells except the current one (drawn by an animated overlay)
/// with one path per colour, plus decade labels and milestone lines.
/// Planned cells are filled with the pale [PhaseColors.plannedTint].
class LifeGridPainter extends CustomPainter {
  LifeGridPainter({
    required this.geometry,
    required this.livedCells,
    required this.style,
    this.paintCurrentCell = false,
    this.phaseRuns = const [],
  });

  final LifeGridGeometry geometry;

  /// Cells before this index are lived; this index is the current cell.
  final int livedCells;
  final LifeGridStyle style;

  /// Paints the current cell as a remaining cell instead of leaving it to
  /// an overlay (used while the onboarding reveal is still filling).
  final bool paintCurrentCell;

  /// Life phase runs coloured with [LifeGridStyle.phaseColors]; cells
  /// outside them keep the lived/remaining colours.
  final List<PhaseCellRun> phaseRuns;

  bool get _showsPhases => style.phaseColors != null && phaseRuns.isNotEmpty;

  /// Lightness factors per quarter of a year (winter, spring, summer, autumn).
  static const List<double> _seasonLightness = [0.88, 1.12, 1.06, 0.94];

  @override
  void paint(Canvas canvas, Size size) {
    _paintCells(canvas);
    if (style.showMilestones) _paintMilestones(canvas);
    _paintLabels(canvas);
  }

  void _paintCells(Canvas canvas) {
    final livedPaths = List.generate(_seasons ? 4 : 1, (_) => Path());
    final remainingPath = Path();
    final phasePaths = <CellColorSlot, Path>{};
    final radius = Radius.circular(geometry.cellRadius);

    for (int i = 0; i < geometry.totalCells; i++) {
      if (i == livedCells && !paintCurrentCell) continue;
      final cell = RRect.fromRectAndRadius(geometry.cellRect(i), radius);
      final slot = cellColorSlot(i);
      switch (slot.fill) {
        case CellFill.remaining:
          remainingPath.addRRect(cell);
        case CellFill.lived:
          livedPaths[slot.index].addRRect(cell);
        case CellFill.phaseEarlier:
        case CellFill.phaseCurrent:
        case CellFill.phasePlanned:
          phasePaths.putIfAbsent(slot, Path.new).addRRect(cell);
      }
    }

    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawPath(remainingPath, paint..color = style.remaining);
    for (int s = 0; s < livedPaths.length; s++) {
      paint.color = _seasons ? _seasonColor(s) : style.lived;
      canvas.drawPath(livedPaths[s], paint);
    }
    for (final MapEntry(key: slot, value: path) in phasePaths.entries) {
      canvas.drawPath(path, paint..color = colorOfSlot(slot));
    }
  }

  bool get _seasons => style.showSeasons && geometry.mode != LifeMode.years;

  /// The colour slot of cell [index]: a phase slot inside a phase run
  /// (when phases are shown), lived (by season) before [livedCells],
  /// remaining otherwise. A run's slot wins over lived/remaining, so a
  /// planned run colours future cells.
  CellColorSlot cellColorSlot(int index) {
    final run = _showsPhases ? runAt(phaseRuns, index) : null;
    if (run != null) {
      return switch (run.kind) {
        PhaseSlotKind.earlier =>
          CellColorSlot(CellFill.phaseEarlier, run.earlierIndex),
        PhaseSlotKind.current => const CellColorSlot(CellFill.phaseCurrent),
        PhaseSlotKind.planned => const CellColorSlot(CellFill.phasePlanned),
      };
    }
    if (index >= livedCells) return const CellColorSlot(CellFill.remaining);
    return CellColorSlot(CellFill.lived, _seasons ? _seasonOf(index) : 0);
  }

  /// The fill painted for [slot]; planned cells take the pale tint.
  Color colorOfSlot(CellColorSlot slot) {
    final phases = style.phaseColors;
    return switch (slot.fill) {
      CellFill.remaining => style.remaining,
      CellFill.lived => _seasons ? _seasonColor(slot.index) : style.lived,
      CellFill.phaseEarlier =>
        phases!.forSlot(PhaseSlotKind.earlier, slot.index),
      CellFill.phaseCurrent => phases!.current,
      CellFill.phasePlanned => phases!.plannedTint,
    };
  }

  /// Quarter of the year a cell falls into; years mode keeps quartering
  /// the row (a decade) since one cell is a whole year.
  int _seasonOf(int index) {
    final mode = geometry.mode;
    final cycle =
        mode == LifeMode.years ? geometry.columns : mode.cellsPerYear;
    return (index % cycle) * 4 ~/ cycle;
  }

  Color _seasonColor(int season) {
    final hsl = HSLColor.fromColor(style.lived);
    final lightness = (hsl.lightness * _seasonLightness[season]).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  void _paintMilestones(Canvas canvas) {
    if (geometry.mode == LifeMode.years) return; // every row is a decade
    final paint = Paint()
      ..color = style.milestone.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    final left = geometry.gutterWidth;
    final right = geometry.size.width;
    for (int row = geometry.rowsPerDecade;
        row < geometry.rows;
        row += geometry.rowsPerDecade) {
      final y = row * geometry.pitch - geometry.gap / 2;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  void _paintLabels(Canvas canvas) {
    for (int row = 0; row < geometry.rows; row++) {
      if (!geometry.isLabelledRow(row)) continue;
      final painter = TextPainter(
        text: TextSpan(text: '${geometry.ageAtRow(row)}', style: style.label),
        textDirection: TextDirection.ltr,
      )..layout();
      final rowCenter = row * geometry.pitch + geometry.cellSize / 2;
      final x = geometry.gutterWidth - 6 - painter.width;
      painter.paint(canvas, Offset(x, rowCenter - painter.height / 2));
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(LifeGridPainter old) {
    return old.livedCells != livedCells ||
        old.paintCurrentCell != paintCurrentCell ||
        old.style != style ||
        !listEquals(old.phaseRuns, phaseRuns) ||
        old.geometry.mode != geometry.mode ||
        old.geometry.totalCells != geometry.totalCells ||
        old.geometry.pitch != geometry.pitch ||
        old.geometry.gutterWidth != geometry.gutterWidth;
  }
}
