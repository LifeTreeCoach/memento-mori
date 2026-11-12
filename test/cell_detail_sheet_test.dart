import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/cell_detail_sheet.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

final _calc =
    LifeCalculator(birthDate: DateTime(1990, 11, 17), now: DateTime(2026, 11, 2));

Future<void> _openSheet(WidgetTester tester, LifePeriod period) async {
  // 640 logical px wide (the Material 3 sheet's max width): the test font's
  // square glyphs would fill a phone width anyway and hide the shrinking.
  tester.view.physicalSize = const Size(640 * 2.75, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showCellDetailSheet(context,
              period: period, friends: const []),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final index in [100, 3000]) {
    testWidgets('sheet without birthdays is full width (week $index)',
        (tester) async {
      final period = LifePeriod.of(LifeMode.weeks, index, _calc);
      await _openSheet(tester, period);
      final sheetWidth = tester.getSize(find.byType(BottomSheet)).width;
      final contentWidth = tester
          .getSize(find.descendant(
              of: find.byType(CellDetailSheet),
              matching: find.byType(SingleChildScrollView)))
          .width;
      expect(contentWidth, sheetWidth);
      expect(sheetWidth, closeTo(640, 0.01));
    });
  }
}
