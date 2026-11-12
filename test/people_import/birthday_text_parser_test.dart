import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_text_parser.dart';

void main() {
  final today = DateTime(2026, 11, 7);
  BirthdayDate? parse(String? text, {int? omitYear}) =>
      parseBirthdayText(text, omitYear: omitYear, today: today);
  BirthdayDate date(int month, int day, [int? year]) =>
      BirthdayDate(month: month, day: day, year: year);

  group('formats', () {
    test('yyyy-MM-dd', () => expect(parse('1988-05-13'), date(5, 13, 1988)));
    test('--MM-dd', () => expect(parse('--05-13'), date(5, 13)));
    test('yyyyMMdd', () => expect(parse('19880513'), date(5, 13, 1988)));
    test('--MMdd', () => expect(parse('--0513'), date(5, 13)));
    test('ISO with time keeps the date part (no zone shift)', () {
      expect(parse('1988-05-13T23:30:00-08:00'), date(5, 13, 1988));
      expect(parse('1988-05-13T00:00:00Z'), date(5, 13, 1988));
      expect(parse('1988-05-13 08:00'), date(5, 13, 1988));
      expect(parse('19880513T231000Z'), date(5, 13, 1988));
    });
    test('millisecond timestamps use the UTC date', () {
      final millis = DateTime.utc(1988, 5, 13).millisecondsSinceEpoch;
      expect(parse('$millis'), date(5, 13, 1988));
      final beforeEpoch = DateTime.utc(1955, 1, 2).millisecondsSinceEpoch;
      expect(parse('$beforeEpoch'), date(1, 2, 1955));
      final lateUtc = DateTime.utc(1988, 5, 13, 23, 59).millisecondsSinceEpoch;
      expect(parse('$lateUtc'), date(5, 13, 1988));
    });
    test('dd.MM.yyyy and d.M.yyyy', () {
      expect(parse('13.05.1988'), date(5, 13, 1988));
      expect(parse('3.5.1988'), date(5, 3, 1988));
      expect(parse('3.5.'), date(5, 3));
    });
    test('surrounding whitespace is ignored', () {
      expect(parse('  1988-05-13 \n'), date(5, 13, 1988));
    });
  });

  group('no year', () {
    test('1604 means no year', () {
      expect(parse('1604-07-21'), date(7, 21));
      expect(parse('16040721'), date(7, 21));
    });
    test('X-APPLE-OMIT-YEAR value means no year', () {
      expect(parse('1900-07-21', omitYear: 1900), date(7, 21));
      expect(parse('1988-07-21', omitYear: 1604), date(7, 21, 1988));
    });
  });

  group('validation', () {
    test('rejects impossible days and months', () {
      expect(parse('1988-02-30'), isNull);
      expect(parse('1988-13-01'), isNull);
      expect(parse('1988-00-10'), isNull);
      expect(parse('1988-04-31'), isNull);
      expect(parse('--04-31'), isNull);
      expect(parse('32.01.1990'), isNull);
    });
    test('29 February only in leap years or without a year', () {
      expect(parse('1992-02-29'), date(2, 29, 1992));
      expect(parse('2000-02-29'), date(2, 29, 2000));
      expect(parse('1900-02-29'), isNull);
      expect(parse('1993-02-29'), isNull);
      expect(parse('--02-29'), date(2, 29));
      expect(parse('1604-02-29'), date(2, 29));
    });
    test('rejects years before 1850 and dates after today', () {
      expect(parse('1849-12-31'), isNull);
      expect(parse('1850-01-01'), date(1, 1, 1850));
      expect(parse('2027-01-01'), isNull);
      expect(parse('2026-11-08'), isNull);
      expect(parse('2026-11-07'), date(11, 7, 2026));
    });
    test('rejects garbage', () {
      for (final text in [
        null,
        '',
        'circa 1800',
        'tomorrow',
        '1988-5',
        '--13',
        '12345',
        '99999999999999999999',
        '1988/05/13',
      ]) {
        expect(parse(text), isNull, reason: '$text');
      }
    });
  });

  test('birthdayFromParts validates separate fields', () {
    expect(
      birthdayFromParts(year: 1604, month: 2, day: 29, today: today),
      date(2, 29),
    );
    expect(birthdayFromParts(month: 6, day: 31, today: today), isNull);
    expect(
      birthdayFromParts(year: 1990, month: 6, day: 30, today: today),
      date(6, 30, 1990),
    );
  });
}
