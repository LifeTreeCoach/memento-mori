/// Pure life-in-weeks arithmetic shared by the app and (mirrored in Kotlin
/// `android/lifecore` and Swift `ios/LifeCore`) by the native widgets.
///
/// All calculations are date-only (time of day and time zone are ignored).
/// The rules are specified in docs/widget-data-contract.md and pinned by
/// test/fixtures/life_calculator_vectors.json — keep all implementations
/// in sync with that fixture.
class LifeCalculator {
  static const int defaultLifeExpectancyYears = 80;
  static const int weeksPerYear = 52;
  static const int monthsPerYear = 12;

  final DateTime birthDate;
  final int lifeExpectancyYears;
  final DateTime today;

  LifeCalculator({
    required DateTime birthDate,
    this.lifeExpectancyYears = defaultLifeExpectancyYears,
    DateTime? now,
  })  : birthDate = _dateOnly(birthDate),
        today = _dateOnly(now ?? DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static int _nonNegative(int value) => value < 0 ? 0 : value;

  bool get _anniversaryReachedThisYear =>
      today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);

  /// Full years of age (a Feb 29 birthday counts from Mar 1 in non-leap years).
  int get ageYears => _nonNegative(
      today.year - birthDate.year - (_anniversaryReachedThisYear ? 0 : 1));

  int get daysLived => _nonNegative(today.difference(birthDate).inDays);

  int get weeksLived => daysLived ~/ 7;

  int get totalWeeks => lifeExpectancyYears * weeksPerYear;

  int get weeksRemaining => _nonNegative(totalWeeks - weeksLived);

  /// 1-based number of the week currently being lived.
  int get currentWeekNumber => weeksLived + 1;

  /// Completed calendar months since birth.
  int get monthsLived {
    final months = (today.year - birthDate.year) * monthsPerYear +
        (today.month - birthDate.month) -
        (today.day < birthDate.day ? 1 : 0);
    return _nonNegative(months);
  }

  int get totalMonths => lifeExpectancyYears * monthsPerYear;

  int get monthsRemaining => _nonNegative(totalMonths - monthsLived);

  int get yearsLived => ageYears;

  int get totalYears => lifeExpectancyYears;

  int get yearsRemaining => _nonNegative(totalYears - yearsLived);

  /// birthDate + lifeExpectancyYears; Feb 29 maps to Mar 1 in non-leap years.
  DateTime get expectedEndDate => DateTime.utc(
      birthDate.year + lifeExpectancyYears, birthDate.month, birthDate.day);

  int get daysRemaining =>
      _nonNegative(expectedEndDate.difference(today).inDays);

  /// Share of [totalWeeks] already lived, 0..100.
  double get percentLived {
    if (totalWeeks <= 0) return 100;
    return (weeksLived / totalWeeks * 100).clamp(0, 100).toDouble();
  }
}
