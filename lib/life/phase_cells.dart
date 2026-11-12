/// Pure mapping of life phases onto the cells of the life grid: which
/// cells each phase covers in a [LifeMode], and the same runs as fractions
/// of the whole lifespan for the alternative layouts.
library;

import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';

/// How a run of phase cells is drawn.
enum PhaseSlotKind {
  /// A phase that has ended.
  earlier,

  /// The current phase, up to and including the current cell.
  current,

  /// The rest of the current phase until its planned end.
  planned,
}

/// Consecutive grid cells [from] (inclusive) to [to] (exclusive) that
/// belong to the phase [phaseId].
class PhaseCellRun {
  const PhaseCellRun({
    required this.from,
    required this.to,
    required this.kind,
    this.earlierIndex = -1,
    required this.phaseId,
  });

  final int from;
  final int to;
  final PhaseSlotKind kind;

  /// Position among the earlier phases (oldest = 0), for cycling their
  /// colours; -1 for the current and planned runs.
  final int earlierIndex;

  final String phaseId;

  /// Number of cells in the run.
  int get length => to - from;

  /// Whether [cell] lies in this run.
  bool contains(int cell) => cell >= from && cell < to;

  @override
  bool operator ==(Object other) =>
      other is PhaseCellRun &&
      other.from == from &&
      other.to == to &&
      other.kind == kind &&
      other.earlierIndex == earlierIndex &&
      other.phaseId == phaseId;

  @override
  int get hashCode => Object.hash(from, to, kind, earlierIndex, phaseId);

  @override
  String toString() =>
      'PhaseCellRun($phaseId, ${kind.name} $from..$to, earlier $earlierIndex)';
}

/// The runs of [spans] (as from `resolvePhases`, oldest first) in [mode].
///
/// A phase starts at the cell of its start date (0 if before birth) and a
/// cell belongs to the last phase starting at or before it, so a phase
/// whose successor starts in the same cell has no run. Cells before the
/// first phase have none. The current phase runs through the current cell
/// ([livedCells]); a planned end adds a [PhaseSlotKind.planned] run up to
/// the cell of that day, including that cell when the day lies after its
/// middle (so most of it is planned). Everything stays in [0, totalCells).
List<PhaseCellRun> phaseRuns({
  required List<PhaseSpan> spans,
  required LifeMode mode,
  required DateTime birthDate,
  required int totalCells,
  required int livedCells,
  required int lifeExpectancyYears,
}) {
  int cellOf(DateTime date) => _clampCell(
    _cellOfDate(date, mode, birthDate, lifeExpectancyYears),
    totalCells,
  );
  int plannedEndCell(DateTime date) => _clampCell(
    _cellEndingAt(date, mode, birthDate, lifeExpectancyYears),
    totalCells,
  );
  final currentEnd = _clampCell(livedCells + 1, totalCells);
  final runs = <PhaseCellRun>[];
  var earlierCount = 0;
  for (final span in spans) {
    final from = cellOf(span.start);
    final end = span.end;
    final to = end == null ? currentEnd : cellOf(end);
    if (to <= from) continue;
    if (span.isCurrent) {
      runs.add(_run(span, from, to, PhaseSlotKind.current));
      final planned = _plannedRun(span, to, plannedEndCell);
      if (planned != null) runs.add(planned);
    } else {
      runs.add(_run(span, from, to, PhaseSlotKind.earlier, earlierCount++));
    }
  }
  return runs;
}

/// The run covering [cell], or null if no phase covers it.
PhaseCellRun? runAt(List<PhaseCellRun> runs, int cell) {
  for (final run in runs) {
    if (run.contains(cell)) return run;
  }
  return null;
}

/// [runs] as fractions (0..1) of a lifespan of [totalCells] cells, for
/// layouts that are not a grid; empty without cells.
List<({double from, double to, PhaseSlotKind kind, int earlierIndex})>
runFractions(List<PhaseCellRun> runs, int totalCells) {
  if (totalCells <= 0) return const [];
  return [
    for (final run in runs)
      (
        from: run.from / totalCells,
        to: run.to / totalCells,
        kind: run.kind,
        earlierIndex: run.earlierIndex,
      ),
  ];
}

/// Index of the cell holding [date] in [mode]; 0 for dates before birth.
int _cellOfDate(
  DateTime date,
  LifeMode mode,
  DateTime birthDate,
  int lifeExpectancyYears,
) {
  final calc = LifeCalculator(
    birthDate: birthDate,
    lifeExpectancyYears: lifeExpectancyYears,
    now: date,
  );
  return mode.livedCells(calc);
}

/// End (exclusive) of a run that lasts until [date]: the cell holding
/// [date], or the one after it once [date] lies past that cell's middle.
int _cellEndingAt(
  DateTime date,
  LifeMode mode,
  DateTime birthDate,
  int lifeExpectancyYears,
) {
  final cell = _cellOfDate(date, mode, birthDate, lifeExpectancyYears);
  final start = LifePeriod.periodStart(mode, cell, birthDate);
  final end = LifePeriod.periodStart(mode, cell + 1, birthDate);
  final day = DateTime.utc(date.year, date.month, date.day);
  final intoCell = day.difference(start).inDays;
  return intoCell * 2 > end.difference(start).inDays ? cell + 1 : cell;
}

/// [cell] limited to the cell boundaries 0..[totalCells].
int _clampCell(int cell, int totalCells) =>
    cell.clamp(0, totalCells < 0 ? 0 : totalCells);

/// The planned rest of the current [span] after [currentEnd], or null
/// without a planned end beyond it.
PhaseCellRun? _plannedRun(
  PhaseSpan span,
  int currentEnd,
  int Function(DateTime) plannedEndCell,
) {
  final plannedEnd = span.phase.plannedEnd;
  if (plannedEnd == null) return null;
  final to = plannedEndCell(plannedEnd);
  if (to <= currentEnd) return null;
  return _run(span, currentEnd, to, PhaseSlotKind.planned);
}

PhaseCellRun _run(
  PhaseSpan span,
  int from,
  int to,
  PhaseSlotKind kind, [
  int earlierIndex = -1,
]) => PhaseCellRun(
  from: from,
  to: to,
  kind: kind,
  earlierIndex: earlierIndex,
  phaseId: span.phase.id,
);
