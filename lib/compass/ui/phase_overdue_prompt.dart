import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Gentle question once the planned end of the current phase has passed:
/// extend it or close it.
class PhaseOverduePrompt extends StatelessWidget {
  const PhaseOverduePrompt({
    super.key,
    required this.onExtend,
    required this.onClose,
  });

  final VoidCallback onExtend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('compass_phase_overdue'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.translate('phase_overdue'),
              style: theme.textTheme.bodyMedium),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 4,
            children: [
              TextButton(
                key: const ValueKey('compass_phase_extend'),
                onPressed: onExtend,
                child: Text(l10n.translate('phase_extend')),
              ),
              TextButton(
                key: const ValueKey('compass_phase_close'),
                onPressed: onClose,
                child: Text(l10n.translate('phase_close')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
