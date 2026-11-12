import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';

/// Expected end dates (UTC, date-only) of the user's and a friend's life,
/// shared by [BirthdaysTogether] and [SharedTime]:
/// - the user's: birth date + life expectancy (see [LifeCalculator]),
/// - a friend's: their birthday in birth year + [Friend.customLifespan]
///   (Feb 29 falls back to Feb 28). Only for friends with a birth year
///   ([Friend.hasBirthYear]); callers check it first.
class ExpectedEnd {
  ExpectedEnd._();

  static DateTime ofUser({
    required DateTime birthDate,
    required int lifeExpectancyYears,
    required DateTime today,
  }) =>
      LifeCalculator(
        birthDate: birthDate,
        lifeExpectancyYears: lifeExpectancyYears,
        now: dateOnly(today),
      ).expectedEndDate;

  static DateTime ofFriend(Friend friend) => dateOnly(Friend.birthdayDateInYear(
      friend.birthDate, friend.birthDate.year + friend.customLifespan));

  /// The earlier of both ends: where the time you can share ends.
  static DateTime shared({
    required Friend friend,
    required DateTime userBirthDate,
    required int userLifeExpectancyYears,
    required DateTime today,
  }) {
    final userEnd = ofUser(
      birthDate: userBirthDate,
      lifeExpectancyYears: userLifeExpectancyYears,
      today: today,
    );
    final friendEnd = ofFriend(friend);
    return userEnd.isBefore(friendEnd) ? userEnd : friendEnd;
  }

  static DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}
