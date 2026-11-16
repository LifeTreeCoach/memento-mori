import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_budget.dart';
import 'package:memento_mori_life_in_weeks/security/personal_store.dart';

/// What the catch-up remembers between reschedules.
class BirthdayCatchUpState {
  /// Marker key (see [BirthdayCatchUpPolicy.markerKeys]) -> day (yyyy-MM-dd)
  /// on which that friend's birthday was already notified (by the scheduled
  /// reminder or by a catch-up).
  final Map<String, String> notifiedOn;

  /// Marker key -> day (yyyy-MM-dd) on which an overdue day-before reminder
  /// was shown by a catch-up.
  final Map<String, String> notifiedDayBeforeOn;

  /// Marker key -> next day-of reminder moment scheduled at the last reschedule.
  final Map<String, DateTime> scheduledDayOf;

  /// Marker key -> next day-before reminder moment scheduled at the last reschedule.
  final Map<String, DateTime> scheduledDayBefore;

  const BirthdayCatchUpState({
    this.notifiedOn = const {},
    this.notifiedDayBeforeOn = const {},
    this.scheduledDayOf = const {},
    this.scheduledDayBefore = const {},
  });

  /// This state with the next scheduled moments taken from the reminders
  /// actually scheduled ([kept], see [ReminderBudget]): a reminder left out
  /// by the budget never fires, so on its day it must count as missed
  /// (caught up), not as delivered.
  BirthdayCatchUpState withScheduled(Iterable<BirthdayOccurrence> kept) {
    Map<String, DateTime> next({required bool dayBefore}) => {
          for (final reminder in kept)
            if (reminder.yearOffset == 0 && reminder.dayBefore == dayBefore)
              for (final key in BirthdayCatchUpPolicy.markerKeys(reminder.friend))
                key: reminder.at,
        };
    return BirthdayCatchUpState(
      notifiedOn: notifiedOn,
      notifiedDayBeforeOn: notifiedDayBeforeOn,
      scheduledDayOf: next(dayBefore: false),
      scheduledDayBefore: next(dayBefore: true),
    );
  }

  /// Whether [friend]'s day-of (or, with [dayBefore], day-before) reminder
  /// was already shown on the day of [now] (see [NotifiedToday]).
  bool isNotifiedToday(Friend friend, DateTime now, {required bool dayBefore}) {
    final markers = dayBefore ? notifiedDayBeforeOn : notifiedOn;
    final today = BirthdayCatchUpPolicy.dayKey(now);
    return BirthdayCatchUpPolicy.markerKeys(friend).any((key) => markers[key] == today);
  }
}

/// Result of [BirthdayCatchUpPolicy.plan]: friends to notify now and the
/// state to persist afterwards.
class BirthdayCatchUpPlan {
  final List<Friend> toShow;
  final List<Friend> toShowDayBefore;
  final BirthdayCatchUpState nextState;

  const BirthdayCatchUpPlan(this.toShow, this.nextState, {this.toShowDayBefore = const []});
}

/// Decides which birthdays of today missed their day-of reminder.
///
/// Today's scheduled reminder is skipped as past once its time has gone by,
/// so a friend added (or the app first opened) after the reminder time would
/// otherwise get no notification until next year. Each friend is caught up
/// at most once per day, and never when the scheduled reminder already fired.
///
/// Reminders are inexact, so they may still be undelivered minutes after their
/// time; the reschedule would then cancel them. A reminder therefore only
/// counts as fired once its time passed AND its id is no longer in
/// [pendingIds] (the plugin drops shown notifications from its pending list).
/// An overdue day-before reminder that is still pending is shown as long as
/// it is still the day before the birthday.
///
/// Markers are kept under the friend's id and identity (name + birth date),
/// so a friend deleted and re-imported (new id) is not notified twice.
class BirthdayCatchUpPolicy {
  BirthdayCatchUpPolicy._();

  static final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');

  static String dayKey(DateTime day) => _dayFormat.format(day);

  /// Keys under which [friend]'s markers are stored: the id and the identity
  /// (which survives a delete + re-import with a new id).
  static List<String> markerKeys(Friend friend) => [friend.id, friend.identityKey];

