import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_close/phase_close_draft.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_dots.dart';

import 'support/compass_test_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// "Building up" since 2 Sep 2022, its planned end passed (so the header
/// offers "Close").
Future<LifePhase> _seedPhase({DateTime? start}) => CompassService.startPhase(
      preset: PhasePreset.buildUp,
      start: start ?? DateTime(2022, 9, 2),
      plannedEnd: DateTime(2026, 10, 1),
      today: compassToday,
    );

Future<Intention> _addNow(String title) async =>
    (await CompassService.addIntention(title: title, today: compassToday))
        .intention;

Future<void> _startClosing(WidgetTester tester, {Size? size}) async {
  await pumpCompassApp(tester, CompassScreen(now: compassToday),
      size: size ?? const Size(393, 4000));
  await _tap(tester, 'compass_phase_close');
}

Intention _intention(String id) =>
    CompassService.data.intentions.firstWhere((i) => i.id == id);

LifePhase _phase(String id) =>
    CompassService.data.phases.firstWhere((p) => p.id == id);

int _dotCount(WidgetTester tester) =>
    tester.widget<StepDots>(find.byType(StepDots)).count;

/// Steps 3 and 4: "Starting a family" for two years.
Future<void> _chooseFamilyForTwoYears(WidgetTester tester) async {
  await _tap(tester, 'phase_preset_family');
  await _tap(tester, 'phase_close_next_phase');
  await _tap(tester, 'duration_choice_24');
  await _tap(tester, 'duration_apply');
}

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() => initCompassTest());

  testWidgets('closing carries over, lets go, keeps the note and begins anew',
      (tester) async {
    final closing = await _seedPhase();
    final keep = await _addNow('Learn Italian');
    final release = await _addNow('Renovate the attic');
    await _startClosing(tester);
    expect(_dotCount(tester), 4);
    expect(_key('phase_close_item_${keep.id}'), findsOneWidget);

    await _tap(tester, 'phase_close_let_go_${release.id}');
    await _tap(tester, 'phase_close_next');
    await tester.enterText(_key('phase_close_note'), 'I found my people.');
    await _tap(tester, 'phase_close_note_next');
    await _chooseFamilyForTwoYears(tester);

    final next = currentSpan(CompassService.data.phases, compassToday)!.phase;
    expect(next.id, isNot(closing.id));
    expect(next.preset, PhasePreset.family);
    expect(next.start, compassToday);
    expect(next.plannedEnd, DateTime(2028, 11, 2));
    expect(_phase(closing.id).note, 'I found my people.');
    expect(_intention(keep.id).phaseId, next.id);
    expect(_intention(keep.id).status, IntentionStatus.now);
    expect(_intention(release.id).status, IntentionStatus.letGo);
    expect(_intention(release.id).letGoAt, compassToday);
    expect(CompassService.data.intentions, hasLength(2));

    expect(_key('phase_close_note'), findsNothing);
    expect(find.text('New phase begun: Starting a family'), findsOneWidget);
    expect(find.text('Starting a family'), findsWidgets);
  });

  testWidgets('without open intentions the first step is the note',
      (tester) async {
    await _seedPhase();
    await _startClosing(tester);
    expect(_dotCount(tester), 3);
    expect(_key('phase_close_note'), findsOneWidget);
    expect(_key('phase_close_cancel'), findsOneWidget);
  });

  testWidgets('"Skip" closes without a note', (tester) async {
    final closing = await _seedPhase();
    await _startClosing(tester);
    await tester.enterText(_key('phase_close_note'), 'Half a thought');
    await _tap(tester, 'phase_close_skip');
    await _chooseFamilyForTwoYears(tester);
    expect(_phase(closing.id).note, isNull);
  });

  testWidgets('going back keeps every entry', (tester) async {
    await _seedPhase();
    final item = await _addNow('Learn Italian');
    await _startClosing(tester);
    await _tap(tester, 'phase_close_let_go_${item.id}');
    await _tap(tester, 'phase_close_next');
    await tester.enterText(_key('phase_close_note'), 'Good friends');
    await _tap(tester, 'phase_close_note_next');
    await _tap(tester, 'phase_preset_calmer');
    await _tap(tester, 'phase_close_next_phase');

    await _tap(tester, 'phase_close_back');
    expect(tester.widget<ChoiceChip>(_key('phase_preset_calmer')).selected,
        isTrue);
    await _tap(tester, 'phase_close_back');
    expect(find.text('Good friends'), findsOneWidget);
    await _tap(tester, 'phase_close_back');
    final choice = tester.widget<SegmentedButton<bool>>(
        find.byType(SegmentedButton<bool>));
    expect(choice.selected, {false});
  });

  testWidgets('leaving the flow changes nothing', (tester) async {
    await _seedPhase();
    await _startClosing(tester);
    await _tap(tester, 'phase_close_cancel');
    expect(CompassService.data.phases, hasLength(1));
    expect(CompassService.data.phases.single.note, isNull);
  });

  testWidgets('a phase that began today cannot be followed today',
      (tester) async {
    await _seedPhase(start: compassToday);
    await _startClosing(tester);
    await _tap(tester, 'phase_close_skip');
    await _tap(tester, 'phase_preset_family');
    await _tap(tester, 'phase_close_next_phase');
    expect(find.text('Another phase already starts on that day.'),
        findsOneWidget);
    expect(_key('duration_apply'), findsNothing);
  });

  test('the draft sorts take along and let go', () async {
    final closing = await _seedPhase();
    final a = await _addNow('a');
    final b = await _addNow('b');
    final draft = PhaseCloseDraft(
        closing: closing, openItems: [a, b], today: compassToday)
      ..takeAlong[b.id] = false;
    expect(draft.carryOver, {a.id});
    expect(draft.letGo, {b.id});
    expect(draft.steps.first, PhaseCloseStep.openItems);
    expect(PhaseCloseDraft(closing: closing, openItems: const [],
            today: compassToday).steps,
        [PhaseCloseStep.note, PhaseCloseStep.next, PhaseCloseStep.duration]);
  });

  group('fits a Pixel 5 (393 x 851)', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('in $lang without overflow', (tester) async {
        await initCompassTest(lang: lang);
        await _seedPhase();
        await _addNow('Mit meiner Großmutter die Familiengeschichte aufschreiben');
        await _addNow('Learn Italian');
        await _startClosing(tester, size: const Size(393, 851));
        expect(tester.takeException(), isNull);
        await _tap(tester, 'phase_close_next');
        expect(tester.takeException(), isNull);
        await _tap(tester, 'phase_close_note_next');
        expect(tester.takeException(), isNull);
        await _tap(tester, 'phase_preset_transition');
        await _tap(tester, 'phase_close_next_phase');
        expect(tester.takeException(), isNull);
        expect(_key('duration_apply'), findsOneWidget);
      });
    }
  });
}
