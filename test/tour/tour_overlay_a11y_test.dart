import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/tour/spotlight_painter.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_card.dart';

import 'tour_test_screen.dart';

final _three = [tourStep('1', 'a'), tourStep('2', 'b'), tourStep('3', 'c')];

ModalRoute<dynamic> _route(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byType(TourCard)))!;

Duration _holeTween(WidgetTester tester) => tester
    .widget<TweenAnimationBuilder<Rect?>>(
        find.byType(TweenAnimationBuilder<Rect?>))
    .duration;

void main() {
  testWidgets('motion: fades with Motion.medium', (tester) async {
    await pumpTourScreen(tester, _three);
    await startTour(tester);
    expect(_route(tester).transitionDuration, const Duration(milliseconds: 300));
    expect(_holeTween(tester), const Duration(milliseconds: 300));
  });

  testWidgets('reduced motion: no animation durations', (tester) async {
    await pumpTourScreen(tester, _three, disableAnimations: true);
    await startTour(tester);
    expect(_route(tester).transitionDuration, Duration.zero);
    expect(_route(tester).reverseTransitionDuration, Duration.zero);
    expect(_holeTween(tester), Duration.zero);
    expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        Duration.zero);
  });

  testWidgets('title is a live-region header; Next has focus',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTourScreen(tester, _three);
    await startTour(tester);
    expect(tester.getSemantics(find.text('Title 1')),
        isSemantics(label: 'Title 1', isHeader: true, isLiveRegion: true));
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
        find.ancestor(
            of: find.byElementPredicate((e) => e == focused),
            matching: find.byKey(const ValueKey('tour_next'))),
        findsOneWidget);
    semantics.dispose();
  });

  testWidgets('dark theme renders with the darker scrim', (tester) async {
    await pumpTourScreen(tester, _three, brightness: Brightness.dark);
    await startTour(tester);
    final painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('tour_spotlight')))
        .painter! as SpotlightPainter;
    expect(painter.scrim.a, closeTo(0.72, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screen with text scale 2.0: card fits, no overflow',
      (tester) async {
    await pumpTourScreen(tester, _three,
        size: const Size(320, 480), textScale: 2);
    await startTour(tester);
    expect(tester.takeException(), isNull);
    final card = tester.getRect(find.byType(TourCard));
    expect(card.width, 288);
    expect(card.top, greaterThanOrEqualTo(16));
    expect(card.bottom, lessThanOrEqualTo(480 - 16));
  });

  test('scrim alpha by brightness', () {
    expect(SpotlightPainter.scrimAlphaFor(Brightness.light), 0.62);
    expect(SpotlightPainter.scrimAlphaFor(Brightness.dark), 0.72);
  });
}
