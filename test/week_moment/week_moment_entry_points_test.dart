import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/settings/compass_section.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_screen.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/compass_test_app.dart';

const ValueKey<String> _replayButton = ValueKey('compass_week_moment');
final Finder _moment = find.byType(WeekMomentScreen);

Future<void> _init() async {
  await initCompassTest();
  await WeekMomentStore.initialize();
}

Future<void> _removeBirthDate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('birth_date');
  await SettingsService.initialize();
}

/// Lets [duration] pass in frames of 50 ms (the moment never settles).
Future<void> _frames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < duration; t += frame) {
    await tester.pump(frame);
  }
}

Future<void> _leaveMoment(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(const ValueKey('week_moment_skip')));
  await _frames(tester, const Duration(milliseconds: 800));
  // Step 1 of the card: go on without writing, then leave from step 2.
  await tester.tap(find.byKey(const ValueKey('week_moment_close_secondary')));
  await _frames(tester, const Duration(milliseconds: 800));
  await tester.tap(find.byKey(ValueKey(key)));
  await _frames(tester, const Duration(seconds: 1));
}

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(_init);

  testWidgets('the Compass settings switch turns the weekly moment off', (
    tester,
  ) async {
    await pumpCompassApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: CompassSection())),
    );
    final tile = find.byKey(const ValueKey('compass_setting_week_moment'));
    expect(find.text('Weekly moment'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(WeekMomentStore.enabled, isFalse);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(WeekMomentStore.enabled, isTrue);
  });

  group('Compass app bar', () {
    testWidgets('has no replay button without a birth date', (tester) async {
      await _removeBirthDate();
      await pumpCompassApp(tester, CompassScreen(now: compassToday));
      expect(find.byKey(_replayButton), findsNothing);
      expect(find.byKey(const ValueKey('compass_tour_help')), findsOneWidget);
    });

    testWidgets('replays the moment and stays on Compass', (tester) async {
      await pumpCompassApp(tester, CompassScreen(now: compassToday));
      expect(find.byTooltip('See your week'), findsOneWidget);

      await tester.tap(find.byKey(_replayButton));
      await _frames(tester, const Duration(milliseconds: 600));
      expect(_moment, findsOneWidget);
      expect(find.byKey(const ValueKey('week_moment_main')), findsOneWidget);
      expect(WeekMomentStore.lastShown, isNull);

      await _leaveMoment(tester, 'week_moment_plan_primary');
      expect(_moment, findsNothing);
      expect(find.byType(CompassScreen), findsOneWidget);
    });
  });
}
