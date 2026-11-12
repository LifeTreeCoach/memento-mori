import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/planned_duration.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/since_stepper.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// "6 months · 1 year · 2 years · 5 years · Open" chips plus an optional
/// fine stepper (years and months, at most [maxMonths]). Controlled.
class PlannedDurationPicker extends StatefulWidget {
  const PlannedDurationPicker({
    super.key,
    required this.value,
    required this.maxMonths,
    required this.onChanged,
  });

  final PlannedDuration value;
  final int maxMonths;
  final ValueChanged<PlannedDuration> onChanged;

  /// Localized chip label of [duration] ("1 year", "Open").
  static String label(AppLocalizations l10n, PlannedDuration duration) {
    final months = duration.months;
    if (months == null) return l10n.translate('duration_open');
    return months % 12 == 0
        ? l10n.plural('phase_duration_years', months ~/ 12)
        : l10n.plural('phase_duration_months', months);
  }

  @override
  State<PlannedDurationPicker> createState() => _PlannedDurationPickerState();
}

class _PlannedDurationPickerState extends State<PlannedDurationPicker> {
  late bool _fine = !PlannedDuration.choices.contains(widget.value);

  void _onStep(int months) => widget.onChanged(months <= 0
      ? const PlannedDuration.open()
      : PlannedDuration.months(months));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in PlannedDuration.choices)
              _chip(context, l10n, choice),
          ],
        ),
        const SizedBox(height: 4),
        if (_fine)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SinceStepper(
              months: widget.value.months ?? 0,
              maxMonths: widget.maxMonths,
              onChanged: _onStep,
            ),
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey('duration_fine'),
              onPressed: () => setState(() => _fine = true),
              child: Text(l10n.translate('duration_fine')),
            ),
          ),
      ],
    );
  }

  Widget _chip(
      BuildContext context, AppLocalizations l10n, PlannedDuration choice) {
    final scheme = Theme.of(context).colorScheme;
    final selected = choice == widget.value;
    final months = choice.months;
    return ChoiceChip(
      key: ValueKey('duration_choice_${months ?? 'open'}'),
      label: Text(PlannedDurationPicker.label(l10n, choice)),
      selected: selected,
      showCheckmark: false,
      shape: const StadiumBorder(),
      selectedColor: scheme.onSurface,
      labelStyle: TextStyle(color: selected ? scheme.surface : scheme.onSurface),
      onSelected: (_) => widget.onChanged(choice),
    );
  }
}
