import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Warns that the system blocks notifications, with an action to allow them.
class NotificationsBlockedTile extends StatelessWidget {
  const NotificationsBlockedTile({super.key, required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    return ListTile(
      leading: Icon(Icons.notifications_paused_outlined, color: error),
      title: Text(
        l10n.translate('settings_notifications_blocked'),
        style: TextStyle(color: error),
      ),
      trailing: TextButton(
        onPressed: onAllow,
        child: Text(l10n.translate('settings_notifications_blocked_action')),
      ),
      onTap: onAllow,
    );
  }
}
