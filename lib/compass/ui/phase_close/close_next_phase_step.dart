import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_picker.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';

/// Closing step 3: "Which phase begins now?" – the shared phase picker;
/// the new phase starts today, so there is no "since" stepper.
class CloseNextPhaseStep extends StatelessWidget {
  const CloseNextPhaseStep({
    super.key,
    required this.eyebrow,
    required this.preset,
    required this.nameController,
    required this.onPresetChanged,
    required this.onNameChanged,
    required this.onNext,
    this.error,
  });

  final String eyebrow;
  final PhasePreset? preset;
  final TextEditingController nameController;
  final ValueChanged<PhasePreset?> onPresetChanged;
  final ValueChanged<String> onNameChanged;

  /// Null until a phase is chosen.
  final VoidCallback? onNext;

  /// Why the next phase cannot begin today, if so.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepLayout(
      topPadding: 8,
      action: FilledButton(
        key: const ValueKey('phase_close_next_phase'),
        onPressed: onNext,
        child: Text(l10n.translate('phase_close_next')),
      ),
      children: [
        PhaseEyebrow(eyebrow),
        Text(l10n.translate('phase_close_next_title'),
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(l10n.translate('phase_close_next_intro'),
            style: PhaseStyle.muted(context)),
        const SizedBox(height: 24),
        PhasePicker(
          preset: preset,
          nameController: nameController,
          onPresetChanged: onPresetChanged,
          onNameChanged: onNameChanged,
        ),
        if (error case final text?)
          Padding(
            key: const ValueKey('phase_close_error'),
            padding: const EdgeInsets.only(top: 12),
            child: Text(text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error)),
          ),
      ],
    );
  }
}