  static BirthdayCatchUpPlan plan({
    required List<Friend> friends,
    required DateTime now,
    required int reminderMinutes,
    required bool remindersEnabled,
    required bool dayBeforeEnabled,
    required Set<int> pendingIds,
    required BirthdayCatchUpState previous,
  }) {
    final today = dayKey(now);
    final notifiedOn = _notifiedToday(previous.notifiedOn, today);
    final notifiedDayBeforeOn = _notifiedToday(previous.notifiedDayBeforeOn, today);
    _markRemovedOverdue(friends, now, previous.scheduledDayOf, notifiedOn);
    final toShow = _dayOfToShow(friends, now, reminderMinutes, remindersEnabled, pendingIds,
        previous.scheduledDayOf, notifiedOn);
    final toShowDayBefore = remindersEnabled && dayBeforeEnabled
        ? _dayBeforeToShow(friends, now, pendingIds, previous.scheduledDayBefore, notifiedDayBeforeOn)
        : <Friend>[];

    final nextState = BirthdayCatchUpState(
      notifiedOn: notifiedOn,
      notifiedDayBeforeOn: notifiedDayBeforeOn,
      scheduledDayOf: remindersEnabled
          ? _scheduled(friends, now, reminderMinutes, notifiedOn, daysBefore: 0)
          : <String, DateTime>{},
      scheduledDayBefore: remindersEnabled && dayBeforeEnabled
          ? _scheduled(friends, now, reminderMinutes, notifiedDayBeforeOn, daysBefore: 1)
          : <String, DateTime>{},
    );
    return BirthdayCatchUpPlan(toShow, nextState, toShowDayBefore: toShowDayBefore);
  }

  /// Today's birthdays without a delivered day-of reminder; marks them in
  /// [notifiedOn] (also those whose scheduled reminder fired).
  static List<Friend> _dayOfToShow(
    List<Friend> friends,
    DateTime now,
    int reminderMinutes,
    bool remindersEnabled,
    Set<int> pendingIds,
    Map<String, DateTime> scheduled,
    Map<String, String> notifiedOn,
  ) {
    final today = dayKey(now);
    final reminderToday = BirthdayReminderScheduler.reminderTimeOn(now, reminderMinutes);
    final toShow = <Friend>[];
    for (final friend in friends) {
      if (_isMarked(notifiedOn, friend)) continue;
      final pending = pendingIds.contains(_reminderId(friend, dayBefore: false));
      if (_isOverdueToday(_scheduledFor(scheduled, friend), now) && !pending) {
        _mark(notifiedOn, friend, today);
      } else if (remindersEnabled && _missedToday(friend, now, reminderToday)) {
        toShow.add(friend);
        _mark(notifiedOn, friend, today);
      }
    }
    return toShow;
  }

  /// Day-before reminders due earlier today (the birthday is tomorrow) that
  /// are still pending; marks them in [notifiedOn], as well as those that
  /// fired (no longer pending).
  static List<Friend> _dayBeforeToShow(
    List<Friend> friends,
    DateTime now,
    Set<int> pendingIds,
    Map<String, DateTime> scheduled,
    Map<String, String> notifiedOn,
  ) {
    final today = dayKey(now);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final toShow = <Friend>[];
    for (final friend in friends.where(BirthdayReminderScheduler.hasReminders)) {
      if (_isMarked(notifiedOn, friend)) continue;
      if (!_isOverdueToday(_scheduledFor(scheduled, friend), now) ||
          !friend.isBirthdayToday(today: tomorrow)) {
        continue;
      }
      if (pendingIds.contains(_reminderId(friend, dayBefore: true))) toShow.add(friend);
      _mark(notifiedOn, friend, today);
    }
    return toShow;
  }

  /// Overdue day-of reminders of friends no longer in [friends] (deleted,
  /// perhaps to be re-imported with a new id) count as delivered: their
  /// pending state can't be checked once the friend is gone.
  static void _markRemovedOverdue(List<Friend> friends, DateTime now,
      Map<String, DateTime> scheduled, Map<String, String> notifiedOn) {
    final present = {for (final friend in friends) ...markerKeys(friend)};
    final today = dayKey(now);
    for (final MapEntry(:key, :value) in scheduled.entries) {
      if (!present.contains(key) && _isOverdueToday(value, now)) {
        notifiedOn[key] = today;
      }
    }
  }

  static bool _isMarked(Map<String, String> markers, Friend friend) =>
      markerKeys(friend).any(markers.containsKey);

  static void _mark(Map<String, String> markers, Friend friend, String day) {
    for (final key in markerKeys(friend)) {
      markers[key] = day;
    }
  }

  /// Scheduled moment by id, else by identity (friend re-imported since).
  static DateTime? _scheduledFor(Map<String, DateTime> scheduled, Friend friend) =>
      scheduled[friend.id] ?? scheduled[friend.identityKey];

  /// Id of the friend's next scheduled (day-of or day-before) reminder.
  static int _reminderId(Friend friend, {required bool dayBefore}) =>
      BirthdayReminderScheduler.notificationIdFor(friend.notificationId, dayBefore: dayBefore);

  /// Markers of earlier days are pruned: only today's matter.
  static Map<String, String> _notifiedToday(Map<String, String> notifiedOn, String today) {
    return {
      for (final entry in notifiedOn.entries)
        if (entry.value == today) entry.key: entry.value,
    };
  }

  /// Whether [scheduled] lies earlier today (delivered unless still pending).
  static bool _isOverdueToday(DateTime? scheduled, DateTime now) {
    if (scheduled == null) return false;
    return _isSameDay(scheduled, now) && !scheduled.isAfter(now);
  }

