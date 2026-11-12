import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ordinal.dart';

void main() {
  group('English', () {
    const cases = {
      1: '1st',
      2: '2nd',
      3: '3rd',
      4: '4th',
      10: '10th',
      11: '11th',
      12: '12th',
      13: '13th',
      21: '21st',
      22: '22nd',
      23: '23rd',
      37: '37th',
      101: '101st',
      111: '111th',
      112: '112th',
      113: '113th',
    };
    cases.forEach((n, expected) {
      test('$n -> $expected', () => expect(yearOrdinal(n, 'en'), expected));
    });
  });

  test('German writes a period', () {
    expect(yearOrdinal(1, 'de'), '1.');
    expect(yearOrdinal(37, 'de'), '37.');
  });

  test('French uses the feminine forms (année)', () {
    expect(yearOrdinal(1, 'fr'), '1re');
    expect(yearOrdinal(2, 'fr'), '2e');
    expect(yearOrdinal(37, 'fr'), '37e');
    expect(yearOrdinal(101, 'fr'), '101e');
  });

  test('Spanish writes .º', () {
    expect(yearOrdinal(1, 'es'), '1.º');
    expect(yearOrdinal(37, 'es'), '37.º');
  });

  test('an unknown language falls back to English', () {
    expect(yearOrdinal(1, 'it'), '1st');
    expect(yearOrdinal(12, ''), '12th');
  });
}
