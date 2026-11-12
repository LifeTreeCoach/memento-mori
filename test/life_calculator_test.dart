import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

const _fixturePath = 'test/fixtures/life_calculator_vectors.json';

List<Map<String, dynamic>> _loadCases() {
  final json = jsonDecode(File(_fixturePath).readAsStringSync());
  return (json['cases'] as List).cast<Map<String, dynamic>>();
}

LifeCalculator _calculatorFor(Map<String, dynamic> vector) => LifeCalculator(
      birthDate: DateTime.parse(vector['birth_date'] as String),
      lifeExpectancyYears: vector['life_expectancy_years'] as int,
      now: DateTime.parse(vector['today'] as String),
    );

Map<String, num> _actualValues(LifeCalculator c) => {
      'age_years': c.ageYears,
      'days_lived': c.daysLived,
      'weeks_lived': c.weeksLived,
      'total_weeks': c.totalWeeks,
      'weeks_remaining': c.weeksRemaining,
      'current_week_number': c.currentWeekNumber,
      'months_lived': c.monthsLived,
      'total_months': c.totalMonths,
      'months_remaining': c.monthsRemaining,
      'years_lived': c.yearsLived,
      'total_years': c.totalYears,
      'years_remaining': c.yearsRemaining,
      'days_remaining': c.daysRemaining,
      'percent_lived': c.percentLived,
    };

void main() {
  group('LifeCalculator matches shared fixture', () {
    for (final vector in _loadCases()) {
      test(vector['name'], () {
        final actual = _actualValues(_calculatorFor(vector));
        final expected = (vector['expected'] as Map).cast<String, num>();
        for (final entry in expected.entries) {
          expect(actual[entry.key], closeTo(entry.value, 1e-4),
              reason: entry.key);
        }
      });
    }
  });

  test('defaults to 80 years and ignores time of day', () {
    final c = LifeCalculator(
      birthDate: DateTime(2000, 1, 1, 23, 59),
      now: DateTime(2000, 1, 8, 0, 1),
    );
    expect(c.lifeExpectancyYears, 80);
    expect(c.weeksLived, 1);
    expect(c.currentWeekNumber, 2);
  });

  test('birth date in the future clamps lived values to zero', () {
    final c = LifeCalculator(
      birthDate: DateTime(2030, 1, 1),
      now: DateTime(2026, 1, 1),
    );
    expect(c.weeksLived, 0);
    expect(c.ageYears, 0);
    expect(c.monthsLived, 0);
    expect(c.percentLived, 0);
  });
}
