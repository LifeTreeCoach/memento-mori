import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:memento_mori_life_in_weeks/reminders/birthday_catch_up.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/lost_alarm_check.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/phase_check_in_planner.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_fingerprints.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_install_marker.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/scheduled_alarm_probe.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';

class ReminderService {
  /// Id of the former repeating weekly reflection notification; cancelled
  /// whenever the weekly reflection is (re)scheduled (all id ranges are
  /// listed in [NotificationIds]).
  static const int weeklyReminderId = NotificationIds.weeklyReminder;

  /// Payload of the former repeating weekly reflection; tapping such a
  /// notification also opens the Compass tab.
  static const String weeklyReminderPayload = 'weekly_reminder';

  /// Bare payload of the Compass reminders (scheduled by earlier versions;
  /// new ones carry their date, see [WeeklyReflectionPlanner.payloadFor]):
  /// tapping it opens the Compass tab.
  static const String compassPayload = WeeklyReflectionPlanner.payload;

  static Future<void> initialize() async {
    if (!await forgetScheduledRemindersIfRestored()) {
      await forgetScheduledRemindersIfAlarmsLost();
    }
    await _createChannels();
  }

  /// Android only: clears the birthday reminder fingerprints when the OS
  /// lost alarms the plugin still lists as pending (a "force stop" cancels
  /// them), so the next pass re-arms everything (see [LostAlarmCheck]).
  /// No-op on other platforms. Returns whether the fingerprints were cleared.
  static Future<bool> forgetScheduledRemindersIfAlarmsLost({LostAlarmCheck? check}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    return (check ??
            LostAlarmCheck(
              probe: const MethodChannelScheduledAlarmProbe(),
              pendingIds: BirthdayReminderScheduler().pendingReminderIds,
            ))
        .run();
  }

  /// Clears the birthday reminder fingerprints when [ReminderInstallMarker]
  /// finds no marker (restored app data, first launch or a cleared cache):
  /// the OS never restores scheduled notifications, so the next pass must
  /// cancel and schedule everything instead of trusting restored state.
  /// Returns whether the fingerprints were cleared.
  static Future<bool> forgetScheduledRemindersIfRestored({
    ReminderInstallMarker? marker,
    ReminderFingerprints? fingerprints,
  }) async {
    try {
      if (!await (marker ?? ReminderInstallMarker()).checkAndMark()) return false;
      await (fingerprints ?? ReminderFingerprints()).clear();
      return true;
    } catch (e) {
      debugPrint('Error checking the reminder install marker: $e');
      return false;
    }
  }

  /// Creates the notification channels named in the current app language.
  static Future<void> _createChannels() async {
    await NotificationService.createChannels(BirthdayReminderScheduler.currentLocalizations());
  }

  /// Schedules the Compass reminders of the chosen [rhythm] (entry point
  /// kept from when only the weekly reflection existed); see
  /// [scheduleCompassReminders].
  static Future<void> scheduleWeeklyReminder() => scheduleCompassReminders();

  /// Schedules the Compass reminders of the chosen [rhythm], replacing
  /// earlier ones (including the former repeating notification): the weekly
  /// reflection ([WeeklyReflectionPlanner]), the phase check-in every
  /// 4 weeks ([PhaseCheckInPlanner]) or nothing.
  static Future<void> scheduleCompassReminders() async {
    final reminders = switch (rhythm()) {
      ReminderRhythm.weekly => await _planWeeklyReflections(),
      ReminderRhythm.every4Weeks => await _planPhaseCheckIns(),
      ReminderRhythm.off => const <WeeklyReflection>[],
    };
    await cancelWeeklyReminder();
    for (final reminder in reminders) {
      await NotificationService.plugin.zonedSchedule(
        id: reminder.id,
        scheduledDate: reminder.date,
        notificationDetails: _weeklyNotificationDetails(reminder.body),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: reminder.title,
        body: reminder.body,
        payload: WeeklyReflectionPlanner.payloadFor(reminder.date),
      );
    }
  }

  /// The weekly reflection: one-off notifications on the next Sundays at
  /// 19:00 local time, each with the Compass question of its week in the
  /// app language (phase questions name the phase lived on that Sunday).
  static Future<List<WeeklyReflection>> _planWeeklyReflections() async {
    await CompassService.initialize();
    return WeeklyReflectionPlanner.plan(
      now: tz.TZDateTime.now(tz.local),
      birthDate: SettingsService.getBirthDate(),
      gentleOnly: CompassService.gentleOnly,
      l10n: BirthdayReminderScheduler.currentLocalizations(),
      isSwapped: (date) => CompassService.weekState(date).swapped,
      phaseAt: (date) => CompassService.currentPhase(today: date),
    );
  }

