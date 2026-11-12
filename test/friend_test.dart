import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';

Friend _friend({required DateTime birthDate, String? groupName, int notificationId = 0}) {
  final now = DateTime.now();
  return Friend(
    id: '1',
    name: 'Anna',
    birthDate: birthDate,
    groupName: groupName,
    createdDate: now,
    lastUpdated: now,
    notificationId: notificationId,
  );
}

void main() {
  group('Friend birthday calculations', () {
    test('birthday today counts as 0 days and returns today', () {
      final now = DateTime.now();
      final friend = _friend(birthDate: DateTime(now.year - 30, now.month, now.day));
      expect(friend.getDaysUntilNextBirthday(), 0);
      expect(friend.getNextBirthday(), DateTime(now.year, now.month, now.day));
    });

    test('birthday yesterday is (almost) a year away', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final friend = _friend(birthDate: DateTime(1990, yesterday.month, yesterday.day));
      expect(friend.getDaysUntilNextBirthday(), inInclusiveRange(363, 365));
    });

    test('Feb 29 birthday maps to Feb 28 in non-leap years', () {
      final friend = _friend(birthDate: DateTime(2000, 2, 29));
      expect(friend.birthdayInYear(2026), DateTime(2026, 2, 28));
      expect(friend.birthdayInYear(2028), DateTime(2028, 2, 29));
    });

    test('Feb 29 birthday: age, today and next birthday agree in non-leap years', () {
      final friend = _friend(birthDate: DateTime(2000, 2, 29));
      final feb27 = DateTime(2027, 2, 27, 15);
      final feb28 = DateTime(2027, 2, 28, 15);
      expect(friend.getCurrentAge(today: feb27), 26);
      expect(friend.isBirthdayToday(today: feb27), isFalse);
      expect(friend.getDaysUntilNextBirthday(today: feb27), 1);
      expect(friend.getCurrentAge(today: feb28), 27);
      expect(friend.isBirthdayToday(today: feb28), isTrue);
      expect(friend.getNextBirthday(today: feb28), DateTime(2027, 2, 28));
      expect(friend.getDaysUntilNextBirthday(today: feb28), 0);
    });

    test('Feb 29 birthday in a leap year is on Feb 29', () {
      final friend = _friend(birthDate: DateTime(2000, 2, 29));
      expect(friend.getCurrentAge(today: DateTime(2028, 2, 28)), 27);
      expect(friend.isBirthdayToday(today: DateTime(2028, 2, 29)), isTrue);
      expect(friend.getCurrentAge(today: DateTime(2028, 2, 29)), 28);
    });

    test('ageOn counts the birthday itself and never goes negative', () {
      final birth = DateTime(1990, 6, 15);
      expect(Friend.ageOn(birth, DateTime(2020, 6, 14)), 29);
      expect(Friend.ageOn(birth, DateTime(2020, 6, 15)), 30);
      expect(Friend.ageOn(birth, DateTime(1980)), 0);
    });

    test('next birthday rolls over to next year once passed', () {
      final friend = _friend(birthDate: DateTime(1990, 1, 10));
      expect(friend.getNextBirthday(today: DateTime(2026, 1, 11)), DateTime(2027, 1, 10));
      expect(friend.getDaysUntilNextBirthday(today: DateTime(2026, 12, 31)), 10);
      expect(friend.getRemainingYears(today: DateTime(2026, 1, 11)), 80 - 36);
    });

    test('remaining years stop at 0 beyond the expected lifespan', () {
      final friend = _friend(birthDate: DateTime(1938, 6, 12));
      final today = DateTime(2026, 11, 5);
      expect(friend.getCurrentAge(today: today), 88);
      expect(friend.getRemainingYears(today: today), 0);
      expect(friend.isBeyondExpectedLifespan(today: today), isTrue);
    });

    test('reaching the expected lifespan counts as beyond it', () {
      final friend = _friend(birthDate: DateTime(1946, 1, 1));
      expect(friend.getRemainingYears(today: DateTime(2025, 12, 31)), 1);
      expect(friend.isBeyondExpectedLifespan(today: DateTime(2025, 12, 31)),
          isFalse);
      expect(friend.getRemainingYears(today: DateTime(2026, 1, 1)), 0);
      expect(friend.isBeyondExpectedLifespan(today: DateTime(2026, 1, 1)),
          isTrue);
    });
  });

  group('Friend.copyWith', () {
    test('clearGroupName removes the group', () {
      final friend = _friend(birthDate: DateTime(1990), groupName: 'Family');
      expect(friend.copyWith(clearGroupName: true).groupName, isNull);
    });

    test('groupName is kept when not cleared', () {
      final friend = _friend(birthDate: DateTime(1990), groupName: 'Family');
      expect(friend.copyWith(name: 'B').groupName, 'Family');
    });
  });

  group('Friend serialization', () {
    test('notificationId round-trips through JSON', () {
      final friend = _friend(birthDate: DateTime(1990, 5, 1), notificationId: 7);
      expect(Friend.fromJson(friend.toJson()).notificationId, 7);
    });

    test('legacy JSON without notificationId defaults to 0', () {
      final map = _friend(birthDate: DateTime(1990, 5, 1)).toMap()..remove('notificationId');
      expect(Friend.fromMap(map).notificationId, 0);
    });

    test('birthDate is stored as a date-only string', () {
      final map = _friend(birthDate: DateTime(1990, 5, 1)).toMap();
      expect(map['birthDate'], '1990-05-01');
      expect(Friend.fromMap(map).birthDate, DateTime(1990, 5, 1));
    });

    test('string and legacy millis birthDate both yield a local date-only value', () {
      final legacyMillis = DateTime(1990, 5, 1).millisecondsSinceEpoch;
      for (final stored in <Object>['1990-05-01', legacyMillis]) {
        final date = Friend.decodeBirthDate(stored);
        expect(date, DateTime(1990, 5, 1), reason: '$stored');
        expect(date.hour, 0);
        expect(date.minute, 0);
        expect(date.isUtc, isFalse);
      }
    });

    test('legacy millis with a time of day keep the local calendar day', () {
      final millis = DateTime(1985, 12, 31, 23, 30).millisecondsSinceEpoch;
      expect(Friend.decodeBirthDate(millis), DateTime(1985, 12, 31));
    });

    test('invalid birthDate throws', () {
      expect(() => Friend.decodeBirthDate(null), throwsFormatException);
      expect(() => Friend.decodeBirthDate('not a date'), throwsFormatException);
    });
  });
}
