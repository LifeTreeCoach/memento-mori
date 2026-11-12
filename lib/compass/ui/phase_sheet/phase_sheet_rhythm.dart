import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_permission.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/settings/reminder_rhythm_control.dart';

/// "Remind me of this phase": the shared Compass reminder rhythm (weekly /
/// every 4 weeks / never). Turning it on asks for the notification
/// permission in context, as in Settings.
class PhaseSheetRhythm extends StatefulWidget {
  const PhaseSheetRhythm({super.key, required this.permission});

  final NotificationPermission permission;

  @override
  State<PhaseSheetRhythm> createState() => _PhaseSheetRhythmState();
}

class _PhaseSheetRhythmState extends State<PhaseSheetRhythm> {
  late ReminderRhythm _rhythm = ReminderService.rhythm();

  Future<void> _set(ReminderRhythm rhythm) async {
    setState(() => _rhythm = rhythm);
    if (rhythm.isOn) {
      try {
        await widget.permission.request();
      } catch (e) {
        debugPrint('Phase sheet: permission request failed: $e');
      }
    }
    await ReminderService.setRhythm(rhythm);
  }

  @override
  Widget build(BuildContext context) {
    return ReminderRhythmControl(
      key: const ValueKey('phase_sheet_rhythm'),
      value: _rhythm,
      onChanged: _set,
    );
  }
}
