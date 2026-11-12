import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/coming_week_style.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/moment_marks.dart';
import 'package:memento_mori_life_in_weeks/life/now_cell_pulse.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/zoomable_area.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// The square-cell life grid: static cells in one repaint boundary, the
/// breathing current cell on top, zoomable, with tap-to-inspect. Cells
/// holding a Compass moment ([momentCells]) get a dot in a separate layer.
/// With [phaseRuns] the cells take the life phase colours. The current
/// cell (the coming week) is always drawn in the [ComingWeekStyle] - light
/// fill, ink frame, gold ring - so it is the only emphasis of the grid.
class LifeGridView extends StatelessWidget {
  const LifeGridView({
    super.key,
    required this.mode,
    required this.totalCells,
    required this.livedCells,
    required this.semanticsLabel,
    required this.onCellTap,
    this.showMilestones = true,
    this.showSeasons = false,
    this.onZoomChanged,
    this.momentCells = const {},
    this.phaseRuns = const [],
  });

  final LifeMode mode;
  final int totalCells;
  final int livedCells;
  final String semanticsLabel;
  final ValueChanged<int> onCellTap;
  final bool showMilestones;
  final bool showSeasons;
  final ValueChanged<bool>? onZoomChanged;

  /// Indices of the cells marked with a moment dot (empty: no marks).
  final Set<int> momentCells;

  /// Life phase runs to colour (empty: no phases).
  final List<PhaseCellRun> phaseRuns;

  static const double _baseGutter = 22;

  @override
  Widget build(BuildContext context) {
    final labelStyle = labelStyleFor(context, mode);
    return LayoutBuilder(builder: (context, constraints) {
      final geometry = LifeGridGeometry(
        mode: mode,
        totalCells: totalCells,
        maxWidth: constraints.maxWidth,
        gutterWidth: gutterWidthFor(context),
      );
      return Semantics(
        label: semanticsLabel,
        image: true,
        child: ExcludeSemantics(
          child: Center(child: _zoomableGrid(context, geometry, labelStyle)),
        ),
      );
    });
  }

  Widget _zoomableGrid(
    BuildContext context,
    LifeGridGeometry geometry,
    TextStyle labelStyle,
  ) {
    final palette = LifePalette.of(context);
    return SizedBox.fromSize(
      size: geometry.size,
      child: ZoomableArea(
        onZoomChanged: onZoomChanged,
        onTap: (position) => _handleTap(geometry, position),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
                child: _staticCells(context, geometry, palette, labelStyle)),
            if (livedCells < totalCells) _comingWeek(context, geometry),
            if (momentCells.isNotEmpty)
              Positioned.fill(
                child: _momentMarks(
                    geometry, palette, Theme.of(context).colorScheme.surface),
              ),
          ],
        ),
      ),
    );
  }

  /// The breathing coming week, in its style; only the halo breathes.
  Widget _comingWeek(BuildContext context, LifeGridGeometry geometry) {
    final style = ComingWeekStyle.of(context);
    return NowCellPulse(
      cell: geometry.cellRect(livedCells),
      radius: geometry.cellRadius,
      color: style.ring,
      comingWeek: style,
    );
  }

  Widget _staticCells(
    BuildContext context,
    LifeGridGeometry geometry,
    LifePalette palette,
    TextStyle labelStyle,
  ) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: LifeGridPainter(
          geometry: geometry,
          livedCells: livedCells,
          phaseRuns: phaseRuns,
          style: LifeGridStyle(
            lived: palette.lived,
            remaining: palette.remaining,
            milestone: palette.milestone,
            label: labelStyle,
            showMilestones: showMilestones,
            showSeasons: showSeasons,
            phaseColors: phaseRuns.isEmpty ? null : PhaseColors.of(context),
          ),
        ),
      ),
    );
  }

  Widget _momentMarks(
      LifeGridGeometry geometry, LifePalette palette, Color surface) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: MomentMarksPainter(
            geometry: geometry,
            cells: momentCells,
            color: palette.moment,
            haloColor: surface,
          ),
        ),
      ),
    );
  }

  void _handleTap(LifeGridGeometry geometry, Offset position) {
    final index = geometry.indexAt(position);
    if (index != null) onCellTap(index);
  }

  /// Decade label style of the grid gutter, scaled with the text size.
  static TextStyle labelStyleFor(BuildContext context, LifeMode mode) {
    final theme = Theme.of(context);
    final scaled = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4);
    return theme.textTheme.labelSmall!.copyWith(
      fontSize: scaled.scale(mode == LifeMode.years ? 11 : 9),
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1,
    );
  }

  /// Gutter width for the decade labels, growing with the text size.
  static double gutterWidthFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4);
    return math.max(_baseGutter, scale.scale(_baseGutter));
  }
}
