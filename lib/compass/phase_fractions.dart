/// Pure geometry of the phase visuals: where dates fall on a lifespan
/// (0 = birth, 1 = expected end), for the lifespan bar and the ribbon.
library;

import 'dart:ui' show lerpDouble;

import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';

/// Position (0..1) of [date] on a [lifeExpectancyYears] lifespan from
/// [birthDate]; 0 without a positive life expectancy.
double lifeFraction(
    DateTime date, DateTime birthDate, int lifeExpectancyYears) {
  if (lifeExpectancyYears <= 0) return 0;
  final birth = _utcDay(birthDate);
  final end = DateTime.utc(
      birth.year + lifeExpectancyYears, birth.month, birth.day);
  final total = end.difference(birth).inDays;
  final lived = _utcDay(date).difference(birth).inDays;
  return (lived / total).clamp(0.0, 1.0).toDouble();
}

DateTime _utcDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// The lifespan bar of one phase: lived before it, the phase so far, its
/// planned rest and the remaining lifespan.
class LifespanBarFractions {
  const LifespanBarFractions({
    required this.phaseStart,
    required this.today,
    required this.plannedEnd,
  });

  /// Bar for a phase from [start] (planned until [plannedEnd]).
  factory LifespanBarFractions.of({
    required DateTime birthDate,
    required int lifeExpectancyYears,
    required DateTime start,
    required DateTime today,
    DateTime? plannedEnd,
  }) {
    double at(DateTime d) => lifeFraction(d, birthDate, lifeExpectancyYears);
    final now = at(today);
    final end = plannedEnd == null ? now : at(plannedEnd);
    return LifespanBarFractions(
      phaseStart: at(start).clamp(0.0, now).toDouble(),
      today: now,
      plannedEnd: end < now ? now : end,
    );
  }

  /// Lived before the phase: 0..[phaseStart].
  final double phaseStart;

  /// The phase so far ends here: [phaseStart]..[today].
  final double today;

  /// Its planned rest: [today]..[plannedEnd] (= [today] without a plan).
  final double plannedEnd;

  static LifespanBarFractions lerp(
      LifespanBarFractions a, LifespanBarFractions b, double t) {
    return LifespanBarFractions(
      phaseStart: lerpDouble(a.phaseStart, b.phaseStart, t)!,
      today: lerpDouble(a.today, b.today, t)!,
      plannedEnd: lerpDouble(a.plannedEnd, b.plannedEnd, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LifespanBarFractions &&
      other.phaseStart == phaseStart &&
      other.today == today &&
      other.plannedEnd == plannedEnd;

  @override
  int get hashCode => Object.hash(phaseStart, today, plannedEnd);
}

/// What a ribbon segment shows.
enum RibbonTone { before, earlier, current, planned }

/// A coloured stretch of the phase ribbon, as fractions of the lifespan.
class RibbonSegment {
  const RibbonSegment(this.from, this.to, this.tone, {this.earlierIndex = 0});

  final double from;
  final double to;
  final RibbonTone tone;

  /// Index of an [RibbonTone.earlier] phase (oldest = 0).
  final int earlierIndex;

  @override
  bool operator ==(Object other) =>
      other is RibbonSegment &&
      other.from == from &&
      other.to == to &&
      other.tone == tone &&
      other.earlierIndex == earlierIndex;

  @override
  int get hashCode => Object.hash(from, to, tone, earlierIndex);

  @override
  String toString() => 'RibbonSegment($from..$to, $tone $earlierIndex)';
}

/// Segments of the whole-life ribbon for [spans] (from [resolvePhases]):
/// the time before the first phase, earlier phases, the current phase until
/// [today] and its planned rest. Empty stretches are left out; the rest of
/// the lifespan is background.
List<RibbonSegment> ribbonSegments(
  List<PhaseSpan> spans, {
  required DateTime birthDate,
  required int lifeExpectancyYears,
  required DateTime today,
}) {
  double at(DateTime d) => lifeFraction(d, birthDate, lifeExpectancyYears);
  if (spans.isEmpty) return [RibbonSegment(0, at(today), RibbonTone.before)];
  final segments = [
    RibbonSegment(0, at(spans.first.start), RibbonTone.before),
    for (var i = 0; i < spans.length; i++) _spanSegment(spans[i], i, at, today),
    if (spans.last.phase.plannedEnd case final end?)
      RibbonSegment(at(today), at(end), RibbonTone.planned),
  ];
  return segments.where((s) => s.to > s.from).toList();
}

RibbonSegment _spanSegment(PhaseSpan span, int index,
    double Function(DateTime) at, DateTime today) {
  if (span.isCurrent) {
    return RibbonSegment(at(span.start), at(today), RibbonTone.current);
  }
  return RibbonSegment(at(span.start), at(span.end ?? today),
      RibbonTone.earlier, earlierIndex: index);
}
