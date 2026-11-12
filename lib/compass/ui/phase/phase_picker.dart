import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Rounded preset chips plus a field for an own name. Controlled: the
/// parent keeps [preset] and [nameController] mutually exclusive.
class PhasePicker extends StatelessWidget {
  const PhasePicker({
    super.key,
    required this.preset,
    required this.nameController,
    required this.onPresetChanged,
    required this.onNameChanged,
    this.presets = PhasePreset.onboarding,
  });

  final PhasePreset? preset;
  final TextEditingController nameController;
  final ValueChanged<PhasePreset?> onPresetChanged;
  final ValueChanged<String> onNameChanged;
  final List<PhasePreset> presets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final p in presets) _chip(context, l10n, p)],
        ),
        PhaseEyebrow(l10n.translate('phase_custom_label'), top: 24),
        TextField(
          key: const ValueKey('phase_custom_name'),
          controller: nameController,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 60,
          decoration: InputDecoration(
            hintText: l10n.translate('phase_custom_hint'),
            counterText: '',
          ),
          onChanged: onNameChanged,
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, AppLocalizations l10n, PhasePreset p) {
    final scheme = Theme.of(context).colorScheme;
    final selected = p == preset;
    return ChoiceChip(
      key: ValueKey('phase_preset_${p.name}'),
      label: Text(l10n.presetName(p)),
      selected: selected,
      showCheckmark: false,
      shape: const StadiumBorder(),
      selectedColor: scheme.onSurface,
      labelStyle: TextStyle(
        color: selected ? scheme.surface : scheme.onSurface,
      ),
      onSelected: (on) => onPresetChanged(on ? p : null),
    );
  }
}
