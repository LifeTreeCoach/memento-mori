import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/coming_week_style.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_view.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';
import 'package:memento_mori_life_in_weeks/week_moment/moment_camera.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/next_week_glow.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_frames.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_grid_layers.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_mix.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_pose.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/year_cells_painter.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';
import 'package:memento_mori_life_in_weeks/week_moment/year_block_layout.dart';

/// The visual stage of the weekly moment (no texts, no buttons): the year
/// of life as a 4x13 block, then one life grid seen through a camera that
/// moves from the year over the phase to the whole life and back to now.
///
/// It only renders [pose]; the screen drives it. The two grid layers are
/// painted once per size and theme and only transformed and faded per
/// frame. Hidden from semantics (the screen labels it).
class WeekMomentStage extends StatefulWidget {
  const WeekMomentStage({super.key, required this.story, required this.pose});

  final WeekMomentStory story;
  final StagePose pose;

  static const double _blockPadding = 24;

  /// The block never grows wider than this (about 28 dp cells).
  static const double maxBlockWidth = 13 * 34;

  /// Share of the stage height the year block may use (from the top).
  static const double blockHeightShare = 0.55;

  /// Where the year block sits in a stage of [size]: the upper part.
  static Rect blockAreaOf(Size size) {
    const pad = _blockPadding;
    final width = math.max(0.0, math.min(size.width - 2 * pad, maxBlockWidth));
    final height = math.max(0.0, size.height * blockHeightShare - pad);
    return Rect.fromLTWH((size.width - width) / 2, pad, width, height);
  }

  @override
  State<WeekMomentStage> createState() => _WeekMomentStageState();
}

class _WeekMomentStageState extends State<WeekMomentStage> {
  StageGridLayers? _layers;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, box) => _stage(context, box.biggest),
        ),
      ),
    );
  }

  Widget _stage(BuildContext context, Size size) {
    if (size.isEmpty || !size.isFinite) return const SizedBox.shrink();
    final geometry = _geometry(context, size.width);
    final layers = _layersFor(context, geometry);
    final scene = _Scene(
      geometry: geometry,
      camera: StageFrames(geometry, widget.story).cameraFor(widget.pose, size),
      mix: StageMix.of(widget.pose),
    );
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        _gridLayer(
          const ValueKey('phase_layer'),
          scene,
          layers.phase,
          scene.mix.phaseLayer,
        ),
        _gridLayer(
          const ValueKey('life_layer'),
          scene,
          layers.life,
          scene.mix.lifeLayer,
        ),
        // Below the coming week, so its halo never blurs the cell.
        if (widget.pose.pulse) _comingHalo(context, scene),
        if (scene.mix.gridOpacity > 0) _comingWeek(context, scene),
        if (scene.mix.blockOpacity > 0)
          _yearBlock(context, scene, layers, size),
      ],
    );
  }

  LifeGridGeometry _geometry(BuildContext context, double width) =>
      LifeGridGeometry(
        mode: LifeMode.weeks,
        totalCells: widget.story.worldCells,
        maxWidth: width,
        gutterWidth: LifeGridView.gutterWidthFor(context),
      );

  StageGridLayers _layersFor(BuildContext context, LifeGridGeometry geometry) {
    final style = _baseStyle(context);
    final phaseColors = PhaseColors.of(context);
    final cached = _layers;
    final reusable =
        cached != null &&
        cached.matches(
          geometry: geometry,
          story: widget.story,
          style: style,
          phaseColors: phaseColors,
        );
    if (reusable) return cached;
    return _layers = StageGridLayers(
      geometry: geometry,
      story: widget.story,
      style: style,
      phaseColors: phaseColors,
    );
  }

  static LifeGridStyle _baseStyle(BuildContext context) {
    final palette = LifePalette.of(context);
    return LifeGridStyle(
      lived: palette.lived,
      remaining: palette.remaining,
      milestone: palette.milestone,
      label: LifeGridView.labelStyleFor(context, LifeMode.weeks),
    );
  }

  /// One cached grid layer: faded and moved, never repainted per frame.
  Widget _gridLayer(
    Key key,
    _Scene scene,
    LifeGridPainter painter,
    double opacity,
  ) {
    final size = scene.geometry.size;
    return Positioned(
      key: key,
      left: 0,
      top: 0,
      width: size.width,
      height: size.height,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform(
          transform: scene.camera.matrix,
          child: RepaintBoundary(
            child: CustomPaint(size: size, isComplex: true, painter: painter),
          ),
        ),
      ),
    );
  }

  /// The coming week on the grid in its style (light fill, ink frame,
  /// gold ring), the grid's only emphasis.
  Widget _comingWeek(BuildContext context, _Scene scene) {
    final cell = scene.screenCell(widget.story.nowCell);
    final outset = ComingWeekStyle.ringWidthOf(cell.width);
    return Positioned.fromRect(
      key: const ValueKey('week_moment_coming_week'),
      rect: cell.inflate(outset),
      child: CustomPaint(
        painter: ComingWeekPainter(
          style: ComingWeekStyle.of(context),
          radius: scene.screenRadius,
          inset: outset,
          opacity: scene.mix.gridOpacity,
        ),
      ),
    );
  }

  /// The coming week breathes in a soft halo of its ring gold.
  Widget _comingHalo(BuildContext context, _Scene scene) {
    final cell = StageFrames(scene.geometry, widget.story).comingCell;
    return NextWeekGlow(
      key: const ValueKey('week_moment_next_pulse'),
      cell: scene.screenCell(cell),
      radius: scene.screenRadius,
      color: ComingWeekStyle.of(context).ring,
    );
  }

  Widget _yearBlock(
    BuildContext context,
    _Scene scene,
    StageGridLayers layers,
    Size size,
  ) {
    final cells = _yearCells(context, scene, layers, size);
    final morph = scene.mix.morph ?? 0;
    return Positioned.fill(
      key: const ValueKey('week_moment_year_block'),
      child: CustomPaint(
        painter: YearCellsPainter(
          cells: cells.at(fill: widget.pose.fill, morph: morph),
          opacity: scene.mix.blockOpacity,
        ),
      ),
    );
  }

  YearCells _yearCells(
    BuildContext context,
    _Scene scene,
    StageGridLayers layers,
    Size size,
  ) {
    final year = widget.story.year;
    final palette = LifePalette.of(context);
    final target = layers.targetOf(widget.pose);
    return YearCells(
      year: year,
      block: YearBlockLayout(
        WeekMomentStage.blockAreaOf(size),
        length: year.length,
      ),
      colors: YearCellColors(
        lived: palette.lived,
        remaining: palette.remaining,
        coming: ComingWeekStyle.of(context),
        target: (cell) => StageGridLayers.colorOf(target, cell),
      ),
      grid: GridCellPlacement(
        rectOf: scene.screenCell,
        radius: scene.screenRadius,
      ),
    );
  }
}

/// The stage's world and camera for one frame.
class _Scene {
  const _Scene({
    required this.geometry,
    required this.camera,
    required this.mix,
  });

  final LifeGridGeometry geometry;
  final CameraFit camera;
  final StageMix mix;

  /// Grid [cell] in stage coordinates.
  Rect screenCell(int cell) => camera.toScreen(geometry.cellRect(cell));

  /// Corner radius of a grid cell in stage coordinates.
  double get screenRadius => geometry.cellRadius * camera.scale;
}
