import 'dart:math' as math;

import 'life_table_set.dart';

/// Lifestyle hazard multiplier H for the single year of age starting at
/// [ageYears] (the integer age of the step, not capped at 100).
typedef HazardMultiplier = double Function(int ageYears);

double _noMultiplier(int ageYears) => 1.0;

/// Summary of a survival curve from the current age onwards.
class CohortResult {
  const CohortResult({
    required this.mean,
    required this.p25,
    required this.median,
    required this.p75,
    required this.reach80,
    required this.reach90,
  });

  /// Expected age at death (current age + remaining life expectancy).
  final double mean;

  /// Age by which 25 % / 50 % / 75 % of people like this have died.
  final double p25;
  final double median;
  final double p75;

  /// Probability of reaching 80 / 90; null when the current age is already >= it.
  final double? reach80;
  final double? reach90;
}

/// Cohort survival from an exact age, as piecewise-constant hazards per single
/// year of age (steps break at integer ages) up to [CohortEngine.maxAge], then an
/// exponential tail.
class SurvivalCurve {
  SurvivalCurve._({
    required this.startAge,
    required this.stepStarts,
    required this.survival,
    required this.hazards,
    required this.tailHazard,
    required this.mean,
    required this.reach80,
    required this.reach90,
  });

  final double startAge;

  /// x_k, the start age of each step.
  final List<double> stepStarts;

  /// S_k at each step start, plus S_end as the last element (length steps + 1).
  final List<double> survival;

  /// mu_k per step (already multiplied by H).
  final List<double> hazards;

  /// Hazard after the last step (or from [startAge] when there are no steps).
  final double tailHazard;

  final double mean;
  final double? reach80;
  final double? reach90;

  int get stepCount => hazards.length;

  /// x_end: [CohortEngine.maxAge], or [startAge] when there were no steps.
  double get endAge =>
      stepCount == 0 ? startAge : CohortEngine.maxAge.toDouble();

  double get endSurvival => survival.last;

  /// S(x), the probability of being alive at age [x] (1 for x <= startAge).
  double survivalAt(double x) {
    if (x <= startAge) return 1.0;
    for (var k = 0; k < stepCount; k++) {
      final end = k + 1 < stepCount ? stepStarts[k + 1] : endAge;
      if (x <= end) {
        return survival[k] * math.exp(-hazards[k] * (x - stepStarts[k]));
      }
    }
    return endSurvival * math.exp(-tailHazard * (x - endAge));
  }

  /// Age where S falls to [target] (0 < target < 1), solved exactly in-step.
  double ageAtSurvival(double target) {
    for (var k = 0; k < stepCount; k++) {
      if (survival[k] > target && target >= survival[k + 1]) {
        return stepStarts[k] + math.log(survival[k] / target) / hazards[k];
      }
    }
    return endAge + math.log(endSurvival / target) / tailHazard;
  }

  CohortResult summarize() => CohortResult(
    mean: mean,
    p25: ageAtSurvival(0.75),
    median: ageAtSurvival(0.5),
    p75: ageAtSurvival(0.25),
    reach80: reach80,
    reach90: reach90,
  );
}

/// The cohort life-expectancy engine; a port of the reference engine in
/// `tool/README.md` (fixtures in `test/fixtures/lifespan_cases.json`).
class CohortEngine {
  const CohortEngine._();

  static const int maxAge = 125;

  /// Survival from exact [age] at calendar time [year] (fractional year).
  static SurvivalCurve survival(
    LifeTable table, {
    required double age,
    required double year,
    HazardMultiplier hazardMultiplier = _noMultiplier,
  }) {
    double mu(double x, double d) {
      final ageYears = x.floor();
      final midYear = year + (x + d / 2.0 - age);
      final index = math.min(ageYears, LifeTable.maxAgeIndex);
      return table.hazard(index, midYear) * hazardMultiplier(ageYears);
    }

    final starts = <double>[];
    final survival = <double>[1.0];
    final hazards = <double>[];
    double? reach80, reach90;
    var s = 1.0;
    var total = 0.0;
    var x = age;
    for (var boundary = age.floor() + 1; boundary <= maxAge; boundary++) {
      final d = boundary - x;
      final rate = mu(x, d);
      final next = s * math.exp(-rate * d);
      total += s * (1.0 - math.exp(-rate * d)) / rate;
      starts.add(x);
      hazards.add(rate);
      survival.add(next);
      s = next;
      if (boundary == 80) reach80 = s;
      if (boundary == 90) reach90 = s;
      x = boundary.toDouble();
    }
    final tail = hazards.isEmpty
        ? table.hazard(LifeTable.maxAgeIndex, year) *
              hazardMultiplier(age.floor())
        : hazards.last;
    total += s / tail;
    return SurvivalCurve._(
      startAge: age,
      stepStarts: starts,
      survival: survival,
      hazards: hazards,
      tailHazard: tail,
      mean: age + total,
      reach80: age < 80 ? reach80 : null,
      reach90: age < 90 ? reach90 : null,
    );
  }

  /// Convenience: [survival] then [SurvivalCurve.summarize].
  static CohortResult run(
    LifeTable table, {
    required double age,
    required double year,
    HazardMultiplier hazardMultiplier = _noMultiplier,
  }) => survival(
    table,
    age: age,
    year: year,
    hazardMultiplier: hazardMultiplier,
  ).summarize();

  /// Equal-weight mixture S(t) = (S_a + S_b) / 2 of two curves from the same
  /// age: mean and reach are averages, percentiles are solved on the mixture.
  static CohortResult mixture(SurvivalCurve a, SurvivalCurve b) {
    assert(
      a.startAge == b.startAge,
      'Mixture curves must start at the same age',
    );
    double s(double x) => (a.survivalAt(x) + b.survivalAt(x)) / 2.0;
    double? average(double? u, double? v) =>
        u == null || v == null ? null : (u + v) / 2.0;
    return CohortResult(
      mean: (a.mean + b.mean) / 2.0,
      p25: _solveDecreasing(s, 0.75, a.startAge),
      median: _solveDecreasing(s, 0.5, a.startAge),
      p75: _solveDecreasing(s, 0.25, a.startAge),
      reach80: average(a.reach80, b.reach80),
      reach90: average(a.reach90, b.reach90),
    );
  }

  /// Smallest x >= [from] with s(x) <= [target] for a continuous, strictly
  /// decreasing s (bisection to machine precision).
  static double _solveDecreasing(
    double Function(double) s,
    double target,
    double from,
  ) {
    var lo = from;
    var hi = math.max(from, maxAge.toDouble());
    while (s(hi) > target) {
      hi += 50.0;
    }
    for (var n = 0; n < 200 && hi - lo > 1e-12; n++) {
      final mid = (lo + hi) / 2.0;
      if (s(mid) > target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2.0;
  }
}
