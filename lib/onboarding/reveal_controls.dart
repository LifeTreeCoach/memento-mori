import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/language_button.dart';
import 'package:memento_mori_life_in_weeks/settings/life_expectancy_sheet.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Two compact rows under the reveal: a life expectancy stepper and the
/// language choice.
class RevealControls extends StatelessWidget {
  const RevealControls({
    super.key,
    required this.lifeExpectancyYears,
    required this.onLifeExpectancyChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  final int lifeExpectancyYears;
  final ValueChanged<int> onLifeExpectancyChanged;
  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _ControlRow(
          label: l10n.translate('settings_life_expectancy'),
          control: _YearsStepper(
            years: lifeExpectancyYears,
            onChanged: onLifeExpectancyChanged,
          ),
        ),
        const SizedBox(height: 8),
        _ControlRow(
          label: l10n.translate('language'),
          control: LanguageButton(
            key: const ValueKey('onboarding_reveal_language_button'),
            language: language,
            onChanged: onLanguageChanged,
          ),
        ),
      ],
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.label, required this.control});

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        control,
      ],
    );
  }
}

/// "−  80 years  +", clamped to the range of the Settings slider.
class _YearsStepper extends StatelessWidget {
  const _YearsStepper({required this.years, required this.onChanged});

  final int years;
  final ValueChanged<int> onChanged;

  static const int _step = 1;

  void _change(int delta) {
    Haptics.selection();
    onChanged(years + delta);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.translate('onboarding_fewer_years'),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove),
          onPressed: years > minLifeExpectancyYears
              ? () => _change(-_step)
              : null,
        ),
        SizedBox(
          width: 84,
          child: Text(
            l10n.translate(
              'settings_years_value',
              replacements: {'n': '$years'},
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.translate('onboarding_more_years'),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          onPressed: years < maxLifeExpectancyYears
              ? () => _change(_step)
              : null,
        ),
      ],
    );
  }
}