  /// The phase check-ins: every 4 weeks from the rhythm's anchor, naming
  /// the current phase and its oldest open "do" intention.
  static Future<List<WeeklyReflection>> _planPhaseCheckIns() async {
    await CompassService.initialize();
    final phase = CompassService.currentPhase();
    return PhaseCheckInPlanner.plan(
      now: tz.TZDateTime.now(tz.local),
      anchor: SettingsService.getRhythmAnchor() ?? DateTime.now(),
      l10n: BirthdayReminderScheduler.currentLocalizations(),
      phase: phase,
      openDoTasks: _openDoTasks(phase),
      birthDate: SettingsService.getBirthDate(),
      gentleOnly: CompassService.gentleOnly,
      isSwapped: (date) => CompassService.weekState(date).swapped,
    );
  }

  static List<Intention> _openDoTasks(LifePhase? phase) => phase == null
      ? const []
      : PhaseCheckInPlanner.openDoTasksIn(
          phase, CompassService.data.intentions);

  /// Cancels every weekly reflection (and the former repeating one).
  static Future<void> cancelWeeklyReminder() async {
    await NotificationService.plugin.cancel(id: weeklyReminderId);
    for (var i = 0; i < NotificationIds.weeklyReflectionCount; i++) {
      await NotificationService.plugin
          .cancel(id: NotificationIds.weeklyReflectionStart + i);
    }
  }

  /// Next Sunday 19:00 strictly after [now].
  static tz.TZDateTime nextWeeklyReminderTime(tz.TZDateTime now) =>
      WeeklyReflectionPlanner.nextTime(now);

  static NotificationDetails _weeklyNotificationDetails(String body) =>
      NotificationService.compassDetails(
          BirthdayReminderScheduler.currentLocalizations(), body);

  /// Reschedules the Compass reminders if they are on (their texts depend
  /// on the birth date, "gentle only", this week's swap and, every 4 weeks,
  /// the current phase); errors are logged.
  static Future<void> refreshWeeklyReflection() async {
    if (!isReminderEnabled()) return;
    try {
      await scheduleCompassReminders();
    } catch (e) {
      debugPrint('Error scheduling the weekly reflection: $e');
    }
  }

  /// Keeps the scheduled texts in step with the Compass: reschedules when
  /// "gentle only" is toggled or this week's question is swapped, in the
  /// weekly rhythm when the life phases change (phase questions name them)
  /// and in the 4-week rhythm when the current phase or its open "do"
  /// intentions change (other Compass changes are ignored).
  static void attachToCompassService() {
    var questionInputs = _compassQuestionInputs();
    CompassService.revision.addListener(() {
      final inputs = _compassQuestionInputs();
      if (inputs == questionInputs) return;
      questionInputs = inputs;
      unawaited(refreshWeeklyReflection());
    });
  }

  static String _compassQuestionInputs() =>
      '${CompassService.gentleOnly}|'
      '${CompassService.weekState(DateTime.now()).swapped}|'
      '${_phaseQuestionInputs()}|'
      '${_phaseCheckInInputs()}';

  /// The phases the weekly reflection's phase questions may name.
  static String _phaseQuestionInputs() {
    if (rhythm() != ReminderRhythm.weekly) return '';
    return [
      for (final p in CompassService.data.phases)
        '${p.id}|${p.name}|${p.preset?.name}|${p.start.toIso8601String()}',
    ].join('\u0001');
  }

  static String _phaseCheckInInputs() {
    if (rhythm() != ReminderRhythm.every4Weeks) return '';
    final phase = CompassService.currentPhase();
    return PhaseCheckInPlanner.signature(phase, _openDoTasks(phase));
  }

  /// Diagnostics: shows the Compass reminder of the chosen rhythm right
  /// now (see [immediateCompassReminder]).
  static Future<void> sendCompassQuestionNow() async {
    try {
      await CompassService.initialize();
      final now = tz.TZDateTime.now(tz.local);
      final reminder = immediateCompassReminder(now);
      await NotificationService.plugin.show(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        notificationDetails: _weeklyNotificationDetails(reminder.body),
        payload: WeeklyReflectionPlanner.payloadFor(now),
      );
    } catch (e) {
      debugPrint('Error sending the Compass question: $e');
    }
  }

