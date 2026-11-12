import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_service.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/settings/choice_tile.dart';
import 'package:memento_mori_life_in_weeks/settings/palette_swatch.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';

/// Theme, grid palette and layout, visual effects and language.
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key, required this.settings});

  final AppSettingsController settings;

  Future<void> _setLanguage(String language) async {
    await settings.setLanguage(language);
    // Synced birthday events carry a localized title.
    unawaited(CalendarService.requestSync());
    await ReminderService.rescheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.translate('settings_section_appearance'),
      children: [
        ChoiceTile<ThemeStyle>(
          icon: Icons.palette_outlined,
          title: l10n.translate('theme_style'),
          options: [
            for (final style in ThemeStyle.values)
              SettingsOption(style, l10n.translate(style.labelKey)),
          ],
          selected: settings.themeStyle,
          onChanged: settings.setThemeStyle,
        ),
        ChoiceTile<AppBrightness>(
          icon: Icons.brightness_6_outlined,
          title: l10n.translate('brightness'),
          options: [
            for (final brightness in AppBrightness.values)
              SettingsOption(brightness, l10n.translate(brightness.labelKey)),
          ],
          selected: settings.brightness,
          onChanged: settings.setBrightness,
        ),
        _paletteTile(context, l10n),
        _layoutTile(l10n),
        ..._effectSwitches(l10n),
        ..._lifespanSwitches(l10n),
        ChoiceTile<String>(
          icon: Icons.translate,
          title: l10n.translate('language'),
          options: [
            for (final code in AppLocalizations.supportedLanguages)
              SettingsOption(
                  code, AppLocalizations.languageNames[code] ?? code),
          ],
          selected: settings.language,
          onChanged: _setLanguage,
        ),
      ],
    );
  }

  Widget _paletteTile(BuildContext context, AppLocalizations l10n) {
    final styleDefault = LifePalette.of(context).toColorTheme();
    ColorTheme preview(String id) => ColorThemes.isStyleDefault(id)
        ? styleDefault
        : ColorThemes.getTheme(id);
    return ChoiceTile<String>(
      icon: Icons.grid_on_outlined,
      title: l10n.translate('settings_grid_palette'),
      options: [
        for (final id in ColorThemes.getSelectableThemeIds())
          SettingsOption(
            id,
            l10n.translate(preview(id).nameKey),
            preview: PaletteSwatch(theme: preview(id)),
          ),
      ],
      selected: settings.colorThemeId,
      onChanged: settings.setColorTheme,
    );
  }

  Widget _layoutTile(AppLocalizations l10n) {
    final visual = settings.visualization;
    return ChoiceTile<LayoutType>(
      icon: Icons.auto_awesome_mosaic_outlined,
      title: l10n.translate('settings_layout'),
      options: [
        for (final layout in LayoutType.values)
          SettingsOption(layout, l10n.translate('layout_${layout.name}')),
      ],
      selected: visual.layoutType,
      onChanged: (layout) =>
          settings.setVisualization(visual.copyWith(layoutType: layout)),
    );
  }

  List<Widget> _effectSwitches(AppLocalizations l10n) {
    final visual = settings.visualization;
    void update(VisualizationSettings next) => settings.setVisualization(next);
    return [
      _switch(l10n, Icons.flag_outlined, 'settings_milestones',
          visual.enableMilestones,
          (v) => update(visual.copyWith(enableMilestones: v))),
      _switch(l10n, Icons.eco_outlined, 'settings_seasons',
          visual.enableSeasons,
          (v) => update(visual.copyWith(enableSeasons: v))),
      _switch(l10n, Icons.gradient, 'settings_gradients',
          visual.enableGradients,
          (v) => update(visual.copyWith(enableGradients: v))),
      _switch(l10n, Icons.motion_photos_on_outlined, 'settings_animations',
          visual.enableAnimations,
          (v) => update(visual.copyWith(enableAnimations: v))),
      _switch(l10n, Icons.view_timeline_outlined, 'settings_phases',
          visual.showPhases, (v) => update(visual.copyWith(showPhases: v))),
    ];
  }

  List<Widget> _lifespanSwitches(AppLocalizations l10n) {
    return [
      _switch(l10n, Icons.donut_large_outlined, 'settings_lifespan',
          settings.lifespanVisualization, settings.setLifespanVisualization),
      if (settings.lifespanVisualization)
        _switch(l10n, Icons.waves_outlined, 'settings_lifespan_animation',
            settings.lifespanAnimation, settings.setLifespanAnimation),
    ];
  }

  /// Switch whose subtitle is the `<titleKey>_sub` string.
  Widget _switch(AppLocalizations l10n, IconData icon, String titleKey,
      bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(l10n.translate(titleKey)),
      subtitle: Text(l10n.translate('${titleKey}_sub')),
      value: value,
      onChanged: onChanged,
    );
  }
}
