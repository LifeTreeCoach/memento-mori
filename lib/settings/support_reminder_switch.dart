import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/support/support_service.dart';

/// "Remind me now and then": the opt-out of the occasional card on the
/// Life tab, shared by the Support and the "Like Memento Mori?" sections.
class SupportReminderSwitch extends StatelessWidget {
  const SupportReminderSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Follows changes made elsewhere too ("I already did, thanks" on the
    // Life tab), since the shell keeps this tab alive.
    return ValueListenableBuilder<int>(
      valueListenable: SupportService.revision,
      builder: (context, _, _) => SwitchListTile(
        key: const ValueKey('support_remind_switch'),
        secondary: const Icon(Icons.event_repeat_outlined),
        title: Text(l10n.translate('support_remind')),
        subtitle: Text(l10n.translate('support_remind_sub')),
        value: SupportService.remindersEnabled,
        onChanged: SupportService.setRemindersEnabled,
      ),
    );
  }
}