  /// The Compass reminder as it would arrive at [now]: every 4 weeks the
  /// phase check-in (current phase and its oldest open "do" intention),
  /// otherwise this week's reflection with its Compass question. Needs an
  /// initialized [CompassService].
  @visibleForTesting
  static WeeklyReflection immediateCompassReminder(tz.TZDateTime now) {
    const id = NotificationIds.immediateCompassQuestion;
    final l10n = BirthdayReminderScheduler.currentLocalizations();
    final birthDate = SettingsService.getBirthDate();
    final swapped = CompassService.weekState(now).swapped;
    if (rhythm() == ReminderRhythm.every4Weeks) {
      final phase = CompassService.currentPhase(today: now);
      return PhaseCheckInPlanner.checkInAt(
        now,
        id: id,
        l10n: l10n,
        phase: phase,
        openDoTasks: _openDoTasks(phase),
        birthDate: birthDate,
        gentleOnly: CompassService.gentleOnly,
        swapped: swapped,
      );
    }
    return WeeklyReflectionPlanner.reflectionAt(
      now,
      id: id,
      birthDate: birthDate,
      gentleOnly: CompassService.gentleOnly,
      l10n: l10n,
      swapped: swapped,
      phase: CompassService.currentPhase(today: now),
    );
  }

  /// Whether any Compass reminder is on (rhythm weekly or every 4 weeks).
  static bool isReminderEnabled() {
    return SettingsService.isWeeklyReminderEnabled();
  }

  /// Legacy switch: on = weekly (or keeps every 4 weeks), off = off.
  static Future<void> setReminderEnabled(bool enabled) async {
    SettingsService.setWeeklyReminderEnabled(enabled);
    
    if (enabled) {
      await scheduleCompassReminders();
    } else {
      await cancelWeeklyReminder();
    }
  }

  /// The chosen Compass reminder rhythm.
  static ReminderRhythm rhythm() => SettingsService.getReminderRhythm();

  /// Stores [rhythm] and schedules (or cancels) its reminders. The choice
  /// is saved first, so it sticks even if scheduling fails (logged).
  static Future<void> setRhythm(ReminderRhythm rhythm) async {
    await SettingsService.setReminderRhythm(rhythm);
    try {
      await scheduleCompassReminders();
    } catch (e) {
      debugPrint('Error scheduling the Compass reminders: $e');
    }
  }

  /// Re-schedules every reminder; notification texts are localized at
  /// scheduling time, so call this after the language changes (it also
  /// renames the notification channels).
  static Future<void> rescheduleAll() async {
    await _createChannels();
    await refreshBirthdayReminders();
    if (isReminderEnabled()) await scheduleCompassReminders();
  }

  // Birthday reminder functionality

  /// Re-plans all birthday reminders from the current friends list.
  /// Called on app start, on resume ([refreshBirthdayRemindersOnResume])
  /// and whenever friends or reminder settings change. Runs one at a time,
  /// so overlapping triggers never interleave their plugin calls.
  static Future<void> refreshBirthdayReminders() {
    final run = _birthdayRefreshTail.then((_) => _refreshBirthdayReminders());
    _birthdayRefreshTail = run;
    return run;
  }

  static Future<void> _birthdayRefreshTail = Future.value();

  /// When the birthday reminders were last re-planned (this process).
  static DateTime? _lastBirthdayRefresh;

  /// Minimum time between two re-plans on resume (same day).
  static const Duration resumeRefreshInterval = Duration(hours: 6);

  /// Re-plans the birthday reminders when the app comes back to the
  /// foreground, at most every [resumeRefreshInterval] unless the date
  /// changed: the reminder budget only covers the soonest birthdays, so the
  /// next ones get planned while the app is used.
  static Future<void> refreshBirthdayRemindersOnResume() async {
    if (!shouldRefreshOnResume(_lastBirthdayRefresh, DateTime.now())) return;
    await refreshBirthdayReminders();
  }

  /// Whether a resume at [now] re-plans, after the last re-plan at [last].
  @visibleForTesting
  static bool shouldRefreshOnResume(DateTime? last, DateTime now) {
    if (last == null) return true;
    final sameDay = last.year == now.year && last.month == now.month && last.day == now.day;
    return !sameDay || now.difference(last) >= resumeRefreshInterval;
  }

  static Future<void> _refreshBirthdayReminders() async {
    try {
      final now = DateTime.now();
      _lastBirthdayRefresh = now;
      final friends = await FriendsService.getAllFriends();
      final scheduler = BirthdayReminderScheduler();
      // Queried before the reschedule replaces them: an overdue reminder that
      // is still pending was not delivered yet (inexact alarms).
      final pendingIds = await scheduler.pendingReminderIds();
      final state = await _catchUpTodaysBirthdays(friends, pendingIds, now);
      final plan = await scheduler.rescheduleAll(
        friends,
        now: now,
        notifiedToday: (friend, {required dayBefore}) =>
            state.isNotifiedToday(friend, now, dayBefore: dayBefore),
      );
      // Only reminders within the budget are pending; the catch-up must
      // treat the others as missed, not as delivered.
      await BirthdayCatchUpStore().save(state.withScheduled(plan.kept));
    } catch (e) {
      debugPrint('Error scheduling birthday reminders: $e');
    }
  }

