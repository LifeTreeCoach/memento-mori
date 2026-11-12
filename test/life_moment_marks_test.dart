import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/home_screen.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/life/moment_marks.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

import 'support/compass_test_app.dart';

/// Birth 1990-11-17 (a Saturday): week 100 starts on 1992-10-17.
final DateTime _week100 = DateTime(1992, 10, 19);

Finder _paintWith<T>() => find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is T);

MomentMarksPainter? _marks(WidgetTester tester) {
  final finder = _paintWith<MomentMarksPainter>();
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<CustomPaint>(finder).painter! as MomentMarksPainter;
}

LifeGridPainter _grid(WidgetTester tester) =>
    tester.widget<CustomPaint>(_paintWith<LifeGridPainter>()).painter!
        as LifeGridPainter;

Future<void> _initLife(WidgetTester tester, {String mode = 'weeks'}) async {
  await initCompassTest(extra: {'display_mode': mode});
}

Future<void> _tapCell(WidgetTester tester, int index) async {
  final origin = tester.getTopLeft(_paintWith<LifeGridPainter>());
  await tester.tapAt(origin + _grid(tester).geometry.cellRect(index).center);
  await tester.pump(const Duration(milliseconds: 400)); // double-tap timeout
  await tester.pumpAndSettle();
}

String _date(WidgetTester tester, DateTime date) =>
    AppLocalizations.of(tester.element(find.byType(HomeScreen)))
        .shortDateFormat
        .format(date);

void main() {
  group('grid marks', () {
    for (final (mode, cell) in [('weeks', 100), ('months', 23), ('years', 1)]) {
      testWidgets('$mode: the cell holding a moment is marked', (tester) async {
        await _initLife(tester, mode: mode);
        await CompassService.addMoment(title: 'First steps', date: _week100);
        await pumpCompassApp(tester, HomeScreen(now: compassToday));
        expect(_marks(tester)!.cells, {cell});
        expect(_marks(tester)!.haloColor,
            Theme.of(tester.element(find.byType(HomeScreen))).colorScheme.surface);
      });
    }

    testWidgets('no moments, no marks layer', (tester) async {
      await _initLife(tester);
      await pumpCompassApp(tester, HomeScreen(now: compassToday));
      expect(_marks(tester), isNull);
    });

    testWidgets('hidden when the setting is off', (tester) async {
      await _initLife(tester);
      await CompassService.addMoment(title: 'First steps', date: _week100);
      await pumpCompassApp(tester, HomeScreen(now: compassToday));
      expect(_marks(tester), isNotNull);

      await tester.runAsync(() => CompassService.setShowGridMarks(false));
      await tester.pumpAndSettle();
      expect(_marks(tester), isNull);
    });

    testWidgets('a new moment repaints the marks, not the grid',
        (tester) async {
      await _initLife(tester);
      await CompassService.addMoment(title: 'First steps', date: _week100);
      await pumpCompassApp(tester, HomeScreen(now: compassToday));
      final oldMarks = _marks(tester)!;
      final oldGrid = _grid(tester);

      await tester.runAsync(() =>
          CompassService.addMoment(title: 'Today', date: compassToday));
      await tester.pumpAndSettle();
      final marks = _marks(tester)!;
      expect(marks.cells, {100, 1876});
      expect(marks.shouldRepaint(oldMarks), isTrue);
      expect(_grid(tester).shouldRepaint(oldGrid), isFalse);
    });
  });

  group('cell sheet', () {
    testWidgets('lists the moments of the period', (tester) async {
      await _initLife(tester);
      await CompassService.addMoment(title: 'First steps', date: _week100);
      await pumpCompassApp(tester, HomeScreen(now: compassToday));
      await _tapCell(tester, 100);
      expect(find.text('First steps'), findsOneWidget);
      expect(find.text(_date(tester, _week100)), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    });

    testWidgets('adds a moment starting on the period\'s first day',
        (tester) async {
      await _initLife(tester);
      await pumpCompassApp(tester, HomeScreen(now: compassToday));
      await _tapCell(tester, 100);
      await tester.tap(find.text('Add a moment for this week'));
      await tester.pumpAndSettle();

      final start = DateTime(1992, 10, 17);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('compass_moment_date')),
              matching: find.text(_date(tester, start))),
          findsOneWidget);
      await tester.enterText(
          find.byKey(const ValueKey('compass_moment_title')), 'Paris');
      await tester.tap(find.byKey(const ValueKey('compass_sheet_save')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(CompassService.data.moments.single.date, start);
      expect(_marks(tester)!.cells, {100});
    });

    testWidgets('the current cell suggests today', (tester) async {
      await _initLife(tester);
      await pumpCompassApp(tester, HomeScreen(now: compassToday));
      await _tapCell(tester, 1876);
      await tester.tap(find.text('Add a moment for this week'));
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('compass_moment_date')),
              matching: find.text(_date(tester, compassToday))),
          findsOneWidget);
    });

    testWidgets('future cells offer no moment', (tester) async {
      await _initLife(tester);
      await pumpCompassApp(tester, HomeScreen(now: compassToday));
      await _tapCell(tester, 3000);
      expect(find.byKey(const ValueKey('cell_add_moment')), findsNothing);
    });
  });
}
