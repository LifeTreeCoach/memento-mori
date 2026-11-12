import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_settings_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_permission.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/settings/notifications_blocked_tile.dart';
import 'package:memento_mori_life_in_weeks/settings/reminder_rhythm_control.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';

/// Birthday reminders (shared flag with the People tab), their time, the
/// Compass reminder rhythm and calendar sync. Every change reschedules reminders.
/// Warns while reminders are on but the system blocks notifications; the
/// status is checked again whenever the app resumes.
class RemindersSection extends StatefulWidget {
  const RemindersSection({
    super.key,
    this.permission = const SystemNotificationPermission(),
  });

  final NotificationPermission permission;

  @override
  State<RemindersSection> createState() => _RemindersSectionState();
}

class _RemindersSectionState extends State<RemindersSection>
    with WidgetsBindingObserver {
  /// Optimistic until checked, so the warning never flashes up.
  bool _permissionGranted = true;

  bool get _birthdaysOn => ReminderService.isBirthdayNotificationsEnabled();

  bool get _anyReminderOn => _birthdaysOn || ReminderService.isReminderEnabled();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The user may come back from the system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final granted = await widget.permission.isGranted();
    if (mounted && granted != _permissionGranted) {
      setState(() => _permissionGranted = granted);
    }
  }

  /// Asks for the permission when a reminder is switched on.
  Future<void> _requestPermission() async {
    await widget.permission.request();
    await _refreshPermission();
  }

  Future<void> _allowNotifications() async {
    await requestOrOpenSettings(widget.permission);
    await _refreshPermission();
  }

  TimeOfDay get _reminderTime {
    final minutes = SettingsService.getBirthdayReminderMinutes();
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  /// Runs [change], then rebuilds if still on screen.
  Future<void> _apply(Future<void> Function() change) async {
    await change();
    if (mounted) setState(() {});
  }

  Future<void> _setBirthdayReminders(bool enabled) => _apply(() async {
        if (enabled) await _requestPermission();
        // FriendsService notifies its listener, which reschedules.
        await ReminderService.setBirthdayNotificationsEnabled(enabled);
      });

  Future<void> _pickReminderTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked == null) return;
    await _apply(() async {
      await SettingsService.setBirthdayReminderMinutes(
          picked.hour * 60 + picked.minute);
      await ReminderService.refreshBirthdayReminders();
    });
  }

  Future<void> _setDayBefore(bool enabled) => _apply(() async {
        await SettingsService.setBirthdayDayBeforeReminderEnabled(enabled);
        await ReminderService.refreshBirthdayReminders();
      });

  Future<void> _setRhythm(ReminderRhythm rhythm) => _apply(() async {
        if (rhythm.isOn) await _requestPermission();
        await ReminderService.setRhythm(rhythm);
      });

  void _openCalendarSync() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CalendarSettingsScreen()),
    );
  }

  /// Title and explanation of the Compass reminder rhythm, its segments
  /// below at full width (room for the longer French/German labels).
  List<Widget> _compassReminder(AppLocalizations l10n) {
    final rhythm = ReminderService.rhythm();
    return [
      ListTile(
        key: const ValueKey('settings_weekly_reflection'),
        leading: const Icon(Icons.nights_stay_outlined),
        title: Text(l10n.translate('settings_weekly_reflection')),
        subtitle:
            Text(l10n.translate(ReminderRhythmControl.descriptionKey(rhythm))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: ReminderRhythmControl(
          value: rhythm,
          onChanged: _setRhythm,
          showDescription: false,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final birthdaysOn = _birthdaysOn;
    return SettingsSection(
      title: l10n.translate('settings_section_reminders'),
      children: [
        if (!_permissionGranted && _anyReminderOn)
          NotificationsBlockedTile(onAllow: _allowNotifications),
        SwitchListTile(
          secondary: Icon(birthdaysOn
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined),
          title: Text(l10n.translate('people_reminders')),
          subtitle: Text(l10n.translate('settings_birthday_reminders_sub')),
          value: birthdaysOn,
          onChanged: _setBirthdayReminders,
        ),
        ListTile(
          enabled: birthdaysOn,
          leading: const Icon(Icons.schedule),
          title: Text(l10n.translate('settings_reminder_time')),
          subtitle: Text(_reminderTime.format(context)),
          onTap: _pickReminderTime,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.event_repeat_outlined),
          title: Text(l10n.translate('birthday_day_before_reminder')),
          value: SettingsService.isBirthdayDayBeforeReminderEnabled(),
          onChanged: birthdaysOn ? _setDayBefore : null,
        ),
        ..._compassReminder(l10n),
        ListTile(
          leading: const Icon(Icons.event_outlined),
          title: Text(l10n.translate('people_calendar_sync')),
          subtitle: Text(l10n.translate('settings_calendar_sync_sub')),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openCalendarSync,
        ),
      ],
    );
  }
}
