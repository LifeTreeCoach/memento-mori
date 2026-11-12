import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';

final birth = DateTime(1990, 11, 17);
final today = DateTime(2026, 11, 2);
const lifeExpectancy = 80;

LifeCalculator calcAt(DateTime date) => LifeCalculator(
  birthDate: birth,
  lifeExpectancyYears: lifeExpectancy,
  now: date,
);

/// Cell of [date] in [mode], as the app maps dates to cells.
int cellOf(LifeMode mode, DateTime date) => mode.livedCells(calcAt(date));

LifePhase phase(String id, DateTime start, {DateTime? plannedEnd}) =>
    LifePhase(id: id, start: start, plannedEnd: plannedEnd);

/// Runs of [phases] in [mode] for [birth] / [today], computed like the app.
List<PhaseCellRun> runsFor(LifeMode mode, List<LifePhase> phases) {
  final calc = calcAt(today);
  return phaseRuns(
    spans: resolvePhases(phases, today),
    mode: mode,
    birthDate: birth,
    totalCells: mode.totalCells(calc),
    livedCells: mode.livedCells(calc),
    lifeExpectancyYears: lifeExpectancy,
  );
}

void main() {
  test('no phases give no runs', () {
    for (final mode in LifeMode.values) {
      expect(runsFor(mode, const []), isEmpty);
    }
  });

  test('weeks: earlier phase ends where the current starts', () {
    const mode = LifeMode.weeks;
    final runs = runsFor(mode, [
      phase('study', DateTime(2010, 9, 1)),
      phase('work', DateTime(2020, 1, 1)),
    ]);
    final lived = mode.livedCells(calcAt(today));
    expect(runs, [
      PhaseCellRun(
        from: cellOf(mode, DateTime(2010, 9, 1)),
        to: cellOf(mode, DateTime(2020, 1, 1)),
        kind: PhaseSlotKind.earlier,
        earlierIndex: 0,
        phaseId: 'study',
      ),
      PhaseCellRun(
        from: cellOf(mode, DateTime(2020, 1, 1)),
        to: lived + 1,
        kind: PhaseSlotKind.current,
        phaseId: 'work',
      ),
    ]);
    expect(lived, 1876);
  });

  test('cells before the first phase have no run', () {
    const mode = LifeMode.weeks;
    final runs = runsFor(mode, [phase('work', DateTime(2020, 1, 1))]);
    expect(runAt(runs, 0), isNull);
    expect(runAt(runs, cellOf(mode, DateTime(2020, 1, 1)) - 1), isNull);
  });

  test('a phase starting before birth clamps to cell 0', () {
    final runs = runsFor(LifeMode.years, [phase('all', DateTime(1985, 1, 1))]);
    expect(runs.single.from, 0);
    expect(runs.single.to, 36);
  });

  test('years: two phases in the same year, the later one wins', () {
    final runs = runsFor(LifeMode.years, [
      phase('a', DateTime(2015, 1, 10)),
      phase('b', DateTime(2015, 6, 1)),
      phase('c', DateTime(2020, 3, 1)),
    ]);
    expect(runs, const [
      PhaseCellRun(
        from: 24,
        to: 29,
        kind: PhaseSlotKind.earlier,
        earlierIndex: 0,
        phaseId: 'b',
      ),
      PhaseCellRun(from: 29, to: 36, kind: PhaseSlotKind.current, phaseId: 'c'),
    ]);
  });

  test('current phase runs through the current cell', () {
    for (final mode in LifeMode.values) {
      final runs = runsFor(mode, [phase('now', DateTime(2024, 5, 5))]);
      final lived = mode.livedCells(calcAt(today));
      expect(runs.single.kind, PhaseSlotKind.current, reason: mode.id);
      expect(runs.single.to, lived + 1, reason: mode.id);
      expect(runAt(runs, lived)?.phaseId, 'now', reason: mode.id);
      expect(runAt(runs, lived + 1), isNull, reason: mode.id);
    }
  });

  test('months: planned run only with a planned end', () {
    const mode = LifeMode.months;
    expect(runsFor(mode, [phase('p', DateTime(2024, 1, 1))]), hasLength(1));
    final runs = runsFor(mode, [
      phase('p', DateTime(2024, 1, 1), plannedEnd: DateTime(2027, 6, 15)),
    ]);
    expect(runs, hasLength(2));
    expect(
      runs.last,
      const PhaseCellRun(
        from: 432,
        // Jun 15 lies past the middle of May 17 - Jun 17: that cell counts.
        to: 439,
        kind: PhaseSlotKind.planned,
        phaseId: 'p',
      ),
    );
  });

  test('planned run is clamped to the last cell', () {
    for (final mode in LifeMode.values) {
      final total = mode.totalCells(calcAt(today));
      final runs = runsFor(mode, [
        phase('p', DateTime(2024, 1, 1), plannedEnd: DateTime(2090, 1, 1)),
      ]);
      expect(runs.last.kind, PhaseSlotKind.planned, reason: mode.id);
      expect(runs.last.to, total, reason: mode.id);
    }
  });

  test('a planned end in the current cell adds no planned run', () {
    for (final end in [DateTime(2026, 11, 10), DateTime(2026, 2, 1)]) {
      final runs = runsFor(LifeMode.years, [
        phase('p', DateTime(2024, 1, 1), plannedEnd: end),
      ]);
      expect(runs.single.kind, PhaseSlotKind.current, reason: '$end');
    }
  });

  group('the cell holding the planned end', () {
    // Years view: cell 36 runs 2026-11-17 .. 2027-11-17, cell 35 is now.
    PhaseCellRun plannedFor(LifeMode mode, DateTime end) => runsFor(mode, [
          phase('p', DateTime(2024, 1, 1), plannedEnd: end),
        ]).last;

    test('years: counts once the end lies past its middle', () {
      final late = plannedFor(LifeMode.years, DateTime(2027, 9, 1));
      expect(late.kind, PhaseSlotKind.planned);
      expect(late.to, 37);
    });

    test('years: is left out when the end lies before its middle', () {
      final runs = runsFor(LifeMode.years, [
        phase('p', DateTime(2024, 1, 1), plannedEnd: DateTime(2027, 2, 1)),
      ]);
      expect(runs.single.kind, PhaseSlotKind.current);
      final early = plannedFor(LifeMode.years, DateTime(2028, 2, 1));
      expect(early.to, 37);
    });

    test('weeks: only a few days decide, the run stays nearly the same', () {
      // 2027-06-15 is a Tuesday; week cells start on the birth weekday.
      final end = DateTime(2027, 6, 15);
      final run = plannedFor(LifeMode.weeks, end);
      expect(run.to - cellOf(LifeMode.weeks, end), inInclusiveRange(0, 1));
    });
  });

  test('earlierIndex counts the earlier phases, -1 for the current', () {
    final runs = runsFor(LifeMode.months, [
      phase('a', DateTime(1996, 9, 1)),
      phase('b', DateTime(2001, 9, 1)),
      phase('c', DateTime(2009, 10, 1)),
      phase('d', DateTime(2015, 2, 1)),
      phase('e', DateTime(2022, 4, 1)),
    ]);
    expect(runs.map((r) => r.earlierIndex), [0, 1, 2, 3, -1]);
    for (var i = 0; i + 1 < runs.length; i++) {
      expect(runs[i].to, runs[i + 1].from);
    }
  });

  test('runAt finds the run covering a cell', () {
    final runs = runsFor(LifeMode.years, [
      phase('a', DateTime(2000, 1, 1)),
      phase('b', DateTime(2010, 1, 1), plannedEnd: DateTime(2030, 1, 1)),
    ]);
    expect(runAt(runs, 8), isNull);
    expect(runAt(runs, 9)?.phaseId, 'a');
    expect(runAt(runs, 19)?.kind, PhaseSlotKind.current);
    expect(runAt(runs, 36)?.kind, PhaseSlotKind.planned);
    expect(runAt(runs, 39), isNull);
  });

  test('runFractions map cells to shares of the lifespan', () {
    const mode = LifeMode.weeks;
    final total = mode.totalCells(calcAt(today));
    final runs = runsFor(mode, [
      phase('a', DateTime(2000, 1, 1)),
      phase('b', DateTime(2018, 1, 1), plannedEnd: DateTime(2080, 1, 1)),
    ]);
    final fractions = runFractions(runs, total);
    expect(fractions, hasLength(runs.length));
    expect(fractions.first.from, runs.first.from / total);
    expect(fractions.last.to, 1.0);
    expect(fractions.first.earlierIndex, 0);
    final sum = fractions.fold<double>(0, (s, f) => s + (f.to - f.from));
    expect(sum, lessThanOrEqualTo(1.0));
    expect(runFractions(runs, 0), isEmpty);
  });
}
