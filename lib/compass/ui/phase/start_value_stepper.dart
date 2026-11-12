import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// "– From the age of 6 +": one whole number between [min] and [max] with
/// its text from [label].
class StartValueStepper extends StatelessWidget {
  const StartValueStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final String Function(int value) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _button('earlier_start_less', l10n.translate('phase_less'),
              Icons.remove_rounded, value > min ? value - 1 : null),
          Expanded(
            child: Text(label(value),
                key: const ValueKey('earlier_start_value'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium),
          ),
          _button('earlier_start_more', l10n.translate('phase_more'),
              Icons.add_rounded, value < max ? value + 1 : null),
        ],
      ),
    );
  }

  Widget _button(String key, String tooltip, IconData icon, int? next) =>
      IconButton(
        key: ValueKey(key),
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: next == null ? null : () => onChanged(next),
      );
}
