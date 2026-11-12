import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/look_back.dart';
import 'package:memento_mori_life_in_weeks/compass/weekly_question.dart';

import 'support/compass_test_app.dart';
import 'support/scroll_thread_probe.dart';

Future<void> _pumpCompass(WidgetTester tester) =>
    pumpCompassApp(tester, CompassScreen(now: compassToday));

CompassPrompt _question({bool gentleOnly = false, int swap = 0}) =>
    questionForWeek(compassToday,
        ageYears: 35, gentleOnly: gentleOnly, swap: swap);

String _en(CompassPrompt prompt) => prompt.textFor('en');

Finder _inSection(String section, Finder finder) =>
    find.descendant(of: find.byKey(ValueKey(section)), matching: finder);

Future<void> _addIntentionViaSheet(WidgetTester tester, String title) async {
  await tester.tap(find.byKey(const ValueKey('compass_add_intention')));
  await tester.pumpAndSettle();
  await tester.enterText(
      find.byKey(const ValueKey('compass_intention_title')), title);
  await tester.tap(find.byKey(const ValueKey('compass_sheet_save')));
  await tester.pumpAndSettle();
}

List<Intention> _withStatus(IntentionStatus status) =>
    CompassService.data.withStatus(status);

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() => initCompassTest());

  group('question of the week', () {
    testWidgets('shows this week\'s question with its kind', (tester) async {
      await _pumpCompass(tester);
      expect(find.text(_en(_question())), findsOneWidget);
      expect(find.text('QUESTION OF THE WEEK · COURAGE'), findsOneWidget);
    });

    testWidgets('"Another question" swaps once and is then hidden',
        (tester) async {
      await _pumpCompass(tester);
      await tester.tap(find.text('Another question'));
      await tester.pumpAndSettle();
      expect(find.text(_en(_question(swap: 1))), findsOneWidget);
      expect(find.text('Another question'), findsNothing);
      expect(CompassService.weekState(compassToday).swapped, isTrue);
    });

    testWidgets('"Not now" collapses the card to a link that reopens it',
        (tester) async {
      await _pumpCompass(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('compass_question_card')), findsNothing);
      expect(find.text('Show this week’s question'), findsOneWidget);
      expect(CompassService.weekState(compassToday).dismissed, isTrue);

      await tester.tap(find.text('Show this week’s question'));
      await tester.pumpAndSettle();
      expect(find.text(_en(_question())), findsOneWidget);
      expect(CompassService.weekState(compassToday).dismissed, isFalse);
    });

    testWidgets('gentle only never asks the courage question', (tester) async {
      await CompassService.setGentleOnly(true);
      await _pumpCompass(tester);
      final gentle = _question(gentleOnly: true);
      expect(gentle.kind, isNot(CompassPromptKind.courage));
      expect(find.text(_en(gentle)), findsOneWidget);
      expect(find.text(_en(_question())), findsNothing);
      expect(find.textContaining('COURAGE'), findsNothing);
    });

    testWidgets('"Make it an intention" prefills the note with the question',
        (tester) async {
      await _pumpCompass(tester);
      await tester.tap(find.text('Make it an intention'));
      await tester.pumpAndSettle();
      final note = tester.widget<TextField>(
          find.byKey(const ValueKey('compass_intention_note')));
      expect(note.controller!.text, _en(_question()));
      expect(find.byKey(const ValueKey('add_intention_screen')), findsOneWidget);
    });
  });

  group('Now', () {
    testWidgets('an empty Now invites instead of nagging', (tester) async {
      await _pumpCompass(tester);
      expect(find.textContaining('One small thing is enough'), findsOneWidget);
    });

    testWidgets('a title is required', (tester) async {
      await _pumpCompass(tester);
      await tester.tap(find.byKey(const ValueKey('compass_add_intention')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('compass_sheet_save')));
      await tester.pumpAndSettle();
      expect(find.text('A few words are enough.'), findsOneWidget);
      expect(CompassService.data.intentions, isEmpty);
    });

    testWidgets('holds three; the fourth goes to Someday with a hint',
        (tester) async {
      await _pumpCompass(tester);
      for (final title in ['One', 'Two', 'Three']) {
        await _addIntentionViaSheet(tester, title);
      }
      expect(_withStatus(IntentionStatus.now), hasLength(3));
      expect(find.byKey(const ValueKey('compass_limit_hint')), findsOneWidget);
      expect(find.text('Add to Someday'), findsOneWidget);

      await _addIntentionViaSheet(tester, 'Four');
      expect(_withStatus(IntentionStatus.now), hasLength(3));
      expect(_withStatus(IntentionStatus.someday).single.title, 'Four');
      expect(find.textContaining('“Now” is full'), findsOneWidget);
      // Someday opened to show where it went.
      expect(_inSection('compass_someday_section', find.text('Four')),
          findsOneWidget);
    });

    testWidgets('Done thanks gently and the intention appears in Lived',
        (tester) async {
      await CompassService.setShowReflection(false);
      await CompassService.addIntention(title: 'Call Mum');
      await _pumpCompass(tester);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Well done.'), findsOneWidget);
      expect(_inSection('compass_now_section', find.text('Call Mum')),
          findsNothing);
      expect(_inSection('compass_lived_section', find.text('Call Mum')),
          findsOneWidget);
      expect(CompassService.data.moments.single.fromIntentionId, isNotNull);
    });

    testWidgets('Done can be undone', (tester) async {
      await CompassService.setShowReflection(false);
      await CompassService.addIntention(title: 'Call Mum');
      await _pumpCompass(tester);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(_inSection('compass_now_section', find.text('Call Mum')),
          findsOneWidget);
      expect(_withStatus(IntentionStatus.now), hasLength(1));
      expect(CompassService.data.moments, isEmpty);
    });

    testWidgets('delete offers undo', (tester) async {
      await CompassService.addIntention(title: 'Learn piano');
      await _pumpCompass(tester);
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(CompassService.data.intentions, isEmpty);
      expect(find.text('Intention deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(_withStatus(IntentionStatus.now).single.title, 'Learn piano');
    });

    testWidgets('move to Someday and back', (tester) async {
      await CompassService.addIntention(title: 'Garden');
      await _pumpCompass(tester);
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to Someday'));
      await tester.pumpAndSettle();
      expect(_withStatus(IntentionStatus.someday), hasLength(1));

      await tester.tap(find.byKey(const ValueKey('compass_someday_toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to Now'));
      await tester.pumpAndSettle();
      expect(_withStatus(IntentionStatus.now), hasLength(1));
    });

    testWidgets('moving to a full Now shows the limit hint', (tester) async {
      for (final title in ['A', 'B', 'C']) {
        await CompassService.addIntention(title: title);
      }
      await CompassService.addIntention(
          title: 'D', status: IntentionStatus.someday);
      await _pumpCompass(tester);
      await tester.tap(find.byKey(const ValueKey('compass_someday_toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byKey(const ValueKey('compass_someday_section')),
          matching: find.byTooltip('More')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to Now'));
      await tester.pumpAndSettle();
      final hint = limitHint(compassWeekIndex(compassToday)).textFor('en');
      expect(find.text(hint), findsNWidgets(2)); // under Now and as snackbar
      expect(_withStatus(IntentionStatus.someday).single.title, 'D');
    });
  });

  group('Lived', () {
    testWidgets('an empty Lived invites', (tester) async {
      await _pumpCompass(tester);
      expect(find.textContaining('glad you lived'), findsOneWidget);
      expect(find.byKey(const ValueKey('compass_look_back')), findsNothing);
    });

    testWidgets('adds a moment and shows it newest first with a look back',
        (tester) async {
      await CompassService.addMoment(
          title: 'First job', date: DateTime(2012, 3, 1), area: LifeArea.growth);
      await _pumpCompass(tester);
      await tester.tap(find.byKey(const ValueKey('compass_add_moment')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('compass_moment_title')), 'Sunrise swim');
      await tester.tap(find.text('Health'));
      await tester.tap(find.byKey(const ValueKey('compass_sheet_save')));
      await tester.pumpAndSettle();

      final swim = tester.getTopLeft(find.text('Sunrise swim')).dy;
      final job = tester.getTopLeft(find.text('First job')).dy;
      expect(swim, lessThan(job));
      expect(find.text('Moments you have kept'), findsOneWidget);
      expect(find.text('Health · 1 moment'), findsOneWidget);
      expect(find.text('Age 20–29 · 1 moment'), findsOneWidget);
      expect(find.text('Age 30–39 · 1 moment'), findsOneWidget);
      expect(
          find.text('You have already lived 1,876\u00A0weeks. Some were hard, '
              'and you got through them.'),
          findsOneWidget);
    });

    testWidgets('the look back also groups by life phase', (tester) async {
      await CompassService.startPhase(
          preset: PhasePreset.study, start: DateTime(2010), today: compassToday);
      await CompassService.startPhase(
          preset: PhasePreset.buildUp, start: DateTime(2022), today: compassToday);
      await CompassService.addMoment(title: 'Thesis', date: DateTime(2012));
      await CompassService.addMoment(title: 'Trip', date: DateTime(2023));
      await CompassService.addMoment(title: 'Move', date: DateTime(2024));
      await _pumpCompass(tester);
      expect(find.text('By phase'), findsOneWidget);
      expect(find.text('University · 1 moment'), findsOneWidget);
      expect(find.text('Building up · 2 moments'), findsOneWidget);
    });

    testWidgets('delete a moment with undo', (tester) async {
      await CompassService.addMoment(title: 'Wedding', date: DateTime(2020));
      await _pumpCompass(tester);
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(CompassService.data.moments, isEmpty);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(CompassService.data.moments.single.title, 'Wedding');
    });
  });

  group('LookBack', () {
    test('counts per area (most first) and per decade of life', () {
      final moments = [
        Moment(id: '1', title: 'a', date: DateTime(1995), area: LifeArea.rest),
        Moment(id: '2', title: 'b', date: DateTime(2015), area: LifeArea.health),
        Moment(id: '3', title: 'c', date: DateTime(2016), area: LifeArea.health),
        Moment(id: '4', title: 'd', date: DateTime(2016)),
      ];
      final lookBack = LookBack.of(moments, birthDate: compassBirthDate);
      expect(lookBack.byArea, [
        (LifeArea.health, 2),
        (LifeArea.rest, 1),
        (null, 1),
      ]);
      expect(lookBack.byDecade, [(0, 1), (20, 3)]);
    });

    test('no decades without a birth date', () {
      final moments = [Moment(id: '1', title: 'a', date: DateTime(2000))];
      expect(LookBack.of(moments).byDecade, isEmpty);
    });

    test('groups moments by phase, oldest phase first', () {
      final school = LifePhase(id: 's', start: DateTime(1996, 11, 17));
      final work = LifePhase(id: 'w', start: DateTime(2015));
      final calm = LifePhase(id: 'c', start: DateTime(2020));
      final spans = resolvePhases([work, school, calm], compassToday);
      final moments = [
        Moment(id: '1', title: 'a', date: DateTime(1995)), // before any phase
        Moment(id: '2', title: 'b', date: DateTime(2000)),
        Moment(id: '3', title: 'c', date: DateTime(2014, 12, 31)),
        Moment(id: '4', title: 'd', date: DateTime(2020)),
        Moment(id: '5', title: 'e', date: compassToday),
      ];
      final byPhase = LookBack.of(moments, phases: spans).byPhase;
      expect([for (final (p, n) in byPhase) (p.id, n)], [('s', 2), ('c', 2)]);
      expect(LookBack.of(moments).byPhase, isEmpty);
    });
  });

  testWidgets('scroll thread shows while more content lies below',
      (tester) async {
    await pumpCompassApp(tester, CompassScreen(now: compassToday),
        size: phoneViewport);
    await tester.pump(); // scroll metrics arrive after the first frame
    expect(scrollThreadOpacity(tester), 1);
  });
}
