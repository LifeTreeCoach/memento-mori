import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_actions.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/people/friend_actions.dart';
import 'package:memento_mori_life_in_weeks/widgets/action_snack_bar.dart';

import 'support/compass_test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  test('every undo/open snackbar lasts 8 s and does not persist', () {
    final bar = actionSnackBar(
        text: 'x', action: SnackBarAction(label: 'Undo', onPressed: () {}));
    expect(bar.duration, const Duration(seconds: 8));
    expect(bar.persist, isFalse);
    expect(CompassActions.undoDuration, actionSnackBarDuration);
    expect(FriendActions.undoDuration, actionSnackBarDuration);
  });

  test('bulk undo offers can stay longer', () {
    final bar = actionSnackBar(
        text: 'x',
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
        duration: bulkActionSnackBarDuration);
    expect(bar.duration, const Duration(seconds: 12));
    expect(bar.persist, isFalse);
  });

  testWidgets('shows for 8 s, then goes away', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showActionSnackBar(
              ScaffoldMessenger.of(context),
              text: 'Removed',
              action: SnackBarAction(label: 'Undo', onPressed: () {}),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle(); // entry animation done, timer running
    await tester.pump(const Duration(milliseconds: 7900));
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('Compass "Done" keeps its undo past the 4 s default',
      (tester) async {
    await initCompassTest();
    // The snackbar thanks only with the look back switched off.
    await CompassService.setShowReflection(false);
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await tester.tap(find.byKey(const ValueKey('compass_add_intention')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('compass_intention_title')), 'Call Mum');
    await tester.tap(find.byKey(const ValueKey('compass_sheet_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
  });
}
