import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/area_chips.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_field_label.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/horizon_picker.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// The folded "More" of the intention flow: a note, the life area and the
/// horizon. Collapsed it is just the toggle.
class IntentionMoreFields extends StatelessWidget {
  const IntentionMoreFields({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.note,
    required this.area,
    required this.onArea,
    required this.horizon,
    required this.onHorizon,
    required this.suggestedAge,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController note;
  final LifeArea? area;
  final ValueChanged<LifeArea?> onArea;
  final Horizon? horizon;
  final ValueChanged<Horizon?> onHorizon;
  final int suggestedAge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('intention_more'),
            icon: Icon(expanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded),
            label: Text(
                l10n.translate(expanded ? 'intention_less' : 'intention_more')),
            onPressed: onToggle,
          ),
        ),
        if (expanded) ..._fields(l10n),
      ],
    );
  }

  List<Widget> _fields(AppLocalizations l10n) => [
        TextField(
          key: const ValueKey('compass_intention_note'),
          controller: note,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration:
              InputDecoration(labelText: l10n.translate('compass_field_note')),
        ),
        CompassFieldLabel(l10n.translate('compass_field_area')),
        AreaChips(selected: area, onChanged: onArea),
        CompassFieldLabel(l10n.translate('compass_field_horizon')),
        HorizonPicker(
          selected: horizon,
          suggestedAge: suggestedAge,
          onChanged: onHorizon,
        ),
      ];
}
