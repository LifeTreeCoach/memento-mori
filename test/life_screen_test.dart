import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/home_screen.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/scroll_thread_probe.dart';

final DateTime _today = DateTime(2026, 11, 2);

Future<void> _initSettings({String? displayMode, bool withBirthDate = true}) async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    if (withBirthDate) 'birth_date': DateTime(1990, 11, 17).toIso8601String(),
    'display_mode': ?displayMode,
    'language': 'en',
    'visualization_settings': jsonEncode(visual.toMap()),
  });
  await SettingsService.initialize();
}

Future<void> _pumpLife(WidgetTester tester,
    {Size physicalSize = const Size(1080, 2340)}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.dark),
    locale: const Locale('en'),
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: HomeScreen(now: _today),
  ));
  await tester.pumpAndSettle();
}

LifeGridPainter _gridPainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is LifeGridPainter));
  return paint.painter! as LifeGridPainter;
}

Offset _cellCenter(WidgetTester tester, int index) {
  final finder = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is LifeGridPainter);
  final origin = tester.getTopLeft(finder);
  return origin + _gridPainter(tester).geometry.cellRect(index).center;
}

void main() {
  group('Life header', () {
    testWidgets('weeks mode shows the current week of the total', (tester) async {
      await _initSettings(displayMode: 'weeks');
      await _pumpLife(tester);
      expect(find.text('WEEK'), findsOneWidget);
      expect(find.text('1,877'), findsOneWidget);
      expect(find.text('of 4,160 · 45% lived'), findsOneWidget);
    });

    testWidgets('months mode shows the current month', (tester) async {
      await _initSettings(displayMode: 'months');
      await _pumpLife(tester);
      expect(find.text('MONTH'), findsOneWidget);
      expect(find.text('432'), findsOneWidget);
      expect(find.text('of 960 · 45% lived'), findsOneWidget);
    });

    testWidgets('years mode shows the current year of life', (tester) async {
      await _initSettings(displayMode: 'years');
      await _pumpLife(tester);
      expect(find.text('YEAR'), findsOneWidget);
      expect(find.text('36'), findsOneWidget);
      expect(find.text('of 80 · 45% lived'), findsOneWidget);
    });

    testWidgets('grid exposes a semantic summary', (tester) async {
      await _initSettings(displayMode: 'weeks');
      await _pumpLife(tester);
      expect(
        find.bySemanticsLabel('Week 1,877 of 4,160, 45 percent lived'),
        findsOneWidget,
      );
    });
  });

  testWidgets('segmented button switches and persists the display mode',
      (tester) async {
    await _initSettings(displayMode: 'weeks');
    await _pumpLife(tester);

    await tester.tap(find.text('Months'));
    await tester.pumpAndSettle();

    expect(find.text('432'), findsOneWidget);
    expect(SettingsService.getDisplayMode(), 'months');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('display_mode'), 'months');
  });

  testWidgets('tapping a week cell opens its detail sheet', (tester) async {
    await _initSettings(displayMode: 'weeks');
    await _pumpLife(tester);

    await tester.tapAt(_cellCenter(tester, 100));
    await tester.pump(const Duration(milliseconds: 400)); // double-tap timeout
    await tester.pumpAndSettle();

    expect(find.text('Week of 17 Oct 1992'), findsOneWidget);
    expect(find.text('You were 1'), findsOneWidget);
    expect(find.text('1,776\u00A0WEEKS AGO'), findsOneWidget);
  });

  testWidgets('tapping the current cell says "This week"', (tester) async {
    await _initSettings(displayMode: 'weeks');
    await _pumpLife(tester);

    await tester.tapAt(_cellCenter(tester, 1876));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('You are 35'), findsOneWidget);
  });

  testWidgets('without a birth date an empty state is shown', (tester) async {
    await _initSettings(withBirthDate: false);
    await _pumpLife(tester);
    expect(find.text('Your weeks begin with a date'), findsOneWidget);
    expect(find.byType(CustomPaint).evaluate().where((e) =>
        (e.widget as CustomPaint).painter is LifeGridPainter), isEmpty);
  });

  testWidgets('scroll thread shows on a phone and hides while zoomed',
      (tester) async {
    await _initSettings(displayMode: 'weeks');
    await _pumpLife(tester, physicalSize: phoneViewport * 3);
    await tester.pump(); // scroll metrics arrive after the first frame
    expect(scrollThreadOpacity(tester), 1);

    final cell = _cellCenter(tester, 100);
    await tester.tapAt(cell);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(cell); // double tap zooms the grid
    await tester.pumpAndSettle();
    expect(scrollThreadOpacity(tester), 0);
  });
}
