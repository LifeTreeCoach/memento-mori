import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/onboarding/year_of_life.dart';

int _week(DateTime birth, DateTime today) =>
    YearOfLife(birthDate: birth, today: today).week;

void main() {
  group('YearOfLife.week', () {
    test('is 1 on the birthday itself', () {
      expect(_week(DateTime(1990, 6, 15), DateTime(2026, 6, 15)), 1);
    });

    test('counts whole weeks since the last birthday', () {
      expect(_week(DateTime(1990, 6, 15), DateTime(2026, 6, 21)), 1);
      expect(_week(DateTime(1990, 6, 15), DateTime(2026, 6, 22)), 2);
      expect(_week(DateTime(1990, 6, 15), DateTime(2026, 11, 5)), 21);
    });

    test('reaches 52 and 53 just before the next birthday', () {
      final birth = DateTime(1990, 6, 15);
      expect(_week(birth, DateTime(2027, 6, 7)), 52); // day 357
      expect(_week(birth, DateTime(2027, 6, 13)), 52); // day 363
      expect(_week(birth, DateTime(2027, 6, 14)), 53); // day 364
      expect(_week(birth, DateTime(2027, 6, 15)), 1);
    });

    test('a leap-year span can reach day 365, still week 53', () {
      // 15 Mar 2027 -> 14 Mar 2028 spans 29 Feb 2028: 365 days.
      expect(_week(DateTime(1990, 3, 15), DateTime(2028, 3, 14)), 53);
    });

    test('a Feb 29 birthday starts on Mar 1 in non-leap years', () {
      final birth = DateTime(2000, 2, 29);
      expect(_week(birth, DateTime(2027, 3, 1)), 1);
      expect(_week(birth, DateTime(2027, 2, 28)), 53);
      expect(_week(birth, DateTime(2028, 2, 29)), 1);
      expect(_week(birth, DateTime(2028, 2, 28)), 53);
    });

    test('ignores the time of day', () {
      expect(_week(DateTime(1990, 6, 15, 23), DateTime(2026, 6, 22, 0, 30)), 2);
    });

    test('the first year of life counts from the birth date', () {
      expect(_week(DateTime(2026, 11, 1), DateTime(2026, 11, 2)), 1);
      expect(_week(DateTime(2026, 1, 1), DateTime(2026, 11, 5)), 45);
    });
  });

  group('YearOfLife next birthday', () {
    YearOfLife year(DateTime birth, DateTime today) =>
        YearOfLife(birthDate: birth, today: today);

    test('on the birthday itself the whole year lies ahead', () {
      final y = year(DateTime(1990, 6, 15), DateTime(2026, 6, 15));
      expect(y.lastBirthday, DateTime.utc(2026, 6, 15));
      expect(y.nextBirthday, DateTime.utc(2027, 6, 15));
      expect(y.daysUntilNextBirthday, 365);
      expect(y.weeksUntilNextBirthday, 52);
      expect(y.lengthInDays, 365);
    });

    test('the day before the birthday (week 53) has one day left', () {
      final y = year(DateTime(1990, 6, 15), DateTime(2027, 6, 14));
      expect(y.week, 53);
      expect(y.nextBirthday, DateTime.utc(2027, 6, 15));
      expect(y.daysUntilNextBirthday, 1);
      expect(y.weeksUntilNextBirthday, 0);
    });

    test('a year spanning Feb 29 is 366 days long', () {
      final y = year(DateTime(1990, 3, 15), DateTime(2027, 3, 15));
      expect(y.nextBirthday, DateTime.utc(2028, 3, 15));
      expect(y.lengthInDays, 366);
      expect(y.daysUntilNextBirthday, 366);
      expect(y.weeksUntilNextBirthday, 52);
    });

    test('a Feb 29 birthday is next on Mar 1 in a non-leap year', () {
      final birth = DateTime(2000, 2, 29);
      final y = year(birth, DateTime(2026, 2, 28));
      expect(y.lastBirthday, DateTime.utc(2025, 3, 1));
      expect(y.nextBirthday, DateTime.utc(2026, 3, 1));
      expect(y.daysUntilNextBirthday, 1);
    });

    test('a Feb 29 birthday is next on Feb 29 in a leap year', () {
      final birth = DateTime(2000, 2, 29);
      final y = year(birth, DateTime(2027, 3, 1));
      expect(y.lastBirthday, DateTime.utc(2027, 3, 1));
      expect(y.nextBirthday, DateTime.utc(2028, 2, 29));
      expect(y.lengthInDays, 365);
      final onIt = year(birth, DateTime(2028, 2, 29));
      expect(onIt.nextBirthday, DateTime.utc(2029, 3, 1));
      expect(onIt.daysUntilNextBirthday, 366);
    });

    test('ignores the time of day', () {
      final y = year(DateTime(1990, 6, 15, 23), DateTime(2027, 6, 14, 23, 59));
      expect(y.daysUntilNextBirthday, 1);
      expect(y.nextBirthday, DateTime.utc(2027, 6, 15));
    });

    test('yearNumber is the 1-based year of life', () {
      final birth = DateTime(1990, 6, 15);
      expect(year(birth, DateTime(2026, 6, 14)).yearNumber, 36);
      expect(year(birth, DateTime(2026, 6, 15)).yearNumber, 37);
      expect(year(DateTime(2026, 1, 1), DateTime(2026, 11, 5)).yearNumber, 1);
    });
  });
}
