import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tours_seen.dart';

export 'tours_seen.dart' show allToursSeen;

/// Monday of an even Compass week (index 148): a courage week unless
/// "gentle only" is on.
final DateTime compassToday = DateTime(2026, 11, 2);

final DateTime compassBirthDate = DateTime(1990, 11, 17);


/// Fresh settings, friends and Compass state in [lang]. Product tours
/// count as seen unless [toursSeen] is false, so their overlay stays out
/// of tests about something else.
Future<void> initCompassTest({
  String lang = 'en',
  Map<String, Object> extra = const {},
  bool toursSeen = true,
}) async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': compassBirthDate.toIso8601String(),
    'language': lang,
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': '[]',
    if (toursSeen) TourProgressStore.key: allToursSeen,
    ...extra,
  });
  PackageInfo.setMockInitialValues(
    appName: 'Memento Mori',
    packageName: 'test',
    version: '1.2.3',
    buildNumber: '45',
    buildSignature: '',
  );
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
  CompassService.clearCacheForTesting();
  await CompassService.initialize();
  CompassSetupStore.clearCacheForTesting();
  await CompassSetupStore.initialize();
  await reloadTourProgress();
}

/// Pumps [home] in the app's theme (its [dark] variant if asked) and
/// language at [size] logical pixels (default: a tall phone so every
/// section is built).
Future<void> pumpCompassApp(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(393, 4000),
  bool dark = false,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(AppSettingsScope(
    controller: controller,
    child: MaterialApp(
      theme: dark ? controller.darkTheme : controller.lightTheme,
      locale: controller.locale,
      supportedLocales: [
        for (final code in AppLocalizations.supportedLanguages) Locale(code),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
}
