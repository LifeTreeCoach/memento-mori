import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Actions offered in a Compass item's overflow menu.
enum CompassMenuAction {
  edit('compass_edit', Icons.edit_outlined),
  moveToNow('compass_move_now', Icons.arrow_upward_rounded),
  moveToSomeday('compass_move_someday', Icons.schedule_outlined),
  letGo('compass_let_go', Icons.air_rounded),
  delete('compass_delete', Icons.delete_outline);

  const CompassMenuAction(this.labelKey, this.icon);

  final String labelKey;
  final IconData icon;
}

/// "More" button with [actions] for one intention or moment.
class CompassItemMenu extends StatelessWidget {
  const CompassItemMenu({
    super.key,
    required this.actions,
    required this.onSelected,
  });

  final List<CompassMenuAction> actions;
  final ValueChanged<CompassMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<CompassMenuAction>(
      tooltip: l10n.translate('compass_more_actions'),
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(action.icon),
              title: Text(l10n.translate(action.labelKey)),
            ),
          ),
      ],
    );
  }
}
