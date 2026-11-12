import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_item_menu.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_meta_text.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// One intention waiting in "Someday"; tap to edit, menu to move or delete.
class SomedayTile extends StatelessWidget {
  const SomedayTile({
    super.key,
    required this.intention,
    required this.onEdit,
    required this.onAction,
  });

  final Intention intention;
  final VoidCallback onEdit;
  final ValueChanged<CompassMenuAction> onAction;

  static const List<CompassMenuAction> _menu = [
    CompassMenuAction.moveToNow,
    CompassMenuAction.edit,
    CompassMenuAction.letGo,
    CompassMenuAction.delete,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = l10n.intentionMeta(intention);
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 4),
      leading: const Icon(Icons.radio_button_unchecked_rounded, size: 20),
      minLeadingWidth: 24,
      title: Text(intention.title),
      subtitle: meta.isEmpty ? null : CompassMetaText(meta),
      trailing: CompassItemMenu(actions: _menu, onSelected: onAction),
      onTap: onEdit,
    );
  }
}
