import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/completion_story.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/reflection/completion_reflection_screen.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/settings/compass_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/compass_test_app.dart';

const _reflection = ValueKey('completion_reflection');
const _phaseLevel = ValueKey('reflection_phase_level');
const _lifeLevel = ValueKey('reflection_life_level');
const _aheadLevel = ValueKey('reflection_ahead_level');

/// "Building up" since 2026-09-01; an intention written three weeks later
/// (so done after 6 weeks, in week 9 of the phase on [compassToday]).
Future<Intention> _intentionInPhase({IntentionKind? kind}) async {
  await CompassService.startPhase(
    preset: PhasePreset.buildUp,
    start: DateTime(2026, 9, 1),
    plannedEnd: DateTime(2027, 9, 1),
    today: compassToday,
  );
  final added = await CompassService.addIntention(
      title: 'Call Mum', kind: kind, today: DateTime(2026, 9, 21));
  return added.intention;
}

Future<void> _forgetBirthDate() async =>
    (await SharedPreferences.getInstance()).remove('birth_date');

Future<void> _tickDone(WidgetTester tester, {String tooltip = 'Done'}) async {
  await tester.pumpWidget(const SizedBox());
  await pumpCompassApp(tester, CompassScreen(now: compassToday));
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

Finder _inLived(Finder finder) => find.descendant(
    of: find.byKey(const ValueKey('compass_lived_section')), matching: finder);

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() => initCompassTest());

  group('opening', () {
    testWidgets('ticking an intention opens the look back with all levels',
        (tester) async {
      await _intentionInPhase();
      await _tickDone(tester);
      expect(find.byKey(_reflection), findsOneWidget);
      expect(find.text('Call Mum'), findsWidgets);
      expect(find.text('LIVED'), findsOneWidget);
      expect(
          find.text('Done after 6 weeks – in week 9 of your phase '
              '“Building up”.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('reflection_week_dot')), findsOneWidget);
      expect(find.byKey(_lifeLevel), findsOneWidget);
      expect(find.textContaining('A moment in week 1,877 of your life'),
          findsOneWidget);
      expect(find.byKey(_aheadLevel), findsOneWidget);
      expect(find.textContaining('weeks lie ahead of you'), findsOneWidget);
      expect(find.byKey(const ValueKey('reflection_thanks')), findsOneWidget);
      // No snackbar on top of it.
      expect(find.textContaining('Well done.'), findsNothing);
      expect(CompassService.data.moments.single.title, 'Call Mum');
    });

    testWidgets('German texts', (tester) async {
      await initCompassTest(lang: 'de');
      await _intentionInPhase();
      await _tickDone(tester, tooltip: 'Erledigt');
      expect(
          find.text('Nach 6 Wochen geschafft – in Woche 9 deiner '
              'Phase „Aufbauphase“.'),
          findsOneWidget);
      expect(find.textContaining('Ein Moment in Woche 1.877 deines Lebens'),
          findsOneWidget);
      expect(find.textContaining('Vor dir liegen noch etwa'), findsOneWidget);
      expect(find.text('Wofür bist du dankbar?'), findsOneWidget);
      expect(find.text('Doch noch nicht erledigt'), findsOneWidget);
    });

    testWidgets('without a phase only the time is told', (tester) async {
      await CompassService.addIntention(title: 'Call Mum', today: compassToday);
      await _tickDone(tester);
      expect(find.text('Done the very same day.'), findsOneWidget);
      expect(find.text('IN THIS PHASE'), findsNothing);
      expect(find.byKey(const ValueKey('reflection_week_dot')), findsNothing);
      expect(find.byKey(_lifeLevel), findsOneWidget);
    });

    testWidgets('without a birth date the life levels drop out',
        (tester) async {
      await _forgetBirthDate();
      await _intentionInPhase();
      await _tickDone(tester);
      expect(find.byKey(_phaseLevel), findsOneWidget);
      expect(find.byKey(_lifeLevel), findsNothing);
      expect(find.byKey(_aheadLevel), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byKey(const ValueKey('reflection_thanks')), findsOneWidget);
    });

    testWidgets('switched off: the snackbar thanks as before', (tester) async {
      await CompassService.setShowReflection(false);
      await CompassService.addIntention(title: 'Call Mum');
      await _tickDone(tester);
      expect(find.byKey(_reflection), findsNothing);
      expect(find.textContaining('Well done.'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });
  });

  group('leaving', () {
    testWidgets('the gratitude note is saved and shown on the Lived tile',
        (tester) async {
      await _intentionInPhase(kind: IntentionKind.enjoy);
      await _tickDone(tester);
      expect(find.text('e.g. the people who were there'), findsOneWidget);
      await tester.enterText(
          find.byKey(const ValueKey('reflection_note')), ' My sister ');
      await tester.tap(find.byKey(const ValueKey('reflection_close')));
      await tester.pumpAndSettle();
      expect(find.byKey(_reflection), findsNothing);
      expect(CompassService.data.moments.single.note, 'My sister');
      expect(_inLived(find.text('My sister')), findsOneWidget);
    });

    testWidgets('closing without a note keeps the moment as it was',
        (tester) async {
      await _intentionInPhase();
      await _tickDone(tester);
      await tester.tap(find.byKey(const ValueKey('reflection_close')));
      await tester.pumpAndSettle();
      expect(CompassService.data.moments.single.note, isNull);
      expect(_inLived(find.text('Call Mum')), findsOneWidget);
    });

    testWidgets('"Not done yet after all" restores the intention to Now',
        (tester) async {
      await _intentionInPhase();
      await _tickDone(tester);
      await tester.enterText(
          find.byKey(const ValueKey('reflection_note')), 'not saved');
      await tester.tap(find.byKey(const ValueKey('reflection_not_done')));
      await tester.pumpAndSettle();
      expect(find.byKey(_reflection), findsNothing);
      final intention = CompassService.data.intentions.single;
      expect(intention.status, IntentionStatus.now);
      expect(intention.phaseId, isNotNull);
      expect(CompassService.data.moments, isEmpty);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('compass_now_section')),
              matching: find.text('Call Mum')),
          findsOneWidget);
    });
  });

  group('motion', () {
    testWidgets('levels reveal one after another, then rest', (tester) async {
      await initCompassTest(extra: {
        'visualization_settings':
            jsonEncode(const VisualizationSettings().toMap()),
      });
      await _intentionInPhase();
      await tester.pumpWidget(const SizedBox());
      await pumpCompassApp(tester, CompassScreen(now: compassToday));
      await tester.tap(find.byTooltip('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      double opacityOf(ValueKey<String> key) => tester
          .widget<FadeTransition>(find
              .ancestor(of: find.byKey(key), matching: find.byType(FadeTransition))
              .first)
          .opacity
          .value;
      expect(opacityOf(_phaseLevel), greaterThan(opacityOf(_aheadLevel)));
      await tester.pumpAndSettle();
      expect(opacityOf(_aheadLevel), 1);
    });
  });

  group('layout', () {
    Future<void> pumpLongest(WidgetTester tester, String lang,
        {bool dark = false, bool motion = false}) async {
      await initCompassTest(lang: lang, extra: {
        if (dark) 'theme_style': 'warm',
        if (dark) 'brightness': 'dark',
        if (motion)
          'visualization_settings':
              jsonEncode(const VisualizationSettings().toMap()),
      });
      final phase = LifePhase(
          id: 'p',
          name: 'A rather long phase name for a rather long time',
          start: DateTime(2020),
          plannedEnd: DateTime(2030));
      final intention = Intention(
        id: 'i',
        title: 'Finally write the long letter to my grandmother in Lisbon',
        status: IntentionStatus.now,
        createdAt: DateTime(2025, 1, 5),
        phaseId: 'p',
        kind: IntentionKind.doTask,
      );
      final moment = Moment(
          id: 'm',
          title: intention.title,
          date: compassToday,
          fromIntentionId: 'i');
      final story = CompletionStory.of(
        intention: intention,
        moment: moment,
        phases: [phase],
        birthDate: compassBirthDate,
        lifeExpectancyYears: 80,
        today: compassToday,
      );
      await pumpCompassApp(
        tester,
        CompletionReflectionScreen(
            intention: intention, moment: moment, story: story),
        size: const Size(393, 851),
        dark: dark,
      );
    }

    for (final lang in ['en', 'de', 'fr', 'es']) {
      testWidgets('no overflow at 393x851 in $lang', (tester) async {
        await pumpLongest(tester, lang);
        expect(find.byKey(_aheadLevel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    /// The note field lies fully inside the scroll area, above its fade
    /// (and so above the pinned actions).
    void expectNoteVisible(WidgetTester tester) {
      final scroll =
          tester.getRect(find.byKey(const ValueKey('step_layout_scroll')));
      final note = tester.getRect(find.byKey(const ValueKey('reflection_note')));
      final close =
          tester.getRect(find.byKey(const ValueKey('reflection_close')));
      expect(note.top, greaterThanOrEqualTo(scroll.top));
      expect(note.bottom,
          lessThanOrEqualTo(scroll.bottom - StepLayout.fadeHeight));
      expect(note.bottom, lessThan(close.top));
    }

    testWidgets('the note field scrolls into view after the reveal (de)',
        (tester) async {
      await pumpLongest(tester, 'de', motion: true);
      expectNoteVisible(tester);
      final position = tester
          .state<ScrollableState>(find.descendant(
              of: find.byKey(const ValueKey('step_layout_scroll')),
              matching: find.byType(Scrollable)).first)
          .position;
      expect(position.pixels, greaterThan(0),
          reason: 'the field starts below the fold at 393x851');
    });

    testWidgets('the note field is in view without motion too (de)',
        (tester) async {
      await pumpLongest(tester, 'de');
      expectNoteVisible(tester);
    });

    /// A short look back without a phase (and without a birth date when
    /// [birthDate] is false), as on a phone.
    Future<void> pumpWithoutPhase(
      WidgetTester tester, {
      bool birthDate = true,
    }) async {
      final intention = Intention(
        id: 'i',
        title: 'Call Mum',
        status: IntentionStatus.now,
        createdAt: compassToday,
        kind: IntentionKind.doTask,
      );
      final moment = Moment(
        id: 'm',
        title: 'Call Mum',
        date: compassToday,
        fromIntentionId: 'i',
      );
      final story = CompletionStory.of(
        intention: intention,
        moment: moment,
        phases: const [],
        birthDate: birthDate ? compassBirthDate : null,
        lifeExpectancyYears: 80,
        today: compassToday,
      );
      await pumpCompassApp(
        tester,
        CompletionReflectionScreen(
          intention: intention,
          moment: moment,
          story: story,
        ),
        size: const Size(393, 851),
      );
    }

    Finder textsIn(ValueKey<String> level) =>
        find.descendant(of: find.byKey(level), matching: find.byType(Text));

    testWidgets('without a phase the time sentence keeps the level gap', (
      tester,
    ) async {
      await pumpWithoutPhase(tester);
      final title = tester.getRect(
        find.byKey(const ValueKey('reflection_title')),
      );
      final timeSentence = tester.getRect(textsIn(_phaseLevel).last);
      final lifeEyebrow = tester.getRect(textsIn(_lifeLevel).first);
      final levelGap = lifeEyebrow.top - timeSentence.bottom;
      expect(levelGap, greaterThan(0));
      expect(
        timeSentence.top - title.bottom,
        greaterThanOrEqualTo(levelGap - 0.5),
      );
    });

    testWidgets('short content is centred vertically at 393x851', (
      tester,
    ) async {
      await pumpWithoutPhase(tester, birthDate: false);
      expect(find.byKey(_lifeLevel), findsNothing);
      final scroll = tester.getRect(
        find.byKey(const ValueKey('step_layout_scroll')),
      );
      final top = tester.getRect(find.text('LIVED')).top;
      final bottom = tester
          .getRect(find.byKey(const ValueKey('reflection_note')))
          .bottom;
      final above = top - scroll.top;
      final below = scroll.bottom - bottom;
      expect(above, greaterThan(150), reason: 'not stuck at the top');
      expect((above - below).abs(), lessThan(24));
    });

    testWidgets('short content does not scroll', (tester) async {
      await pumpWithoutPhase(tester, birthDate: false);
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('step_layout_scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      expect(position.maxScrollExtent, 0);
      expectNoteVisible(tester);
    });

    testWidgets('no overflow in Warm dark', (tester) async {
      await pumpLongest(tester, 'de', dark: true);
      expect(Theme.of(tester.element(find.byKey(_reflection))).brightness,
          Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the Compass settings switch turns the look back off',
      (tester) async {
    await pumpCompassApp(
        tester, const Scaffold(body: SingleChildScrollView(child: CompassSection())));
    final tile = find.byKey(const ValueKey('compass_setting_reflection'));
    expect(find.text('Look back after finishing'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(CompassService.showReflection, isFalse);
  });
}
