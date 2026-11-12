import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Expected lifespan slider (50–120 years) with the time that may remain.
class LifespanSlider extends StatelessWidget {
  const LifespanSlider({
    super.key,
    required this.lifespan,
    required this.currentAge,
    required this.onChanged,
  });

  static const int minYears = 50;
  static const int maxYears = 120;

  final int lifespan;

  /// Age today; null while no birth date is chosen.
  final int? currentAge;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = FriendText(l10n);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final age = currentAge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('form_lifespan_help'), style: muted),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: lifespan.toDouble(),
                min: minYears.toDouble(),
                max: maxYears.toDouble(),
                divisions: maxYears - minYears,
                // No value bubble: the number is shown next to the slider,
                // and a label would be read out twice by screen readers.
                semanticFormatterCallback: (value) => l10n.translate(
                  'form_lifespan_semantics',
                  replacements: {'years': text.years(value.round())},
                ),
                onChanged: (value) => onChanged(value.round()),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$lifespan',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        if (age != null)
          Text(
            age >= lifespan
                ? l10n.translate('friend_beyond_expectancy')
                : l10n.translate(
                    'form_lifespan_remaining',
                    replacements: {'years': text.years(lifespan - age)},
                  ),
            style: muted,
          ),
      ],
    );
  }
}
