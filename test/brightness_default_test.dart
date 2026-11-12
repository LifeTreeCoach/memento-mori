import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _init(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  await SettingsService.initialize();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          (_) async => true,
        );
  });

  test('brightness defaults to light when nothing is stored', () async {
    await _init({});
    expect(SettingsService.defaultBrightness, AppBrightness.light);
    expect(SettingsService.getBrightness(), 'light');
    final controller = AppSettingsController();
    addTearDown(controller.dispose);
    expect(controller.brightness, AppBrightness.light);
    expect(controller.themeMode, ThemeMode.light);
  });

  for (final stored in AppBrightness.values) {
    test('a stored "${stored.id}" choice is respected', () async {
      await _init({'brightness': stored.id});
      expect(SettingsService.getBrightness(), stored.id);
      final controller = AppSettingsController();
      addTearDown(controller.dispose);
      expect(controller.themeMode, stored.themeMode);
    });
  }

  test('setBrightness stores the choice', () async {
    await _init({});
    final controller = AppSettingsController();
    addTearDown(controller.dispose);
    await controller.setBrightness(AppBrightness.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('brightness'), 'dark');
  });
}
