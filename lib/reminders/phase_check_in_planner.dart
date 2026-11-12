import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';
import 'package:timezone/timezone.dart' as tz;

/// Plans the phase check-in of the "every 4 weeks" rhythm: Sundays at 19:00,
/// four weeks apart, counted from a stable anchor, so rescheduling never
/// shifts the dates (pure; [ReminderService] schedules the result).
///
/// Uses the weekly reflection's ids and payload: only one rhythm is ever
/// scheduled at a time.
class PhaseCheckInPlanner {
  PhaseCheckInPlanner._();

  static const int count = 3;
  static const int intervalWeeks = 4;
  static const int hour = WeeklyReflectionPlanner.hour;
  static const String payload = WeeklyReflectionPlanner.payload;

  /// The Sunday on or after [anchor]: week 0 of the rhythm (date only).
  static DateTime anchorSunday(DateTime anchor) {
    final daysUntilSunday = (DateTime.sunday - anchor.weekday) % 7;
    return DateTime(anchor.year, anchor.month, anchor.day + daysUntilSunday);
  }

  /// The next [count] check-in times strictly after [now]: Sundays at 19:00
  /// whose distance to [anchor]'s week is a multiple of 4 weeks.
  static List<tz.TZDateTime> nextCheckInTimes(
    tz.TZDateTime now,
    DateTime anchor, {
    int count = count,
  }) {
    final week0 = anchorSunday(anchor);
    final firstSunday = WeeklyReflectionPlanner.nextTime(now);
    final weeks = _daysBetween(week0, firstSunday) ~/ 7;
    final firstWeek = weeks <= 0 ? 0 : _roundUpToInterval(weeks);
    return [
      for (var i = 0; i < count; i++)
        tz.TZDateTime(now.location, week0.year, week0.month,
            week0.day + 7 * (firstWeek + intervalWeeks * i), hour),
    ];
  }

  /// Open "do" intentions of [phase], oldest first.
  static List<Intention> openDoTasksIn(
      LifePhase phase, Iterable<Intention> intentions) {
    final tasks = intentions
        .where((i) =>
            i.isOpen && i.kind == IntentionKind.doTask && i.phaseId == phase.id)
        .toList();
    // List.sort is not stable; keep the stored order on equal days.
    final order = {for (var i = 0; i < tasks.length; i++) tasks[i]: i};
    tasks.sort((a, b) {
      final byDay = a.createdAt.compareTo(b.createdAt);
      return byDay != 0 ? byDay : order[a]!.compareTo(order[b]!);
    });
    return tasks;
  }

  /// What the check-in texts depend on, to reschedule only when it changes.
  static String signature(LifePhase? phase, List<Intention> openDoTasks) {
    if (phase == null) return '';
    final titles = openDoTasks.map((i) => i.title).join('\u0001');
    return '${phase.id}|${phase.name}|${phase.preset?.name}|$titles';
  }

  /// The check-in notifications after [now], with ids 10.. of the weekly
  /// reflection range, in the language of [l10n].
  static List<WeeklyReflection> plan({
    required tz.TZDateTime now,
    required DateTime anchor,
    required AppLocalizations l10n,
    LifePhase? phase,
    List<Intention> openDoTasks = const [],
    DateTime? birthDate,
    bool gentleOnly = false,
    bool Function(DateTime date)? isSwapped,
  }) {
    final times = nextCheckInTimes(now, anchor);
    return [
      for (var i = 0; i < times.length; i++)
        checkInAt(
          times[i],
          id: NotificationIds.weeklyReflectionStart + i,
          l10n: l10n,
          phase: phase,
          openDoTasks: openDoTasks,
          birthDate: birthDate,
          gentleOnly: gentleOnly,
          swapped: isSwapped?.call(_day(times[i])) ?? false,
        ),
    ];
  }

  /// The check-in for [time]: asks about the oldest open "do" intention of
  /// [phase] and what was good in it; without a phase, the question of the
  /// week (as the weekly reflection asks it).
  static WeeklyReflection checkInAt(
    tz.TZDateTime time, {
    required int id,
    required AppLocalizations l10n,
    LifePhase? phase,
    List<Intention> openDoTasks = const [],
    DateTime? birthDate,
    bool gentleOnly = false,
    bool swapped = false,
  }) {
    return WeeklyReflection(
      id: id,
      date: time,
      title: l10n.translate('phase_check_in_title'),
      body: phase == null
          ? WeeklyReflectionPlanner.questionText(
              WeeklyReflectionPlanner.questionFor(_day(time),
                  birthDate: birthDate,
                  gentleOnly: gentleOnly,
                  swapped: swapped),
              l10n)
          : _phaseBody(l10n, phaseDisplayName(phase, l10n), openDoTasks),
    );
  }

  static String _phaseBody(
      AppLocalizations l10n, String phase, List<Intention> openDoTasks) {
    if (openDoTasks.isEmpty) {
      return l10n.translate('phase_check_in_body',
          replacements: {'phase': phase});
    }
    return l10n.translate('phase_check_in_body_task',
        replacements: {'phase': phase, 'title': openDoTasks.first.title});
  }

  static int _roundUpToInterval(int weeks) =>
      (weeks + intervalWeeks - 1) ~/ intervalWeeks * intervalWeeks;

  /// Whole calendar days from [from] to [to] (DST-safe).
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  static DateTime _day(DateTime time) =>
      DateTime(time.year, time.month, time.day);
}
