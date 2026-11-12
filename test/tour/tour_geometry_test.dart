import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_geometry.dart';

const _phone = Size(400, 800);
const _safe = EdgeInsets.only(top: 24, bottom: 34);

TourLayout _layout(Rect? target, Size card,
        {Size screen = _phone, EdgeInsets padding = _safe}) =>
    TourGeometry.layout(
        screen: screen, padding: padding, target: target, card: card);

void main() {
  test('card width is min(screen - 32, 360)', () {
    expect(TourGeometry.cardWidthFor(400), 360);
    expect(TourGeometry.cardWidthFor(320), 288);
    expect(TourGeometry.cardWidthFor(10), 0);
  });

  test('hole is the target inflated by 8', () {
    final layout = _layout(const Rect.fromLTWH(50, 100, 100, 40),
        const Size(360, 150));
    expect(layout.hole, const Rect.fromLTRB(42, 92, 158, 148));
    expect(TourGeometry.holeRadius, 16);
  });

  test('below the hole when it fits', () {
    final layout = _layout(const Rect.fromLTWH(50, 100, 100, 40),
        const Size(360, 150));
    expect(layout.placement, CardPlacement.below);
    expect(layout.cardOffset.dy, 148 + TourGeometry.gap);
    expect(layout.cardOffset.dx, 16); // centred on the target, kept 16 in
  });

  test('above the hole when below does not fit', () {
    final layout = _layout(const Rect.fromLTWH(200, 650, 100, 40),
        const Size(360, 150));
    expect(layout.placement, CardPlacement.above);
    expect(layout.cardOffset.dy, 642 - TourGeometry.gap - 150);
  });

  test('pinned to the bottom of the safe area when neither fits', () {
    final layout = _layout(const Rect.fromLTWH(0, 200, 400, 400),
        const Size(360, 300));
    expect(layout.placement, CardPlacement.bottom);
    expect(layout.cardOffset.dy, 800 - 34 - 16 - 300);
  });

  test('small screen with a card scaled by text 2.0 stays in the safe area',
      () {
    const screen = Size(320, 480);
    final width = TourGeometry.cardWidthFor(screen.width);
    final maxHeight = TourGeometry.maxCardHeightFor(screen, _safe);
    final card = Size(width, maxHeight); // tallest card the layout allows
    final layout = _layout(const Rect.fromLTWH(20, 150, 280, 60), card,
        screen: screen);
    expect(layout.placement, CardPlacement.bottom);
    expect(layout.cardOffset.dy, greaterThanOrEqualTo(24 + 16));
    expect(layout.cardOffset.dy + card.height,
        lessThanOrEqualTo(480 - 34 - 16));
    expect(layout.cardOffset.dx, 16);
  });

  test('centred without a target', () {
    final layout = _layout(null, const Size(360, 200));
    expect(layout.hole, isNull);
    expect(layout.placement, CardPlacement.centred);
    expect(layout.cardOffset.dx, 20);
    final top = 24 + 16.0;
    final bottom = 800 - 34 - 16.0;
    expect(layout.cardOffset.dy, top + (bottom - top - 200) / 2);
  });
}
