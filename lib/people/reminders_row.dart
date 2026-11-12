import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Compact switch for birthday reminders.
class RemindersRow extends StatelessWidget {
  const RemindersRow({super.key, required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      secondary: Icon(enabled
          ? Icons.notifications_active_outlined
          : Icons.notifications_off_outlined),
      title: Text(AppLocalizations.of(context).translate('people_reminders')),
      value: enabled,
      onChanged: onChanged,
    );
  }
}
