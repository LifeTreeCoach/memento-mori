import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/tour/spotlight_painter.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_card.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';

import 'tour_test_screen.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

SpotlightPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_key('tour_spotlight')).painter!
        as SpotlightPainter;

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

final _three = [tourStep('1', 'a'), tourStep('2', 'b'), tourStep('3', 'c')];

void main() {
  testWidgets('the hole matches the anchor rect, inflated by 8',
      (tester) async {
    await pumpTourScreen(tester, _three);
    await startTour(tester);
    expect(_painter(tester).hole, tester.getRect(boxOf('a')).inflate(8));
    expect(find.text('Tip 1 of 3'), findsOneWidget);
  });

  testWidgets('Next scrolls to each anchor; Done completes', (tester) async {
    final harness = await pumpTourScreen(tester, _three);
    await startTour(tester);
    await _tap(tester, 'tour_next');
    final b = tester.getRect(boxOf('b'));
    expect(b.top, closeTo(0.3 * (800 - 80), 1)); // ensureVisible 0.3
    expect(_painter(tester).hole, b.inflate(8));
    expect(find.text('Tip 2 of 3'), findsOneWidget);
    await _tap(tester, 'tour_next');
    expect(_painter(tester).hole, tester.getRect(boxOf('c')).inflate(8));
    expect(_key('tour_skip'), findsNothing, reason: 'no Skip next to Done');
    await _tap(tester, 'tour_done');
    expect(find.byType(TourCard), findsNothing);
    expect(harness.result,
        const TourResult(TourOutcome.completed, lastIndex: 2));
  });

  testWidgets('Skip ends the tour where it is', (tester) async {
    final harness = await pumpTourScreen(tester, _three);
    await startTour(tester);
    await _tap(tester, 'tour_next');
    await _tap(tester, 'tour_skip');
    expect(find.byType(TourCard), findsNothing);
    expect(
        harness.result, const TourResult(TourOutcome.skipped, lastIndex: 1));
  });

  testWidgets('Skip shows on every step but the last', (tester) async {
    await pumpTourScreen(tester, _three);
    await startTour(tester);
    expect(_key('tour_skip'), findsOneWidget);
    await _tap(tester, 'tour_next');
    expect(_key('tour_skip'), findsOneWidget);
    await _tap(tester, 'tour_next');
    expect(_key('tour_done'), findsOneWidget);
    expect(_key('tour_skip'), findsNothing);
  });

  testWidgets('system back on the last step still skips', (tester) async {
    final harness = await pumpTourScreen(tester, _three);
    await startTour(tester);
    await _tap(tester, 'tour_next');
    await _tap(tester, 'tour_next');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TourCard), findsNothing);
    expect(
        harness.result, const TourResult(TourOutcome.skipped, lastIndex: 2));
  });

  testWidgets('system back skips', (tester) async {
    final harness = await pumpTourScreen(tester, _three);
    await startTour(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TourCard), findsNothing);
    expect(
        harness.result, const TourResult(TourOutcome.skipped, lastIndex: 0));
  });

  testWidgets('a missing anchor is dropped from the count', (tester) async {
    await pumpTourScreen(tester, [tourStep('1', 'a'), tourStep('2', 'gone'),
        tourStep('3', 'c')]);
    await startTour(tester);
    expect(find.text('Tip 1 of 2'), findsOneWidget);
    await _tap(tester, 'tour_next');
    expect(find.text('Tip 2 of 2'), findsOneWidget);
    expect(find.text('Title 3'), findsOneWidget);
  });

  testWidgets('no anchor at all: nothing is shown', (tester) async {
    final harness = await pumpTourScreen(tester, [tourStep('1', 'gone')]);
    await startTour(tester);
    expect(find.byType(TourCard), findsNothing);
    expect(harness.result, TourResult.nothingShown);
  });

  testWidgets('a step without anchor is a centred card without hole',
      (tester) async {
    await pumpTourScreen(tester, [tourStep('1', null)]);
    await startTour(tester);
    expect(_painter(tester).hole, isNull);
    expect(tester.getCenter(find.byType(TourCard)).dx, 200);
  });
}
