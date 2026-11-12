import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/compass/setup_flow.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// "Set up Compass" at the top of the Compass while a setup step is open:
/// a checked or empty circle per step, "2 of 4", "Continue" and a way to
/// hide the card for good.
class SetupChecklistCard extends StatelessWidget {
  const SetupChecklistCard({
    super.key,
    required this.facts,
    required this.progress,
    required this.onContinue,
    required this.onDismiss,
  });

  final SetupFacts facts;
  final CompassSetupProgress progress;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  static String stepLabelKey(SetupStep step) => 'setup_step_${step.name}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('compass_setup_card'),
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, l10n),
          for (final step in SetupStep.values) _row(context, l10n, step),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton(
              key: const ValueKey('compass_setup_continue'),
              onPressed: onContinue,
              child: Text(l10n.translate('setup_card_continue')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final progressText = l10n.translate('setup_card_progress', replacements: {
      'done': '${doneCount(facts, progress)}',
      'total': '${SetupStep.values.length}',
    });
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.translate('setup_card_title'),
                  style: theme.textTheme.titleMedium),
              Text(progressText,
                  key: const ValueKey('compass_setup_progress'),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('compass_setup_dismiss'),
          tooltip: l10n.translate('setup_card_dismiss'),
          icon: const Icon(Icons.close),
          onPressed: onDismiss,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, SetupStep step) {
    final scheme = Theme.of(context).colorScheme;
    final done = isStepDone(step, facts, progress);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            key: ValueKey('compass_setup_${step.name}_${done ? 'done' : 'open'}'),
            size: 20,
            color: done ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.translate(stepLabelKey(step)),
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
