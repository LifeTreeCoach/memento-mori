import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';

/// The reminder choice at the end of onboarding; swappable in tests.
abstract class ReminderOptIn {
  /// Asks for the notification permission and turns reminders on.
  Future<void> enable();

  /// Turns weekly and birthday reminders off and cancels anything scheduled.
  Future<void> skip();
}

/// Uses the real notification permission and reminder scheduling.
class SystemReminderOptIn implements ReminderOptIn {
  const SystemReminderOptIn();

  @override
  Future<void> enable() async {
    try {
      // Denied keeps the user's choice; Settings then warns that the
      // system blocks notifications and offers to allow them.
      final granted = await NotificationService.requestPermission();
      if (!granted) debugPrint('Onboarding: notification permission denied');
      // FriendsService notifies its listener, which reschedules birthdays.
      await ReminderService.setBirthdayNotificationsEnabled(true);
      await ReminderService.setReminderEnabled(true);
    } catch (e) {
      debugPrint('Onboarding: enabling reminders failed: $e');
    }
  }

  /// Both reminders default to on, so "Not now" must switch them off
  /// explicitly. The settings are saved before any plugin call, so they
  /// stick even if cancelling fails.
  @override
  Future<void> skip() async {
    await _attempt('disabling weekly reminder',
        () => ReminderService.setReminderEnabled(false));
    // FriendsService notifies its listener, which cancels birthday reminders.
    await _attempt('disabling birthday reminders',
        () => ReminderService.setBirthdayNotificationsEnabled(false));
    // Also cancels when no listener is wired yet.
    await _attempt('rescheduling reminders', ReminderService.rescheduleAll);
  }

  static Future<void> _attempt(
      String step, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Onboarding: $step failed: $e');
    }
  }
}
