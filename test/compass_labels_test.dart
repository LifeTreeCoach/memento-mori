import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/area_chips.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/horizon_picker.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

import 'support/compass_test_app.dart';

String _byAge(String lang, int age) =>
    AppLocalizations(Locale(lang)).horizonLabel(Horizon.byAge(age));

/// Hosts [child] in the app's theme so the chips render as in the sheet.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await initCompassTest();
  await pumpCompassApp(tester, Scaffold(body: child));
}

void main() {
  group('horizon "by age" label', () {
    test('names the age in years, plural-correct', () {
      expect(_byAge('en', 45), 'By age 45');
      expect(_byAge('de', 45), 'Bis 45\u00A0Jahre');
      expect(_byAge('fr', 45), 'Jusqu’à 45 ans');
      expect(_byAge('es', 45), 'Hasta los 45\u00A0años');
      expect(_byAge('de', 1), 'Bis 1\u00A0Jahr');
      expect(_byAge('fr', 1), 'Jusqu’à 1 an');
    });
  });

  group('area chips', () {
    testWidgets('the selected area shows a check mark', (tester) async {
      LifeArea? selected = LifeArea.health;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => AreaChips(
            selected: selected,
            onChanged: (area) => setState(() => selected = area),
          ),
        ),
      );
      Finder checkIn(LifeArea area) => find.descendant(
          of: find.byKey(ValueKey('compass_area_${area.name}')),
          matching: find.byIcon(Icons.check_rounded));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(checkIn(LifeArea.health), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('compass_area_growth')));
      await tester.pumpAndSettle();
      expect(checkIn(LifeArea.growth), findsOneWidget);
      expect(checkIn(LifeArea.health), findsNothing);

      await tester.tap(find.byKey(const ValueKey('compass_area_growth')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('match the horizon chips: the selected one is checked',
        (tester) async {
      await _pump(
        tester,
        Column(children: [
          AreaChips(selected: LifeArea.health, onChanged: (_) {}),
          HorizonPicker(
            selected: Horizon.thisYear,
            onChanged: (_) {},
            suggestedAge: 40,
          ),
        ]),
      );
      final horizon = tester.widget<ChoiceChip>(find.ancestor(
          of: find.text('This year'), matching: find.byType(ChoiceChip)));
      expect(horizon.selected, isTrue);
      expect(horizon.showCheckmark, isNot(false));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
