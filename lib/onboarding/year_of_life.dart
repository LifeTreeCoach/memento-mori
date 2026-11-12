import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

/// Where today lies in the current year of life (from the last birthday
/// up to the next one), date-only like [LifeCalculator].
class YearOfLife {
  YearOfLife({required DateTime birthDate, required DateTime today})
    : _calculator = LifeCalculator(birthDate: birthDate, now: today);

  final LifeCalculator _calculator;

  /// The last birthday on or before today. A Feb 29 birthday falls on
  /// Mar 1 in non-leap years, as in [LifeCalculator.ageYears].
  DateTime get lastBirthday => _birthdayAtAge(_calculator.ageYears);

  /// The first birthday strictly after [lastBirthday] (so always after
  /// today), with the same Feb 29 -> Mar 1 rule.
  DateTime get nextBirthday => _birthdayAtAge(_calculator.ageYears + 1);

  /// 1-based number of the current year of life: 1 from birth up to the
  /// first birthday, 37 for someone who is 36.
  int get yearNumber => _calculator.ageYears + 1;

  /// Days from today to [nextBirthday]: 1 the day before, the full
  /// [lengthInDays] on the birthday itself, never 0.
  int get daysUntilNextBirthday =>
      nextBirthday.difference(_calculator.today).inDays;

  /// Whole weeks left until [nextBirthday] (`daysUntilNextBirthday ~/ 7`).
  int get weeksUntilNextBirthday => daysUntilNextBirthday ~/ 7;

  /// Length of the current year of life in days: 365, or 366 when it
  /// spans a Feb 29.
  int get lengthInDays => nextBirthday.difference(lastBirthday).inDays;

  /// The birthday on which the person turns [age]. `DateTime.utc` rolls
  /// Feb 29 over to Mar 1 in non-leap years.
  DateTime _birthdayAtAge(int age) {
    final birth = _calculator.birthDate;
    return DateTime.utc(birth.year + age, birth.month, birth.day);
  }

  /// Whole weeks lived since [lastBirthday].
  int get completedWeeks =>
      _calculator.today.difference(lastBirthday).inDays ~/ 7;

  /// 1-based week of the current year of life: 1 on the birthday itself,
  /// 53 in the last one or two days before the next birthday.
  int get week => completedWeeks + 1;
}
