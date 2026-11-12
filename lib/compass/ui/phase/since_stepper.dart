import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Pure stepping rules of [SinceStepper] on a total of months.
class SinceSteps {
  SinceSteps._();

  /// Upper bound without a birth date.
  static const int maxMonthsWithoutBirthDate = 100 * 12;

  /// [months] with the years changed by [delta] (months kept, clamped to
  /// [max]); null when not possible.
  static int? addYears(int months, int delta, int max) {
    final years = months ~/ 12 + delta;
    if (years < 0 || years * 12 > max) return null;
    final next = years * 12 + months % 12;
    return next > max ? max : next;
  }

  /// [months] with the month part changed by [delta] (0..11, at most
  /// [max] in total); null when not possible.
  static int? addMonths(int months, int delta, int max) {
    final rest = months % 12 + delta;
    if (rest < 0 || rest > 11) return null;
    final next = months ~/ 12 * 12 + rest;
    return next > max ? null : next;
  }
}

/// "– 4 Jahre +" and "– 2 Monate +": how long ago something began, at most
/// [maxMonths] (the age when the birth date is known).
class SinceStepper extends StatelessWidget {
  const SinceStepper({
    super.key,
    required this.months,
    required this.maxMonths,
    required this.onChanged,
  });

  final int months;
  final int maxMonths;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _box(context, 'years', months ~/ 12, SinceSteps.addYears)),
        const SizedBox(width: 12),
        Expanded(
            child: _box(context, 'months', months % 12, SinceSteps.addMonths)),
      ],
    );
  }

  Widget _box(BuildContext context, String unit, int value,
      int? Function(int, int, int) step) {
    final l10n = AppLocalizations.of(context);
    final less = step(months, -1, maxMonths);
    final more = step(months, 1, maxMonths);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _button(l10n, 'phase_${unit}_less', Icons.remove_rounded, less),
          Expanded(child: _value(context, l10n, unit, value)),
          _button(l10n, 'phase_${unit}_more', Icons.add_rounded, more),
        ],
      ),
    );
  }

  Widget _button(
      AppLocalizations l10n, String key, IconData icon, int? next) {
    return IconButton(
      key: ValueKey(key),
      visualDensity: VisualDensity.compact,
      tooltip: l10n.translate(key.endsWith('less') ? 'phase_less' : 'phase_more'),
      icon: Icon(icon),
      onPressed: next == null ? null : () => onChanged(next),
    );
  }

  Widget _value(
      BuildContext context, AppLocalizations l10n, String unit, int value) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: theme.textTheme.headlineSmall),
        Text(
          l10n.plural('phase_unit_$unit', value),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
