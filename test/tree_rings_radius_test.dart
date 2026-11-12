import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/tree_rings_layout_painter.dart';

void main() {
  group('TreeRingsLayoutPainter.radiusForYears', () {
    const maxRadius = 160.0;

    double radius(double years, [int lifeExpectancy = 80]) =>
        TreeRingsLayoutPainter.radiusForYears(years, maxRadius, lifeExpectancy);

    test('is 0 at birth and maxRadius at life expectancy', () {
      for (final lifeExpectancy in [60, 80, 95]) {
        expect(radius(0, lifeExpectancy), 0);
        expect(radius(lifeExpectancy.toDouble(), lifeExpectancy), maxRadius);
      }
    });

    test('is strictly increasing across the lifespan', () {
      var previous = -1.0;
      for (var years = 0.0; years <= 90; years += 0.5) {
        final r = radius(years, 90);
        expect(r, greaterThan(previous));
        previous = r;
      }
    });

    test('decade ring radius equals the lived fill radius at that age', () {
      for (final lifeExpectancy in [70, 80, 100]) {
        for (var decade = 10; decade <= lifeExpectancy; decade += 10) {
          final progress = decade / lifeExpectancy;
          final fillRadius = radius(progress * lifeExpectancy, lifeExpectancy);
          expect(radius(decade.toDouble(), lifeExpectancy),
              closeTo(fillRadius, 1e-9));
        }
      }
    });

    test('a 36.8-year fill lies between rings 30 and 40', () {
      expect(radius(36.8), greaterThan(radius(30)));
      expect(radius(36.8), lessThan(radius(40)));
    });

    test('clamps outside the lifespan and handles zero expectancy', () {
      expect(radius(-5), 0);
      expect(radius(200), maxRadius);
      expect(radius(10, 0), 0);
    });
  });
}
