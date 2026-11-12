/// The turn of the week that the weekly moment closes: the ISO calendar
/// week that just ended and the one that follows it. Pure, no clock.
library;

import 'package:memento_mori_life_in_weeks/compass/weekly_question.dart';

/// The ISO week that ended with the latest Sunday on or before a day, and
/// the week after it (52 or 53 turns into 1 at the turn of a year).
class WeekTurn {
  const WeekTurn({required this.endedWeek, required this.nextWeek});

  /// The turn seen from [day]: its own week when it is a Sunday (the
  /// reminder's day), else the week of the Sunday before.
  factory WeekTurn.on(DateTime day) {
    final sunday = lastSundayOnOrBefore(day);
    final monday = DateTime(sunday.year, sunday.month, sunday.day + 1);
    return WeekTurn(
      endedWeek: isoWeekOf(sunday).week,
      nextWeek: isoWeekOf(monday).week,
    );
  }

  /// The latest Sunday on or before [day] (date only).
  static DateTime lastSundayOnOrBefore(DateTime day) =>
      DateTime(day.year, day.month, day.day - day.weekday % DateTime.daysPerWeek);

  /// ISO number of the week that just ended (1-53).
  final int endedWeek;

  /// ISO number of the week that begins (1-53).
  final int nextWeek;

  @override
  bool operator ==(Object other) =>
      other is WeekTurn &&
      other.endedWeek == endedWeek &&
      other.nextWeek == nextWeek;

  @override
  int get hashCode => Object.hash(endedWeek, nextWeek);

  @override
  String toString() => 'WeekTurn($endedWeek -> $nextWeek)';
}
