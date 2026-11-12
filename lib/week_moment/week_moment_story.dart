/// Pure numbers behind the weekly moment: the year of life, the current
/// phase and the whole life, all as cell indices of the weeks grid (52
/// cells per row from birth) so their colours match the life grid. The
/// texts are built from these numbers by the UI.
library;

import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/time_window.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/onboarding/year_of_life.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';

/// The story the weekly moment tells: this year, this phase, this life.
class WeekMomentStory {
  const WeekMomentStory({
    required this.passedWeeks,
    required this.nowCell,
    required this.worldCells,
    required this.year,
    required this.phase,
    required this.life,
  });

  /// The story on [today]; [rhythm] decides how many weeks just passed and
  /// [showPhases] whether the life act shows phases.
  factory WeekMomentStory.of({
    required DateTime birthDate,
    required int lifeExpectancyYears,
    required DateTime today,
    required List<LifePhase> phases,
    required ReminderRhythm rhythm,
    required bool showPhases,
  }) {
    final calc = LifeCalculator(
      birthDate: birthDate,
      lifeExpectancyYears: lifeExpectancyYears,
      now: today,
    );
    final passed = passedWeeksFor(rhythm);
    final world = worldCellsOf(calc);
    final runs = _allRuns(calc, phases, today, world);
    return WeekMomentStory(
      passedWeeks: passed,
      nowCell: calc.weeksLived,
      worldCells: world,
      year: YearMoment.of(calc, passedWeeks: passed),
      phase: PhaseMoment.of(calc, phases: phases, runs: runs),
      life: LifeMoment.of(calc, runs: showPhases ? runs : const []),
    );
  }

  /// Weeks since the last reminder: 4 for [ReminderRhythm.every4Weeks],
  /// else 1 (also when reminders are off, e.g. a replay).
  static int passedWeeksFor(ReminderRhythm rhythm) =>
      rhythm == ReminderRhythm.every4Weeks ? 4 : 1;

  /// Cells of the grid: the whole lifespan, or up to the current week
  /// when it lies beyond the life expectancy.
  static int worldCellsOf(LifeCalculator calc) {
    final throughNow = calc.weeksLived + 1;
    return calc.totalWeeks > throughNow ? calc.totalWeeks : throughNow;
  }

  /// Weeks that just passed (1, or 4 for the 4-week rhythm).
  final int passedWeeks;

  /// Index of the current week in the grid (= weeks lived).
  final int nowCell;

  /// Number of cells in the grid (at least [nowCell] + 1).
  final int worldCells;

  final YearMoment year;

  /// The current phase, or null without one.
  final PhaseMoment? phase;

  final LifeMoment life;
}

/// The current year of life (birthday to birthday) in grid cells.
class YearMoment {
  const YearMoment({
    required this.yearNumber,
    required this.yearStart,
    required this.length,
    required this.filled,
    required this.passedFrom,
    required this.passedTo,
    required this.weeksUntilBirthday,
    required this.daysUntilBirthday,
    required this.justBegan,
  });

  /// The year of life around [calc]'s today; the passed range covers at
  /// most [passedWeeks] cells before the current one, never before the
  /// last birthday's cell.
  factory YearMoment.of(LifeCalculator calc, {required int passedWeeks}) {
    final year = YearOfLife(birthDate: calc.birthDate, today: calc.today);
    final start = _cellOf(calc, year.lastBirthday);
    final now = calc.weeksLived;
    final passedFrom = now - passedWeeks;
    return YearMoment(
      yearNumber: year.yearNumber,
      yearStart: start,
      length: _cellOf(calc, year.nextBirthday) - start,
      filled: now - start,
      passedFrom: passedFrom < start ? start : passedFrom,
      passedTo: now,
      weeksUntilBirthday: year.weeksUntilNextBirthday,
      daysUntilBirthday: year.daysUntilNextBirthday,
      justBegan: year.completedWeeks == 0,
    );
  }

  /// 1-based number of the year of life (37 for someone who is 36).
  final int yearNumber;

  /// Grid cell holding the last birthday.
  final int yearStart;

  /// Cells from [yearStart] up to (excluding) the next birthday's cell:
  /// 52 or 53.
  final int length;

  /// Cells of this year before the current one (0..[length] - 1).
  final int filled;

  /// First just-passed cell (inclusive).
  final int passedFrom;

  /// End of the just-passed cells (exclusive) = the current cell.
  final int passedTo;

  final int weeksUntilBirthday;
  final int daysUntilBirthday;

