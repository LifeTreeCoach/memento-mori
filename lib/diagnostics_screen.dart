import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_launch_requests.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/pending_notifications_section.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/support/support_service.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_launcher.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_result.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// Developer-ish tools to verify that reminders reach the device.
class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({
    super.key,
    this.loadPendingNotifications,
    this.weekMoments = const WeekMomentLauncher(),
  });

  /// Replaces the plugin query in tests.
  final PendingNotificationsLoader? loadPendingNotifications;

  /// Shows the weekly moment on request.
  final WeekMomentLauncher weekMoments;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String doneKey,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).translate(doneKey);
    await action();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> _sendTestNotification() =>
      ReminderService.sendTestNotification();

  static Future<void> _scheduleTestReminder() async {
    await NotificationService.requestPermission();
    await ReminderService.scheduleTestBirthdayReminder(
        const Duration(minutes: 1));
  }

  static Future<void> _checkBirthdays() =>
      ReminderService.checkTodaysBirthdays();

  static Future<void> _sendCompassQuestion() =>
      ReminderService.sendCompassQuestionNow();

  static Future<void> _showSupportPrompt() async => SupportService.showNow();

  static Future<void> _resetSupportSchedule() =>
      SupportService.resetSchedule(DateTime.now());

  static Future<void> _resetCompassSetup() => CompassSetupStore.reset();

  static Future<void> _resetTours() => TourProgressStore.reset();

  static Future<void> _resetWeekMoment() =>
      WeekMomentStore.resetForDiagnostics();

  /// Plays the moment; "Plan the week" asks the shell for the Compass tab.
  Future<void> _showWeekMoment(BuildContext context) async {
    final result = await weekMoments.replay(context, now: DateTime.now());
    if (result == WeekMomentResult.continued) CompassLaunchRequests.request();
  }

  Widget _pendingNotifications() {
    final load = loadPendingNotifications;
    return load == null
        ? const PendingNotificationsSection()
        : PendingNotificationsSection(load: load);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('diagnostics_title'))),
      body: ScrollThread(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                l10n.translate('diagnostics_intro'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.translate('diagnostics_test_notification')),
              subtitle:
                  Text(l10n.translate('diagnostics_test_notification_sub')),
              onTap: () => _run(context, _sendTestNotification,
                  'diagnostics_test_notification_sent'),
            ),
            ListTile(
              leading: const Icon(Icons.alarm_outlined),
              title: Text(l10n.translate('test_reminder_in_1_min')),
              subtitle: Text(l10n.translate('diagnostics_test_reminder_sub')),
              onTap: () => _run(
                  context, _scheduleTestReminder, 'test_reminder_scheduled'),
            ),
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: Text(l10n.translate('diagnostics_check_birthdays')),
              subtitle: Text(l10n.translate('diagnostics_check_birthdays_sub')),
              onTap: () => _run(context, _checkBirthdays,
                  'diagnostics_check_birthdays_done'),
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: Text(l10n.translate('diagnostics_compass_question')),
              subtitle: Text(l10n.translate('diagnostics_compass_question_sub')),
              onTap: () => _run(context, _sendCompassQuestion,
                  'diagnostics_compass_question_sent'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text(l10n.translate('diagnostics_support_show')),
              subtitle: Text(l10n.translate('diagnostics_support_show_sub')),
              onTap: () =>
                  _run(context, _showSupportPrompt, 'diagnostics_support_shown'),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(l10n.translate('diagnostics_support_reset')),
              subtitle: Text(l10n.translate('diagnostics_support_reset_sub')),
              onTap: () => _run(context, _resetSupportSchedule,
                  'diagnostics_support_reset_done'),
            ),
            ListTile(
              key: const ValueKey('diagnostics_compass_setup_reset'),
              leading: const Icon(Icons.explore_off_outlined),
              title: Text(l10n.translate('diagnostics_compass_setup_reset')),
              subtitle:
                  Text(l10n.translate('diagnostics_compass_setup_reset_sub')),
              onTap: () => _run(context, _resetCompassSetup,
                  'diagnostics_compass_setup_reset_done'),
            ),
            ListTile(
              key: const ValueKey('diagnostics_tours_reset'),
              leading: const Icon(Icons.tour_outlined),
              title: Text(l10n.translate('diagnostics_tours_reset')),
              subtitle: Text(l10n.translate('diagnostics_tours_reset_sub')),
              onTap: () =>
                  _run(context, _resetTours, 'diagnostics_tours_reset_done'),
            ),
            ListTile(
              key: const ValueKey('diagnostics_week_moment'),
              leading: const Icon(Icons.calendar_view_week_outlined),
              title: Text(l10n.translate('diagnostics_week_moment')),
              subtitle: Text(l10n.translate('diagnostics_week_moment_sub')),
              onTap: () => _showWeekMoment(context),
            ),
            ListTile(
              key: const ValueKey('diagnostics_week_moment_reset'),
              leading: const Icon(Icons.event_repeat_outlined),
              title: Text(l10n.translate('diagnostics_week_moment_reset')),
              subtitle:
                  Text(l10n.translate('diagnostics_week_moment_reset_sub')),
              onTap: () => _run(context, _resetWeekMoment,
                  'diagnostics_week_moment_reset_done'),
            ),
            const Divider(),
            _pendingNotifications(),
          ],
        ),
      ),
    );
  }
}
