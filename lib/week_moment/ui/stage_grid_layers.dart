import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_pose.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';

/// The two grid painters of the stage, built once per size and theme:
/// [phase] colours the current phase, [life] the phases of the whole life
/// (or none). Reusing the instances keeps their cached pictures.
class StageGridLayers {
  StageGridLayers({
    required this.geometry,
    required this.story,
    required this.style,
    required this.phaseColors,
  }) : phase = _painter(geometry, story, style, phaseColors, _phaseRuns(story)),
       life = _painter(geometry, story, style, phaseColors, story.life.runs);

  final LifeGridGeometry geometry;
  final WeekMomentStory story;

  /// Style without phase colours; each layer adds [phaseColors] if it
  /// has runs.
  final LifeGridStyle style;
  final PhaseColors phaseColors;

  final LifeGridPainter phase;
  final LifeGridPainter life;

  static List<PhaseCellRun> _phaseRuns(WeekMomentStory story) =>
      story.phase?.runs ?? const [];

  static LifeGridPainter _painter(
    LifeGridGeometry geometry,
    WeekMomentStory story,
    LifeGridStyle style,
    PhaseColors phaseColors,
    List<PhaseCellRun> runs,
  ) => LifeGridPainter(
    geometry: geometry,
    livedCells: story.nowCell,
    paintCurrentCell: true,
    phaseRuns: runs,
    style: runs.isEmpty ? style : _withPhases(style, phaseColors),
  );

  static LifeGridStyle _withPhases(LifeGridStyle style, PhaseColors colors) =>
      LifeGridStyle(
        lived: style.lived,
        remaining: style.remaining,
        milestone: style.milestone,
        label: style.label,
        showMilestones: style.showMilestones,
        showSeasons: style.showSeasons,
        phaseColors: colors,
      );

  /// Whether these layers were built for the same inputs.
  bool matches({
    required LifeGridGeometry geometry,
    required WeekMomentStory story,
    required LifeGridStyle style,
    required PhaseColors phaseColors,
  }) =>
      identical(story, this.story) &&
      style == this.style &&
      phaseColors == this.phaseColors &&
      _sameGeometry(geometry);

  bool _sameGeometry(LifeGridGeometry other) =>
      other.mode == geometry.mode &&
      other.totalCells == geometry.totalCells &&
      other.pitch == geometry.pitch &&
      other.gutterWidth == geometry.gutterWidth;

  /// The layer the year block morphs into (or out of) during [pose].
  LifeGridPainter targetOf(StagePose pose) {
    final gridAct = pose.from == WeekMomentAct.week ? pose.to : pose.from;
    return gridAct == WeekMomentAct.phase ? phase : life;
  }

  /// The colour [painter] gives grid [cell].
  static Color colorOf(LifeGridPainter painter, int cell) =>
      painter.colorOfSlot(painter.cellColorSlot(cell));
}
