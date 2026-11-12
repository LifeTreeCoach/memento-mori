import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_budget.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_fingerprints.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';

/// Title and body of a birthday notification.
class BirthdayReminderContent {
  final String title;
  final String body;

  const BirthdayReminderContent(this.title, this.body);
}

/// Whether [friend]'s reminder due today (day-of, or day-before when
/// [dayBefore]) was already shown today, so it must not be scheduled again.
typedef NotifiedToday = bool Function(Friend friend, {required bool dayBefore});

bool _neverNotified(Friend friend, {required bool dayBefore}) => false;

/// Schedules one-shot birthday notifications with the OS alarm manager.
///
/// For each friend the next two birthdays are scheduled (so reminders keep
/// working if the app is not opened for a year), capped by the platform's
/// budget ([ReminderBudget]). Everything is re-planned on app start, on
/// resume and after every relevant change, so age and text stay correct.
class BirthdayReminderScheduler {
  static const String payloadPrefix = 'birthday:';
  static const String testPayloadPrefix = 'birthday-test:';
  static const int idRangeStart = NotificationIds.scheduledBirthdayStart;
  static const int testNotificationId = NotificationIds.scheduledBirthdayTest;
  static const int _scheduledYears = 2;

  /// The "open the app to plan the next reminders" note (see [ReminderBudget]).
  static const int refreshNotificationId = NotificationIds.birthdayRefresh;

  /// Payload of the refresh note: no special action, its tap just opens the app.
  static const String refreshPayload = 'birthday-refresh';

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderFingerprints _fingerprints;
  final ReminderPlatform _platform;

  BirthdayReminderScheduler([
    FlutterLocalNotificationsPlugin? plugin,
    ReminderFingerprints? fingerprints,
    ReminderPlatform? platform,
  ])  : _plugin = plugin ?? NotificationService.plugin,
        _fingerprints = fingerprints ?? ReminderFingerprints(),
        _platform = platform ?? ReminderPlatform.current;

  // ---------------------------------------------------------------------------
  // Pure helpers (unit-tested)
  // ---------------------------------------------------------------------------

  /// Next reminder moment strictly after [now] for a birthday on [birthday],
  /// [daysBefore] days ahead of the birthday at [hour]:[minute] local time.
  /// Feb 29 birthdays fall on Feb 28 in non-leap years.
  static DateTime nextOccurrence(
    DateTime birthday,
    DateTime now, {
    int hour = 9,
    int minute = 0,
    int daysBefore = 0,
  }) {
    for (int year = now.year; ; year++) {
      final birthdayDate = Friend.birthdayDateInYear(birthday, year);
      final reminder = DateTime(
        birthdayDate.year,
        birthdayDate.month,
        birthdayDate.day - daysBefore,
        hour,
        minute,
      );
      if (reminder.isAfter(now)) return reminder;
    }
  }

