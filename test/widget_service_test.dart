import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() async {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'),
            (call) async {
      calls.add(call);
      return true;
    });
    SharedPreferences.setMockInitialValues({
      'birth_date': '1990-03-15T00:00:00.000',
      'language': 'en',
    });
    await SettingsService.initialize();
    WidgetService.resetPublishedForTesting();
  });

  int updates() => calls.where((c) => c.method == 'updateWidget').length;
  Iterable<MethodCall> saves() =>
      calls.where((c) => c.method == 'saveWidgetData');

  test('publishes every input and redraws the widget', () async {
    await WidgetService.publishInputs();
    expect(updates(), 1);
    final saved = {for (final c in saves()) c.arguments['id']: c.arguments['data']};
    expect(saved['birth_date'], '1990-03-15');
    expect(saved['life_expectancy_years'], 80);
    expect(saved['schema_version'], WidgetService.schemaVersion);
  });

  test('unchanged inputs are not written again', () async {
    await WidgetService.publishInputs();
    calls.clear();
    await WidgetService.publishInputs();
    expect(calls, isEmpty);
  });

  test('changed inputs are published again', () async {
    await WidgetService.publishInputs();
    calls.clear();
    await SettingsService.setLifeExpectancyYears(90);
    await WidgetService.publishInputs();
    expect(updates(), 1);
    expect(
      saves().singleWhere((c) => c.arguments['id'] == 'life_expectancy_years')
          .arguments['data'],
      90,
    );
  });

  Map<String, Object?> savedValues() =>
      {for (final c in saves()) c.arguments['id'] as String: c.arguments['data']};

  group('dark colours of a user colour theme', () {
    test('are published adapted like the dark app', () async {
      SettingsService.setColorTheme('ocean');
      await SettingsService.setThemeStyle('warm');
      await WidgetService.publishInputs();

      final ocean = ColorThemes.getTheme('ocean');
      final dark = LifePalette.resolve(
        ThemeStyle.warm,
        Brightness.dark,
        gridOverride: LifePaletteColors.fromColorTheme(ocean),
      );
      final saved = savedValues();
      expect(saved['color_lived'], ocean.livedColor.toARGB32());
      expect(saved['color_remaining'], ocean.remainingColor.toARGB32());
      expect(saved['color_lived_dark'], dark.lived.toARGB32());
      expect(saved['color_remaining_dark'], dark.remaining.toARGB32());
      expect(saved['color_accent_dark'], dark.now.toARGB32());
      expect(saved['color_remaining_dark'],
          isNot(ocean.remainingColor.toARGB32()));
    });

    test('are removed again for the style palette', () async {
      SettingsService.setColorTheme('ocean');
      await WidgetService.publishInputs();
      calls.clear();
      SettingsService.setColorTheme(ColorThemes.styleDefaultId);
      await WidgetService.publishInputs();

      final saved = savedValues();
      for (final key in WidgetService.darkColorKeys) {
        expect(saved.containsKey(key), isTrue, reason: key);
        expect(saved[key], isNull, reason: key);
      }
    });
  });
}