  /// The birthday lies within the last 7 days.
  final bool justBegan;

  /// End (exclusive) of the year: the next birthday's cell.
  int get yearEnd => yearStart + length;

  /// Number of just-passed cells (0 right after a birthday).
  int get passedCount => passedTo - passedFrom;

  /// Grid cell of the current week.
  int get nowCell => yearStart + filled;
}

/// The current life phase in grid cells.
class PhaseMoment {
  const PhaseMoment({
    required this.phase,
    required this.weekInPhase,
    required this.plannedLeft,
    required this.overdue,
    required this.from,
    required this.to,
    required this.runs,
  });

  /// The phase current on [calc]'s today, or null without one. [runs] are
  /// all phase runs of the grid; only the current and planned ones are
  /// kept.
  static PhaseMoment? of(
    LifeCalculator calc, {
    required List<LifePhase> phases,
    required List<PhaseCellRun> runs,
  }) {
    final span = currentSpan(phases, calc.today);
    if (span == null) return null;
    final own = _currentRuns(runs);
    final weeks = _weeksOf(span, calc.today);
    final overdue = isOverdue(span, calc.today);
    return PhaseMoment(
      phase: span.phase,
      weekInPhase: weeks.lived + 1,
      plannedLeft: overdue || weeks.left <= 0 ? null : weeks.left,
      overdue: overdue,
      from: own.isEmpty ? calc.weeksLived : own.first.from,
      to: _phaseEnd(calc.weeksLived, own),
      runs: own,
    );
  }

  final LifePhase phase;

  /// 1-based week of the phase (1 in the week it started).
  final int weekInPhase;

  /// Full weeks planned until its end; null when open-ended, overdue or
  /// ending within a week.
  final int? plannedLeft;

  /// The planned end has been reached.
  final bool overdue;

  /// First grid cell of the phase (inclusive).
  final int from;

  /// End (exclusive): past the current cell, or the planned end's cell.
  final int to;

  /// The current and planned runs, as drawn in the life grid.
  final List<PhaseCellRun> runs;

  /// No planned weeks to speak of: "it has room as long as it needs".
  bool get isOpen => plannedLeft == null;

  static PhaseWeeks _weeksOf(PhaseSpan span, DateTime today) =>
      phaseWeeks(span, today) ??
      PhaseWeeks(
        lived: LifeCalculator(birthDate: span.start, now: today).weeksLived,
        left: 0,
      );

  static List<PhaseCellRun> _currentRuns(List<PhaseCellRun> runs) => [
    for (final run in runs)
      if (run.kind != PhaseSlotKind.earlier) run,
  ];

  static int _phaseEnd(int nowCell, List<PhaseCellRun> own) {
    final throughNow = nowCell + 1;
    if (own.isEmpty || own.last.to < throughNow) return throughNow;
    return own.last.to;
  }
}

/// The whole life in grid cells.
class LifeMoment {
  const LifeMoment({
    required this.totalWeeks,
    required this.weeksLived,
    required this.weeksRemaining,
    required this.beyond,
    required this.runs,
  });

  /// The life of [calc]; [runs] are the phases to show (empty when the
  /// phases are hidden).
  factory LifeMoment.of(
    LifeCalculator calc, {
    required List<PhaseCellRun> runs,
  }) => LifeMoment(
    totalWeeks: calc.totalWeeks,
    weeksLived: calc.weeksLived,
    weeksRemaining: calc.weeksRemaining,
    beyond: calc.weeksLived >= calc.totalWeeks,
    runs: runs,
  );

  final int totalWeeks;
  final int weeksLived;
  final int weeksRemaining;

  /// Lived past the life expectancy: every week from here is a gift.
  final bool beyond;

  /// Phase runs of the whole grid; empty when phases are hidden.
  final List<PhaseCellRun> runs;
}

/// Grid cell (weeks) holding [date].
int _cellOf(LifeCalculator calc, DateTime date) =>
    LifeCalculator(birthDate: calc.birthDate, now: date).weeksLived;

/// Phase runs of all [phases] in a weeks grid of [worldCells] cells.
List<PhaseCellRun> _allRuns(
  LifeCalculator calc,
  List<LifePhase> phases,
  DateTime today,
  int worldCells,
) => phaseRuns(
  spans: resolvePhases(phases, today),
  mode: LifeMode.weeks,
  birthDate: calc.birthDate,
  totalCells: worldCells,
  livedCells: calc.weeksLived,
  lifeExpectancyYears: calc.lifeExpectancyYears,
);
