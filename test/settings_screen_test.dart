import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_screen.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/scroll_thread_probe.dart';

final DateTime _today = DateTime(2026, 11, 2);

Future<void> _init({String lang = 'en'}) async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': DateTime(1990, 11, 17).toIso8601String(),
    'language': lang,
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': '[]',
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
}

/// Pumps [home] inside the app-wide settings scope, as main.dart does.
Future<void> _pump(WidgetTester tester, Widget home,
    {Size physicalSize = const Size(1080, 15000)}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(AppSettingsScope(
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        theme: controller.lightTheme,
        darkTheme: controller.darkTheme,
        themeMode: controller.themeMode,
        locale: controller.locale,
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: home,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _pumpSettings(WidgetTester tester) =>
    _pump(tester, const SettingsScreen(alwaysShowDiagnostics: false));

void main() {
  testWidgets('shows the section headers in English', (tester) async {
    await _init();
    await _pumpSettings(tester);
    for (final header in [
      'LIFE',
      'APPEARANCE',
      'REMINDERS',
      'WIDGET',
      'DATA',
      'ABOUT',
    ]) {
      expect(find.text(header), findsOneWidget, reason: header);
    }
  });

  testWidgets('shows the section headers in German', (tester) async {
    await _init(lang: 'de');
    await _pumpSettings(tester);
    for (final header in [
      'LEBEN',
      'DARSTELLUNG',
      'ERINNERUNGEN',
      'WIDGET',
      'DATEN',
      'ÜBER',
    ]) {
      expect(find.text(header), findsOneWidget, reason: header);
    }
  });

  testWidgets('formats the birth date with the app-wide date format', (tester) async {
    await _init();
    await _pumpSettings(tester);
    expect(find.text('17 Nov 1990'), findsOneWidget);
  });

  testWidgets('formats the birth date in German', (tester) async {
    await _init(lang: 'de');
    await _pumpSettings(tester);
    expect(find.text('17. Nov. 1990'), findsOneWidget);
  });

  testWidgets('version tapped 7 times reveals Diagnostics, persistently',
      (tester) async {
    await _init();
    await _pumpSettings(tester);
    expect(find.text('1.2.3 (45)'), findsOneWidget);
    expect(find.text('Diagnostics'), findsNothing);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('Version'));
      await tester.pump();
    }
    expect(find.text('Diagnostics'), findsNothing);
    expect(find.text('1 more tap to unlock diagnostics'), findsOneWidget);

    await tester.tap(find.text('Version'));
    await tester.pumpAndSettle();
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(SettingsService.isDiagnosticsUnlocked(), isTrue);
  });

  testWidgets('on iOS, "Add widget" explains the widget gallery', (tester) async {
    await _init();
    await _pumpSettings(tester);

    await tester.tap(find.text('Add widget to home screen'));
    await tester.pumpAndSettle();
    expect(find.text('Add the widget manually'), findsOneWidget);
    expect(find.textContaining('Edit → Add Widget'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('debug builds always show Diagnostics', (tester) async {
    await _init();
    await _pump(tester, const SettingsScreen(alwaysShowDiagnostics: true));
    expect(find.text('Diagnostics'), findsOneWidget);
  });

  testWidgets('changing life expectancy persists and updates the Life tab',
      (tester) async {
    await _init();
    await _pump(tester, AppShell(now: _today));
    expect(find.text('of 4,160 · 45% lived'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('80\u00A0years'), findsOneWidget);
    await tester.tap(find.text('Life expectancy'));
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(90);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(SettingsService.getLifeExpectancyYears(), 90);
    expect(find.text('90\u00A0years'), findsOneWidget);

    await tester.tap(find.text('Life').last);
    await tester.pumpAndSettle();
    expect(find.text('of 4,680 · 40% lived'), findsOneWidget);
  });

  testWidgets('"Show life phases" switch persists showPhases', (tester) async {
    await _init();
    await _pumpSettings(tester);
    final tile = find.widgetWithText(SwitchListTile, 'Show life phases');
    expect(tile, findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(SettingsService.getVisualizationSettings().showPhases, isFalse);
  });

  testWidgets('default view stays in sync with the Life tab', (tester) async {
    await _init();
    await _pump(tester, AppShell(now: _today));
    await tester.tap(find.text('Months').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final defaultView = find.ancestor(
      of: find.text('Default view'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: defaultView, matching: find.text('Months')),
      findsOneWidget,
    );
  });

  testWidgets('scroll thread shows while more settings lie below',
      (tester) async {
    await _init();
    await _pump(tester, const SettingsScreen(alwaysShowDiagnostics: false),
        physicalSize: phoneViewport * 3);
    await tester.pump(); // scroll metrics arrive after the first frame
    expect(scrollThreadOpacity(tester), 1);
  });
}
