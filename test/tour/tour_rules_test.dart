import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_rules.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

void main() {
  group('shouldStartTour', () {
    test('starts when unseen, visible, current and not blocked', () {
      expect(
          shouldStartTour(seen: false, tabVisible: true, routeIsCurrent: true),
          isTrue);
    });

    test('each condition alone prevents the start', () {
      expect(
          shouldStartTour(seen: true, tabVisible: true, routeIsCurrent: true),
          isFalse);
      expect(
          shouldStartTour(seen: false, tabVisible: false, routeIsCurrent: true),
          isFalse);
      expect(
          shouldStartTour(seen: false, tabVisible: true, routeIsCurrent: false),
          isFalse);
      expect(
          shouldStartTour(
              seen: false, tabVisible: true, routeIsCurrent: true, blocked: true),
          isFalse);
    });
  });

  group('availableSteps', () {
    const a = TourStep(id: 'a', anchorId: 'x', titleKey: 't', bodyKey: 'b');
    const b = TourStep(id: 'b', anchorId: 'gone', titleKey: 't', bodyKey: 'b');
    const c = TourStep(id: 'c', titleKey: 't', bodyKey: 'b');

    test('keeps centred steps and steps with an anchor, in order', () {
      expect(availableSteps([a, b, c], (id) => id == 'x'), [a, c]);
    });

    test('empty when nothing is anchored and nothing is centred', () {
      expect(availableSteps([a, b], (_) => false), isEmpty);
    });
  });

  test('TourResult equality and flags', () {
    const done = TourResult(TourOutcome.completed, lastIndex: 2);
    expect(done, const TourResult(TourOutcome.completed, lastIndex: 2));
    expect(done.completed, isTrue);
    expect(done.skipped, isFalse);
    expect(TourResult.nothingShown.lastIndex, -1);
  });
}
