/// The order and timing of the weekly moment's acts, and the pure reducer
/// that moves through them (taps, skip, timers). No Flutter, no clock: the
/// screen feeds events in and renders the state it gets back.
library;

import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';

/// One act of the weekly moment, in the order they are shown. The final
/// act [next] holds the two [ClosingStep]s.
enum WeekMomentAct { week, phase, life, next }

/// The two steps of the final act, one after the other: close the week
/// that passed (what was beautiful), then plan the next one (what counts).
/// Only the buttons move between them, never a tap on the stage or a timer.
enum ClosingStep {
  close,
  plan;

  /// 1-based number of the step ("1 of 2").
  int get number => index + 1;

  /// Number of steps.
  static int get count => values.length;
}

/// The acts to show: the phase act only when a phase is current.
List<WeekMomentAct> actsFor({required bool hasPhase}) => [
  WeekMomentAct.week,
  if (hasPhase) WeekMomentAct.phase,
  WeekMomentAct.life,
  WeekMomentAct.next,
];

/// The acts for [WeekMomentStory]s.
extension WeekMomentStoryActs on WeekMomentStory {
  /// The acts this story tells (the phase act only with a current phase).
  List<WeekMomentAct> get acts => actsFor(hasPhase: phase != null);
}

/// How long each act enters (zoom, fill) and then holds before the next one.
class WeekMomentTiming {
  const WeekMomentTiming();

  /// How long [act] takes to enter.
  Duration enter(WeekMomentAct act) => switch (act) {
    WeekMomentAct.week => const Duration(milliseconds: 900),
    WeekMomentAct.phase => const Duration(milliseconds: 2000),
    WeekMomentAct.life => const Duration(milliseconds: 1800),
    WeekMomentAct.next => const Duration(milliseconds: 1400),
  };

  /// How long [act] holds once entered; null for the final act, which
  /// stays until the user leaves.
  Duration? hold(WeekMomentAct act) => switch (act) {
    WeekMomentAct.week => const Duration(milliseconds: 3600),
    WeekMomentAct.phase => const Duration(milliseconds: 3000),
    WeekMomentAct.life => const Duration(milliseconds: 3400),
    WeekMomentAct.next => null,
  };

  /// Time from the start until the last of [acts] has entered.
  Duration runTime(List<WeekMomentAct> acts) =>
      acts.fold(Duration.zero, (sum, act) => sum + _span(act, acts));

  Duration _span(WeekMomentAct act, List<WeekMomentAct> acts) {
    final isLast = act == acts.last;
    return isLast ? enter(act) : enter(act) + (hold(act) ?? Duration.zero);
  }
}

/// Whether an act is still entering or has landed and holds.
enum MomentPhase { entering, holding }

/// What happens to the moment: an entry animation finished, a hold timer
/// ran out, the user tapped the stage or pressed "Skip".
enum MomentEvent { entered, holdElapsed, tap, skip }

/// Where the moment is: which act, and whether it enters or holds.
class MomentState {
  const MomentState(this.act, this.phase, {required this.isFinal});

  /// The first act, entering.
  factory MomentState.initial(List<WeekMomentAct> acts) =>
      _stateAt(0, MomentPhase.entering, acts);

  final WeekMomentAct act;
  final MomentPhase phase;

  /// Whether [act] is the last act.
  final bool isFinal;

  @override
  bool operator ==(Object other) =>
      other is MomentState &&
      other.act == act &&
      other.phase == phase &&
      other.isFinal == isFinal;

  @override
  int get hashCode => Object.hash(act, phase, isFinal);

  @override
  String toString() => 'MomentState($act, $phase, final: $isFinal)';
}

/// The state after [event] in [state], moving through [acts].
MomentState reduce(
  MomentState state,
  MomentEvent event,
  List<WeekMomentAct> acts,
) {
  final index = acts.indexOf(state.act);
  return switch ((event, state.phase)) {
    (MomentEvent.skip, _) => _skipped(state, acts),
    (MomentEvent.entered, MomentPhase.entering) ||
    (
      MomentEvent.tap,
      MomentPhase.entering,
    ) => _stateAt(index, MomentPhase.holding, acts),
    (MomentEvent.tap, MomentPhase.holding) ||
    (
      MomentEvent.holdElapsed,
      MomentPhase.holding,
    ) => _advanced(state, index, acts),
    _ => state,
  };
}

MomentState _skipped(MomentState state, List<WeekMomentAct> acts) {
  if (state.isFinal) return state;
  return _stateAt(acts.length - 1, MomentPhase.holding, acts);
}

MomentState _advanced(MomentState state, int index, List<WeekMomentAct> acts) {
  if (state.isFinal) return state;
  return _stateAt(index + 1, MomentPhase.entering, acts);
}

MomentState _stateAt(int index, MomentPhase phase, List<WeekMomentAct> acts) =>
    MomentState(acts[index], phase, isFinal: index == acts.length - 1);
