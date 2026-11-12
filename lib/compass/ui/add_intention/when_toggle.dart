import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// "In this phase | Someday" ("Now | Someday" without a current phase):
/// whether the intention goes to the "Now" list or waits.
class WhenToggle extends StatelessWidget {
  const WhenToggle({
    super.key,
    required this.selected,
    required this.hasPhase,
    required this.onChanged,
  });

  /// [IntentionStatus.now] or [IntentionStatus.someday].
  final IntentionStatus selected;

  /// A current phase exists, so "Now" means "in this phase".
  final bool hasPhase;
  final ValueChanged<IntentionStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nowLabel = hasPhase ? 'intention_when_phase' : 'intention_when_now';
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<IntentionStatus>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: IntentionStatus.now,
            label: Text(l10n.translate(nowLabel),
                key: const ValueKey('intention_when_now')),
          ),
          ButtonSegment(
            value: IntentionStatus.someday,
            label: Text(l10n.translate('intention_when_someday'),
                key: const ValueKey('intention_when_someday')),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}
