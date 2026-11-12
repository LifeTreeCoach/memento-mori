/// Pure logic of "Add earlier phases": which phases came before the
/// current one, where an earlier phase starts (an age or a year) and
/// whether that start is allowed.
library;

import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

/// The phases before the current one on [today], oldest first.
List<PhaseSpan> earlierSpans(List<LifePhase> phases, DateTime today) {
  final spans = resolvePhases(phases, today);
  return spans.isEmpty ? const [] : spans.sublist(0, spans.length - 1);
}

/// The [age]th birthday after [birthDate] (29 February falls back to 28).
DateTime startAtAge(DateTime birthDate, int age) {
  final year = birthDate.year + age;
  final lastDay = DateTime(year, birthDate.month + 1, 0).day;
  final day = birthDate.day < lastDay ? birthDate.day : lastDay;
  return DateTime(year, birthDate.month, day);
}

/// Full years of age on [day] (0 before the birth date).
int ageOn(DateTime birthDate, DateTime day) =>
    LifeCalculator(birthDate: birthDate, now: day).ageYears;

/// The problem with an earlier phase starting on [start], or null: the
/// rules of [validateStart], and it must begin before the current phase
/// ([ignoreId] is the phase being edited).
PhaseStartError? validateEarlierStart(
  DateTime start, {
  DateTime? birthDate,
  required DateTime today,
  required List<LifePhase> phases,
  String? ignoreId,
}) {
  final error = validateStart(start,
      birthDate: birthDate, today: today, others: phases, ignoreId: ignoreId);
  if (error != null) return error;
  final current = _currentOtherThan(phases, today, ignoreId);
  if (current != null && !compassDate(start).isBefore(current.start)) {
    return PhaseStartError.notBeforeCurrent;
  }
  return null;
}

/// The current phase, unless it is the phase [ignoreId] being edited (then
/// the newest of the others).
LifePhase? _currentOtherThan(
    List<LifePhase> phases, DateTime today, String? ignoreId) {
  final others = phases.where((p) => p.id != ignoreId).toList();
  return currentSpan(others, today)?.phase;
}
