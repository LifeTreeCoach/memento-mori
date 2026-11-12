import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';

LifePhase _phase(String id, DateTime start, {DateTime? plannedEnd}) =>
    LifePhase(id: id, start: start, plannedEnd: plannedEnd);

void main() {
  final today = DateTime(2026, 11, 6, 21, 15);
  final birth = DateTime(1990, 3, 15);

  group('resolvePhases', () {
    test('no phases: nothing current', () {
      expect(resolvePhases([], today), isEmpty);
      expect(currentSpan([], today), isNull);
    });

    test('sorted by start, each ends where the next starts, last is current', () {
      final spans = resolvePhases([
        _phase('job', DateTime(2022, 4, 1)),
        _phase('study', DateTime(2016, 10, 1)),
      ], today);
      expect(spans.map((s) => s.phase.id), ['study', 'job']);
      expect(spans.first.end, DateTime(2022, 4, 1));
      expect(spans.first.isCurrent, isFalse);
      expect(spans.last.end, isNull);
      expect(spans.last.isCurrent, isTrue);
      expect(currentSpan([_phase('a', DateTime(2020))], today)!.phase.id, 'a');
    });

    test('a phase starting today is current, future phases are ignored', () {
      final spans = resolvePhases([
        _phase('old', DateTime(2020)),
        _phase('new', DateTime(2026, 11, 6)),
        _phase('later', DateTime(2026, 11, 7)),
      ], today);
      expect(spans.map((s) => s.phase.id), ['old', 'new']);
      expect(currentSpan([_phase('later', DateTime(2027))], today), isNull);
    });
  });

  group('months and shares', () {
    test('monthsIn counts until the end, or today while current', () {
      final spans = resolvePhases([
        _phase('a', DateTime(2020, 1, 15)),
        _phase('b', DateTime(2022, 7, 14)),
      ], today);
      expect(monthsIn(spans.first, today), 29);
      expect(monthsIn(spans.last, today), 51);
      final startedToday = resolvePhases([_phase('c', today)], today).single;
      expect(monthsIn(startedToday, today), 0);
    });

    test('a phase starting on the birth date counts from birth', () {
      final span = resolvePhases([_phase('childhood', birth)], today).single;
      expect(monthsIn(span, today), 439);
    });

    test('shareOfLifespan is a fraction of the expectancy in months', () {
      expect(shareOfLifespan(96, 80), closeTo(0.1, 1e-9));
      expect(shareOfLifespan(0, 80), 0);
      expect(shareOfLifespan(2000, 80), 1);
      expect(shareOfLifespan(12, 0), isNull);
      expect(shareOfLifespan(12, -1), isNull);
    });
  });

  group('planned end', () {
    PhaseSpan current({DateTime? plannedEnd}) => resolvePhases(
        [_phase('p', DateTime(2025), plannedEnd: plannedEnd)], today).single;

    test('months and weeks left, null without a planned end', () {
      final span = current(plannedEnd: DateTime(2028, 1, 6));
      expect(plannedMonthsLeft(span, today), 14);
      expect(plannedWeeksLeft(span, today), 60, reason: '426 days');
      expect(plannedMonthsLeft(current(), today), isNull);
      expect(plannedWeeksLeft(current(), today), isNull);
    });

    test('never negative and overdue from the planned end on', () {
      final past = current(plannedEnd: DateTime(2026, 5, 1));
      expect(plannedMonthsLeft(past, today), 0);
      expect(plannedWeeksLeft(past, today), 0);
      expect(isOverdue(past, today), isTrue);
      expect(isOverdue(current(plannedEnd: DateTime(2026, 11, 6)), today), isTrue);
      expect(isOverdue(current(plannedEnd: DateTime(2026, 11, 7)), today), isFalse);
      expect(isOverdue(current(), today), isFalse);
    });

    test('an earlier phase is never overdue', () {
      final spans = resolvePhases([
        _phase('a', DateTime(2020), plannedEnd: DateTime(2021)),
        _phase('b', DateTime(2022)),
      ], today);
      expect(isOverdue(spans.first, today), isFalse);
    });
  });

  group('startFromAgo', () {
    test('goes back years and months, clamping the day to short months', () {
      expect(startFromAgo(today, 4, 2), DateTime(2022, 9, 6));
      expect(startFromAgo(today, 0, 0), DateTime(2026, 11, 6));
      expect(startFromAgo(today, 0, 11), DateTime(2025, 12, 6));
      expect(startFromAgo(DateTime(2026, 3, 31), 0, 1), DateTime(2026, 2, 28));
      expect(startFromAgo(DateTime(2025, 3, 31), 1, 1), DateTime(2024, 2, 29));
    });

    test('never before the birth date', () {
      expect(startFromAgo(today, 50, 0, birthDate: birth), birth);
      expect(startFromAgo(today, 1, 0, birthDate: birth), DateTime(2025, 11, 6));
    });
  });

  group('validateStart', () {
    final others = [_phase('a', DateTime(2020, 1, 1))];
    PhaseStartError? validate(DateTime start, {String? ignoreId}) =>
        validateStart(start,
            birthDate: birth, today: today, others: others, ignoreId: ignoreId);

    test('between birth and today (both inclusive) is fine', () {
      expect(validate(birth), isNull);
      expect(validate(DateTime(2026, 11, 6)), isNull);
      expect(validate(DateTime(2010, 5, 5)), isNull);
    });

    test('before birth, in the future, or on a taken day is not', () {
      expect(validate(DateTime(1990, 3, 14)), PhaseStartError.beforeBirth);
      expect(validate(DateTime(2026, 11, 7)), PhaseStartError.inFuture);
      expect(validate(DateTime(2020, 1, 1, 12)), PhaseStartError.duplicateDay);
    });

    test('the phase being edited may keep its day; no birth date skips that check', () {
      expect(validate(DateTime(2020, 1, 1), ignoreId: 'a'), isNull);
      expect(
          validateStart(DateTime(1900), today: today, others: const []), isNull);
    });
  });
}
