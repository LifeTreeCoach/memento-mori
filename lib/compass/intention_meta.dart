/// Pure facts behind the quiet meta lines of intentions and the moments
/// they became: what kind an intention is, how much planned time its phase
/// has left, and in which year of its phase it was done.
library;

import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

/// What the meta line under an open intention tells.
class IntentionMeta {
  const IntentionMeta({
    this.kind,
    this.monthsLeft,
    this.weeksLeft,
    this.dueDate,
  });

  final IntentionKind? kind;

  /// Planned months left in the intention's phase (doTask in the current
  /// phase with a planned end only).
  final int? monthsLeft;

  /// Planned weeks left, the same way; used under a month.
  final int? weeksLeft;

  /// The appointment of an enjoy intention.
  final DateTime? dueDate;
}

/// The meta of [intention] on [today], with [current] the phase lived now.
IntentionMeta intentionMetaOf(
  Intention intention, {
  required PhaseSpan? current,
  required DateTime today,
}) {
  final kind = intention.kind;
  if (kind == IntentionKind.enjoy) {
    return IntentionMeta(kind: kind, dueDate: intention.dueDate);
  }
  final inCurrent =
      current != null && intention.phaseId == current.phase.id;
  if (kind != IntentionKind.doTask || !inCurrent) {
    return IntentionMeta(kind: kind);
  }
  return IntentionMeta(
    kind: kind,
    monthsLeft: plannedMonthsLeft(current, today),
    weeksLeft: plannedWeeksLeft(current, today),
  );
}

/// The phase a done intention belonged to and the year of that phase
/// (1 = its first year) in which it was done.
class PhaseYear {
  const PhaseYear(this.phase, this.year);

  final LifePhase phase;
  final int year;
}

/// The phase id of the intention [moment] was completed from, or null
/// (a free moment, an unknown intention or one without a phase).
String? intentionPhaseIdOf(Moment moment, List<Intention> intentions) =>
    _byId(intentions, moment.fromIntentionId, (i) => i.id)?.phaseId;

/// The phase span [moment] belongs to, one rule for every view: the phase
/// of the intention it was completed from (even when done after that phase
/// ended), otherwise the span containing its date; null before any phase.
PhaseSpan? phaseSpanOfMoment(
  Moment moment, {
  required List<Intention> intentions,
  required List<PhaseSpan> spans,
}) {
  final intentionPhase = _byId(
      spans, intentionPhaseIdOf(moment, intentions), (s) => s.phase.id);
  if (intentionPhase != null) return intentionPhase;
  for (final span in spans) {
    final started = !moment.date.isBefore(span.start);
    final notEnded = span.end == null || moment.date.isBefore(span.end!);
    if (started && notEnded) return span;
  }
  return null;
}

/// Where [moment] (from a completed intention) fell in that intention's
/// phase (the same phase [phaseSpanOfMoment] groups it by); null without
/// such an intention, phase, or before the phase began.
PhaseYear? phaseYearOf(Moment moment, CompassData data) {
  final phase =
      _byId(data.phases, intentionPhaseIdOf(moment, data.intentions), (p) => p.id);
  if (phase == null || moment.date.isBefore(phase.start)) return null;
  final years = LifeCalculator(birthDate: phase.start, now: moment.date).ageYears;
  return PhaseYear(phase, years + 1);
}

T? _byId<T>(List<T> items, String? id, String Function(T) idOf) {
  if (id == null) return null;
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}