  /// The next [count] reminder moments after [now] (see [nextOccurrence]).
  /// With [skipToday] a reminder due later today is left out (it was already
  /// shown today), so the following ones are returned instead.
  static List<DateTime> upcomingReminders(
    DateTime birthday,
    DateTime now, {
    int reminderMinutes = 9 * 60,
    int daysBefore = 0,
    bool skipToday = false,
    int count = _scheduledYears,
  }) {
    final reminders = <DateTime>[];
    DateTime after = now;
    while (reminders.length < count) {
      after = nextOccurrence(birthday, after,
          hour: reminderMinutes ~/ 60, minute: reminderMinutes % 60, daysBefore: daysBefore);
      if (skipToday && _isSameDay(after, now)) continue;
      reminders.add(after);
    }
    return reminders;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whether birthday reminders are scheduled for [friend] (per-friend toggle).
  static bool hasReminders(Friend friend) => friend.isActive && friend.notificationId > 0;

  /// Today's day-of reminder moment ([reminderMinutes] after midnight of [now]).
  static DateTime reminderTimeOn(DateTime now, int reminderMinutes) {
    return DateTime(now.year, now.month, now.day, reminderMinutes ~/ 60, reminderMinutes % 60);
  }

  /// Notification id for a friend's reminder. Each friend owns four ids:
  /// [yearOffset] 0/1 (next / following birthday) x day-of / day-before.
  static int notificationIdFor(
    int friendNotificationId, {
    int yearOffset = 0,
    bool dayBefore = false,
  }) {
    return idRangeStart + friendNotificationId * 4 + yearOffset * 2 + (dayBefore ? 1 : 0);
  }

  /// The age the friend turns on the birthday this reminder belongs to.
  static int ageOnBirthdayFor(DateTime birthDate, DateTime reminder, int daysBefore) {
    final birthdayDate = DateTime(reminder.year, reminder.month, reminder.day + daysBefore);
    return birthdayDate.year - birthDate.year;
  }

  /// [ageOnBirthdayFor] for [friend]; null without a birth year.
  static int? friendAgeOnBirthdayFor(Friend friend, DateTime reminder, int daysBefore) =>
      friend.hasBirthYear ? ageOnBirthdayFor(friend.birthDate, reminder, daysBefore) : null;

  /// Localized notification text; uses the friend's custom message when set.
  /// A null [age] (no birth year) gives an age-free text.
  static BirthdayReminderContent buildContent(
    Friend friend,
    int? age,
    AppLocalizations localizations, {
    bool dayBefore = false,
  }) {
    final replacements = {'name': friend.name, 'age': '$age'};
    final titleKey = dayBefore ? 'birthday_notification_title_tomorrow' : 'birthday_notification_title';
    final bodyKey = dayBefore ? 'birthday_notification_body_tomorrow' : 'birthday_notification_body_today';
    final title = localizations.translate(titleKey, replacements: replacements);
    final ageLine = age == null
        ? localizations.translate('${bodyKey}_noage', replacements: replacements)
        : localizations.plural(bodyKey, age, replacements: replacements);
    final customMessage = friend.customNotificationMessage?.trim() ?? '';
    final body = customMessage.isEmpty ? ageLine : '$customMessage\n\n$ageLine';
    return BirthdayReminderContent(title, body);
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  /// Brings the pending birthday reminders in line with [friends]: the
  /// upcoming reminders that fit the platform budget ([ReminderBudget]),
  /// plus the refresh note when some were left out. Only what changed is
  /// cancelled or scheduled (see [ReminderDiff]); each plugin call rewrites
  /// the plugin's whole pending list on Android, so this keeps a reschedule
  /// of many people fast.
  ///
  /// Reminders due later today that [notifiedToday] reports as already shown
  /// (catch-up or delivered earlier) are skipped, so moving the reminder time
  /// never notifies the same birthday twice in one day. Returns the plan.
  Future<BirthdayBudgetPlan> rescheduleAll(
    List<Friend> friends, {
    DateTime? now,
    NotifiedToday notifiedToday = _neverNotified,
  }) async {
    final plan = FriendsService.isBirthdayNotificationsEnabled()
        ? _plan(friends, now ?? DateTime.now(), notifiedToday)
        : BirthdayBudgetPlan.empty;
    final desired = _desiredNotifications(plan);
    final diff = ReminderDiff.compute(
      desired: desired,
      pending: await _pendingScheduledIds(),
      stored: await _fingerprints.load(),
    );
    for (final id in diff.toCancel) {
      await _plugin.cancel(id: id);
    }
    for (final notification in diff.toSchedule) {
      await _scheduleDesired(notification);
    }
    await _fingerprints.save(desired);
    return plan;
  }

  BirthdayBudgetPlan _plan(List<Friend> friends, DateTime now, NotifiedToday notifiedToday) {
    final all = ReminderBudget.occurrences(
      friends: friends,
      now: now,
      reminderMinutes: SettingsService.getBirthdayReminderMinutes(),
      dayBeforeEnabled: SettingsService.isBirthdayDayBeforeReminderEnabled(),
      notifiedToday: notifiedToday,
    );
    return ReminderBudget.select(all, limit: ReminderBudget.limitFor(_platform));
  }

  /// The notifications [plan] asks for, with text in the app language.
  static List<DesiredNotification> _desiredNotifications(BirthdayBudgetPlan plan) {
    final l10n = currentLocalizations();
    return [
      for (final reminder in plan.kept) _reminderNotification(reminder, l10n),
      if (plan.refreshAt case final refreshAt?) _refreshNotification(refreshAt, l10n),
    ];
  }

  static DesiredNotification _reminderNotification(
      BirthdayOccurrence reminder, AppLocalizations l10n) {
    final content = buildContent(reminder.friend, reminder.age, l10n, dayBefore: reminder.dayBefore);
    return DesiredNotification(
      id: reminder.id,
      when: _toLocalTz(reminder.at),
      title: content.title,
      body: content.body,
      payload: '$payloadPrefix${reminder.friend.id}',
    );
  }

  static DesiredNotification _refreshNotification(DateTime at, AppLocalizations l10n) {
    return DesiredNotification(
      id: refreshNotificationId,
      when: _toLocalTz(at),
      title: l10n.translate('birthday_refresh_title'),
      body: l10n.translate('birthday_refresh_body'),
      payload: refreshPayload,
    );
  }

  Future<void> _scheduleDesired(DesiredNotification notification) => _schedule(
        id: notification.id,
        when: notification.when,
        content: BirthdayReminderContent(notification.title, notification.body),
        payload: notification.payload,
      );

  /// Cancels every pending birthday reminder (identified by payload prefix)
  /// and the refresh note.
  Future<void> cancelAll() async {
    for (final id in await _pendingScheduledIds()) {
      await _plugin.cancel(id: id);
    }
  }

  /// Ids of the scheduled birthday reminders not delivered yet (the plugin
  /// drops a scheduled notification from its pending list once it is shown).
  Future<Set<int>> pendingReminderIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return {
      for (final request in pending)
        if (_isReminderPayload(request.payload)) request.id,
    };
  }

  /// Pending reminders plus the refresh note: everything [rescheduleAll] owns.
  Future<Set<int>> _pendingScheduledIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return {
      for (final request in pending)
        if (_isReminderPayload(request.payload) || request.payload == refreshPayload)
          request.id,
    };
  }

  static bool _isReminderPayload(String? payload) => payload?.startsWith(payloadPrefix) ?? false;

  /// Schedules a birthday-style reminder for [friend] at now + [delay]
  /// through the same code path as real reminders (diagnostics).
  Future<void> scheduleTest(Friend friend, Duration delay) async {
    final age = friendAgeOnBirthdayFor(friend, DateTime.now(), 0);
    final content = buildContent(friend, age, currentLocalizations());
    await _schedule(
      id: testNotificationId,
      when: tz.TZDateTime.now(tz.local).add(delay),
      content: content,
      payload: '$testPayloadPrefix${friend.id}',
    );
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required BirthdayReminderContent content,
    required String payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      notificationDetails: _notificationDetails(content.body),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: content.title,
      body: content.body,
      payload: payload,
    );
  }

  static tz.TZDateTime _toLocalTz(DateTime local) {
    return tz.TZDateTime(tz.local, local.year, local.month, local.day, local.hour, local.minute);
  }

  /// Localizations of the app language (no BuildContext needed).
  static AppLocalizations currentLocalizations() {
    return AppLocalizations(Locale(SettingsService.getLanguage()));
  }

  static NotificationDetails _notificationDetails(String body) =>
      NotificationService.birthdayDetails(currentLocalizations(), body);
}
