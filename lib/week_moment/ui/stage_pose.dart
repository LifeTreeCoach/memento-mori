import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';

/// What the weekly moment's stage shows at one instant, driven by the
/// screen's controllers: a transition [from] one act [to] the next at
/// progress [t], the act-1 [fill] of the just-passed weeks and whether the
/// next week [pulse]s in the final act.
@immutable
class StagePose {
  const StagePose({
    required this.from,
    required this.to,
    this.t = 1,
    this.fill = 1,
    this.pulse = false,
  });

  /// Landed on [act] (no transition running).
  const StagePose.at(WeekMomentAct act, {this.fill = 1, this.pulse = false})
    : from = act,
      to = act,
      t = 1;

  final WeekMomentAct from;
  final WeekMomentAct to;

  /// Transition progress, 0 (= [from]) to 1 (= [to]).
  final double t;

  /// Act 1: how far the just-passed weeks have filled (0..1).
  final double fill;

  /// Final act: the next, still empty week glows.
  final bool pulse;

  /// Curve of the camera between two acts.
  static const Curve cameraCurve = Curves.easeInOutCubic;

  /// [t] clamped to 0..1.
  double get progress => t.clamp(0.0, 1.0);

  /// [progress] eased with [cameraCurve].
  double get eased => cameraCurve.transform(progress);

  @override
  bool operator ==(Object other) =>
      other is StagePose &&
      other.from == from &&
      other.to == to &&
      other.t == t &&
      other.fill == fill &&
      other.pulse == pulse;

  @override
  int get hashCode => Object.hash(from, to, t, fill, pulse);

  @override
  String toString() =>
      'StagePose(${from.name} -> ${to.name}, t: $t, fill: $fill, '
      'pulse: $pulse)';
}
