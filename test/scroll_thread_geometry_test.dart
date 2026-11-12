import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread_geometry.dart';

ScrollThreadGeometry _geometry(double pixels, {double max = 900}) =>
    scrollThreadGeometry(
      pixels: pixels,
      maxScrollExtent: max,
      viewportDimension: 300,
      trackHeight: 300,
    );

void main() {
  group('scrollThreadGeometry', () {
    test('length is the viewport share of the content', () {
      // 300 of 1200 => a quarter of the 300 track.
      expect(_geometry(0).length, 75);
    });

    test('top follows the scroll fraction', () {
      expect(_geometry(0).top, 0);
      expect(_geometry(450).top, closeTo(112.5, 1e-9));
      expect(_geometry(900).top, 225);
    });

    test('long content keeps the minimum length', () {
      final geometry = _geometry(0, max: 100000);
      expect(geometry.length, scrollThreadMinLength);
      expect(_geometry(100000, max: 100000).top, 300 - scrollThreadMinLength);
    });

    test('overscroll stays inside the track', () {
      expect(_geometry(-80).top, 0);
      expect(_geometry(-80).length, 75);
      final below = _geometry(1200);
      expect(below.top, 225);
      expect(below.top + below.length, 300);
    });

    test('content that fits fills the track at the top', () {
      final geometry = _geometry(0, max: 0);
      expect(geometry.top, 0);
      expect(geometry.length, 300);
    });

    test('a track shorter than the minimum is never exceeded', () {
      final geometry = scrollThreadGeometry(
        pixels: 50,
        maxScrollExtent: 100000,
        viewportDimension: 300,
        trackHeight: 10,
      );
      expect(geometry.length, 10);
      expect(geometry.top, 0);
    });
  });

  group('hasMoreBelow', () {
    test('needs more than 16 dp below', () {
      expect(hasMoreBelow(0), isFalse);
      expect(hasMoreBelow(16), isFalse);
      expect(hasMoreBelow(16.5), isTrue);
      expect(hasMoreBelow(500), isTrue);
    });
  });
}
