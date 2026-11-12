import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/sheet_title.dart';

const int minLifeExpectancyYears = 50;
const int maxLifeExpectancyYears = 110;

/// Sheet with a 50–110 year slider; resolves to the chosen value on save,
/// or null when dismissed. With [onEstimate], an "Estimate from data" button
/// closes the sheet and calls it.
Future<int?> showLifeExpectancySheet(
  BuildContext context,
  int current, {
  VoidCallback? onEstimate,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        _LifeExpectancySheet(initial: current, onEstimate: onEstimate),
  );
}

class _LifeExpectancySheet extends StatefulWidget {
  const _LifeExpectancySheet({required this.initial, this.onEstimate});

  final int initial;
  final VoidCallback? onEstimate;

  @override
  State<_LifeExpectancySheet> createState() => _LifeExpectancySheetState();
}

class _LifeExpectancySheetState extends State<_LifeExpectancySheet> {
  late double _years = widget.initial
      .clamp(minLifeExpectancyYears, maxLifeExpectancyYears)
      .toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final years = _years.round();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.translate('settings_life_expectancy')),
          const SizedBox(height: 8),
          Text(
            l10n.translate(
              'settings_years_value',
              replacements: {'n': '$years'},
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Slider(
              value: _years,
              min: minLifeExpectancyYears.toDouble(),
              max: maxLifeExpectancyYears.toDouble(),
              divisions: maxLifeExpectancyYears - minLifeExpectancyYears,
              label: '$years',
              semanticFormatterCallback: (value) =>
                  l10n.plural('friend_years', value.round()),
              onChanged: (value) => setState(() => _years = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.translate('settings_life_expectancy_note'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.onEstimate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton.icon(
                  key: const ValueKey('life_expectancy_estimate'),
                  icon: const Icon(Icons.insights_outlined),
                  label: Text(l10n.translate('estimate_estimate_from_data')),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onEstimate!();
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: FilledButton(
              onPressed: () => Navigator.pop(context, years),
              child: Text(MaterialLocalizations.of(context).saveButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
