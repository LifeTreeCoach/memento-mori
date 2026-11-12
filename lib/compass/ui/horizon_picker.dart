import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Optional horizon: this season, this year, someday or "by age X" with a
/// number field. Tapping the selected chip clears it.
class HorizonPicker extends StatefulWidget {
  const HorizonPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.suggestedAge,
  });

  final Horizon? selected;
  final ValueChanged<Horizon?> onChanged;

  /// Age filled in when "by an age" is picked without one.
  final int suggestedAge;

  @override
  State<HorizonPicker> createState() => _HorizonPickerState();
}

class _HorizonPickerState extends State<HorizonPicker> {
  static const List<Horizon> _fixed = [
    Horizon.thisSeason,
    Horizon.thisYear,
    Horizon.someday,
  ];

  late final TextEditingController _age = TextEditingController(
      text: '${widget.selected?.age ?? widget.suggestedAge}');

  bool get _byAge => widget.selected?.kind == HorizonKind.byAge;

  @override
  void dispose() {
    _age.dispose();
    super.dispose();
  }

  void _selectByAge(bool on) {
    if (!on) return widget.onChanged(null);
    final age = int.tryParse(_age.text) ?? widget.suggestedAge;
    widget.onChanged(Horizon.byAge(age));
  }

  void _ageChanged(String text) {
    final age = int.tryParse(text);
    if (age != null) widget.onChanged(Horizon.byAge(age));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final horizon in _fixed)
              ChoiceChip(
                label: Text(l10n.horizonLabel(horizon)),
                selected: widget.selected == horizon,
                onSelected: (on) => widget.onChanged(on ? horizon : null),
              ),
            ChoiceChip(
              label: Text(l10n.translate('compass_horizon_by_age_chip')),
              selected: _byAge,
              onSelected: _selectByAge,
            ),
          ],
        ),
        if (_byAge) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            child: TextField(
              key: const ValueKey('compass_horizon_age'),
              controller: _age,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                  labelText: l10n.translate('compass_field_age')),
              onChanged: _ageChanged,
            ),
          ),
        ],
      ],
    );
  }
}
