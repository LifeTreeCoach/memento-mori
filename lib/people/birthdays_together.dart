import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people/expected_end.dart';

/// How many more of a friend's birthdays you can expect to share.
///
/// The shared window runs from today to whichever life is expected to end
/// first ([ExpectedEnd.shared]): the user's (birth date + life expectancy)
/// or the friend's (birth date + [Friend.customLifespan]). The friend's
/// birthdays inside that window are counted, both ends inclusive:
/// - a birthday today counts (the day has not passed yet),
/// - the birthday on which an expectancy is reached counts,
/// - a friend already beyond their expectancy gets 0,
/// - a friend without a birth year gets null (no expected end).
class BirthdaysTogether {
  BirthdaysTogether._();

  static int? count({
    required Friend friend,
    required DateTime userBirthDate,
    required int userLifeExpectancyYears,
    required DateTime today,
  }) {
    if (!friend.hasBirthYear) return null;
    final day = _dateOnly(today);
    final end = ExpectedEnd.shared(
      friend: friend,
      userBirthDate: userBirthDate,
      userLifeExpectancyYears: userLifeExpectancyYears,
      today: day,
    );
    return _birthdaysBetween(friend, day, end);
  }

  static int _birthdaysBetween(Friend friend, DateTime from, DateTime to) {
    var total = 0;
    for (var year = from.year; year <= to.year; year++) {
      if (year <= friend.birthDate.year) continue; // not a birthday yet
      final birthday = _birthday(friend, year);
      if (!birthday.isBefore(from) && !birthday.isAfter(to)) total++;
    }
    return total;
  }

  static DateTime _birthday(Friend friend, int year) =>
      _dateOnly(Friend.birthdayDateInYear(friend.birthDate, year));

  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}
