import 'package:memento_mori_life_in_weeks/reminders/phase_check_in_planner.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';

/// When the weekly moment is due (pure, local time): after a tap on the
/// Compass reminder, or once as a catch-up when the app is opened soon after
/// a reminder fired without a tap.
class WeekMomentDue {
  WeekMomentDue._();

  static const int _daysPerInterval = 7 * PhaseCheckInPlanner.intervalWeeks;

  /// The day of a reminder time (date only).
  static DateTime reminderDayOf(DateTime time) =>
      DateTime(time.year, time.month, time.day);

  /// The latest reminder time at or before [now] for [rhythm]: the weekly
  /// rhythm fires every Sunday at [WeeklyReflectionPlanner.hour], the 4-weekly
  /// one every 4 weeks from [anchor]'s Sunday at the same hour. Null when off,
  /// without an anchor (4-weekly) or before the first check-in.
  static DateTime? latestReminder(DateTime now, ReminderRhythm rhythm,
      {DateTime? anchor}) {
    switch (rhythm) {
      case ReminderRhythm.weekly:
        return _latestSunday(now);
      case ReminderRhythm.every4Weeks:
        return anchor == null ? null : _latestCheckIn(now, anchor);
      case ReminderRhythm.off:
        return null;
    }
  }

  /// How long after a reminder the catch-up may still show.
  static Duration catchUpWindow(ReminderRhythm rhythm) =>
      rhythm == ReminderRhythm.every4Weeks
          ? const Duration(days: 7)
          : const Duration(days: 3);

  /// Whether the moment is shown on opening the app without a tap: the
  /// latest reminder fired within [catchUpWindow], on a day after [since]
  /// (never right after an install or update), and was not shown yet.
  static bool catchUpDue({
    required DateTime now,
    required ReminderRhythm rhythm,
    DateTime? anchor,
    required bool enabled,
    required bool onboarded,
    required bool hasBirthDate,
    DateTime? lastShown,
    required DateTime since,
  }) {
    if (!enabled || !onboarded || !hasBirthDate || !rhythm.isOn) return false;
    final reminder = latestReminder(now, rhythm, anchor: anchor);
    if (reminder == null) return false;
    if (!now.isBefore(reminder.add(catchUpWindow(rhythm)))) return false;
    final day = reminderDayOf(reminder);
    return day.isAfter(reminderDayOf(since)) && !_sameDay(lastShown, day);
  }

  /// Whether a tap on the reminder of [reminderDay] shows the moment.
  static bool showOnTap({
    required bool enabled,
    required bool hasBirthDate,
    DateTime? lastShown,
    required DateTime reminderDay,
  }) =>
      enabled && hasBirthDate && !_sameDay(lastShown, reminderDay);

  /// Latest Sunday at the reminder hour at or before [now].
  static DateTime _latestSunday(DateTime now) {
    final daysSinceSunday = (now.weekday - DateTime.sunday) % 7;
    final time = _atReminderHour(now, -daysSinceSunday);
    return time.isAfter(now) ? _atReminderHour(time, -7) : time;
  }

  /// Latest check-in (anchor Sunday + 4·k weeks, k >= 0) at or before [now].
  static DateTime? _latestCheckIn(DateTime now, DateTime anchor) {
    final week0 = PhaseCheckInPlanner.anchorSunday(anchor);
    final days = _daysBetween(week0, now);
    if (days < 0) return null;
    final steps = days ~/ _daysPerInterval;
    final time = _atReminderHour(week0, _daysPerInterval * steps);
    if (!time.isAfter(now)) return time;
    if (steps == 0) return null;
    return _atReminderHour(week0, _daysPerInterval * (steps - 1));
  }

  /// [day] moved by [days] calendar days, at the reminder hour (DST-safe).
  static DateTime _atReminderHour(DateTime day, int days) => DateTime(
      day.year, day.month, day.day + days, WeeklyReflectionPlanner.hour);

  /// Whole calendar days from [from] to [to].
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  static bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}
