import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';

/// Where a period lies relative to today.
enum PeriodRelation { past, current, future }

/// The span of time one grid cell stands for.
class LifePeriod {
  LifePeriod._({
    required this.mode,
    required this.index,
    required this.start,
    required this.end,
    required this.relation,
    required this.distance,
    required this.ageAtStart,
    required this.today,
  });

  /// Period of cell [index] in [mode] for the life described by [calc].
  factory LifePeriod.of(LifeMode mode, int index, LifeCalculator calc) {
    final start = periodStart(mode, index, calc.birthDate);
    final current = mode.livedCells(calc);
    final age = LifeCalculator(birthDate: calc.birthDate, now: start).ageYears;
    return LifePeriod._(
      mode: mode,
      index: index,
      start: start,
      end: periodStart(mode, index + 1, calc.birthDate),
      relation: index < current
          ? PeriodRelation.past
          : index == current
              ? PeriodRelation.current
              : PeriodRelation.future,
      distance: (index - current).abs(),
      ageAtStart: age,
      today: calc.today,
    );
  }

  final LifeMode mode;
  final int index;

  /// First day of the period (UTC, date only).
  final DateTime start;

  /// First day after the period.
  final DateTime end;
  final PeriodRelation relation;

  /// Number of cells between this period and the current one.
  final int distance;
  final int ageAtStart;
  final DateTime today;

  /// Start of cell [index]: the first day on which [LifeCalculator] counts
  /// [index] weeks/months/years lived, so the cell holding today is always
  /// the lived count. A Feb 29 year starts on Mar 1 in non-leap years.
  static DateTime periodStart(LifeMode mode, int index, DateTime birthDate) {
    final b = birthDate;
    switch (mode) {
      case LifeMode.weeks:
        return DateTime.utc(b.year, b.month, b.day + index * 7);
      case LifeMode.months:
        return _monthStart(b, index);
      case LifeMode.years:
        return DateTime.utc(b.year + index, b.month, b.day);
    }
  }

  /// Month [index] starts on the birth day of its calendar month; a month
  /// too short for that day (e.g. Feb for a 31st) is completed only on the
  /// 1st of the following month, matching [LifeCalculator.monthsLived].
  static DateTime _monthStart(DateTime b, int index) {
    final month = DateTime.utc(b.year, b.month + index);
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    return b.day <= daysInMonth
        ? DateTime.utc(month.year, month.month, b.day)
        : DateTime.utc(month.year, month.month + 1);
  }

  bool contains(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    return !d.isBefore(start) && d.isBefore(end);
  }

  /// Moments can be noted for past periods and the current one.
  bool get canHoldMoments => relation != PeriodRelation.future;

  /// Day a new moment for this period starts on: today if the period holds
  /// it, else the period's first day.
  DateTime get suggestedMomentDate => contains(today) ? today : start;

  /// Friends' birthdays (including the day of birth) inside this period,
  /// oldest first. A friend without a birth year has a birthday (without an
  /// age) in every period that holds their day and month: the grid starts
  /// at the user's birth, so these never reach before it.
  List<FriendBirthday> birthdaysOf(Iterable<Friend> friends) {
    final result = <FriendBirthday>[];
    for (final friend in friends) {
      for (int year = start.year; year <= end.year; year++) {
        final local = Friend.birthdayDateInYear(friend.birthDate, year);
        final birthday = DateTime.utc(local.year, local.month, local.day);
        final age = friend.ageTurningIn(year);
        if ((age != null && age < 0) || !contains(birthday)) continue;
        result.add(FriendBirthday(
          friend: friend,
          age: age,
          date: birthday,
          isPast: birthday.isBefore(today),
          isToday: birthday == today,
        ));
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}

/// A friend's birthday that falls into a [LifePeriod].
class FriendBirthday {
  const FriendBirthday({
    required this.friend,
    required this.age,
    required this.date,
    required this.isPast,
    this.isToday = false,
  });

  final Friend friend;

  /// Null without a birth year.
  final int? age;
  final DateTime date;
  final bool isPast;
  final bool isToday;
}
