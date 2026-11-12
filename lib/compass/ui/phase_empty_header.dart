import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Top of the Compass before any phase: "No phase yet" and "Set phase".
class PhaseEmptyHeader extends StatelessWidget {
  const PhaseEmptyHeader({super.key, required this.onSet});

  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('compass_phase_empty'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittingPhaseEyebrow(
          long: l10n.translate('phase_header_eyebrow'),
          short: l10n.translate('phase_eyebrow'),
        ),
        Text(l10n.translate('phase_empty_title'),
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(l10n.translate('phase_empty_body'),
            style: PhaseStyle.muted(context)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          key: const ValueKey('compass_phase_set'),
          icon: const Icon(Icons.flag_outlined, size: 18),
          label: Text(l10n.translate('phase_set')),
          onPressed: onSet,
        ),
      ],
    );
  }
}
