/// Pure logic of "About how much longer should this phase last?": a number
/// of months from today, or open-ended.
library;

import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

/// How much longer a phase is planned to last: [months] from today, or
/// open-ended ([months] null).
@immutable
class PlannedDuration {
  const PlannedDuration.months(int this.months) : assert(months > 0);
  const PlannedDuration.open() : months = null;

  /// Months from today; null = no planned end.
  final int? months;

  bool get isOpen => months == null;

  /// The quick choices: 6 months, 1, 2 and 5 years, open.
  static const List<PlannedDuration> choices = [
    PlannedDuration.months(6),
    PlannedDuration.months(12),
    PlannedDuration.months(24),
    PlannedDuration.months(60),
    PlannedDuration.open(),
  ];

  /// Longest plan: until the expected end of a [lifeExpectancyYears]
  /// lifespan from [birthDate] (at least a month); 100 years without one.
  static int maxMonths({
    DateTime? birthDate,
    required int lifeExpectancyYears,
    required DateTime today,
  }) {
    if (birthDate == null) return 100 * LifeCalculator.monthsPerYear;
    final end = DateTime(birthDate.year + lifeExpectancyYears,
        birthDate.month, birthDate.day);
    final left = LifeCalculator(birthDate: today, now: end).monthsLived;
    return left < 1 ? 1 : left;
  }

  /// The duration that ends on [plannedEnd] (whole months from [today],
  /// at least 1); open without a planned end.
  factory PlannedDuration.until(DateTime? plannedEnd, DateTime today) {
    if (plannedEnd == null) return const PlannedDuration.open();
    final months = LifeCalculator(birthDate: today, now: plannedEnd).monthsLived;
    return PlannedDuration.months(months < 1 ? 1 : months);
  }

  /// The planned end: [months] calendar months after [today] (day clamped
  /// to short months); null when open.
  DateTime? endFrom(DateTime today) {
    final m = months;
    return m == null ? null : startFromAgo(compassDate(today), 0, -m);
  }

  /// Months of the whole phase from [start] to its planned end; null when
  /// open.
  int? totalMonths(DateTime start, DateTime today) {
    final end = endFrom(today);
    return end == null
        ? null
        : LifeCalculator(birthDate: start, now: end).monthsLived;
  }

  /// Share (0..1) of a [lifeExpectancyYears] lifespan the whole phase takes
  /// (from [start] to its planned end); null when open.
  double? totalShare(DateTime start, DateTime today, int lifeExpectancyYears) {
    final total = totalMonths(start, today);
    return total == null ? null : shareOfLifespan(total, lifeExpectancyYears);
  }

  @override
  bool operator ==(Object other) =>
      other is PlannedDuration && other.months == months;

  @override
  int get hashCode => months.hashCode;

  @override
  String toString() => 'PlannedDuration(${months ?? 'open'})';
}
