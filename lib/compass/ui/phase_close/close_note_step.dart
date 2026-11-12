import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';

/// Closing step 2: "What was good about this phase?" – an optional note
/// that stays with the closed phase. "Skip" goes on without one.
class CloseNoteStep extends StatelessWidget {
  const CloseNoteStep({
    super.key,
    required this.eyebrow,
    required this.controller,
    required this.onNext,
    required this.onSkip,
  });

  final String eyebrow;
  final TextEditingController controller;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepLayout(
      topPadding: 8,
      action: FilledButton(
        key: const ValueKey('phase_close_note_next'),
        onPressed: onNext,
        child: Text(l10n.translate('phase_close_next')),
      ),
      secondaryAction: TextButton(
        key: const ValueKey('phase_close_skip'),
        onPressed: onSkip,
        child: Text(l10n.translate('phase_close_skip')),
      ),
      children: [
        PhaseEyebrow(eyebrow),
        Text(l10n.translate('phase_close_note_title'),
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(l10n.translate('phase_close_note_intro'),
            style: PhaseStyle.muted(context)),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('phase_close_note'),
          controller: controller,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.translate('phase_close_note_hint'),
            hintStyle: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Fraunces',
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
