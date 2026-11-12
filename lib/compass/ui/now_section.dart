import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_actions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_invite.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_section_header.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_tour.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/intention_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';

/// "Now": at most [nowLimit] intention cards and an add button. When full,
/// the button adds to "Someday" and a limit hint asks what can wait.
class NowSection extends StatelessWidget {
  const NowSection({
    super.key,
    required this.intentions,
    required this.actions,
    this.current,
    required this.today,
  });

  final List<Intention> intentions;
  final CompassActions actions;

  /// The phase lived [today]; the rows name its planned time left.
  final PhaseSpan? current;
  final DateTime today;

  bool get _isFull => intentions.length >= nowLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('compass_now_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompassSectionHeader(
          title: l10n.translate('compass_now'),
          // The explanation for an empty list, the count once there is one.
          subtitle: intentions.isEmpty ? l10n.translate('compass_now_sub') : null,
          trailing: intentions.isEmpty ? null : _count(context, l10n),
        ),
        if (intentions.isEmpty)
          CompassInvite(l10n.translate('compass_now_empty')),
        for (final intention in intentions) ...[
          IntentionCard(
            key: ValueKey('compass_intention_${intention.id}'),
            intention: intention,
            onEdit: () => actions.editIntention(intention),
            onDone: () => actions.complete(intention),
            onAction: (action) => actions.onIntentionMenu(intention, action),
            current: current,
            today: today,
          ),
          const SizedBox(height: 8),
        ],
        if (_isFull) _limitHint(context),
        _addButton(l10n),
      ],
    );
  }

  /// "2 of 3 · the rest can wait".
  Widget _count(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Flexible(
      child: Text(
        l10n.nowCountText(intentions.length),
        key: const ValueKey('compass_now_count'),
        textAlign: TextAlign.end,
        style: theme.textTheme.labelMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _limitHint(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        actions.limitHintText(),
        key: const ValueKey('compass_limit_hint'),
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  /// The Compass tour points at this button for "Now".
  Widget _addButton(AppLocalizations l10n) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TourAnchor(id: CompassTour.nowAnchor, child: _button(l10n)),
    );
  }

  Widget _button(AppLocalizations l10n) {
    return _isFull
        ? TextButton.icon(
            key: const ValueKey('compass_add_intention'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.translate('compass_add_to_someday')),
            // Asked for "Now": the service files it under "Someday" and
            // the actions explain why.
            onPressed: () => actions.addIntention(),
          )
        : FilledButton.tonalIcon(
            key: const ValueKey('compass_add_intention'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.translate('compass_add_intention')),
            onPressed: () => actions.addIntention(),
          );
  }
}
