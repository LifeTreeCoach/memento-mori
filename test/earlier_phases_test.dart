import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/earlier_phases.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/earlier_phases_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/compass_test_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, String key, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.ensureVisible(_key(key));
    await tester.tap(_key(key));
    await tester.pumpAndSettle();
  }
}

/// The current phase: "Building up" since 2 Sep 2022 (age 31).
Future<LifePhase> _seedCurrent() => CompassService.startPhase(
    preset: PhasePreset.buildUp, start: DateTime(2022, 9, 2), today: compassToday);

Future<void> _pumpScreen(WidgetTester tester,
        {DateTime? birthDate, Size size = const Size(393, 4000)}) =>
    pumpCompassApp(
      tester,
      EarlierPhasesScreen(today: compassToday, birthDate: birthDate),
      size: size,
    );

/// Adds [preset] at [age] through the form.
Future<void> _addAtAge(WidgetTester tester, PhasePreset preset, int age) async {
  await _tap(tester, 'earlier_add');
  await _tap(tester, 'phase_preset_${preset.name}');
  if (age > 0) await _tap(tester, 'earlier_start_more', times: age);
  await _tap(tester, 'earlier_save');
}

List<PhasePreset?> get _resolvedPresets => [
      for (final span in resolvePhases(CompassService.data.phases, compassToday))
        span.phase.preset,
    ];

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() => initCompassTest());

  group('pure logic', () {
    test('startAtAge lands on the birthday (29 Feb on 28 Feb)', () {
      expect(startAtAge(DateTime(1990, 11, 17), 6), DateTime(1996, 11, 17));
      expect(startAtAge(DateTime(2000, 2, 29), 1), DateTime(2001, 2, 28));
    });

    test('earlier phases must begin before the current one', () {
      final current = LifePhase(id: 'c', start: DateTime(2022, 9, 2));
      PhaseStartError? check(DateTime start, {String? ignoreId}) =>
          validateEarlierStart(start,
              birthDate: compassBirthDate,
              today: compassToday,
              phases: [current],
              ignoreId: ignoreId);
      expect(check(DateTime(2000)), isNull);
      expect(check(DateTime(2022, 9, 2)), PhaseStartError.duplicateDay);
      expect(check(DateTime(2023)), PhaseStartError.notBeforeCurrent);
      expect(check(DateTime(1980)), PhaseStartError.beforeBirth);
    });

    test('earlierSpans leaves out the current phase', () {
      final phases = [
        LifePhase(id: 'a', start: DateTime(2000)),
        LifePhase(id: 'b', start: DateTime(2010)),
      ];
      expect(earlierSpans(phases, compassToday).map((s) => s.phase.id), ['a']);
      expect(earlierSpans(const [], compassToday), isEmpty);
    });
  });

  testWidgets('childhood at 0 and school at 6 come before the current phase',
      (tester) async {
    await _seedCurrent();
    await _pumpScreen(tester, birthDate: compassBirthDate);
    expect(find.text('No earlier phases yet.'), findsOneWidget);
    expect(find.text('A phase lasts until the next one begins.'), findsOneWidget);

    await _addAtAge(tester, PhasePreset.childhood, 0);
    await _addAtAge(tester, PhasePreset.school, 6);

    expect(_resolvedPresets,
        [PhasePreset.childhood, PhasePreset.school, PhasePreset.buildUp]);
    final starts = resolvePhases(CompassService.data.phases, compassToday)
        .map((s) => s.start);
    expect(starts.take(2), [compassBirthDate, DateTime(1996, 11, 17)]);
    expect(find.text('0–6 years'), findsOneWidget);
    expect(find.text('6–31 years'), findsOneWidget);
  });

  testWidgets('a taken day and a start after the current phase are refused',
      (tester) async {
    await _seedCurrent();
    await CompassService.startPhase(
        preset: PhasePreset.childhood, start: compassBirthDate, today: compassToday);
    await _pumpScreen(tester, birthDate: compassBirthDate);
    await _addAtAge(tester, PhasePreset.school, 0);
    expect(find.text('Another phase already starts on that day.'),
        findsOneWidget);
    await _tap(tester, 'earlier_start_more', times: 32);
    await _tap(tester, 'earlier_save');
    expect(find.text('An earlier phase begins before your current one.'),
        findsOneWidget);
    expect(CompassService.data.phases, hasLength(2));
  });

  testWidgets('without a birth date the start is a year', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('birth_date');
    await _seedCurrent();
    await _pumpScreen(tester);
    await _tap(tester, 'earlier_add');
    expect(find.text('From 2016'), findsOneWidget);
    await _tap(tester, 'phase_preset_study');
    await _tap(tester, 'earlier_save');
    final study = CompassService.data.phases
        .firstWhere((p) => p.preset == PhasePreset.study);
    expect(study.start, DateTime(2016));
    expect(find.text('2016–2022'), findsOneWidget);
  });

  testWidgets('editing keeps the start until stepped; notes show in italics',
      (tester) async {
    await _seedCurrent();
    final school = await CompassService.startPhase(
        preset: PhasePreset.school, start: DateTime(1997, 8, 1), today: compassToday);
    await CompassService.editPhase(school.copyWith(note: 'Best friends forever'));
    await _pumpScreen(tester, birthDate: compassBirthDate);
    expect(find.textContaining('Best friends forever'), findsOneWidget);

    await _tap(tester, 'earlier_phase_${school.id}');
    await _tap(tester, 'phase_preset_study');
    await _tap(tester, 'earlier_save');
    final edited = CompassService.data.phases.firstWhere((p) => p.id == school.id);
    expect(edited.preset, PhasePreset.study);
    expect(edited.start, DateTime(1997, 8, 1));
    expect(edited.note, 'Best friends forever');
  });

  testWidgets('delete asks first, then removes the phase', (tester) async {
    await _seedCurrent();
    final school = await CompassService.startPhase(
        preset: PhasePreset.school, start: DateTime(1997, 8, 1), today: compassToday);
    await _pumpScreen(tester, birthDate: compassBirthDate);
    await _tap(tester, 'earlier_delete_${school.id}');
    expect(find.text('Delete this phase?'), findsOneWidget);
    await _tap(tester, 'earlier_delete_confirm');
    expect(CompassService.data.phases.map((p) => p.id),
        isNot(contains(school.id)));
    expect(find.text('No earlier phases yet.'), findsOneWidget);
  });

  group('fits a Pixel 5 (393 x 851)', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('in $lang without overflow', (tester) async {
        await initCompassTest(lang: lang);
        await _seedCurrent();
        final school = await CompassService.startPhase(
            name: 'Mit meiner Großmutter die Familiengeschichte aufschreiben',
            start: DateTime(1997, 8, 1),
            today: compassToday);
        await CompassService.editPhase(
            school.copyWith(note: 'A long and very warm note about friends'));
        await _pumpScreen(tester,
            birthDate: compassBirthDate, size: const Size(393, 851));
        expect(tester.takeException(), isNull);
        await _tap(tester, 'earlier_add');
        await _tap(tester, 'phase_preset_childhood');
        await _tap(tester, 'earlier_start_more', times: 32);
        await _tap(tester, 'earlier_save');
        expect(tester.takeException(), isNull);
        expect(_key('earlier_error'), findsOneWidget);
      });
    }
  });
}
