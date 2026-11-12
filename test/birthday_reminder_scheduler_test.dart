import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

void main() {
  group('BirthdayReminderScheduler.nextOccurrence', () {
    final birthday = DateTime(1990, 6, 15);

    test('birthday today, before reminder time -> today', () {
      final now = DateTime(2026, 6, 15, 8, 0);
      expect(BirthdayReminderScheduler.nextOccurrence(birthday, now),
          DateTime(2026, 6, 15, 9, 0));
    });

    test('birthday today, after reminder time -> next year', () {
      final now = DateTime(2026, 6, 15, 10, 0);
      expect(BirthdayReminderScheduler.nextOccurrence(birthday, now),
          DateTime(2027, 6, 15, 9, 0));
    });

    test('birthday exactly at reminder time counts as passed', () {
      final now = DateTime(2026, 6, 15, 9, 0);
      expect(BirthdayReminderScheduler.nextOccurrence(birthday, now),
          DateTime(2027, 6, 15, 9, 0));
    });

    test('birthday tomorrow -> tomorrow at configured time', () {
      final now = DateTime(2026, 6, 14, 23, 0);
      expect(
          BirthdayReminderScheduler.nextOccurrence(birthday, now, hour: 7, minute: 30),
          DateTime(2026, 6, 15, 7, 30));
    });

    test('Dec 31 rolls over to January birthday of next year', () {
      final now = DateTime(2026, 12, 31, 12, 0);
      expect(BirthdayReminderScheduler.nextOccurrence(DateTime(1985, 1, 2), now),
          DateTime(2027, 1, 2, 9, 0));
    });

    test('Feb 29 birthday in a leap year -> Feb 29', () {
      final now = DateTime(2028, 1, 10);
      expect(BirthdayReminderScheduler.nextOccurrence(DateTime(2000, 2, 29), now),
          DateTime(2028, 2, 29, 9, 0));
    });

    test('Feb 29 birthday in a non-leap year -> Feb 28', () {
      final now = DateTime(2026, 1, 10);
      expect(BirthdayReminderScheduler.nextOccurrence(DateTime(2000, 2, 29), now),
          DateTime(2026, 2, 28, 9, 0));
    });

    test('day-before reminder crosses year boundary (Jan 1 birthday)', () {
      final now = DateTime(2026, 6, 1);
      expect(
          BirthdayReminderScheduler.nextOccurrence(DateTime(1990, 1, 1), now, daysBefore: 1),
          DateTime(2026, 12, 31, 9, 0));
    });

    test('day-before reminder already passed today -> next year', () {
      final now = DateTime(2026, 6, 14, 10, 0);
      expect(BirthdayReminderScheduler.nextOccurrence(birthday, now, daysBefore: 1),
          DateTime(2027, 6, 14, 9, 0));
    });

    test('second occurrence is one year after the first', () {
      final now = DateTime(2026, 3, 1);
      final first = BirthdayReminderScheduler.nextOccurrence(birthday, now);
      final second = BirthdayReminderScheduler.nextOccurrence(birthday, first);
      expect(second, DateTime(2027, 6, 15, 9, 0));
    });
  });

  group('BirthdayReminderScheduler.upcomingReminders', () {
    final birthday = DateTime(1990, 6, 15);
    final morning = DateTime(2026, 6, 15, 9, 30);

    test('not notified -> today and next year', () {
      expect(BirthdayReminderScheduler.upcomingReminders(birthday, morning, reminderMinutes: 10 * 60),
          [DateTime(2026, 6, 15, 10), DateTime(2027, 6, 15, 10)]);
    });

    test('already notified today -> skips today, still two future years', () {
      expect(
          BirthdayReminderScheduler.upcomingReminders(birthday, morning,
              reminderMinutes: 10 * 60, skipToday: true),
          [DateTime(2027, 6, 15, 10), DateTime(2028, 6, 15, 10)]);
    });

    test('skipToday leaves other days untouched', () {
      final before = DateTime(2026, 6, 1);
      expect(BirthdayReminderScheduler.upcomingReminders(birthday, before, skipToday: true),
          BirthdayReminderScheduler.upcomingReminders(birthday, before));
    });

    test('day-before shown today -> skips today\'s day-before', () {
      final eve = DateTime(2026, 6, 14, 9, 30);
      expect(
          BirthdayReminderScheduler.upcomingReminders(birthday, eve,
              reminderMinutes: 23 * 60, daysBefore: 1, skipToday: true),
          [DateTime(2027, 6, 14, 23), DateTime(2028, 6, 14, 23)]);
    });
  });

  group('BirthdayReminderScheduler.ageOnBirthdayFor', () {
    test('day-of reminder', () {
      expect(BirthdayReminderScheduler.ageOnBirthdayFor(
          DateTime(1990, 6, 15), DateTime(2026, 6, 15, 9), 0), 36);
    });

    test('day-before reminder on Dec 31 belongs to next year birthday', () {
      expect(BirthdayReminderScheduler.ageOnBirthdayFor(
          DateTime(1990, 1, 1), DateTime(2026, 12, 31, 9), 1), 37);
    });
  });

  group('BirthdayReminderScheduler.notificationIdFor', () {
    test('ids are unique across friends, years and day-before', () {
      final ids = <int>{};
      for (int friend = 1; friend <= 500; friend++) {
        for (int year = 0; year < 2; year++) {
          for (final dayBefore in [false, true]) {
            ids.add(BirthdayReminderScheduler.notificationIdFor(
                friend, yearOffset: year, dayBefore: dayBefore));
          }
        }
      }
      expect(ids.length, 500 * 4);
    });

    test('ids stay in the dedicated birthday range', () {
      final id = BirthdayReminderScheduler.notificationIdFor(1);
      expect(id, greaterThanOrEqualTo(BirthdayReminderScheduler.idRangeStart));
      expect(BirthdayReminderScheduler.testNotificationId,
          lessThan(BirthdayReminderScheduler.idRangeStart));
    });

    test('FriendsService.nextNotificationId picks a fresh id', () {
      expect(FriendsService.nextNotificationId([]), 1);
      expect(FriendsService.nextNotificationId([3, 1, 7]), 8);
    });
  });

  group('BirthdayReminderScheduler.buildContent', () {
    final now = DateTime(2026, 1, 1);
    Friend friend({String? message}) => Friend(
          id: 'a',
          name: 'Anna',
          birthDate: DateTime(1996, 6, 15),
          customNotificationMessage: message,
          createdDate: now,
          lastUpdated: now,
        );

    test('English default text includes age', () {
      final content = BirthdayReminderScheduler.buildContent(
          friend(), 30, AppLocalizations(const Locale('en')));
      expect(content.body, 'Anna turns 30 today 🎂');
      expect(content.title, contains('Anna'));
    });

    test('German day-before text', () {
      final content = BirthdayReminderScheduler.buildContent(
          friend(), 30, AppLocalizations(const Locale('de')), dayBefore: true);
      expect(content.body, 'Anna wird morgen 30.');
    });

    test('custom message is used and age line appended', () {
      final content = BirthdayReminderScheduler.buildContent(
          friend(message: 'Call her!'), 30, AppLocalizations(const Locale('en')));
      expect(content.body, 'Call her!\n\nAnna turns 30 today 🎂');
    });
  });
}
