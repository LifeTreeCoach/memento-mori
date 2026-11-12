import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:memento_mori_life_in_weeks/life/moment_marks.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

final DateTime _birth = DateTime(1990, 11, 17);
final DateTime _today = DateTime(2026, 11, 2);

Moment _moment(DateTime date) => Moment(id: '$date', title: 'm', date: date);

LifeGridGeometry _geometry(LifeMode mode) => LifeGridGeometry(
      mode: mode,
      totalCells: mode.totalCells(LifeCalculator(birthDate: _birth, now: _today)),
      maxWidth: 380,
    );

MomentMarksPainter _painter(LifeMode mode, Set<int> cells,
        {Color color = const Color(0xFF2E7069)}) =>
    MomentMarksPainter(geometry: _geometry(mode), cells: cells, color: color);

void main() {
  group('momentCellIndices', () {
    Set<int> cellsOf(LifeMode mode, List<DateTime> dates) => momentCellIndices(
          moments: dates.map(_moment),
          mode: mode,
          birthDate: _birth,
          totalCells: mode.totalCells(LifeCalculator(birthDate: _birth)),
        );

    test('weeks: one cell per week, several moments share it', () {
      expect(
        cellsOf(LifeMode.weeks, [
          DateTime(1990, 11, 17),
          DateTime(1990, 11, 24),
          DateTime(1990, 11, 30),
        ]),
        {0, 1},
      );
    });

    test('months and years use the grid period of the date', () {
      expect(cellsOf(LifeMode.months, [DateTime(1991, 1, 17), DateTime(1991, 1, 16)]),
          {2, 1});
      expect(cellsOf(LifeMode.years, [DateTime(2000, 11, 17), DateTime(2000, 11, 16)]),
          {10, 9});
    });

    test('cells match LifePeriod (the cell sheet lists the same moments)', () {
      final calc = LifeCalculator(birthDate: _birth, now: _today);
      for (final mode in LifeMode.values) {
        final date = DateTime(2012, 6, 3);
        final index = cellsOf(mode, [date]).single;
        expect(LifePeriod.of(mode, index, calc).contains(date), isTrue,
            reason: mode.id);
      }
    });

    test('moments before birth or after the last cell are skipped', () {
      expect(cellsOf(LifeMode.weeks, [DateTime(1990, 11, 16), DateTime(2080, 1, 1)]),
          isEmpty);
    });
  });

  group('MomentMarksPainter', () {
    for (final mode in LifeMode.values) {
      test('${mode.id}: dots in the marked cells only', () {
        final painter = _painter(mode, {0, 5});
        final geometry = painter.geometry;
        expect(
          (Canvas canvas) => painter.paint(canvas, geometry.size),
          paints
            ..path(
              color: const Color(0xFF2E7069),
              includes: [
                geometry.cellRect(0).center,
                geometry.cellRect(5).center,
              ],
              excludes: [
                geometry.cellRect(1).center,
                geometry.cellRect(0).topLeft,
              ],
            ),
        );
      });
    }

    test('dots stay inside their cell', () {
      final painter = _painter(LifeMode.weeks, {3});
      expect(painter.dotRadius * 2, lessThan(painter.geometry.cellSize));
    });

    group('weeks mode stands out', () {
      const surface = Color(0xFF141415);
      MomentMarksPainter weeks({double width = 380, Color? halo = surface}) =>
          MomentMarksPainter(
            geometry: LifeGridGeometry(
              mode: LifeMode.weeks,
              totalCells: 4160,
              maxWidth: width,
            ),
            cells: const {3},
            color: const Color(0xFF2E7069),
            haloColor: halo,
          );

      test('the dot is larger relative to the cell than in other modes', () {
        final painter = weeks();
        expect(painter.dotRadius / painter.geometry.cellSize,
            greaterThan(MomentMarksPainter.dotRatio));
      });

      test('has a minimum radius, and dot plus halo leave a rim of the cell',
          () {
        for (final width in [200.0, 300.0, 360.0, 393.0, 600.0]) {
          final painter = weeks(width: width);
          final half = painter.geometry.cellSize / 2;
          expect(painter.markRadius, lessThan(half), reason: '$width');
          if (half * MomentMarksPainter.maxMarkRatio >=
              MomentMarksPainter.minWeekDotRadius + painter.haloWidth) {
            expect(painter.dotRadius,
                greaterThanOrEqualTo(MomentMarksPainter.minWeekDotRadius),
                reason: '$width');
          }
        }
      });

      test('paints a halo in the surface colour under the dot', () {
        final painter = weeks();
        final center = painter.geometry.cellRect(3).center;
        expect(
          (Canvas canvas) => painter.paint(canvas, painter.geometry.size),
          paints
            ..path(color: surface, includes: [center])
            ..path(color: const Color(0xFF2E7069), includes: [center]),
        );
        expect(painter.haloWidth, greaterThan(0));
      });

      test('months and years keep the plain dot', () {
        for (final mode in [LifeMode.months, LifeMode.years]) {
          final painter = MomentMarksPainter(
            geometry: _geometry(mode),
            cells: const {1},
            color: const Color(0xFF2E7069),
            haloColor: surface,
          );
          expect(painter.haloWidth, 0);
          expect(painter.dotRadius,
              painter.geometry.cellSize * MomentMarksPainter.dotRatio);
        }
      });

      test('a new halo colour repaints', () {
        expect(weeks().shouldRepaint(weeks(halo: const Color(0xFFFFFFFF))),
            isTrue);
      });
    });

    test('no cells paint nothing', () {
      final painter = _painter(LifeMode.weeks, const {});
      expect((Canvas canvas) => painter.paint(canvas, const Size(380, 600)),
          paintsNothing);
    });

    test('repaints only when the marks, colour or layout change', () {
      final painter = _painter(LifeMode.weeks, {1, 2});
      expect(painter.shouldRepaint(_painter(LifeMode.weeks, {2, 1})), isFalse);
      expect(painter.shouldRepaint(_painter(LifeMode.weeks, {1, 2, 3})), isTrue);
      expect(
          painter.shouldRepaint(_painter(LifeMode.weeks, {1, 2},
              color: const Color(0xFF000000))),
          isTrue);
      expect(painter.shouldRepaint(_painter(LifeMode.months, {1, 2})), isTrue);
    });
  });

  group('LifePalette.moment', () {
    const palettes = {
      'stoicLight': LifePalette.stoicLight,
      'stoicDark': LifePalette.stoicDark,
      'warmLight': LifePalette.warmLight,
      'warmDark': LifePalette.warmDark,
    };
    palettes.forEach((name, palette) {
      test('$name: visible on lived and remaining cells', () {
        expect(contrastRatio(palette.moment, palette.lived),
            greaterThanOrEqualTo(LifePalette.minMomentContrast));
        expect(contrastRatio(palette.moment, palette.remaining),
            greaterThanOrEqualTo(LifePalette.minMomentContrast));
      });
    });

    test('is part of copyWith, lerp and equality', () {
      const other = Color(0xFF123456);
      final copy = LifePalette.stoicDark.copyWith(moment: other);
      expect(copy.moment, other);
      expect(copy, isNot(LifePalette.stoicDark));
      expect(LifePalette.stoicDark.lerp(copy, 1).moment, other);
    });
  });

  group('LifePeriod moment date', () {
    final calc = LifeCalculator(birthDate: _birth, now: _today);

    test('a past period suggests its first day', () {
      final period = LifePeriod.of(LifeMode.weeks, 100, calc);
      expect(period.canHoldMoments, isTrue);
      expect(period.suggestedMomentDate, period.start);
    });

    test('the current period suggests today', () {
      for (final mode in LifeMode.values) {
        final period = LifePeriod.of(mode, mode.livedCells(calc), calc);
        expect(period.suggestedMomentDate, calc.today, reason: mode.id);
      }
    });

    test('future periods hold no moments', () {
      final period = LifePeriod.of(LifeMode.years, 60, calc);
      expect(period.canHoldMoments, isFalse);
    });
  });
}
