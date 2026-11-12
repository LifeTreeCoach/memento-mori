import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/visualization_effects.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('VisualizationEffects.getSeasonalColor', () {
    const base = Color(0xFF808080);

    test('keeps the colour bright (channels stay in 0..1)', () {
      // Week 20 = spring, factor 1.2.
      final spring = VisualizationEffects.getSeasonalColor(base, 20, 52);
      expect(spring.r, closeTo(base.r * 1.2, 1e-6));
      expect(spring.g, closeTo(base.g * 1.2, 1e-6));
      expect(spring.b, closeTo(base.b * 1.2, 1e-6));
      expect(spring.a, base.a);
    });

    test('darkens winter weeks and clamps at white', () {
      final winter = VisualizationEffects.getSeasonalColor(base, 0, 52);
      expect(winter.r, closeTo(base.r * 0.8, 1e-6));
      final white = VisualizationEffects.getSeasonalColor(Colors.white, 20, 52);
      expect(white.r, 1.0);
    });
  });

  group('SettingsService visualization settings', () {
    setUp(() async {
      const stored = VisualizationSettings(enableSeasons: true);
      SharedPreferences.setMockInitialValues({
        'visualization_settings': jsonEncode(stored.toMap()),
      });
      await SettingsService.initialize();
    });

    test('decodes once and returns the cached object', () {
      final first = SettingsService.getVisualizationSettings();
      expect(first.enableSeasons, isTrue);
      expect(identical(SettingsService.getVisualizationSettings(), first),
          isTrue);
    });

    test('a save replaces the cached value', () async {
      SettingsService.getVisualizationSettings();
      SettingsService.setVisualizationSettings(
          const VisualizationSettings(enableSeasons: false));
      expect(SettingsService.getVisualizationSettings().enableSeasons, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('visualization_settings'), contains('false'));
    });
  });

  group('VisualizationEffects.getMilestoneColor', () {
    test('marks decade years in every view', () {
      expect(VisualizationEffects.getMilestoneColor(519, 52), isNull); // year 9
      expect(VisualizationEffects.getMilestoneColor(520, 52), isNotNull); // year 10
      expect(VisualizationEffects.getMilestoneColor(571, 52), isNotNull); // still year 10
      expect(VisualizationEffects.getMilestoneColor(572, 52), isNull); // year 11
      expect(VisualizationEffects.getMilestoneColor(240, 12), isNotNull); // month view, year 20
      expect(VisualizationEffects.getMilestoneColor(30, 1), isNotNull); // year view
      expect(VisualizationEffects.getMilestoneColor(0, 52), isNull);
    });

    test('views without enough items per year keep their colour', () {
      const base = Color(0xFF336699);
      expect(VisualizationEffects.getSeasonalColor(base, 5, 1), base);
    });
  });

  group('VisualizationSettings.showPhases', () {
    test('is on by default and for maps saved before it existed', () {
      expect(const VisualizationSettings().showPhases, isTrue);
      expect(VisualizationSettings.fromMap({'layoutType': 1}).showPhases, isTrue);
    });

    test('tolerates a value of the wrong type', () {
      expect(VisualizationSettings.fromMap({'showPhases': 'no'}).showPhases,
          isTrue);
    });

    test('round-trips through toMap/fromMap and copyWith', () {
      final off = const VisualizationSettings().copyWith(showPhases: false);
      expect(off.showPhases, isFalse);
      expect(off.copyWith(enableSeasons: true).showPhases, isFalse);
      final decoded = VisualizationSettings.fromMap(
          jsonDecode(jsonEncode(off.toMap())) as Map<String, dynamic>);
      expect(decoded.showPhases, isFalse);
    });

    test('is persisted by SettingsService', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.initialize();
      SettingsService.setVisualizationSettings(
          const VisualizationSettings(showPhases: false));
      await SettingsService.initialize();
      expect(SettingsService.getVisualizationSettings().showPhases, isFalse);
    });
  });
}
