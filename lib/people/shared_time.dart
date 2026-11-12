import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people/birthdays_together.dart';
import 'package:memento_mori_life_in_weeks/people/expected_end.dart';
import 'package:memento_mori_life_in_weeks/people/meeting_frequency.dart';

/// The time the user and a friend can still share (pure, date-only, UTC).
///
/// Inspired by Tim Urban's "The Tail End": what counts is the encounters
/// left, not the years. The window runs from today (or the friend's birth,
/// if still ahead) to [ExpectedEnd.shared], the earlier of both expected
/// ends. Which of the two ends comes first is never exposed as text.
class SharedTime {
  const SharedTime._({
    required this.today,
    required this.userBirthDate,
    required this.userEnd,
    required this.friendBirthDate,
    required this.friendEnd,
    required this.sharedEnd,
    required this.birthdaysTogether,
  });

  /// Average days per year, for converting days to years.
  static const double daysPerYear = 365.25;

  final DateTime today;
  final DateTime userBirthDate;
  final DateTime userEnd;
  final DateTime friendBirthDate;
  final DateTime friendEnd;

  /// Where the shared window ends (earlier of [userEnd] and [friendEnd]).
  final DateTime sharedEnd;

  /// Shared birthdays ahead (see [BirthdaysTogether]).
  final int birthdaysTogether;

  /// Null without the user's birth date or the friend's birth year (the
  /// "Together" view is hidden).
  static SharedTime? compute({
    required Friend friend,
    required DateTime? userBirthDate,
    required int userLifeExpectancyYears,
    required DateTime today,
  }) {
    if (userBirthDate == null || !friend.hasBirthYear) return null;
    final day = ExpectedEnd.dateOnly(today);
    return SharedTime._(
      today: day,
      userBirthDate: ExpectedEnd.dateOnly(userBirthDate),
      userEnd: ExpectedEnd.ofUser(
        birthDate: userBirthDate,
        lifeExpectancyYears: userLifeExpectancyYears,
        today: day,
      ),
      friendBirthDate: ExpectedEnd.dateOnly(friend.birthDate),
      friendEnd: ExpectedEnd.ofFriend(friend),
      sharedEnd: ExpectedEnd.shared(
        friend: friend,
        userBirthDate: userBirthDate,
        userLifeExpectancyYears: userLifeExpectancyYears,
        today: day,
      ),
      birthdaysTogether: BirthdaysTogether.count(
        friend: friend,
        userBirthDate: userBirthDate,
        userLifeExpectancyYears: userLifeExpectancyYears,
        today: day,
      )!,
    );
  }

  /// Start of the time ahead: today, or a birth still to come.
  DateTime get _aheadStart => _latest([today, userBirthDate, friendBirthDate]);

  /// Days of shared time ahead (never negative).
  int get remainingDays => _daysBetween(_aheadStart, sharedEnd);

  /// True once the window is used up (an expectancy is reached): show
  /// "every shared day is a gift" instead of numbers.
  bool get isBeyondExpectancy => remainingDays == 0;

  double get remainingYears => remainingDays / daysPerYear;

  int get remainingWeeks => remainingDays ~/ 7;

  /// Years lived side by side so far: from the later birth date to today.
  double get livedAlongsideYears =>
      _daysBetween(_latest([userBirthDate, friendBirthDate]), today) /
      daysPerYear;

  /// Encounters left at [frequency] ([MeetingFrequency.perYear] over the
  /// time ahead; daily = one per day), or null without a frequency.
  int? meetingsLeft(MeetingFrequency? frequency) {
    if (frequency == null) return null;
    if (frequency == MeetingFrequency.daily) return remainingDays;
    return (remainingYears * frequency.perYear).round();
  }

  static DateTime _latest(List<DateTime> dates) =>
      dates.reduce((a, b) => a.isAfter(b) ? a : b);

  static int _daysBetween(DateTime from, DateTime to) {
    final days = to.difference(from).inDays;
    return days < 0 ? 0 : days;
  }
}

/// How many encounters one dot stands for so that at most [maxDots] dots
/// are drawn: 1, 10, 100, ...
int encountersPerDot(int encounters, {int maxDots = 400}) {
  var scale = 1;
  while (encounters / scale > maxDots) {
    scale *= 10;
  }
  return scale;
}
