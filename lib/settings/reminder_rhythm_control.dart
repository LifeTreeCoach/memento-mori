import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';

/// Chooses the Compass reminder rhythm (weekly / every 4 weeks / off) and,
/// unless [showDescription] is false, explains the chosen one below.
/// Used in Settings, the phase sheet and the Compass setup.
class ReminderRhythmControl extends StatelessWidget {
  const ReminderRhythmControl({
    super.key,
    required this.value,
    required this.onChanged,
    this.showDescription = true,
  });

  final ReminderRhythm value;

  /// Null disables the control.
  final ValueChanged<ReminderRhythm>? onChanged;
  final bool showDescription;

  /// Segment label keys, also used as widget keys of the labels.
  static String labelKey(ReminderRhythm rhythm) => switch (rhythm) {
        ReminderRhythm.weekly => 'rhythm_weekly',
        ReminderRhythm.every4Weeks => 'rhythm_every_4_weeks',
        ReminderRhythm.off => 'rhythm_off',
      };

  /// Localization key of the sentence explaining [rhythm].
  static String descriptionKey(ReminderRhythm rhythm) =>
      'settings_${labelKey(rhythm)}_sub';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final segments = SegmentedButton<ReminderRhythm>(
      segments: [
        for (final rhythm in ReminderRhythm.values)
          ButtonSegment(
            value: rhythm,
            label: Text(
              l10n.translate('settings_${labelKey(rhythm)}'),
              key: ValueKey(labelKey(rhythm)),
              textAlign: TextAlign.center,
              // Wraps instead of cutting off on very narrow screens.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: {value},
      showSelectedIcon: false,
      // Narrow padding keeps "Alle 4 Wochen" on one line on a 393dp phone,
      // also inside the wider page margins of the Compass setup.
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
      ),
      onSelectionChanged: onChanged == null
          ? null
          : (selection) => onChanged!(selection.single),
    );
    if (!showDescription) return segments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        segments,
        const SizedBox(height: 8),
        Text(
          l10n.translate(descriptionKey(value)),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
