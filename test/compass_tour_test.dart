import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_tour.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_tour_trigger.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/compass_setup_screen.dart';
import 'package:memento_mori_life_in_weeks/diagnostics_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:memento_mori_life_in_weeks/widget_launches.dart';

import 'support/compass_test_app.dart';

class _NoWidgetLaunches implements WidgetLaunches {
  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) =>
      const Stream<void>.empty().listen(null);
}

Widget _shell() =>
    AppShell(now: compassToday, widgetLaunches: _NoWidgetLaunches());

Finder _key(String key) => find.byKey(ValueKey(key));

Finder get _tourTitle => _key('tour_title');

const Size _pixel5 = Size(393, 851);

/// The tour button [key] labelled as in the Compass tour's first step.
Finder _buttonLabel(String key) => find.descendant(
    of: _key(key),
    matching: find.text(key == 'tour_skip' ? 'Not now' : 'Show me'));

String _titleText(WidgetTester tester) =>
    tester.widget<Text>(_tourTitle).data!;

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, IconData icon) async {
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.byIcon(icon)));
  await tester.pumpAndSettle();
}

Future<void> _openCompassTab(WidgetTester tester) =>
    _openTab(tester, Icons.explore_outlined);

Future<void> _seedPhase() => CompassService.startPhase(
    preset: PhasePreset.buildUp,
    start: DateTime(2024, 3, 1),
    today: compassToday);

bool get _seen => TourProgressStore.isSeen(CompassTour.id);

