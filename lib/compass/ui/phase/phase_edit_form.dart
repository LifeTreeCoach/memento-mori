import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/lifespan_preview_card.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_picker.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/since_stepper.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';

/// "Which phase of your life are you in right now?": preset chips or an
/// own name, how long ago it began and a live lifespan preview. The body of
/// [PhaseEditScreen] and of the Compass setup's first step.
class PhaseEditForm extends StatefulWidget {
  const PhaseEditForm({
    super.key,
    required this.draft,
    required this.onSaved,
    this.firstTime = false,
  });

  final PhaseDraft draft;

  /// Called once the phase was saved.
  final VoidCallback onSaved;

  /// The very first phase (eyebrow "Compass · first time").
  final bool firstTime;

  @override
  State<PhaseEditForm> createState() => _PhaseEditFormState();
}

class _PhaseEditFormState extends State<PhaseEditForm> {
  late final TextEditingController _name =
      TextEditingController(text: _draft.name);
  PhaseStartError? _error;

  PhaseDraft get _draft => widget.draft;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _onPreset(PhasePreset? preset) => setState(() {
        _draft.preset = preset;
        if (preset != null) {
          _draft.name = '';
          _name.clear();
        }
      });

  void _onName(String name) => setState(() {
        _draft.name = name;
        _draft.preset = null;
      });

  void _onMonths(int months) => setState(() {
        _draft.setMonths(months);
        _error = null;
      });

  Future<void> _save({DateTime? day}) async {
    final error = _draft.validate(day: day);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await _draft.save(day: day);
    if (mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StepLayout(
      topPadding: 0,
      action: FilledButton(
        key: const ValueKey('phase_apply'),
        onPressed: _draft.canSave ? _save : null,
        child: Text(l10n.translate('phase_apply')),
      ),
      secondaryAction: _draft.isNew ? _startToday(l10n) : null,
      children: _content(context, l10n),
    );
  }

  Widget _startToday(AppLocalizations l10n) => TextButton(
        key: const ValueKey('phase_start_today'),
        onPressed: _draft.canSave ? () => _save(day: _draft.today) : null,
        child: Text(l10n.translate('phase_start_today')),
      );

  List<Widget> _content(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return [
      if (widget.firstTime)
        PhaseEyebrow(l10n.translate('phase_eyebrow_first'))
      else
        FittingPhaseEyebrow(
          long: l10n.translate('phase_header_eyebrow'),
          short: l10n.translate('phase_eyebrow'),
        ),
      Text(l10n.translate('phase_question'), style: theme.textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(l10n.translate('phase_intro'), style: PhaseStyle.muted(context)),
      const SizedBox(height: 24),
      PhasePicker(
        preset: _draft.preset,
        nameController: _name,
        onPresetChanged: _onPreset,
        onNameChanged: _onName,
      ),
      PhaseEyebrow(l10n.translate('phase_since_label'), top: 24),
      SinceStepper(
        months: _draft.months,
        maxMonths: _draft.maxMonths,
        onChanged: _onMonths,
      ),
      const SizedBox(height: 20),
      LifespanPreviewCard(
        name: _draft.displayName(l10n),
        months: _draft.months,
        fractions: _draft.fractions,
        share: _draft.share,
        lifeExpectancyYears: _draft.lifeExpectancyYears,
      ),
      if (_error case final error?) _errorText(context, l10n.startErrorText(error)),
    ];
  }

  Widget _errorText(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('phase_error'),
      padding: const EdgeInsets.only(top: 12),
      child: Text(text,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error)),
    );
  }
}
