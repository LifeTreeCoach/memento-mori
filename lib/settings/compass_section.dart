import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_actions.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';

/// Compass: life phases, gentle questions only, moments on the life grid,
/// the question card on the Life tab, the look back after completing and
/// the weekly moment after the Sunday reminder.
class CompassSection extends StatefulWidget {
  const CompassSection({super.key});

  @override
  State<CompassSection> createState() => _CompassSectionState();
}

class _CompassSectionState extends State<CompassSection> {
  /// "Life phases" opens the phase sheet (or the editor without a phase).
  late final PhaseActions _phases = PhaseActions(
    contextOf: () => context,
    today: DateTime.now,
    birthDate: SettingsService.getBirthDate,
    lifeExpectancyYears: SettingsService.getLifeExpectancyYears,
  );

  @override
  void initState() {
    super.initState();
    // Values may still be loading on a cold start.
    CompassService.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _set(Future<void> Function(bool) setter, bool value) async {
    await setter(value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.translate('settings_section_compass'),
      children: [
        ListTile(
          key: const ValueKey('compass_setting_phases'),
          leading: const Icon(Icons.timeline_rounded),
          title: Text(l10n.translate('compass_setting_phases')),
          subtitle: Text(l10n.translate('compass_setting_phases_sub')),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _phases.openSheet,
        ),
        _switch(
          l10n,
          key: 'compass_setting_gentle',
          icon: Icons.spa_outlined,
          value: CompassService.gentleOnly,
          setter: CompassService.setGentleOnly,
        ),
        _switch(
          l10n,
          key: 'compass_setting_grid_marks',
          icon: Icons.grid_view_outlined,
          value: CompassService.showGridMarks,
          setter: CompassService.setShowGridMarks,
        ),
        _switch(
          l10n,
          key: 'compass_setting_life_card',
          icon: Icons.help_outline_rounded,
          value: CompassService.showLifeCard,
          setter: CompassService.setShowLifeCard,
        ),
        _switch(
          l10n,
          key: 'compass_setting_reflection',
          icon: Icons.auto_awesome_outlined,
          value: CompassService.showReflection,
          setter: CompassService.setShowReflection,
        ),
        _switch(
          l10n,
          key: 'compass_setting_week_moment',
          icon: Icons.calendar_view_week_outlined,
          value: WeekMomentStore.enabled,
          setter: WeekMomentStore.setEnabled,
        ),
      ],
    );
  }

  /// A switch titled `<key>` with the subtitle `<key>_sub`.
  Widget _switch(
    AppLocalizations l10n, {
    required String key,
    required IconData icon,
    required bool value,
    required Future<void> Function(bool) setter,
  }) {
    return SwitchListTile(
      key: ValueKey(key),
      secondary: Icon(icon),
      title: Text(l10n.translate(key)),
      subtitle: Text(l10n.translate('${key}_sub')),
      value: value,
      onChanged: (on) => _set(setter, on),
    );
  }
}
