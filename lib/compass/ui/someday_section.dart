import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_actions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_invite.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_section_header.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/someday_tile.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_tour.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';

/// "Someday": a collapsible list of intentions that wait calmly.
class SomedaySection extends StatelessWidget {
  const SomedaySection({
    super.key,
    required this.intentions,
    required this.expanded,
    required this.onToggle,
    required this.actions,
  });

  final List<Intention> intentions;
  final bool expanded;
  final VoidCallback onToggle;
  final CompassActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('compass_someday_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TourAnchor(
          id: CompassTour.somedayAnchor,
          child: CompassSectionHeader(
            title: l10n.translate('compass_someday'),
            subtitle: _subtitle(l10n),
            trailing: _toggle(context, l10n),
          ),
        ),
        if (expanded) ..._content(l10n),
      ],
    );
  }

  /// "3 ideas waiting. Most may stay here – that's fine." (the original
  /// explanation while the list is empty).
  String _subtitle(AppLocalizations l10n) => intentions.isEmpty
      ? l10n.translate('compass_someday_sub')
      : [
          l10n.plural('compass_someday_waiting', intentions.length),
          l10n.translate('compass_someday_fine'),
        ].join(' ');

  /// "3 ⌄": the count and the expand button.
  Widget _toggle(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (intentions.isNotEmpty)
          Text(
            l10n.numberFormat.format(intentions.length),
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        IconButton(
          key: const ValueKey('compass_someday_toggle'),
          tooltip: l10n.translate(expanded ? 'compass_collapse' : 'compass_expand'),
          icon: Icon(expanded
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded),
          onPressed: onToggle,
        ),
      ],
    );
  }

  List<Widget> _content(AppLocalizations l10n) => [
        if (intentions.isEmpty)
          CompassInvite(l10n.translate('compass_someday_empty')),
        for (final intention in intentions)
          SomedayTile(
            key: ValueKey('compass_someday_${intention.id}'),
            intention: intention,
            onEdit: () => actions.editIntention(intention),
            onAction: (action) => actions.onIntentionMenu(intention, action),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('compass_add_someday'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.translate('compass_add_to_someday')),
            onPressed: () =>
                actions.addIntention(status: IntentionStatus.someday),
          ),
        ),
      ];
}
