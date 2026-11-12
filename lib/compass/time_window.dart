/// Pure arithmetic of the "your time window" card in the intention flow:
/// the weeks of the current phase lived and still planned, their share of
/// the lifespan and how many weeks one dot stands for.
library;

import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

/// Weeks of the current phase: lived so far and planned until its end.
class PhaseWeeks {
  const PhaseWeeks({required this.lived, required this.left});

  final int lived;
  final int left;

  int get total => lived + left;
}

/// The weeks of [span] on [today]; null without a planned end.
PhaseWeeks? phaseWeeks(PhaseSpan span, DateTime today) {
  final left = plannedWeeksLeft(span, today);
  if (left == null) return null;
  final lived = LifeCalculator(birthDate: span.start, now: today).weeksLived;
  return PhaseWeeks(lived: lived, left: left);
}

/// Average weeks in a year (365.25 / 7).
const double weeksPerYear = 365.25 / 7;

/// Share (0..1) of a [lifeExpectancyYears] lifespan that [weeks] make up;
/// null without a positive life expectancy.
double? weeksShareOfLifespan(int weeks, int lifeExpectancyYears) {
  if (lifeExpectancyYears <= 0) return null;
  final share = weeks / (lifeExpectancyYears * weeksPerYear);
  return share.clamp(0.0, 1.0).toDouble();
}

/// Most dots the week row shows.
const int maxWeekDots = 120;

/// Weeks per dot so that [totalWeeks] fit in [maxDots]: 1 week, else 4
/// weeks (about a month), a quarter (13) or a year (52).
int weeksPerDot(int totalWeeks, {int maxDots = maxWeekDots}) {
  for (final weeks in const [1, 4, 13]) {
    if (totalWeeks <= maxDots * weeks) return weeks;
  }
  return 52;
}

/// Dots for [weeks] at [perDot] weeks each (a started dot counts).
int dotsFor(int weeks, int perDot) => (weeks + perDot - 1) ~/ perDot;
