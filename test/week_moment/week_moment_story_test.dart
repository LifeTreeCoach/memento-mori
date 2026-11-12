import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';

WeekMomentStory story({
  required DateTime birth,
  required DateTime today,
  int lifeExpectancyYears = 80,
  List<LifePhase> phases = const [],
  ReminderRhythm rhythm = ReminderRhythm.weekly,
  bool showPhases = true,
}) => WeekMomentStory.of(
  birthDate: birth,
  lifeExpectancyYears: lifeExpectancyYears,
  today: today,
  phases: phases,
  rhythm: rhythm,
  showPhases: showPhases,
);

int weeksBetween(DateTime from, DateTime to) =>
    LifeCalculator(birthDate: from, now: to).weeksLived;

void main() {
  final julyBirth = DateTime(1990, 7, 10);

  group('passed weeks', () {
    test('rhythm decides how many weeks passed', () {
      expect(WeekMomentStory.passedWeeksFor(ReminderRhythm.weekly), 1);
      expect(WeekMomentStory.passedWeeksFor(ReminderRhythm.every4Weeks), 4);
      expect(WeekMomentStory.passedWeeksFor(ReminderRhythm.off), 1);
    });

    test('weekly marks one week, every 4 weeks four', () {
      final today = DateTime(2026, 1, 15);
      final weekly = story(birth: julyBirth, today: today);
      final monthly = story(
        birth: julyBirth,
        today: today,
        rhythm: ReminderRhythm.every4Weeks,
      );
      expect(weekly.year.passedTo, weekly.nowCell);
      expect(weekly.year.passedFrom, weekly.nowCell - 1);
      expect(monthly.year.passedFrom, monthly.nowCell - 4);
      expect(monthly.year.passedCount, 4);
    });

    test('a recent birthday cuts the passed weeks', () {
      final s = story(
        birth: julyBirth,
        today: DateTime(2025, 7, 25),
        rhythm: ReminderRhythm.every4Weeks,
      );
      expect(s.nowCell, 1828);
      expect(s.year.yearStart, 1826);
      expect(s.year.passedFrom, 1826);
      expect(s.year.passedTo, 1828);
      expect(s.year.justBegan, isFalse);
    });
  });

  group('year of life', () {
    test('birthday week: just began, nothing passed', () {
      final s = story(birth: julyBirth, today: DateTime(2025, 7, 10));
      expect(s.year.yearNumber, 36);
      expect(s.year.justBegan, isTrue);
      expect(s.year.filled, 0);
      expect(s.year.passedCount, 0);
      expect(s.year.daysUntilBirthday, 365);
    });

    test('days after the birthday still count as just begun', () {
      final s = story(birth: julyBirth, today: DateTime(2025, 7, 15));
      expect(s.year.justBegan, isTrue);
      expect(s.year.filled, 1);
      expect(s.year.passedFrom, 1826);
      expect(s.year.passedTo, 1827);
    });

    test('day before the birthday: 53 cells, last one current', () {
      final s = story(birth: julyBirth, today: DateTime(2029, 7, 9));
      expect(s.year.yearNumber, 39);
      expect(s.year.yearStart, 1982);
      expect(s.year.length, 53);
      expect(s.year.filled, 52);
      expect(s.nowCell, s.year.yearEnd - 1);
      expect(s.year.daysUntilBirthday, 1);
      expect(s.year.weeksUntilBirthday, 0);
    });

    test('around 40 the year no longer starts on a row', () {
      final s = story(birth: DateTime(1986, 1, 1), today: DateTime(2026, 6, 1));
      expect(s.year.yearNumber, 41);
      expect(s.year.yearStart, 2087);
      expect(s.year.yearStart % 52, isNot(0));
      expect(s.year.length, 52);
      expect(s.year.nowCell, s.nowCell);
    });
  });

  group('phase', () {
    final birth = DateTime(1986, 1, 1);
    final today = DateTime(2026, 6, 1);
    final earlier = LifePhase(id: 'old', start: DateTime(2010, 1, 1));

    PhaseMoment phaseWith(LifePhase current, {bool showPhases = true}) => story(
      birth: birth,
      today: today,
      phases: [earlier, current],
      showPhases: showPhases,
    ).phase!;

    test('with a planned end: weeks left and planned cells', () {
      final p = phaseWith(
        LifePhase(
          id: 'now',
          start: DateTime(2025, 6, 1),
          plannedEnd: DateTime(2027, 6, 1),
        ),
      );
      final nowCell = weeksBetween(birth, today);
      expect(p.phase.id, 'now');
      expect(p.weekInPhase, 53);
      expect(p.plannedLeft, 52);
      expect(p.isOpen, isFalse);
      expect(p.from, weeksBetween(birth, DateTime(2025, 6, 1)));
      expect(p.to, greaterThan(nowCell + 1));
      expect(p.runs.map((r) => r.kind), [
        PhaseSlotKind.current,
        PhaseSlotKind.planned,
      ]);
      expect(p.runs.last.to, p.to);
    });

    test('open-ended: room as long as it needs', () {
      final p = phaseWith(LifePhase(id: 'now', start: DateTime(2025, 6, 1)));
      expect(p.plannedLeft, isNull);
      expect(p.isOpen, isTrue);
      expect(p.overdue, isFalse);
      expect(p.to, weeksBetween(birth, today) + 1);
      expect(p.runs.single.kind, PhaseSlotKind.current);
    });

    test('overdue counts as open', () {
      final p = phaseWith(
        LifePhase(
          id: 'now',
          start: DateTime(2025, 6, 1),
          plannedEnd: DateTime(2026, 5, 1),
        ),
      );
      expect(p.overdue, isTrue);
      expect(p.isOpen, isTrue);
      expect(p.to, weeksBetween(birth, today) + 1);
    });

    test('started this week', () {
      final p = phaseWith(LifePhase(id: 'now', start: today));
      expect(p.weekInPhase, 1);
      expect(p.from, weeksBetween(birth, today));
      expect(p.to, p.from + 1);
    });

    test('no phase, or only a future one', () {
      expect(story(birth: birth, today: today).phase, isNull);
      final future = LifePhase(id: 'f', start: DateTime(2027, 1, 1));
      expect(story(birth: birth, today: today, phases: [future]).phase, isNull);
    });

    test('showPhases off hides the life runs, keeps the phase', () {
      final current = LifePhase(id: 'now', start: DateTime(2025, 6, 1));
      final shown = story(
        birth: birth,
        today: today,
        phases: [earlier, current],
      );
      final hidden = story(
        birth: birth,
        today: today,
        phases: [earlier, current],
        showPhases: false,
      );
      expect(shown.life.runs.map((r) => r.phaseId), ['old', 'now']);
      expect(hidden.life.runs, isEmpty);
      expect(hidden.phase!.runs, isNotEmpty);
    });
  });

  group('life', () {
    test('within the life expectancy', () {
      final s = story(birth: DateTime(1986, 1, 1), today: DateTime(2026, 6, 1));
      expect(s.life.totalWeeks, 4160);
      expect(s.life.weeksLived, s.nowCell);
      expect(s.life.weeksRemaining, 4160 - s.nowCell);
      expect(s.life.beyond, isFalse);
      expect(s.worldCells, 4160);
    });

    test('beyond the life expectancy the grid grows to now', () {
      final s = story(
        birth: DateTime(1940, 1, 1),
        today: DateTime(2026, 6, 1),
        phases: [LifePhase(id: 'late', start: DateTime(2020, 1, 1))],
      );
      expect(s.life.beyond, isTrue);
      expect(s.life.weeksRemaining, 0);
      expect(s.worldCells, s.nowCell + 1);
      expect(s.phase!.to, s.nowCell + 1);
      expect(s.phase!.runs.single.to, s.nowCell + 1);
    });
  });
}
