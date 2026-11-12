import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Weeks · Months · Years.
class LifeModeSelector extends StatelessWidget {
  const LifeModeSelector({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final LifeMode mode;
  final ValueChanged<LifeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<LifeMode>(
        showSelectedIcon: false,
        segments: [
          for (final m in LifeMode.values)
            ButtonSegment(value: m, label: Text(l10n.translate(m.id))),
        ],
        selected: {mode},
        onSelectionChanged: (selection) {
          Haptics.selection();
          onChanged(selection.first);
        },
      ),
    );
  }
}
