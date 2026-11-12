import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';

/// The platform whose pending-notification limit applies.
enum ReminderPlatform {
  android,
  ios;

  /// iOS (and macOS, same notification center) or Android (everything else).
  static ReminderPlatform get current => switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => ReminderPlatform.ios,
        _ => ReminderPlatform.android,
      };
}

/// One scheduled birthday reminder: [friend]'s day-of (or day-before)
/// reminder of the next ([yearOffset] 0) or following (1) birthday.
@immutable
class BirthdayOccurrence {
  final Friend friend;
  final int id;
  final DateTime at;
  final bool dayBefore;
  final int yearOffset;

  const BirthdayOccurrence({
    required this.friend,
    required this.id,
    required this.at,
    required this.dayBefore,
    required this.yearOffset,
  });

  int get daysBefore => dayBefore ? 1 : 0;

  /// The age [friend] turns on the birthday this reminder belongs to; null
  /// without a birth year.
  int? get age => BirthdayReminderScheduler.friendAgeOnBirthdayFor(friend, at, daysBefore);

  @override
  String toString() => 'BirthdayOccurrence($id, $at, ${friend.name})';
}

/// The birthday reminders that fit the platform's budget.
@immutable
class BirthdayBudgetPlan {
  /// Reminders to schedule, earliest first.
  final List<BirthdayOccurrence> kept;

  /// When the "open the app" refresh note fires; null when every upcoming
  /// reminder fit (nothing was left out).
  final DateTime? refreshAt;

  const BirthdayBudgetPlan(this.kept, {this.refreshAt});

  static const BirthdayBudgetPlan empty = BirthdayBudgetPlan([]);

  bool get truncated => refreshAt != null;

  /// Notifications this plan schedules (reminders plus the refresh note).
  int get notificationCount => kept.length + (truncated ? 1 : 0);
}

/// Caps the scheduled birthday reminders at what the OS keeps.
///
/// iOS keeps only the 64 soonest pending notifications per app and silently
/// drops the rest; Android limits alarms per app (about 500). With many
/// people the plain "next two birthdays x day-of/day-before" set exceeds
/// both, so only the earliest reminders are scheduled. When some are left
/// out, the last slot becomes a gentle note asking to open the app, which
/// plans the next ones (app start, resume and friend changes reschedule).
class ReminderBudget {
  ReminderBudget._();

  /// Android: stays well below the ~500 alarms per app the system allows
  /// (the Compass reminders and diagnostics need a few more).
  static const int androidLimit = 400;

  /// iOS keeps at most this many pending notifications per app.
  static const int iosPendingLimit = 64;

  /// Ids the Compass reminders may occupy at the same time (ids 10-13).
  static const int iosCompassSlots = NotificationIds.weeklyReflectionCount;

  /// Kept free on iOS (e.g. for the diagnostics test reminder).
  static const int iosReserve = 1;

  /// iOS: what is left for birthdays (64 - 4 Compass - 1 reserve = 59).
  static const int iosLimit = iosPendingLimit - iosCompassSlots - iosReserve;

  /// The refresh note fires this long after the last kept reminder.
  static const Duration refreshDelay = Duration(minutes: 1);

  /// Birthday notifications (refresh note included) allowed on [platform].
  static int limitFor(ReminderPlatform platform) => switch (platform) {
        ReminderPlatform.android => androidLimit,
        ReminderPlatform.ios => iosLimit,
      };

  /// Every upcoming reminder as [BirthdayReminderScheduler] computes it:
  /// the next two birthdays of each friend with reminders, day-of and (with
  /// [dayBeforeEnabled]) day-before; a reminder due later today is skipped
  /// when [notifiedToday] reports it as already shown (catch-up).
  static List<BirthdayOccurrence> occurrences({
    required List<Friend> friends,
    required DateTime now,
    required int reminderMinutes,
    required bool dayBeforeEnabled,
    NotifiedToday? notifiedToday,
  }) {
    return [
      for (final friend in friends.where(BirthdayReminderScheduler.hasReminders))
        for (final dayBefore in [false, if (dayBeforeEnabled) true])
          ..._friendOccurrences(friend, now, reminderMinutes, dayBefore,
              notifiedToday?.call(friend, dayBefore: dayBefore) ?? false),
    ];
  }

  static Iterable<BirthdayOccurrence> _friendOccurrences(
      Friend friend, DateTime now, int reminderMinutes, bool dayBefore, bool skipToday) {
    final moments = BirthdayReminderScheduler.upcomingReminders(
      friend.birthDate,
      now,
      reminderMinutes: reminderMinutes,
      daysBefore: dayBefore ? 1 : 0,
      skipToday: skipToday,
    );
    return [
      for (final (yearOffset, at) in moments.indexed)
        BirthdayOccurrence(
          friend: friend,
          id: BirthdayReminderScheduler.notificationIdFor(friend.notificationId,
              yearOffset: yearOffset, dayBefore: dayBefore),
          at: at,
          dayBefore: dayBefore,
          yearOffset: yearOffset,
        ),
    ];
  }

  /// The earliest reminders of [all] that fit in [limit] notifications.
  /// When some are left out, the last slot goes to the refresh note, fired
  /// [refreshDelay] after the last kept reminder.
  static BirthdayBudgetPlan select(List<BirthdayOccurrence> all, {required int limit}) {
    assert(limit >= 2, 'needs room for a reminder and the refresh note');
    final sorted = [...all]..sort(_byFireTime);
    if (sorted.length <= limit) return BirthdayBudgetPlan(sorted);
    final kept = sorted.sublist(0, limit - 1);
    return BirthdayBudgetPlan(kept, refreshAt: kept.last.at.add(refreshDelay));
  }

  /// Fire time, then id, so the selection is stable.
  static int _byFireTime(BirthdayOccurrence a, BirthdayOccurrence b) {
    final byTime = a.at.compareTo(b.at);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }
}
