import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_pose.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';

/// How strongly each layer of the stage shows for a [StagePose]: the two
/// grid layers (phase, life) and the act-1 year block. Pure.
@immutable
class StageMix {
  const StageMix({
    required this.phaseLayer,
    required this.lifeLayer,
    required this.morph,
  });

  factory StageMix.of(StagePose pose) {
    final from = _LayerWeights.of(pose.from);
    final to = _LayerWeights.of(pose.to);
    final p = _layerProgress(pose);
    return StageMix(
      phaseLayer: lerpDouble(from.phase, to.phase, p)!,
      lifeLayer: lerpDouble(from.life, to.life, p)!,
      morph: _morphOf(pose),
    );
  }

  /// Opacity of the grid layer coloured with the current phase.
  final double phaseLayer;

  /// Opacity of the grid layer of the whole life.
  final double lifeLayer;

  /// Year block: 0 = cells in the block, 1 = cells at their grid places;
  /// null when the block is not shown.
  final double? morph;

  /// The grid fades in over this share of a transition out of act 1.
  static const Interval gridIn = Interval(0.4, 1, curve: Curves.easeOut);

  /// The year block fades out over the end of its morph.
  static const Interval blockOut = Interval(0.85, 1);

  /// Opacity of the year block.
  double get blockOpacity {
    final m = morph;
    return m == null ? 0 : 1 - blockOut.transform(m);
  }

  /// Opacity of the grid as a whole (for marks drawn on it).
  double get gridOpacity => math.max(phaseLayer, lifeLayer);

  static double _layerProgress(StagePose pose) {
    final t = pose.progress;
    if (pose.from == pose.to) return 1;
    if (pose.from == WeekMomentAct.week) return gridIn.transform(t);
    if (pose.to == WeekMomentAct.week) return 1 - gridIn.transform(1 - t);
    return pose.eased;
  }

  static double? _morphOf(StagePose pose) {
    final fromWeek = pose.from == WeekMomentAct.week;
    final toWeek = pose.to == WeekMomentAct.week;
    if (fromWeek && toWeek) return 0;
    if (fromWeek) return pose.progress;
    if (toWeek) return 1 - pose.progress;
    return null;
  }
}

/// Target opacities of the grid layers in one act.
class _LayerWeights {
  const _LayerWeights(this.phase, this.life);

  final double phase;
  final double life;

  static _LayerWeights of(WeekMomentAct act) => switch (act) {
    WeekMomentAct.week => const _LayerWeights(0, 0),
    WeekMomentAct.phase => const _LayerWeights(1, 0),
    WeekMomentAct.life || WeekMomentAct.next => const _LayerWeights(0, 1),
  };
}
