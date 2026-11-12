import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/compass_setup_screen.dart';
import 'package:memento_mori_life_in_weeks/diagnostics_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
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

Finder get _setup => find.byType(CompassSetupScreen);

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _openCompassTab(WidgetTester tester) async {
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.explore_outlined)));
  await tester.pumpAndSettle();
}

/// Phase step: "Building up", begun today.
Future<void> _confirmPhase(WidgetTester tester) async {
  await _tap(tester, 'phase_preset_buildUp');
  await _tap(tester, 'phase_apply');
}

/// Drops every cache and reads the same stored prefs again, as after an
/// app restart.
Future<void> _restart(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  CompassService.clearCacheForTesting();
  await CompassService.initialize();
  CompassSetupStore.clearCacheForTesting();
  await CompassSetupStore.initialize();
}

String _progressText(WidgetTester tester) =>
    tester.widget<Text>(_key('compass_setup_progress')).data!;

Future<LifePhase> _seedPhase() => CompassService.startPhase(
    preset: PhasePreset.buildUp,
    start: DateTime(2024, 3, 1),
    today: compassToday);

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() => initCompassTest());

  group('opens by itself', () {
    testWidgets('on the first visit to the Compass tab, not at app start',
        (tester) async {
      await pumpCompassApp(tester, _shell());
      expect(_setup, findsNothing);
      expect(CompassSetupStore.progress.autoOpened, isFalse);

      await _openCompassTab(tester);
      expect(_setup, findsOneWidget);
      expect(find.text('Which phase of your life are you in right now?'),
          findsOneWidget);
      expect(find.text('COMPASS · FIRST TIME'), findsOneWidget);
      expect(CompassSetupStore.progress.autoOpened, isTrue);
    });

    testWidgets('only once', (tester) async {
      await pumpCompassApp(tester, _shell());
      await _openCompassTab(tester);
      await _tap(tester, 'compass_setup_close');
      expect(_setup, findsNothing);

      await tester.tap(find.byIcon(Icons.hourglass_empty_rounded));
      await tester.pumpAndSettle();
      await _openCompassTab(tester);
      expect(_setup, findsNothing);
      expect(_key('compass_setup_card'), findsOneWidget);
    });

    testWidgets('not for a Compass screen outside the shell', (tester) async {
      await pumpCompassApp(tester, CompassScreen(now: compassToday));
      expect(_setup, findsNothing);
      expect(_key('compass_setup_card'), findsOneWidget);
    });

    testWidgets('existing users only get the card, no data is lost',
        (tester) async {
      await CompassService.addIntention(title: 'Learn to sail', today: compassToday);
      await CompassService.addMoment(title: 'Sunrise hike', date: compassToday);
      await pumpCompassApp(tester, _shell());
      await _openCompassTab(tester);

      expect(_setup, findsNothing);
      expect(_key('compass_setup_card'), findsOneWidget);
      // The open "Now" intention counts as the first one.
      expect(_progressText(tester), '1 of 4');
      expect(find.text('Learn to sail'), findsOneWidget);
      expect(CompassService.data.intentions, hasLength(1));
      expect(CompassService.data.moments, hasLength(1));
    });
  });

  testWidgets('"Later" at step 2, restart, "Continue" resumes at step 2',
      (tester) async {
    await pumpCompassApp(tester, _shell());
    await _openCompassTab(tester);
    await _confirmPhase(tester);
    expect(find.text('About how much longer should this phase last?'),
        findsOneWidget);

    await _tap(tester, 'compass_setup_later');
    expect(_setup, findsNothing);
    expect(_key('compass_setup_card'), findsOneWidget);
    expect(_progressText(tester), '1 of 4');
    expect(_key('compass_setup_phase_done'), findsOneWidget);
    expect(_key('compass_setup_duration_open'), findsOneWidget);

    await _restart(tester);
    await pumpCompassApp(tester, _shell());
    await _openCompassTab(tester);
    expect(_setup, findsNothing);
    expect(_progressText(tester), '1 of 4');

    await _tap(tester, 'compass_setup_continue');
    expect(_setup, findsOneWidget);
    expect(_key('duration_apply'), findsOneWidget);
  });

  testWidgets('a full run saves phase, plan, intention and rhythm',
      (tester) async {
    await pumpCompassApp(tester, _shell());
    await _openCompassTab(tester);
    await _confirmPhase(tester);

    await _tap(tester, 'duration_choice_24');
    expect(find.text('until about November 2028'), findsOneWidget);
    await _tap(tester, 'duration_apply');

    await tester.enterText(_key('compass_intention_title'), 'Norway with Dad');
    await tester.pumpAndSettle();
    await _tap(tester, 'compass_sheet_save');

    await _tap(tester, 'rhythm_every_4_weeks');
    await _tap(tester, 'setup_rhythm_apply');

    expect(_setup, findsNothing);
    expect(_key('compass_setup_card'), findsNothing);
    final phase = CompassService.data.phases.single;
    expect(phase.preset, PhasePreset.buildUp);
    expect(phase.plannedEnd, DateTime(2028, 11, 2));
    final intention = CompassService.data.intentions.single;
    expect(intention.title, 'Norway with Dad');
    expect(intention.status, IntentionStatus.now);
    expect(intention.phaseId, phase.id);
    expect(intention.kind, IntentionKind.doTask);
    expect(ReminderService.rhythm(), ReminderRhythm.every4Weeks);
    expect(CompassSetupStore.progress.lastStep, isNull);
  });

  testWidgets('"Open" counts as a chosen duration', (tester) async {
    await _seedPhase();
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await _tap(tester, 'compass_setup_continue');
    expect(_key('duration_apply'), findsOneWidget);

    await _tap(tester, 'duration_choice_open');
    expect(find.text('No planned end – that’s fine too.'), findsOneWidget);
    await _tap(tester, 'duration_apply');
    expect(_key('setup_intention_form'), findsOneWidget);
    expect(CompassService.data.phases.single.plannedEnd, isNull);
    expect(CompassSetupStore.progress.completed, contains(SetupStep.duration));
  });

  testWidgets('back returns to the previous step', (tester) async {
    await pumpCompassApp(tester, _shell());
    await _openCompassTab(tester);
    await _confirmPhase(tester);
    await _tap(tester, 'compass_setup_back');
    expect(_key('phase_apply'), findsOneWidget);
    // Editing the phase now, not starting another one.
    await _tap(tester, 'phase_apply');
    expect(CompassService.data.phases, hasLength(1));
    expect(_key('duration_apply'), findsOneWidget);
  });

  testWidgets('steps already done are passed over', (tester) async {
    await _seedPhase();
    await CompassService.addIntention(title: 'Read more', today: compassToday);
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await _tap(tester, 'compass_setup_continue');
    await _tap(tester, 'duration_choice_6');
    await _tap(tester, 'duration_apply');
    // The intention step is done already: on to the rhythm.
    expect(_key('setup_rhythm_apply'), findsOneWidget);
  });

  testWidgets('"Later" on the first step resumes there from the card',
      (tester) async {
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await _tap(tester, 'compass_setup_continue');
    await _tap(tester, 'compass_setup_later');
    expect(CompassSetupStore.progress.skipped, {SetupStep.phase});
    expect(_progressText(tester), '0 of 4');

    await _tap(tester, 'compass_setup_continue');
    expect(_key('phase_apply'), findsOneWidget);
  });

  testWidgets('the dismiss button hides the card for good', (tester) async {
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await _tap(tester, 'compass_setup_dismiss');
    expect(_key('compass_setup_card'), findsNothing);
    expect(CompassSetupStore.progress.cardDismissed, isTrue);
    expect(_key('compass_phase_empty'), findsOneWidget);
  });

  testWidgets('diagnostics resets the setup', (tester) async {
    await CompassSetupStore.save(const CompassSetupProgress(
        cardDismissed: true, autoOpened: true, completed: {SetupStep.rhythm}));
    await pumpCompassApp(
        tester, DiagnosticsScreen(loadPendingNotifications: () async => const []));
    await _tap(tester, 'diagnostics_compass_setup_reset');
    expect(CompassSetupStore.progress, CompassSetupProgress.empty);
    expect(find.text('Compass setup reset'), findsOneWidget);
  });

  group('fits a Pixel 5 (393 x 851)', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      for (final step in SetupStep.values) {
        testWidgets('$step in $lang without overflow', (tester) async {
          await initCompassTest(lang: lang);
          if (step != SetupStep.phase) await _seedPhase();
          await pumpCompassApp(
            tester,
            CompassSetupScreen(
              start: step,
              today: compassToday,
              birthDate: compassBirthDate,
              lifeExpectancyYears: 80,
            ),
            size: const Size(393, 851),
          );
          if (step == SetupStep.duration) await _tap(tester, 'duration_fine');
          expect(tester.takeException(), isNull);
        });
      }
      testWidgets('the card in $lang without overflow', (tester) async {
        await initCompassTest(lang: lang);
        await pumpCompassApp(tester, CompassScreen(now: compassToday),
            size: const Size(393, 851));
        expect(_key('compass_setup_card'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
