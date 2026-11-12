import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_edit_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/compass_test_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _pumpCompass(WidgetTester tester, {Size? size}) => size == null
    ? pumpCompassApp(tester, CompassScreen(now: compassToday))
    : pumpCompassApp(tester, CompassScreen(now: compassToday), size: size);

Future<void> _tap(WidgetTester tester, String key, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.ensureVisible(_key(key));
    await tester.tap(_key(key));
    await tester.pumpAndSettle();
  }
}

Future<LifePhase> _seed(DateTime start,
        {PhasePreset? preset = PhasePreset.buildUp,
        String name = '',
        DateTime? plannedEnd}) =>
    CompassService.startPhase(
        preset: preset,
        name: name,
        start: start,
        plannedEnd: plannedEnd,
        today: compassToday);

LifePhase get _onlyPhase => CompassService.data.phases.single;

String _text(Finder finder) => (finder.evaluate().single.widget as Text).data!;

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() => initCompassTest());

  testWidgets('without phases the empty header invites to set one',
      (tester) async {
    await _pumpCompass(tester);
    expect(_key('compass_phase_empty'), findsOneWidget);
    expect(find.text('No phase yet'), findsOneWidget);
    expect(_key('compass_phase_header'), findsNothing);
    expect(find.text('Compass'), findsOneWidget);
  });

  testWidgets('a preset and "4 y 2 mo" set the phase and fill the header',
      (tester) async {
    await _pumpCompass(tester);
    await _tap(tester, 'compass_phase_set');
    expect(find.text('COMPASS · FIRST TIME'), findsOneWidget);
    expect(tester.widget<FilledButton>(_key('phase_apply')).onPressed, isNull);

    await _tap(tester, 'phase_preset_buildUp');
    await _tap(tester, 'phase_years_more', times: 4);
    await _tap(tester, 'phase_months_more', times: 2);
    expect(_text(_key('phase_preview_share')), '5% of your lifespan');
    await _tap(tester, 'phase_apply');

    expect(_onlyPhase.preset, PhasePreset.buildUp);
    expect(_onlyPhase.start, DateTime(2022, 9, 2));
    expect(_text(_key('compass_phase_name')), 'Building up');
    expect(_text(_key('compass_phase_subtitle')),
        'For 4\u00A0years and 2\u00A0months · 5% of your lifespan');
    expect(find.text('YOUR LIFE PHASE'), findsOneWidget);
    expect(_key('compass_phase_ribbon'), findsOneWidget);
  });

  testWidgets('"Start a new phase today" saves an own name from today',
      (tester) async {
    await _pumpCompass(tester);
    await _tap(tester, 'compass_phase_set');
    await _tap(tester, 'phase_years_more', times: 3);
    await tester.enterText(_key('phase_custom_name'), 'Sabbatical');
    await tester.pumpAndSettle();
    await _tap(tester, 'phase_start_today');

    expect(_onlyPhase.name, 'Sabbatical');
    expect(_onlyPhase.preset, isNull);
    expect(_onlyPhase.start, compassToday);
    expect(_text(_key('compass_phase_subtitle')), 'Just begun');
  });

  testWidgets('editing changes the name and keeps the start until stepped',
      (tester) async {
    await _seed(DateTime(2020, 1, 2));
    await _pumpCompass(tester);
    await _tap(tester, 'compass_phase_edit');
    expect(find.text('YOUR LIFE PHASE'), findsOneWidget);
    expect(_key('phase_start_today'), findsNothing);

    await _tap(tester, 'phase_preset_family');
    await _tap(tester, 'phase_apply');
    expect(_onlyPhase.preset, PhasePreset.family);
    expect(_onlyPhase.start, DateTime(2020, 1, 2));
    expect(_text(_key('compass_phase_name')), 'Starting a family');

    await _tap(tester, 'compass_phase_edit');
    await tester.enterText(_key('phase_custom_name'), 'Our house');
    await _tap(tester, 'phase_years_less');
    await _tap(tester, 'phase_apply');
    expect(_onlyPhase.preset, isNull);
    expect(_onlyPhase.name, 'Our house');
    expect(_onlyPhase.start, DateTime(2021, 1, 2));
  });

  testWidgets('without a birth date no percentages, but a hint',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('birth_date');
    expect(SettingsService.getBirthDate(), isNull);
    await _seed(DateTime(2022, 9, 2));
    await _pumpCompass(tester);

    expect(_text(_key('compass_phase_subtitle')),
        'For 4\u00A0years and 2\u00A0months');
    expect(_key('compass_phase_no_birth_date'), findsOneWidget);
    expect(_key('compass_phase_ribbon'), findsNothing);
    expect(find.textContaining('%'), findsNothing);

    await _tap(tester, 'compass_phase_edit');
    expect(_key('phase_preview_share'), findsNothing);
    expect(find.textContaining('With your birth date'), findsOneWidget);
  });

  group('planned end', () {
    testWidgets('shows the planned months left', (tester) async {
      await _seed(DateTime(2025, 1, 1), plannedEnd: DateTime(2028, 1, 2));
      await _pumpCompass(tester);
      expect(_text(_key('compass_phase_planned')),
          'Planned: about 14\u00A0more months');
      expect(_key('compass_phase_overdue'), findsNothing);
    });

    testWidgets('once passed, asks to extend or close', (tester) async {
      await _seed(DateTime(2025, 1, 1), plannedEnd: DateTime(2026, 10, 1));
      await _pumpCompass(tester);
      expect(find.text('Your planned time is up.'), findsOneWidget);

      await _tap(tester, 'compass_phase_extend');
      await _tap(tester, 'duration_choice_12');
      await _tap(tester, 'duration_apply');
      expect(_onlyPhase.plannedEnd, DateTime(2027, 11, 2));
      expect(_key('compass_phase_overdue'), findsNothing);
      expect(_text(_key('compass_phase_planned')),
          'Planned: about 12\u00A0more months');
    });

    testWidgets('"Close" starts the close flow', (tester) async {
      await _seed(DateTime(2025, 1, 1), plannedEnd: DateTime(2026, 10, 1));
      await _pumpCompass(tester);
      await _tap(tester, 'compass_phase_close');
      expect(_key('phase_close_note'), findsOneWidget);
    });

    testWidgets('"Leave it open" removes the plan', (tester) async {
      await _seed(DateTime(2025, 1, 1), plannedEnd: DateTime(2026, 10, 1));
      await _pumpCompass(tester);
      await _tap(tester, 'compass_phase_extend');
      await _tap(tester, 'duration_choice_open');
      await _tap(tester, 'duration_apply');
      expect(_onlyPhase.plannedEnd, isNull);
      expect(_key('compass_phase_planned'), findsNothing);
    });
  });

  testWidgets('a start day taken by another phase shows a message',
      (tester) async {
    await _seed(DateTime(2022, 9, 2));
    final draft = PhaseDraft(
        today: compassToday, birthDate: compassBirthDate, lifeExpectancyYears: 80);
    await pumpCompassApp(tester, PhaseEditScreen(draft: draft));
    await _tap(tester, 'phase_preset_study');
    await _tap(tester, 'phase_years_more', times: 4);
    await _tap(tester, 'phase_months_more', times: 2);
    await _tap(tester, 'phase_apply');
    expect(find.text('Another phase already starts on that day.'),
        findsOneWidget);
    expect(CompassService.data.phases, hasLength(1));
  });

  testWidgets('the stepper stops at the age', (tester) async {
    await _pumpCompass(tester);
    await _tap(tester, 'compass_phase_set');
    await _tap(tester, 'phase_years_more', times: 35);
    expect(tester.widget<IconButton>(_key('phase_years_more')).onPressed,
        isNull);
  });

  group('fits a Pixel 5 (393 x 851)', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('in $lang without overflow', (tester) async {
        await initCompassTest(lang: lang);
        await _pumpCompass(tester, size: const Size(393, 851));
        await _tap(tester, 'compass_phase_set');
        await _tap(tester, 'phase_preset_family');
        await _tap(tester, 'phase_years_more', times: 12);
        await _tap(tester, 'phase_apply');

        await CompassService.startPhase(
          name: 'Mit meiner Großmutter die Familiengeschichte aufschreiben',
          start: DateTime(2025, 1, 1),
          plannedEnd: DateTime(2026, 10, 1),
          today: compassToday,
        );
        await tester.pumpAndSettle();
        expect(_key('compass_phase_overdue'), findsOneWidget);
        await _tap(tester, 'compass_phase_edit');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
