import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/weekly_question.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:timezone/timezone.dart' as tz;

/// One scheduled weekly reflection notification.
class WeeklyReflection {
  const WeeklyReflection({
    required this.id,
    required this.date,
    required this.title,
    required this.body,
  });

  final int id;
  final tz.TZDateTime date;
  final String title;

  /// The Compass question of the week of [date].
  final String body;
}

/// Plans the weekly reflection: one-off notifications on the next
/// [count] Sundays at 19:00, each carrying the Compass question of its week
/// (pure; [ReminderService] schedules the result).
class WeeklyReflectionPlanner {
  WeeklyReflectionPlanner._();

  static const int count = NotificationIds.weeklyReflectionCount;
  static const int hour = 19;

  /// Opens the Compass tab when the notification is tapped.
  static const String payload = 'compass';

  /// Prefix of the dated payload (`compass:yyyy-MM-dd`), see [payloadFor].
  static const String payloadPrefix = '$payload:';

  /// The payload of a Compass reminder shown at [date]: opens the Compass
  /// tab and carries the reminder's local date (`compass:yyyy-MM-dd`).
  static String payloadFor(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$payloadPrefix$year-${two(date.month)}-${two(date.day)}';
  }

  /// Next Sunday 19:00 strictly after [now].
  static tz.TZDateTime nextTime(tz.TZDateTime now) {
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    var time = tz.TZDateTime(
        now.location, now.year, now.month, now.day + daysUntilSunday, hour);
    if (!time.isAfter(now)) {
      time = tz.TZDateTime(
          now.location, time.year, time.month, time.day + 7, hour);
    }
    return time;
  }

  /// The next [count] reflection times after [now], one week apart.
  static List<tz.TZDateTime> nextTimes(tz.TZDateTime now) {
    final first = nextTime(now);
    return [
      for (var week = 0; week < count; week++)
        tz.TZDateTime(first.location, first.year, first.month,
            first.day + 7 * week, hour),
    ];
  }

  /// The question of the week of [date], as the Compass tab shows it.
  /// Without [birthDate] the Compass tab's neutral age is used; phase
  /// questions are only chosen with the [phase] lived on [date].
  static CompassPrompt questionFor(
    DateTime date, {
    required DateTime? birthDate,
    required bool gentleOnly,
    bool swapped = false,
    LifePhase? phase,
  }) {
    final ageYears = birthDate == null
        ? compassDefaultAgeYears
        : LifeCalculator(birthDate: birthDate, now: date).ageYears.toDouble();
    return questionForWeek(
      date,
      ageYears: ageYears,
      gentleOnly: gentleOnly,
      swap: swapped ? 1 : 0,
      hasPhase: phase != null,
    );
  }

  /// [question] in the language of [l10n], with `{phase}` filled from
  /// [phase] (phase questions are only chosen when it is set).
  static String questionText(
    CompassPrompt question,
    AppLocalizations l10n, {
    LifePhase? phase,
  }) {
    return question.textFor(
      l10n.locale.languageCode,
      replacements: {
        if (phase != null) 'phase': phaseDisplayName(phase, l10n),
      },
    );
  }

  /// The notification of every time in [nextTimes], in the language of
  /// [l10n]. [isSwapped] tells whether the user asked for another question
  /// in the week of a date; [phaseAt] gives the life phase lived on a date
  /// (null = none), so each Sunday asks with the phase of its own day.
  static List<WeeklyReflection> plan({
    required tz.TZDateTime now,
    required DateTime? birthDate,
    required bool gentleOnly,
    required AppLocalizations l10n,
    bool Function(DateTime date)? isSwapped,
    LifePhase? Function(DateTime date)? phaseAt,
  }) {
    final times = nextTimes(now);
    return [
      for (var i = 0; i < times.length; i++)
        reflectionAt(
          times[i],
          id: NotificationIds.weeklyReflectionStart + i,
          birthDate: birthDate,
          gentleOnly: gentleOnly,
          l10n: l10n,
          swapped: isSwapped?.call(_day(times[i])) ?? false,
          phase: phaseAt?.call(_day(times[i])),
        ),
    ];
  }

  /// The reflection notification for [time] with [id]; [phase] is the
  /// life phase lived on that day (null = none).
  static WeeklyReflection reflectionAt(
    tz.TZDateTime time, {
    required int id,
    required DateTime? birthDate,
    required bool gentleOnly,
    required AppLocalizations l10n,
    bool swapped = false,
    LifePhase? phase,
  }) {
    final question = questionFor(_day(time),
        birthDate: birthDate,
        gentleOnly: gentleOnly,
        swapped: swapped,
        phase: phase);
    return WeeklyReflection(
      id: id,
      date: time,
      title: l10n.translate('weekly_reflection_title'),
      body: questionText(question, l10n, phase: phase),
    );
  }

  static DateTime _day(DateTime time) =>
      DateTime(time.year, time.month, time.day);
}
