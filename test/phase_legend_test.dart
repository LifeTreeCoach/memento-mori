import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/phase_legend.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

final _birth = DateTime(1990, 11, 17);
final _today = DateTime(2026, 11, 2);

/// The design reference: five phases, the current one with a planned end.
final List<LifePhase> _phases = [
  LifePhase(id: 'a', preset: PhasePreset.childhood, start: _birth),
  LifePhase(id: 'b', preset: PhasePreset.school, start: DateTime(1996, 11, 17)),
  LifePhase(id: 'c', preset: PhasePreset.study, start: DateTime(2009, 11, 17)),
  LifePhase(
      id: 'd', preset: PhasePreset.careerStart, start: DateTime(2015, 11, 17)),
  LifePhase(
    id: 'e',
    preset: PhasePreset.buildUp,
    start: DateTime(2022, 11, 17),
    plannedEnd: DateTime(2028, 6, 1),
  ),
];

List<PhaseLegendEntry> _entries(
  String lang, {
  List<LifePhase>? phases,
  LifeMode mode = LifeMode.months,
}) {
  final spans = resolvePhases(phases ?? _phases, _today);
  final calc = LifeCalculator(birthDate: _birth, now: _today);
  final runs = phaseRuns(
    spans: spans,
    mode: mode,
    birthDate: _birth,
    totalCells: mode.totalCells(calc),
    livedCells: mode.livedCells(calc),
    lifeExpectancyYears: calc.lifeExpectancyYears,
  );
  return phaseLegendEntries(
    spans: spans,
    runs: runs,
    birthDate: _birth,
    l10n: AppLocalizations(Locale(lang)),
  );
}

void main() {
  group('phaseLegendEntries', () {
    test('German: whole-year ages, current until today, then planned', () {
      expect(_entries('de').map((e) => e.label), [
        'Kindheit 0–6',
        'Schule 6–19',
        'Studium 19–25',
        'Berufsstart 25–32',
        'Aufbauphase 32–heute',
        'geplant',
      ]);
    });

    test('English labels', () {
      final labels = _entries('en').map((e) => e.label).toList();
      expect(labels.first, 'Childhood 0–6');
      expect(labels[4], 'Building up 32–now');
      expect(labels.last, 'planned');
    });

    test('kinds and colour indices follow the runs', () {
      final entries = _entries('en');
      expect(entries.map((e) => e.kind), [
        ...List.filled(4, PhaseSlotKind.earlier),
        PhaseSlotKind.current,
        PhaseSlotKind.planned,
      ]);
      expect(entries.take(4).map((e) => e.earlierIndex), [0, 1, 2, 3]);
      expect(entries[4].isCurrent, isTrue);
      expect(entries.last.phaseId, isNull);
    });

    test('no planned entry without a planned end', () {
      final open = [
        LifePhase(id: 'x', name: 'Own way', start: DateTime(2020, 1, 1)),
      ];
      expect(_entries('de', phases: open).map((e) => e.label),
          ['Own way 29–heute']);
    });

    test('a phase without a cell in the mode is kept, marked', () {
      // Starts and ends inside the same year: no run in years mode.
      final phases = [
        LifePhase(id: 'a', name: 'Short', start: DateTime(2020, 12, 1)),
        LifePhase(id: 'b', name: 'Now', start: DateTime(2021, 2, 1)),
      ];
      final entries = _entries('en', phases: phases, mode: LifeMode.years);
      expect(entries.map((e) => e.label), ['Short 30–30', 'Now 30–now']);
      expect(entries.first.inGrid, isFalse);
      expect(entries.last.inGrid, isTrue);
    });
  });

  group('PhaseLegend swatches', () {
    final colors = PhaseColors.stoicLight;
    final remaining = LifePalette.stoicLight.remaining;

    test('planned looks like a planned cell: the pale tint, no ring', () {
      const entry = PhaseLegendEntry(label: 'planned', kind: PhaseSlotKind.planned);
      expect(
        PhaseLegend.swatchOf(entry, colors),
        PhaseSwatch(fill: colors.plannedTint),
      );
      expect(colors.plannedTint, isNot(remaining));
    });

    test('phases in the grid are filled, others only outlined', () {
      const current = PhaseLegendEntry(label: 'c', kind: PhaseSlotKind.current);
      const missing = PhaseLegendEntry(
          label: 'x', kind: PhaseSlotKind.earlier, inGrid: false);
      expect(PhaseLegend.swatchOf(current, colors),
          PhaseSwatch(fill: colors.current));
      expect(PhaseLegend.swatchOf(missing, colors),
          PhaseSwatch(border: colors.earlierAt(0), borderWidth: 1.5));
    });
  });

  group('PhaseLegend fits a phone width', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('$lang at 393 wide wraps without overflow', (tester) async {
        tester.view.physicalSize = const Size(393 * 3, 852 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          locale: Locale(lang),
          supportedLocales: [
            for (final code in AppLocalizations.supportedLanguages) Locale(code),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PhaseLegend(entries: _entries(lang)),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final legend = tester.getRect(find.byType(PhaseLegend));
        expect(legend.right, lessThanOrEqualTo(393 - 24));
        expect(find.byType(Text), findsNWidgets(6));
      });
    }
  });
}
