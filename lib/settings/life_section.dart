import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_profile_store.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/settings/choice_tile.dart';
import 'package:memento_mori_life_in_weeks/settings/life_expectancy_sheet.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';

const List<String> lifeDisplayModes = ['weeks', 'months', 'years'];

/// Birth date, life expectancy and the Life tab's default view.
class LifeSection extends StatelessWidget {
  const LifeSection({
    super.key,
    required this.settings,
    this.lifespanStore = const SettingsLifespanProfileStore(),
  });

  final AppSettingsController settings;

  /// The user's own lifespan estimate (summary + where applying saves).
  final LifespanProfileStore lifespanStore;

  Future<void> _pickBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: settings.birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    await settings.setBirthDate(picked);
    // The weekly reflection's questions follow the life stage.
    await ReminderService.refreshWeeklyReflection();
  }

  Future<void> _pickLifeExpectancy(BuildContext context) async {
    final years = await showLifeExpectancySheet(
      context,
      settings.lifeExpectancyYears,
      onEstimate: settings.birthDate == null
          ? null
          : () => _openEstimate(context),
    );
    if (years != null) await settings.setLifeExpectancyYears(years);
  }

  Future<void> _openEstimate(BuildContext context) =>
      LifespanEstimateScreen.open(context, settings, store: lifespanStore);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.translate('settings_section_life'),
      children: [
        ListTile(
          leading: const Icon(Icons.cake_outlined),
          title: Text(l10n.translate('settings_birth_date')),
          subtitle: Text(_birthDateLabel(l10n)),
          onTap: () => _pickBirthDate(context),
        ),
        ListTile(
          leading: const Icon(Icons.hourglass_empty_rounded),
          title: Text(l10n.translate('settings_life_expectancy')),
          subtitle: Text(l10n.translate('settings_years_value',
              replacements: {'n': '${settings.lifeExpectancyYears}'})),
          onTap: () => _pickLifeExpectancy(context),
        ),
        ListTile(
          key: const ValueKey('settings_lifespan_estimate'),
          leading: const Icon(Icons.insights_outlined),
          title: Text(l10n.translate('estimate_settings_title')),
          subtitle: Text(_estimateLabel(l10n)),
          enabled: settings.birthDate != null,
          onTap: () => _openEstimate(context),
        ),
        ChoiceTile<String>(
          icon: Icons.grid_view_outlined,
          title: l10n.translate('settings_default_view'),
          options: [
            for (final mode in lifeDisplayModes)
              SettingsOption(mode, l10n.translate(mode)),
          ],
          selected: settings.displayMode,
          onChanged: settings.setDisplayMode,
        ),
      ],
    );
  }

  /// "About 86 · 79–94", "· adjusted by you" when the life expectancy no
  /// longer matches the applied estimate.
  String _estimateLabel(AppLocalizations l10n) {
    if (settings.birthDate == null) {
      return l10n.translate('estimate_settings_needs_birth_date');
    }
    final applied = lifespanStore.load().applied;
    if (applied == null) return l10n.translate('estimate_settings_sub');
    final estimate = applied.estimate;
    final summary = l10n.translate('estimate_settings_summary', replacements: {
      'mean': '${estimate.mean.round()}',
      'p25': '${estimate.p25.round()}',
      'p75': '${estimate.p75.round()}',
    });
    if (settings.lifeExpectancyYears == applied.appliedYears) return summary;
    return '$summary · ${l10n.translate('estimate_adjusted')}';
  }

  String _birthDateLabel(AppLocalizations l10n) {
    final date = settings.birthDate;
    if (date == null) return l10n.translate('settings_birth_date_unset');
    return l10n.shortDateFormat.format(date);
  }
}
