import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_item_menu.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_meta_text.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// One lived moment: its note (italic) under the title, date and area
/// below; tap to edit.
class MomentTile extends StatelessWidget {
  const MomentTile({
    super.key,
    required this.moment,
    required this.onEdit,
    required this.onAction,
    this.phaseNote,
  });

  final Moment moment;
  final VoidCallback onEdit;
  final ValueChanged<CompassMenuAction> onAction;

  /// "Done · Building up, year 3" when it came from a phase's intention.
  final String? phaseNote;

  static const List<CompassMenuAction> _menu = [
    CompassMenuAction.edit,
    CompassMenuAction.delete,
  ];

  IconData get _icon => momentIcon(moment);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 4),
      leading: Icon(_icon, size: 20, color: theme.colorScheme.primary),
      minLeadingWidth: 24,
      title: _title(theme),
      subtitle: CompassMetaText([
        l10n.shortDateFormat.format(moment.date),
        if (moment.area case final area?) l10n.areaLabel(area),
        ?phaseNote,
      ]),
      trailing: CompassItemMenu(actions: _menu, onSelected: onAction),
      onTap: onEdit,
    );
  }

  /// The title, with the note (if any) in italics beneath.
  Widget _title(ThemeData theme) {
    final note = moment.note;
    if (note == null) return Text(moment.title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(moment.title),
        Text(
          note,
          key: const ValueKey('compass_moment_note'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
