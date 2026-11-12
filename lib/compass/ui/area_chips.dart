import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Optional life area as a wrap of chips; tapping the selected chip
/// clears it.
class AreaChips extends StatelessWidget {
  const AreaChips({super.key, required this.selected, required this.onChanged});

  final LifeArea? selected;
  final ValueChanged<LifeArea?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final area in LifeArea.values)
          ChoiceChip(
            key: ValueKey('compass_area_${area.name}'),
            // The selected chip shows a check mark like the horizon chips
            // (in place of its icon, so the label doesn't shift).
            avatar: Icon(
              area == selected ? Icons.check_rounded : lifeAreaIcon(area),
              size: 18,
            ),
            label: Text(l10n.areaLabel(area)),
            selected: area == selected,
            showCheckmark: false,
            onSelected: (on) => onChanged(on ? area : null),
          ),
      ],
    );
  }
}
