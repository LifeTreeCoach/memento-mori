import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/earlier_phase_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_picker.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/start_value_stepper.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';

/// Opens the earlier phase form full screen; true once saved.
Future<bool> showEarlierPhaseForm(
    BuildContext context, EarlierPhaseDraft draft) async {
  final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => EarlierPhaseForm(draft: draft),
  ));
  return saved ?? false;
}

/// "Which phase was it?": every preset (incl. childhood and school) or an
/// own name, and when it began ("From the age of 6", or a year without a
/// birth date). Pops true once saved.
class EarlierPhaseForm extends StatefulWidget {
  const EarlierPhaseForm({super.key, required this.draft});

  final EarlierPhaseDraft draft;

  @override
  State<EarlierPhaseForm> createState() => _EarlierPhaseFormState();
}

class _EarlierPhaseFormState extends State<EarlierPhaseForm> {
  late final _name = TextEditingController(text: _draft.name);
  PhaseStartError? _error;

  EarlierPhaseDraft get _draft => widget.draft;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _onPreset(PhasePreset? preset) => setState(() {
        _draft.preset = preset;
        if (preset == null) return;
        _draft.name = '';
        _name.clear();
      });

  void _onName(String name) => setState(() {
        _draft.name = name;
        _draft.preset = null;
      });

  Future<void> _save() async {
    final error = _draft.validate();
    if (error != null) return setState(() => _error = error);
    await _draft.save();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: StepLayout(
          topPadding: 0,
          action: FilledButton(
            key: const ValueKey('earlier_save'),
            onPressed: _draft.canSave ? _save : null,
            child: Text(l10n.translate('earlier_save')),
          ),
          children: _content(context, l10n),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return [
      PhaseEyebrow(l10n.translate('earlier_title')),
      Text(l10n.translate('earlier_form_title'),
          style: theme.textTheme.headlineMedium),
      const SizedBox(height: 24),
      PhasePicker(
        preset: _draft.preset,
        nameController: _name,
        onPresetChanged: _onPreset,
        onNameChanged: _onName,
        presets: PhasePreset.values,
      ),
      PhaseEyebrow(l10n.translate('earlier_start_label'), top: 24),
      StartValueStepper(
        value: _draft.value,
        min: _draft.min,
        max: _draft.max,
        label: (v) => _startLabel(l10n, v),
        onChanged: (v) => setState(() {
          _draft.setValue(v);
          _error = null;
        }),
      ),
      if (_error case final error?) _errorText(context, l10n.startErrorText(error)),
    ];
  }

  String _startLabel(AppLocalizations l10n, int value) => _draft.byAge
      ? l10n.plural('earlier_from_age', value)
      : l10n.translate('earlier_from_year', replacements: {'year': '$value'});

  Widget _errorText(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('earlier_error'),
      padding: const EdgeInsets.only(top: 12),
      child: Text(text,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error)),
    );
  }
}
