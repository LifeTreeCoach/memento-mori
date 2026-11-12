/// Pure date logic of life phases: where each phase starts and ends, how
/// long it has lasted and what share of the lifespan that is.
library;

import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

/// A [LifePhase] placed on the timeline.
class PhaseSpan {
  const PhaseSpan({
    required this.phase,
    required this.start,
    this.end,
    required this.isCurrent,
  });

  final LifePhase phase;

  /// First day (date only).
  final DateTime start;

  /// Start of the next phase (exclusive); null for the current phase.
  final DateTime? end;

  /// The latest phase that has started.
  final bool isCurrent;
}

/// Phases that have started by [today], oldest first; each ends where the
/// next one starts and the last one is current.
List<PhaseSpan> resolvePhases(List<LifePhase> phases, DateTime today) {
  final day = compassDate(today);
  final started = phases.where((p) => !p.start.isAfter(day)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return [
    for (var i = 0; i < started.length; i++)
      PhaseSpan(
        phase: started[i],
        start: started[i].start,
        end: i + 1 < started.length ? started[i + 1].start : null,
        isCurrent: i == started.length - 1,
      ),
  ];
}

/// The phase lived on [today], or null before the first phase.
PhaseSpan? currentSpan(List<LifePhase> phases, DateTime today) {
  final spans = resolvePhases(phases, today);
  return spans.isEmpty ? null : spans.last;
}

/// Completed months of [span] (until its end, or [today] while current).
int monthsIn(PhaseSpan span, DateTime today) =>
    LifeCalculator(birthDate: span.start, now: span.end ?? today).monthsLived;

/// Share (0..1) of a [lifeExpectancyYears] lifespan that [months] make up;
/// null without a positive life expectancy.
double? shareOfLifespan(int months, int lifeExpectancyYears) {
  if (lifeExpectancyYears <= 0) return null;
  final total = lifeExpectancyYears * LifeCalculator.monthsPerYear;
  return (months / total).clamp(0.0, 1.0).toDouble();
}

/// Completed months from [today] to the planned end; null without one,
/// never negative.
int? plannedMonthsLeft(PhaseSpan span, DateTime today) =>
    _untilPlannedEnd(span, today)?.monthsLived;

/// Full weeks from [today] to the planned end; null without one, never
/// negative.
int? plannedWeeksLeft(PhaseSpan span, DateTime today) =>
    _untilPlannedEnd(span, today)?.weeksLived;

LifeCalculator? _untilPlannedEnd(PhaseSpan span, DateTime today) {
  final plannedEnd = span.phase.plannedEnd;
  if (plannedEnd == null) return null;
  return LifeCalculator(birthDate: today, now: plannedEnd);
}

/// The current phase reached its planned end (on or after that day).
bool isOverdue(PhaseSpan span, DateTime today) {
  final plannedEnd = span.phase.plannedEnd;
  return span.isCurrent &&
      plannedEnd != null &&
      !compassDate(today).isBefore(plannedEnd);
}

/// Share (0..1) of the life lived so far (from [birthDate] to [today])
/// that [months] make up; null before a month of life.
double? shareOfLifeSoFar(int months, DateTime birthDate, DateTime today) {
  final lived = LifeCalculator(birthDate: birthDate, now: today).monthsLived;
  if (lived <= 0) return null;
  return (months / lived).clamp(0.0, 1.0).toDouble();
}

/// The day [years] and [months] before [today] (day clamped to short
/// months), but never before [birthDate].
DateTime startFromAgo(DateTime today, int years, int months,
    {DateTime? birthDate}) {
  final monthIndex = today.year * 12 + today.month - 1 - years * 12 - months;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final start = DateTime(year, month, today.day < lastDay ? today.day : lastDay);
  final birth = birthDate == null ? null : compassDate(birthDate);
  return birth != null && start.isBefore(birth) ? birth : start;
}

/// Why a phase start is not allowed.
enum PhaseStartError {
  beforeBirth,
  inFuture,
  duplicateDay,

  /// An earlier phase must start before the current one.
  notBeforeCurrent,
}

/// The problem with starting a phase on [start], or null if it is fine:
/// it must lie between [birthDate] and [today] and not share its day with
/// one of [others] (except the phase [ignoreId] being edited).
PhaseStartError? validateStart(
  DateTime start, {
  DateTime? birthDate,
  required DateTime today,
  required Iterable<LifePhase> others,
  String? ignoreId,
}) {
  final day = compassDate(start);
  if (birthDate != null && day.isBefore(compassDate(birthDate))) {
    return PhaseStartError.beforeBirth;
  }
  if (day.isAfter(compassDate(today))) return PhaseStartError.inFuture;
  final taken = others.any((p) => p.id != ignoreId && p.start == day);
  return taken ? PhaseStartError.duplicateDay : null;
}
