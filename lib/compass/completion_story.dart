/// Pure facts behind the calm look back after completing an intention: how
/// long it took, where it happened in its phase and in the whole lifespan,
/// and how much time lies ahead. Every level that lacks its data (no
/// phase, no birth date) is null, so the view simply leaves it out.
library;

import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_meta.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/time_window.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

/// Unit in which the time an intention took is told.
enum TakenUnit { sameDay, days, weeks, months }

/// How long an intention took, in the unit that reads naturally: the same
/// day, days under a week, weeks up to [maxWeeks], months after that.
class TakenTime {
  const TakenTime(this.unit, this.count);

  /// From the day it was written down ([from]) to the day it was done.
  factory TakenTime.between(DateTime from, DateTime to) {
    final calc = LifeCalculator(birthDate: from, now: to);
    final days = calc.daysLived;
    if (days == 0) return const TakenTime(TakenUnit.sameDay, 0);
    if (days < DateTime.daysPerWeek) return TakenTime(TakenUnit.days, days);
    final weeks = calc.weeksLived;
    if (weeks <= maxWeeks) return TakenTime(TakenUnit.weeks, weeks);
    return TakenTime(TakenUnit.months, calc.monthsLived);
  }

  /// Longest span still told in weeks (about four months).
  static const int maxWeeks = 16;

  final TakenUnit unit;

  /// Days, weeks or months (0 for [TakenUnit.sameDay]).
  final int count;

  /// It took months: the look back says it was allowed to take time.
  bool get isLong => unit == TakenUnit.months;

  @override
  bool operator ==(Object other) =>
      other is TakenTime && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);

  @override
  String toString() => 'TakenTime($unit, $count)';
}

/// Where the completion fell in its phase.
class PhaseStory {
  const PhaseStory({
    required this.phase,
    required this.weekInPhase,
    required this.weeks,
  });

  final LifePhase phase;

  /// Week of the phase it was done in (1 = its first week).
  final int weekInPhase;

  /// The phase's weeks with this week counted as lived (the planned rest
  /// is 0 without a planned end), for the week dots.
  final PhaseWeeks weeks;

  /// 0-based index of this week among [weeks].
  int get weekIndex => weekInPhase - 1;
}

/// Where the completion fell in the whole lifespan.
class LifeStory {
  const LifeStory({
    required this.weekOfLife,
    required this.totalWeeks,
    required this.weeksRemaining,
    required this.position,
    required this.bar,
  });

  /// 1-based week of life it happened in.
  final int weekOfLife;
  final int totalWeeks;

  /// Weeks expected ahead (0 beyond the life expectancy).
  final int weeksRemaining;

  /// Position (0..1) of the day on the lifespan.
  final double position;

  /// The lifespan bar: lived before the phase, the phase, its planned rest.
  final LifespanBarFractions bar;
}

/// Tone of the closing line of the look back.
enum GratitudeTone { doTask, enjoy, long }

/// Everything the look back after completing an intention tells.
class CompletionStory {
  const CompletionStory({
    required this.taken,
    this.kind,
    this.phase,
    this.life,
    required this.gratitudeIndex,
  });

  /// The story of [intention] completed as [moment]. Its phase is the one
  /// [phaseSpanOfMoment] groups the moment by (from [phases] as they stand
  /// on [today]); the phase level is left out when the moment lies outside
  /// that phase, the life levels without [birthDate].
  factory CompletionStory.of({
    required Intention intention,
    required Moment moment,
    required List<LifePhase> phases,
    required DateTime? birthDate,
    required int lifeExpectancyYears,
    required DateTime today,
  }) {
    final span = phaseSpanOfMoment(moment,
        intentions: [intention], spans: resolvePhases(phases, today));
    return CompletionStory(
      taken: TakenTime.between(intention.createdAt, moment.date),
      kind: intention.kind,
      phase: span == null ? null : _phaseStory(span, moment.date),
      life: birthDate == null
          ? null
          : _lifeStory(span, moment.date, birthDate, lifeExpectancyYears),
      gratitudeIndex: stableIndex(intention.id),
    );
  }

  final TakenTime taken;
  final IntentionKind? kind;

  /// Null without a phase containing the day.
  final PhaseStory? phase;

  /// Null without a birth date.
  final LifeStory? life;

  /// Picks one of the closing lines of [tone], the same for an intention
  /// every time (see [stableIndex]).
  final int gratitudeIndex;

  /// Tone of the closing line: a long wait first, then the kind.
  GratitudeTone get tone {
    if (taken.isLong) return GratitudeTone.long;
    return kind == IntentionKind.enjoy
        ? GratitudeTone.enjoy
        : GratitudeTone.doTask;
  }

  /// A small non-negative number derived from [id] that is the same on
  /// every run (unlike [String.hashCode]).
  static int stableIndex(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x3fffffff;
    }
    return hash;
  }
}

PhaseStory? _phaseStory(PhaseSpan span, DateTime day) {
  final ended = span.end != null && !day.isBefore(span.end!);
  if (day.isBefore(span.start) || ended) return null;
  final lived = LifeCalculator(birthDate: span.start, now: day).weeksLived;
  final planned = phaseWeeks(span, day);
  return PhaseStory(
    phase: span.phase,
    weekInPhase: lived + 1,
    weeks: PhaseWeeks(lived: lived + 1, left: planned?.left ?? 0),
  );
}

LifeStory _lifeStory(
    PhaseSpan? span, DateTime day, DateTime birthDate, int years) {
  final calc = LifeCalculator(
      birthDate: birthDate, lifeExpectancyYears: years, now: day);
  final current = span != null && span.isCurrent ? span : null;
  return LifeStory(
    weekOfLife: calc.currentWeekNumber,
    totalWeeks: calc.totalWeeks,
    weeksRemaining: calc.weeksRemaining,
    position: lifeFraction(day, birthDate, years),
    bar: LifespanBarFractions.of(
      birthDate: birthDate,
      lifeExpectancyYears: years,
      start: current?.start ?? day,
      today: day,
      plannedEnd: current?.phase.plannedEnd,
    ),
  );
}