/// An existing user: a phase, the setup opened by itself before.
Future<void> _initExistingUser() async {
  await initCompassTest(
      toursSeen: false, extra: {'compass_setup': '{"autoOpened":true}'});
  await _seedPhase();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('new user', () {
    setUp(() => initCompassTest(toursSeen: false));

    testWidgets('gets the setup first, then the tour', (tester) async {
      await pumpCompassApp(tester, _shell(), size: _pixel5);
      await _openCompassTab(tester);
      expect(find.byType(CompassSetupScreen), findsOneWidget);
      expect(_tourTitle, findsNothing);

      await _tap(tester, 'compass_setup_close');
      expect(find.byType(CompassSetupScreen), findsNothing);
      expect(_titleText(tester), 'What is a phase?');
      expect(_buttonLabel('tour_next'), findsOneWidget);
      expect(_buttonLabel('tour_skip'), findsOneWidget);
      expect(_seen, isTrue);
    });
  });

  group('existing user', () {
    setUp(_initExistingUser);

    testWidgets('sees the tour on the first visit, all five steps',
        (tester) async {
      await pumpCompassApp(tester, _shell(), size: _pixel5);
      expect(_tourTitle, findsNothing, reason: 'not on the Life tab');

      await _openCompassTab(tester);
      expect(_titleText(tester), 'What is a phase?');
      expect(find.text('Tip 1 of 5'), findsOneWidget);
      await _tap(tester, 'tour_next');
      expect(_titleText(tester), 'Your phase');
      await _tap(tester, 'tour_next');
      expect(_titleText(tester), 'Question of the week');
      await _tap(tester, 'tour_next');
      expect(_titleText(tester), 'Now');
      await _tap(tester, 'tour_next');
      expect(_titleText(tester), 'Someday & Lived');
      await _tap(tester, 'tour_done');
      expect(_tourTitle, findsNothing);
      expect(_seen, isTrue);
    });

    testWidgets('not again on the second visit', (tester) async {
      await pumpCompassApp(tester, _shell(), size: _pixel5);
      await _openCompassTab(tester);
      await _tap(tester, 'tour_skip');
      await _openTab(tester, Icons.hourglass_empty_rounded);
      await _openCompassTab(tester);
      expect(_tourTitle, findsNothing);
    });

    testWidgets('"Not now" ends the tour and marks it seen', (tester) async {
      await pumpCompassApp(tester, _shell(), size: _pixel5);
      await _openCompassTab(tester);
      expect(_buttonLabel('tour_skip'), findsOneWidget);
      await _tap(tester, 'tour_skip');
      expect(_tourTitle, findsNothing);
      expect(_seen, isTrue);
    });

    testWidgets('the help button replays a seen tour', (tester) async {
      await TourProgressStore.markSeen(CompassTour.id);
      await pumpCompassApp(tester, _shell(), size: _pixel5);
      await _openCompassTab(tester);
      expect(_tourTitle, findsNothing);
      expect(find.byTooltip('How Compass works'), findsOneWidget);

      await _tap(tester, 'compass_tour_help');
      expect(_titleText(tester), 'What is a phase?');
      await _tap(tester, 'tour_next');
      expect(_titleText(tester), 'Your phase');
    });

    testWidgets('shows again after "Show hints again" in Settings',
        (tester) async {
      await TourProgressStore.markSeen(CompassTour.id);
      // Tall enough for the whole Settings list.
      await pumpCompassApp(tester, _shell(), size: const Size(393, 8000));
      await _openTab(tester, Icons.settings_outlined);
      await _tap(tester, 'settings_show_tips_tile');
      expect(find.text('Hints will show again'), findsOneWidget);
      expect(_seen, isFalse);

      await _openCompassTab(tester);
      expect(_titleText(tester), 'What is a phase?');
    });
  });

  group('trigger', () {
    setUp(() => initCompassTest(toursSeen: false));

    Future<CompassTourTrigger> pumpTriggerScreen(WidgetTester tester) async {
      final anchors = TourAnchors();
      late BuildContext screenContext;
      await pumpCompassApp(
        tester,
        TourAnchorScope(
          anchors: anchors,
          child: Builder(builder: (context) {
            screenContext = context;
            return Scaffold(
              body: TourAnchor(
                  id: CompassTour.phaseAnchor,
                  child: const SizedBox(height: 80, width: 80)),
            );
          }),
        ),
      );
      return CompassTourTrigger(contextOf: () => screenContext, anchors: anchors);
    }

    testWidgets('does not start under a sheet', (tester) async {
      final trigger = await pumpTriggerScreen(tester);
      final context = tester.element(find.byType(Scaffold));
      showModalBottomSheet<void>(
          context: context, builder: (_) => const SizedBox(height: 200));
      await tester.pumpAndSettle();

      unawaited(trigger.startIfDue(tabVisible: () => true, blocked: () => false));
      await tester.pumpAndSettle();
      expect(_tourTitle, findsNothing);
      expect(_seen, isFalse);
    });

    testWidgets('waits while the setup is due', (tester) async {
      final trigger = await pumpTriggerScreen(tester);
      unawaited(trigger.startIfDue(tabVisible: () => true, blocked: () => true));
      await tester.pumpAndSettle();
      expect(_tourTitle, findsNothing);
      expect(_seen, isFalse);
    });

    testWidgets('starts when free and shows only steps with an anchor',
        (tester) async {
      final trigger = await pumpTriggerScreen(tester);
      unawaited(
          trigger.startIfDue(tabVisible: () => true, blocked: () => false));
      await tester.pumpAndSettle();
      expect(find.text('Tip 1 of 2'), findsOneWidget);
      expect(_seen, isTrue);
    });

    testWidgets('without anchors only the centred intro shows',
        (tester) async {
      await pumpCompassApp(tester, const Scaffold());
      final trigger = CompassTourTrigger(
          contextOf: () => tester.element(find.byType(Scaffold)),
          anchors: TourAnchors());
      unawaited(trigger.show());
      await tester.pumpAndSettle();
      // A single tip goes without "Tip 1 of 1".
      expect(_key('tour_counter'), findsNothing);
      expect(_titleText(tester), 'What is a phase?');
    });
  });

  testWidgets('diagnostics resets the tours', (tester) async {
    await initCompassTest();
    expect(_seen, isTrue);
    await pumpCompassApp(
        tester, DiagnosticsScreen(loadPendingNotifications: () async => const []));
    await tester.ensureVisible(_key('diagnostics_tours_reset'));
    await _tap(tester, 'diagnostics_tours_reset');
    expect(_seen, isFalse);
    expect(find.text('Tours reset'), findsOneWidget);
  });

  test('every Compass tour text exists in every language', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      final values = AppLocalizations.valuesFor(lang);
      for (final step in CompassTour.steps) {
        for (final key in [
          step.titleKey,
          step.bodyKey,
          ?step.primaryLabelKey,
          ?step.secondaryLabelKey,
        ]) {
          expect(values[key], isNotNull, reason: '$lang $key');
        }
      }
    }
  });
}
