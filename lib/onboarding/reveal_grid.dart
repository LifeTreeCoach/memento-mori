import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_view.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/now_cell_pulse.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// The weeks grid sized to fit its box in both directions, filled up to
/// [progress] × [livedCells]. Once [landed], the current week pulses.
class RevealGrid extends StatelessWidget {
  const RevealGrid({
    super.key,
    required this.progress,
    required this.totalCells,
    required this.livedCells,
    required this.landed,
    required this.semanticsLabel,
  });

  final Animation<double> progress;
  final int totalCells;
  final int livedCells;
  final bool landed;
  final String semanticsLabel;

  static const LifeMode _mode = LifeMode.weeks;

  @override
  Widget build(BuildContext context) {
    final gutter = LifeGridView.gutterWidthFor(context);
    final labelStyle = LifeGridView.labelStyleFor(context, _mode);
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = LifeGridGeometry(
          mode: _mode,
          totalCells: totalCells,
          maxWidth: _fittingWidth(constraints, gutter),
          gutterWidth: gutter,
        );
        return Semantics(
          label: semanticsLabel,
          image: true,
          child: ExcludeSemantics(
            child: Center(
              child: SizedBox.fromSize(
                size: geometry.size,
                child: _layers(context, geometry, labelStyle),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Width at which the grid's height also fits [constraints].
  double _fittingWidth(BoxConstraints constraints, double gutter) {
    final rows = (totalCells / _mode.columns).ceil();
    final pitchForHeight = constraints.maxHeight / rows;
    final widthForHeight = gutter + _mode.columns * pitchForHeight;
    return math.min(constraints.maxWidth, widthForHeight);
  }

  Widget _layers(
    BuildContext context,
    LifeGridGeometry geometry,
    TextStyle labelStyle,
  ) {
    final palette = LifePalette.of(context);
    final style = LifeGridStyle(
      lived: palette.lived,
      remaining: palette.remaining,
      milestone: palette.milestone,
      label: labelStyle,
    );
    final showNow = landed && livedCells < totalCells;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) => CustomPaint(
                painter: LifeGridPainter(
                  geometry: geometry,
                  livedCells: (progress.value * livedCells).round(),
                  style: style,
                  paintCurrentCell: !showNow,
                ),
              ),
            ),
          ),
        ),
        if (showNow)
          NowCellPulse(
            cell: geometry.cellRect(livedCells),
            radius: geometry.cellRadius,
            color: palette.now,
          ),
      ],
    );
  }
}
