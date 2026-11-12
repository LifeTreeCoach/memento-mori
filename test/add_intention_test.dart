import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/time_window.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/intention_flow_context.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/phase_week_dots.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/time_window_card.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';

import 'support/compass_test_app.dart';

ValueKey<String> _key(String key) => ValueKey(key);

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(_key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Phase "Building up" since March 2024, planned until [plannedEnd].
Future<LifePhase> _seedPhase({DateTime? plannedEnd}) =>
    CompassService.startPhase(
      preset: PhasePreset.buildUp,
      start: DateTime(2024, 3, 1),
      plannedEnd: plannedEnd,
      today: compassToday,
    );

Future<void> _openFlow(WidgetTester tester, {Size? size}) async {
  await pumpCompassApp(tester, CompassScreen(now: compassToday),
      size: size ?? const Size(393, 4000));
  await tester.scrollUntilVisible(find.byKey(_key('compass_add_intention')), 200,
      scrollable: find.byType(Scrollable).first);
  await _tap(tester, 'compass_add_intention');
}

Future<void> _enterTitle(WidgetTester tester, String title) async {
  await tester.enterText(find.byKey(_key('compass_intention_title')), title);
  await tester.pumpAndSettle();
}

Intention _single() => CompassService.data.intentions.single;

void main() {
  setUpAll(() async {
    for (final code in AppLocalizations.supportedLanguages) {
      await initializeDateFormatting(code);
    }
  });
  setUp(() => initCompassTest());

  testWidgets('shows the phase on top and saves a doTask in this phase',
      (tester) async {
    final phase = await _seedPhase(plannedEnd: DateTime(2028, 1, 1));
    await _openFlow(tester);
    expect(find.text('BUILDING UP'), findsOneWidget);
    expect(find.text('What do you want to spend a few weeks on?'),
        findsOneWidget);
    expect(find.text('Plan it for this phase'), findsOneWidget);
    expect(find.byKey(_key('intention_due_date')), findsNothing);

    await _enterTitle(tester, 'Norway with Dad');
    await _tap(tester, 'compass_sheet_save');

    final intention = _single();
    expect(intention.kind, IntentionKind.doTask);
    expect(intention.status, IntentionStatus.now);
    expect(intention.phaseId, phase.id);
    expect(find.textContaining('Intention · ~13 more months'),
        findsOneWidget);
  });

  testWidgets('kind cards switch between doing and enjoying', (tester) async {
    await _seedPhase();
    await _openFlow(tester);
    await _tap(tester, 'intention_kind_enjoy');
    expect(find.byKey(_key('intention_due_date')), findsOneWidget);
    expect(find.text('no rush, but not without a date'), findsOneWidget);
    await _tap(tester, 'intention_kind_doTask');
    expect(find.byKey(_key('intention_due_date')), findsNothing);
  });

  testWidgets('enjoy with a date', (tester) async {
    await _seedPhase();
    await _openFlow(tester);
    await _enterTitle(tester, 'Swim in the lake');
    await _tap(tester, 'intention_kind_enjoy');
    await _tap(tester, 'intention_due_date');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('16 November'), findsOneWidget);
    expect(find.textContaining('you’ve set 16 November'), findsOneWidget);
    await _tap(tester, 'compass_sheet_save');

    final intention = _single();
    expect(intention.kind, IntentionKind.enjoy);
    expect(intention.dueDate, DateTime(2026, 11, 16));
    expect(find.text('Enjoy · on 16 November'), findsOneWidget);
  });

  testWidgets('closing the date picker leaves the keyboard closed',
      (tester) async {
    await _seedPhase();
    await _openFlow(tester);
    await _enterTitle(tester, 'Swim in the lake');
    final title = find.descendant(
        of: find.byKey(_key('compass_intention_title')),
        matching: find.byType(EditableText));
    bool titleFocused() =>
        tester.widget<EditableText>(title).focusNode.hasFocus;
    expect(titleFocused(), isTrue);
    await _tap(tester, 'intention_kind_enjoy');
    await _tap(tester, 'intention_due_date');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('16 November'), findsOneWidget);
    expect(titleFocused(), isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('someday belongs to no phase', (tester) async {
    await _seedPhase();
    await _openFlow(tester);
    await _enterTitle(tester, 'Learn the cello');
    await _tap(tester, 'intention_when_someday');
    expect(find.byKey(_key('intention_time_window')), findsNothing);
    expect(find.text('Keep it for someday'), findsOneWidget);
    await _tap(tester, 'compass_sheet_save');

    expect(_single().status, IntentionStatus.someday);
    expect(_single().phaseId, isNull);
  });

  testWidgets('without a phase: "Now", no time window', (tester) async {
    await _openFlow(tester);
    expect(find.text('COMPASS'), findsOneWidget);
    expect(find.text('Now'), findsWidgets);
    expect(find.text('In this phase'), findsNothing);
    expect(find.text('Plan it now'), findsOneWidget);
    expect(find.byKey(_key('intention_time_window')), findsNothing);
    await _enterTitle(tester, 'Call Mum');
    await _tap(tester, 'compass_sheet_save');
    expect(_single().status, IntentionStatus.now);
    expect(_single().phaseId, isNull);
  });

  testWidgets('a full Now overflows into Someday with a hint', (tester) async {
    await _seedPhase();
    for (var i = 0; i < nowLimit; i++) {
      await CompassService.addIntention(title: 'Now $i', today: compassToday);
    }
    await _openFlow(tester);
    await _enterTitle(tester, 'One more');
    await _tap(tester, 'compass_sheet_save');

    final added = CompassService.data.intentions.last;
    expect(added.status, IntentionStatus.someday);
    expect(added.phaseId, isNull);
    expect(find.text('“Now” is full, so this one waits in “Someday”. Nothing is lost.'),
        findsOneWidget);
  });

  testWidgets('"Make it an intention" prefills the note and opens "More"',
      (tester) async {
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await tester.tap(find.text('Make it an intention'));
    await tester.pumpAndSettle();
    final note = tester
        .widget<TextField>(find.byKey(_key('compass_intention_note')))
        .controller!
        .text;
    expect(note, isNotEmpty);
    await _enterTitle(tester, 'Say yes more often');
    await _tap(tester, 'compass_sheet_save');
    expect(_single().note, note);
  });

  testWidgets('back leaves without saving', (tester) async {
    await _openFlow(tester);
    await _enterTitle(tester, 'Not yet');
    await _tap(tester, 'add_intention_back');
    expect(CompassService.data.intentions, isEmpty);
  });

  testWidgets('the edit sheet changes the kind and keeps the date',
      (tester) async {
    await CompassService.addIntention(title: 'Picnic', today: compassToday);
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await tester.tap(find.text('Picnic'));
    await tester.pumpAndSettle();
    await _tap(tester, 'intention_kind_enjoy');
    await _tap(tester, 'intention_due_date');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tap(tester, 'compass_sheet_save');
    expect(_single().kind, IntentionKind.enjoy);
    expect(_single().dueDate, DateTime(2026, 11, 16));
  });

  testWidgets('"Let go" keeps the intention and can be undone',
      (tester) async {
    await CompassService.addIntention(title: 'Marathon', today: compassToday);
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let go'));
    await tester.pumpAndSettle();
    expect(_single().status, IntentionStatus.letGo);
    expect(find.text('Let go. That’s all right.'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_single().status, IntentionStatus.now);
  });

  testWidgets('Now counts, Lived names the phase year', (tester) async {
    await _seedPhase();
    await CompassService.addIntention(title: 'Norway', today: compassToday,
        kind: IntentionKind.doTask);
    await CompassService.addIntention(title: 'Cello', today: compassToday,
        status: IntentionStatus.someday);
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    expect(find.text('1 of 3 · the rest can wait'), findsOneWidget);
    expect(find.textContaining('1 idea waiting.'), findsOneWidget);

    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    // The look back opens first; closing it shows Lived.
    await tester.tap(find.byKey(const ValueKey('reflection_close')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Done · Building up, year\u00A03'), findsOneWidget);
  });

  group('time window', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      DateTime? plannedEnd,
      DateTime? birthDate,
      ReminderRhythm rhythm = ReminderRhythm.every4Weeks,
      IntentionKind kind = IntentionKind.doTask,
      String lang = 'de',
    }) async {
      await initCompassTest(lang: lang);
      final phase = LifePhase(id: 'p', preset: PhasePreset.buildUp,
          start: DateTime(2024, 3, 1), plannedEnd: plannedEnd);
      final span = PhaseSpan(phase: phase, start: phase.start, isCurrent: true);
      await pumpCompassApp(
        tester,
        Scaffold(
          body: TimeWindowCard(
            flow: IntentionFlowContext(today: compassToday,
                birthDate: birthDate, lifeExpectancyYears: 80, phase: span,
                rhythm: rhythm),
            phase: span,
            kind: kind,
            dueDate: null,
          ),
        ),
      );
    }

    String body(WidgetTester tester) => tester
        .widget<Text>(find.byKey(_key('intention_window_body')))
        .data!;

    testWidgets('weeks left, share and the 4-week check-in', (tester) async {
      await pumpCard(tester, plannedEnd: DateTime(2027, 12, 27),
          birthDate: compassBirthDate);
      expect(find.text('Noch etwa 60 Wochen in dieser Phase.'),
          findsOneWidget);
      expect(body(tester),
          'Das sind 1,4 % deiner Lebensspanne. Nicht viel – aber genug, '
          'wenn du bald anfängst. Du wirst alle vier Wochen kurz gefragt, ob '
          'es vorangeht.');
      expect(find.byKey(_key('intention_week_dots')), findsOneWidget);
      expect(find.text('1\u00A0Punkt = 4\u00A0Wochen'), findsOneWidget);
    });

    testWidgets('weekly rhythm, no birth date: no percent', (tester) async {
      await pumpCard(tester, plannedEnd: DateTime(2027, 12, 27),
          rhythm: ReminderRhythm.weekly);
      expect(body(tester),
          'Nicht viel – aber genug, wenn du bald anfängst. Sonntags erinnert '
          'dich der Kompass an deine Vorhaben.');
    });

    testWidgets('rhythm off: no reminder sentence', (tester) async {
      await pumpCard(tester, plannedEnd: DateTime(2027, 12, 27),
          birthDate: compassBirthDate, rhythm: ReminderRhythm.off);
      expect(body(tester), isNot(contains('erinnert')));
      expect(body(tester), isNot(contains('gefragt')));
    });

    testWidgets('no planned end: just begin, no dots', (tester) async {
      await pumpCard(tester, birthDate: compassBirthDate,
          rhythm: ReminderRhythm.off);
      expect(find.text('Diese Phase hat kein geplantes Ende. Fang einfach an.'),
          findsOneWidget);
      expect(find.byKey(_key('intention_week_dots')), findsNothing);
      expect(find.byKey(_key('intention_window_body')), findsNothing);
    });

    testWidgets('enjoy is gentler', (tester) async {
      await pumpCard(tester, plannedEnd: DateTime(2027, 12, 27),
          birthDate: compassBirthDate, kind: IntentionKind.enjoy);
      expect(body(tester),
          'Kein Druck. Gib ihm einen Termin, dann passiert es eher.');
    });
  });

  group('week dots scale caption', () {
    const expected = {
      'en': ['1\u00A0dot = 1\u00A0week', '1\u00A0dot = 4\u00A0weeks'],
      'de': ['1\u00A0Punkt = 1\u00A0Woche', '1\u00A0Punkt = 4\u00A0Wochen'],
      'fr': ['1\u00A0point = 1\u00A0semaine', '1\u00A0point = 4\u00A0semaines'],
      'es': ['1\u00A0punto = 1\u00A0semana', '1\u00A0punto = 4\u00A0semanas'],
    };
    for (final MapEntry(key: lang, value: captions) in expected.entries) {
      testWidgets('shown for 1 and 4 weeks per dot ($lang)', (tester) async {
        await initCompassTest(lang: lang);
        for (final (weeks, caption) in [
          (const PhaseWeeks(lived: 30, left: 50), captions[0]),
          (const PhaseWeeks(lived: 100, left: 60), captions[1]),
        ]) {
          await pumpCompassApp(
              tester, Scaffold(body: PhaseWeekDots(weeks: weeks)));
          expect(
              tester
                  .widget<Text>(find.byKey(_key('intention_dots_scale')))
                  .data,
              caption);
        }
      });
    }
  });

  group('fits a Pixel 5 (393 x 851)', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('the flow in $lang without overflow', (tester) async {
        await initCompassTest(lang: lang);
        await _seedPhase(plannedEnd: DateTime(2027, 12, 27));
        await _openFlow(tester, size: const Size(393, 851));
        await _tap(tester, 'intention_kind_enjoy');
        await _tap(tester, 'intention_more');
        for (var i = 0; i < 6; i++) {
          await tester.dragFrom(const Offset(200, 600), const Offset(0, -500));
          await tester.pumpAndSettle();
        }
        await _tap(tester, 'intention_when_someday');
        await _tap(tester, 'intention_kind_doTask');
        await _tap(tester, 'intention_when_now');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
