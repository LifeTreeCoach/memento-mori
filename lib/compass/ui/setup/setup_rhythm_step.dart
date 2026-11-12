import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/settings/reminder_rhythm_control.dart';

/// Setup step 4: "How often should the Compass remind you?" with the
/// shared rhythm segments (starting at [initial]).
class SetupRhythmStep extends StatefulWidget {
  const SetupRhythmStep({
    super.key,
    required this.initial,
    required this.onConfirm,
  });

  final ReminderRhythm initial;

  /// Applies the chosen rhythm (asks for the permission when it is on).
  final Future<void> Function(ReminderRhythm rhythm) onConfirm;

  @override
  State<SetupRhythmStep> createState() => _SetupRhythmStepState();
}

class _SetupRhythmStepState extends State<SetupRhythmStep> {
  late ReminderRhythm _rhythm = widget.initial;
  bool _saving = false;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    await widget.onConfirm(_rhythm);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StepLayout(
      topPadding: 0,
      action: FilledButton(
        key: const ValueKey('setup_rhythm_apply'),
        onPressed: _saving ? null : _confirm,
        child: Text(l10n.translate('setup_rhythm_apply')),
      ),
      children: [
        PhaseEyebrow(l10n.translate('nav_compass')),
        Text(l10n.translate('setup_rhythm_question'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(l10n.translate('setup_rhythm_intro'),
            style: PhaseStyle.muted(context)),
        const SizedBox(height: 24),
        ReminderRhythmControl(
          key: const ValueKey('setup_rhythm_control'),
          value: _rhythm,
          onChanged: (rhythm) => setState(() => _rhythm = rhythm),
        ),
      ],
    );
  }
}
