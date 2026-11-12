import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_route.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_due.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_inputs.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_result.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_turn.dart';

/// Decides whether the weekly moment shows and shows it: after a tap on the
/// Compass reminder ([forReminder]), as a catch-up on opening the app
/// ([catchUpIfDue]) or on request ([replay]). Injectable into the shell;
/// tests override [loadInputs], [markShown] or [show].
class WeekMomentLauncher {
  const WeekMomentLauncher();

  /// Pause after start or resume before the catch-up looks (a tap wins).
  static const Duration settle = Duration(milliseconds: 800);

  /// The tap on the reminder of [reminderDay] (null: the latest reminder
  /// of the rhythm, else today); shown once per reminder day.
  Future<WeekMomentResult> forReminder(
    BuildContext context, {
    DateTime? reminderDay,
    required DateTime now,
  }) async {
    final inputs = await loadInputs();
    if (!context.mounted) return WeekMomentResult.notShown;
    final day = reminderDay ?? _latestReminderDay(inputs, now);
    if (!inputs.showsOnTap(day)) return WeekMomentResult.notShown;
    return _markAndShow(context, inputs, day: day, now: now);
  }

  /// The moment for the latest reminder when it fired without a tap.
  Future<WeekMomentResult> catchUpIfDue(
    BuildContext context, {
    required DateTime now,
  }) async {
    final inputs = await loadInputs();
    if (!context.mounted) return WeekMomentResult.notShown;
    final reminder = inputs.latestReminder(now);
    if (reminder == null || !inputs.catchUpDue(now)) {
      return WeekMomentResult.notShown;
    }
    final day = WeekMomentDue.reminderDayOf(reminder);
    return _markAndShow(context, inputs, day: day, now: now);
  }

  /// The moment on request (Compass, Diagnostics): needs a birth date only
  /// and records nothing.
  Future<WeekMomentResult> replay(
    BuildContext context, {
    required DateTime now,
  }) async {
    final inputs = await loadInputs();
    if (!inputs.hasBirthDate || !context.mounted) {
      return WeekMomentResult.notShown;
    }
    return show(context, inputs, now: now);
  }

  /// Reads the services.
  Future<WeekMomentInputs> loadInputs() => WeekMomentInputs.load();

  /// Records the reminder [day] as shown.
  Future<void> markShown(DateTime day) => WeekMomentStore.markShown(day);

  /// Pushes the moment for [inputs] on [now]'s day; its card names the
  /// week of [reminderDay] (null: of [now]) and the one after it.
  Future<WeekMomentResult> show(
    BuildContext context,
    WeekMomentInputs inputs, {
    required DateTime now,
    DateTime? reminderDay,
  }) =>
      showWeekMoment(
        context,
        story: inputs.storyOn(now),
        address: inputs.address,
        turn: WeekTurn.on(reminderDay ?? now),
      );

  /// Marks before pushing, so a reminder shows its moment at most once.
  Future<WeekMomentResult> _markAndShow(
    BuildContext context,
    WeekMomentInputs inputs, {
    required DateTime day,
    required DateTime now,
  }) async {
    await markShown(day);
    if (!context.mounted) return WeekMomentResult.notShown;
    return show(context, inputs, now: now, reminderDay: day);
  }

  static DateTime _latestReminderDay(WeekMomentInputs inputs, DateTime now) =>
      WeekMomentDue.reminderDayOf(inputs.latestReminder(now) ?? now);
}