  static bool _missedToday(Friend friend, DateTime now, DateTime reminderToday) {
    return BirthdayReminderScheduler.hasReminders(friend) &&
        friend.isBirthdayToday(today: now) &&
        !now.isBefore(reminderToday);
  }

  /// The reminders [BirthdayReminderScheduler.rescheduleAll] schedules next
  /// ([daysBefore] 0 = day-of, 1 = day-before); today's is skipped for
  /// friends in [notifiedToday].
  static Map<String, DateTime> _scheduled(List<Friend> friends, DateTime now,
      int reminderMinutes, Map<String, String> notifiedToday, {required int daysBefore}) {
    final moments = <String, DateTime>{};
    for (final friend in friends.where(BirthdayReminderScheduler.hasReminders)) {
      final at = BirthdayReminderScheduler.upcomingReminders(
        friend.birthDate,
        now,
        reminderMinutes: reminderMinutes,
        daysBefore: daysBefore,
        skipToday: _isMarked(notifiedToday, friend),
        count: 1,
      ).single;
      for (final key in markerKeys(friend)) {
        moments[key] = at;
      }
    }
    return moments;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Persists [BirthdayCatchUpState] in the [PersonalStore].
class BirthdayCatchUpStore {
  static const String notifiedKey = PersonalKeys.birthdayCatchUpShown;
  static const String scheduledKey = PersonalKeys.birthdayCatchUpScheduledDayOf;
  static const String notifiedDayBeforeKey = PersonalKeys.birthdayCatchUpShownDayBefore;
  static const String scheduledDayBeforeKey = PersonalKeys.birthdayCatchUpScheduledDayBefore;

  /// The store, re-read first.
  static Future<PersonalStore> _loaded() async {
    final store = PersonalStore.instance;
    await store.reload();
    return store;
  }

  /// False until the first catch-up run saved its state (e.g. right after
  /// updating from a version without catch-up).
  Future<bool> hasState() async => (await _loaded()).containsKey(scheduledKey);

  Future<BirthdayCatchUpState> load() async {
    final store = await _loaded();
    return BirthdayCatchUpState(
      notifiedOn: _decode(store.getString(notifiedKey)),
      notifiedDayBeforeOn: _decode(store.getString(notifiedDayBeforeKey)),
      scheduledDayOf: _decodeMoments(store.getString(scheduledKey)),
      scheduledDayBefore: _decodeMoments(store.getString(scheduledDayBeforeKey)),
    );
  }

  Future<void> save(BirthdayCatchUpState state) async {
    final store = PersonalStore.instance;
    await store.setString(notifiedKey, jsonEncode(state.notifiedOn));
    await store.setString(notifiedDayBeforeKey, jsonEncode(state.notifiedDayBeforeOn));
    await store.setString(scheduledKey, _encodeMoments(state.scheduledDayOf));
    await store.setString(scheduledDayBeforeKey, _encodeMoments(state.scheduledDayBefore));
  }

  static String _encodeMoments(Map<String, DateTime> moments) =>
      jsonEncode(moments.map((id, at) => MapEntry(id, at.toIso8601String())));

  static Map<String, DateTime> _decodeMoments(String? json) {
    try {
      return _decode(json).map((id, iso) => MapEntry(id, DateTime.parse(iso)));
    } catch (_) {
      return {};
    }
  }

  static Map<String, String> _decode(String? json) {
    if (json == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(json) as Map);
    } catch (_) {
      return {};
    }
  }
}

/// Runs the catch-up: shows missed birthday notifications via [show] (day-of)
/// and [showDayBefore] (overdue day-before reminders) and
/// remembers what was notified and scheduled. Returns that state, so the
/// reschedule can skip reminders already shown today.
class BirthdayCatchUp {
  final BirthdayCatchUpStore _store;

  BirthdayCatchUp([BirthdayCatchUpStore? store]) : _store = store ?? BirthdayCatchUpStore();

  Future<BirthdayCatchUpState> run({
    required List<Friend> friends,
    required DateTime now,
    required int reminderMinutes,
    required bool remindersEnabled,
    required bool dayBeforeEnabled,
    required Set<int> pendingIds,
    required Future<void> Function(Friend friend) show,
    required Future<void> Function(Friend friend) showDayBefore,
  }) async {
    // Without saved state we can't tell whether today's reminders already
    // fired (first start after an update), so record the state silently.
    final firstRun = !await _store.hasState();
    final plan = BirthdayCatchUpPolicy.plan(
      friends: friends,
      now: now,
      reminderMinutes: reminderMinutes,
      remindersEnabled: remindersEnabled,
      dayBeforeEnabled: dayBeforeEnabled,
      pendingIds: pendingIds,
      previous: await _store.load(),
    );
    await _store.save(plan.nextState);
    if (firstRun) return plan.nextState;
    for (final friend in plan.toShow) {
      await show(friend);
    }
    for (final friend in plan.toShowDayBefore) {
      await showDayBefore(friend);
    }
    return plan.nextState;
  }
}
