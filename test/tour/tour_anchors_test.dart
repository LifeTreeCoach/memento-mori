import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';

Widget _scope(TourAnchors anchors, Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: TourAnchorScope(anchors: anchors, child: child));

void main() {
  testWidgets('registers, measures and unregisters on dispose',
      (tester) async {
    final anchors = TourAnchors();
    await tester.pumpWidget(_scope(
        anchors,
        const Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 10, top: 20),
            child: TourAnchor(
                id: 'x',
                child: SizedBox(key: ValueKey('kept'), width: 50, height: 30)),
          ),
        )));
    expect(anchors.contains('x'), isTrue);
    expect(anchors.rectOf('x'), const Rect.fromLTWH(10, 20, 50, 30));
    expect(find.byKey(const ValueKey('kept')), findsOneWidget);

    await tester.pumpWidget(_scope(anchors, const SizedBox()));
    expect(anchors.contains('x'), isFalse);
    expect(anchors.contextOf('x'), isNull);
    expect(anchors.rectOf('x'), isNull);
  });

  testWidgets('an id change moves the registration', (tester) async {
    final anchors = TourAnchors();
    Widget anchor(String id) => _scope(
        anchors, TourAnchor(id: id, child: const SizedBox(width: 5, height: 5)));
    await tester.pumpWidget(anchor('x'));
    await tester.pumpWidget(anchor('y'));
    expect(anchors.contains('x'), isFalse);
    expect(anchors.contains('y'), isTrue);
  });

  test('unregister ignores a context that no longer owns the id', () {
    final anchors = TourAnchors();
    final first = _FakeContext();
    final second = _FakeContext();
    anchors.register('x', first);
    anchors.register('x', second);
    anchors.unregister('x', first);
    expect(anchors.contextOf('x'), same(second));
  });

  testWidgets('without a scope the anchor just shows its child',
      (tester) async {
    await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: TourAnchor(id: 'x', child: Text('hi'))));
    expect(find.text('hi'), findsOneWidget);
  });
}

class _FakeContext extends Fake implements BuildContext {
  @override
  bool get mounted => true;
}
