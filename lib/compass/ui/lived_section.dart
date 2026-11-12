import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_actions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_invite.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_item_menu.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_section_header.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/look_back.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/look_back_card.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/moment_tile.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// "Lived": kept moments (also completed intentions), newest first, an add
/// button and the "Look back" summary.
class LivedSection extends StatelessWidget {
  const LivedSection({
    super.key,
    required this.moments,
    required this.actions,
    this.birthDate,
    this.weeksLived,
    this.phaseNoteOf,
    this.phases = const [],
    this.intentions = const [],
  });

  final List<Moment> moments;
  final CompassActions actions;
  final DateTime? birthDate;
  final int? weeksLived;

  /// "Done · Building up, year 3" for a moment from an intention of a
  /// phase; null for the others.
  final String? Function(Moment moment)? phaseNoteOf;

  /// Life phases from [resolvePhases]; the look back groups by them.
  final List<PhaseSpan> phases;

  /// All intentions: a moment done from one counts in its phase.
  final List<Intention> intentions;

  /// Newest first; same day: the later added first.
  List<Moment> get _newestFirst {
    final indexed = moments.indexed.toList()
      ..sort((a, b) {
        final byDate = b.$2.date.compareTo(a.$2.date);
        return byDate != 0 ? byDate : b.$1 - a.$1;
      });
    return [for (final (_, moment) in indexed) moment];
  }

  void _onAction(Moment moment, CompassMenuAction action) {
    if (action == CompassMenuAction.delete) {
      actions.deleteMoment(moment);
    } else {
      actions.editMoment(moment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('compass_lived_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompassSectionHeader(
          title: l10n.translate('compass_lived'),
          subtitle: l10n.translate('compass_lived_sub'),
        ),
        if (moments.isEmpty)
          CompassInvite(l10n.translate('compass_lived_empty')),
        for (final moment in _newestFirst)
          MomentTile(
            key: ValueKey('compass_moment_${moment.id}'),
            moment: moment,
            onEdit: () => actions.editMoment(moment),
            onAction: (action) => _onAction(moment, action),
            phaseNote: phaseNoteOf?.call(moment),
          ),
        _addButton(l10n),
        if (moments.isNotEmpty) ...[
          const SizedBox(height: 16),
          LookBackCard(
            lookBack: LookBack.of(
              moments,
              birthDate: birthDate,
              phases: phases,
              intentions: intentions,
            ),
            weeksLived: weeksLived,
          ),
        ],
      ],
    );
  }

  Widget _addButton(AppLocalizations l10n) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const ValueKey('compass_add_moment'),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.translate('compass_add_moment')),
          onPressed: actions.addMoment,
        ),
      );
}
