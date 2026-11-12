import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/staggered_intro.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/onboarding/year_strip.dart';

/// Step 1: one quiet line, the birth date (with this year of life as week
/// squares) and an optional name.
class BirthDateStep extends StatelessWidget {
  const BirthDateStep({
    super.key,
    required this.birthDate,
    required this.today,
    required this.canContinue,
    required this.nameController,
    required this.onBirthDateChanged,
    required this.onContinue,
  });

  final DateTime? birthDate;
  final DateTime today;
  final bool canContinue;
  final TextEditingController nameController;
  final ValueChanged<DateTime> onBirthDateChanged;
  final VoidCallback onContinue;

  /// Suggested start of the picker when nothing is chosen yet.
  static const int _suggestedAge = 30;

  Future<void> _pickDate(BuildContext context) async {
    final lastDate = DateTime(today.year, today.month, today.day - 1);
    final initial =
        birthDate ??
        DateTime(today.year - _suggestedAge, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate) ? lastDate : initial,
      firstDate: DateTime(1900),
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) onBirthDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return StepLayout(
      action: FilledButton(
        onPressed: canContinue ? onContinue : null,
        child: Text(l10n.translate('onboarding_continue')),
      ),
      topPadding: 32,
      children: [
        StaggeredIntro(
          children: [
            Text(
              l10n.translate('onboarding_title'),
              style: theme.textTheme.headlineLarge,
            ),
            Text(
              l10n.translate('onboarding_subtitle'),
              style: theme.textTheme.bodyLarge?.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _DateField(date: birthDate, onTap: () => _pickDate(context)),
        const SizedBox(height: 16),
        YearStrip(birthDate: birthDate, today: today),
        const SizedBox(height: 24),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            // "Optional" sits in the helper: one long label gets ellipsized.
            labelText: l10n.translate('onboarding_name_label'),
            hintText: l10n.translate('onboarding_name_hint'),
            helperText: l10n.translate('onboarding_name_helper'),
          ),
        ),
      ],
    );
  }
}

/// A large tappable date: label above, the date (or a hint) in serif.
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = date;
    final text = value == null
        ? l10n.translate('onboarding_birth_date_hint')
        : l10n.shortDateFormat.format(value);
    return Material(
      color:
          theme.inputDecorationTheme.fillColor ?? scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const ValueKey('onboarding_birth_date'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('onboarding_birth_date_label'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: value == null ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
