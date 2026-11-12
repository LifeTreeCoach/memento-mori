import 'dart:ui';

import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/week_moment/moment_camera.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_pose.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';

/// The camera frame of every act of a [story] in the world of [geometry],
/// and the camera for a [StagePose]. Pure.
class StageFrames {
  StageFrames(this.geometry, this.story);

  final LifeGridGeometry geometry;
  final WeekMomentStory story;

  late final Rect yearFrame = MomentFrames.year(
    geometry,
    story.year.yearStart,
    story.year.length,
  );

  /// The cell emphasised in the final act: the coming week, the first
  /// one not yet lived.
  int get comingCell => story.nowCell;

  /// The frame of [act] in a [viewport] (phase and next are zoomed-in
  /// windows in its aspect); the phase act without a phase shows the year.
  Rect frameOf(WeekMomentAct act, Size viewport) => switch (act) {
    WeekMomentAct.week => yearFrame,
    WeekMomentAct.phase => _phaseFrame(viewport),
    WeekMomentAct.life => MomentFrames.life(geometry),
    WeekMomentAct.next => MomentFrames.next(
      geometry,
      comingCell,
      viewport: viewport,
    ),
  };

  Rect _phaseFrame(Size viewport) {
    final phase = story.phase;
    if (phase == null) return yearFrame;
    return MomentFrames.phase(
      geometry,
      phase.from,
      phase.to,
      yearFrame,
      nowCell: story.nowCell,
      viewport: viewport,
    );
  }

  /// The camera of [pose] in a [viewport]: between the two acts' frames.
  CameraFit cameraFor(StagePose pose, Size viewport) {
    final frame = lerpFrame(
      frameOf(pose.from, viewport),
      frameOf(pose.to, viewport),
      pose.eased,
    );
    return CameraFit.fit(frame, viewport);
  }
}