  /// Shows today's birthdays whose reminder time passed before a reminder
  /// could be scheduled or was delivered, and overdue day-before reminders
  /// still pending (see [BirthdayCatchUpPolicy]); must run before the
  /// reschedule, which replaces pending reminders and skips today's past one.
  static Future<BirthdayCatchUpState> _catchUpTodaysBirthdays(
      List<Friend> friends, Set<int> pendingIds, DateTime now) {
    return BirthdayCatchUp().run(
      friends: friends,
      now: now,
      reminderMinutes: SettingsService.getBirthdayReminderMinutes(),
      remindersEnabled: FriendsService.isBirthdayNotificationsEnabled(),
      dayBeforeEnabled: SettingsService.isBirthdayDayBeforeReminderEnabled(),
      pendingIds: pendingIds,
      show: sendBirthdayNotification,
      showDayBefore: sendDayBeforeBirthdayNotification,
    );
  }

  /// Diagnostics: schedules a birthday reminder [delay] from now using the
  /// same scheduling path as real reminders, for a neutral sample person
  /// whose birthday is today (so name, age and "today" always agree).
  static Future<void> scheduleTestBirthdayReminder(Duration delay) async {
    await BirthdayReminderScheduler().scheduleTest(sampleFriend(DateTime.now()), delay);
  }

  /// Sample person "Alex" turning 30 on the day of [now] (diagnostics).
  @visibleForTesting
  static Friend sampleFriend(DateTime now) {
    return Friend(
      id: 'test',
      name: 'Alex',
      birthDate: DateTime(now.year - 30, now.month, now.day),
      createdDate: now,
      lastUpdated: now,
    );
  }

  /// Show a notification right now for every friend whose birthday is today
  static Future<void> checkTodaysBirthdays() async {
    try {
      await FriendsService.initialize();
      for (final friend in FriendsService.getTodaysBirthdays()) {
        await sendBirthdayNotification(friend);
      }
    } catch (e) {
      debugPrint('Error checking birthdays: $e');
    }
  }

  /// Shows the birthday notification of [friend] right now.
  static Future<void> sendBirthdayNotification(Friend friend) async {
    final content = BirthdayReminderScheduler.buildContent(
      friend,
      friend.getCurrentAge(),
      BirthdayReminderScheduler.currentLocalizations(),
    );
    await _showBirthdayNotification(
        content, NotificationIds.immediateBirthday(friend.notificationId),
        friend: friend);
  }

  /// Shows the "birthday tomorrow" notification of [friend] right now.
  static Future<void> sendDayBeforeBirthdayNotification(Friend friend) async {
    final age = BirthdayReminderScheduler.friendAgeOnBirthdayFor(friend, DateTime.now(), 1);
    final content = BirthdayReminderScheduler.buildContent(
      friend,
      age,
      BirthdayReminderScheduler.currentLocalizations(),
      dayBefore: true,
    );
    await _showBirthdayNotification(
        content, NotificationIds.immediateBirthday(friend.notificationId),
        friend: friend);
  }

  /// A tap opens [friend]'s detail, like a scheduled reminder's.
  static Future<void> _showBirthdayNotification(
      BirthdayReminderContent content, int id, {Friend? friend}) async {
    final details = NotificationService.birthdayDetails(
        BirthdayReminderScheduler.currentLocalizations(), content.body);
    await NotificationService.plugin.show(
      id: id,
      title: content.title,
      body: content.body,
      notificationDetails: details,
      payload: friend == null
          ? null
          : '${BirthdayReminderScheduler.payloadPrefix}${friend.id}',
    );
  }

  /// Check if birthday notifications are enabled
  static bool isBirthdayNotificationsEnabled() {
    return FriendsService.isBirthdayNotificationsEnabled();
  }

  /// Enable/disable birthday notifications
  /// (FriendsService notifies its change listener, which reschedules reminders.)
  static Future<void> setBirthdayNotificationsEnabled(bool enabled) async {
    await FriendsService.setBirthdayNotificationsEnabled(enabled);
  }

  /// Send a test notification to verify notifications are working
  static Future<void> sendTestNotification() async {
    final l10n = BirthdayReminderScheduler.currentLocalizations();
    final content = BirthdayReminderContent(
      l10n.translate('test_notification_title'),
      l10n.translate('test_notification_body'),
    );
    try {
      await _showBirthdayNotification(content, NotificationIds.immediateTest);
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }
}
