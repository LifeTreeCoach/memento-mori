import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/planned_duration.dart';

void main() {
  final today = DateTime(2026, 11, 2);

  test('choices: 6 months, 1, 2, 5 years and open', () {
    expect(PlannedDuration.choices.map((d) => d.months),
        [6, 12, 24, 60, null]);
  });

  group('endFrom', () {
    test('adds calendar months, day clamped to short months', () {
      expect(const PlannedDuration.months(6).endFrom(today),
          DateTime(2027, 5, 2));
      expect(const PlannedDuration.months(6).endFrom(DateTime(2026, 8, 31)),
          DateTime(2027, 2, 28));
    });

    test('open has no end', () {
      expect(const PlannedDuration.open().endFrom(today), isNull);
      expect(const PlannedDuration.open().isOpen, isTrue);
    });
  });

  group('until', () {
    test('whole months to the planned end, at least one', () {
      expect(PlannedDuration.until(DateTime(2027, 11, 2), today),
          const PlannedDuration.months(12));
      expect(PlannedDuration.until(DateTime(2026, 11, 20), today),
          const PlannedDuration.months(1));
      expect(PlannedDuration.until(DateTime(2026, 1, 1), today),
          const PlannedDuration.months(1));
    });

    test('without a planned end it is open', () {
      expect(PlannedDuration.until(null, today), const PlannedDuration.open());
    });
  });

  group('total share', () {
    test('counts the whole phase from its start to the planned end', () {
      final start = DateTime(2025, 11, 2);
      const twoYears = PlannedDuration.months(24);
      expect(twoYears.totalMonths(start, today), 36);
      // 36 of 960 months.
      expect(twoYears.totalShare(start, today, 80), closeTo(0.0375, 1e-9));
    });

    test('open has none', () {
      expect(const PlannedDuration.open().totalShare(today, today, 80), isNull);
    });
  });

  group('maxMonths', () {
    test('until the expected end of the lifespan', () {
      expect(
          PlannedDuration.maxMonths(
              birthDate: DateTime(1990, 11, 2),
              lifeExpectancyYears: 80,
              today: today),
          44 * 12);
    });

    test('at least a month, 100 years without a birth date', () {
      expect(
          PlannedDuration.maxMonths(
              birthDate: DateTime(1900),
              lifeExpectancyYears: 80,
              today: today),
          1);
      expect(PlannedDuration.maxMonths(lifeExpectancyYears: 80, today: today),
          1200);
    });
  });

  test('the lifespan bar grows by the planned rest', () {
    final birth = DateTime(1990, 11, 2);
    LifespanBarFractions bar(PlannedDuration d) => LifespanBarFractions.of(
        birthDate: birth,
        lifeExpectancyYears: 80,
        start: DateTime(2025, 11, 2),
        today: today,
        plannedEnd: d.endFrom(today));
    final open = bar(const PlannedDuration.open());
    final fiveYears = bar(const PlannedDuration.months(60));
    expect(open.plannedEnd, open.today);
    expect(fiveYears.today, open.today);
    expect(fiveYears.plannedEnd - fiveYears.today, closeTo(5 / 80, 0.001));
  });
}
