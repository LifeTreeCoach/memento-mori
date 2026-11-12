import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_service.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

Friend _friend({DateTime? birthDate}) {
  final now = DateTime(2026, 1, 1);
  return Friend(
    id: 'f1',
    name: 'Anna',
    birthDate: birthDate ?? DateTime(1990, 5, 1),
    createdDate: now,
    lastUpdated: now,
  );
}

void main() {
  final en = AppLocalizations(const Locale('en'));
  final de = AppLocalizations(const Locale('de'));

  group('allDayBounds', () {
    test('local midnight of the date to local midnight of the next day', () {
      final (start, end) = CalendarService.allDayBounds(DateTime(2026, 5, 1, 15, 30));
      expect(start, DateTime(2026, 5, 1));
      expect(end, DateTime(2026, 5, 2));
      expect(start.isUtc, isFalse);
    });

    test('month and year rollover', () {
      final (_, monthEnd) = CalendarService.allDayBounds(DateTime(2026, 4, 30));
      expect(monthEnd, DateTime(2026, 5, 1));
      final (_, yearEnd) = CalendarService.allDayBounds(DateTime(2026, 12, 31));
      expect(yearEnd, DateTime(2027, 1, 1));
    });

    test('spans exactly one calendar day', () {
      final (start, end) = CalendarService.allDayBounds(DateTime(2026, 3, 29));
      expect((end.year, end.month, end.day), (2026, 3, 30));
      expect((start.hour, end.hour), (0, 0));
    });
  });

  group('event text', () {
    test('title is age-free and localized', () {
      expect(CalendarService.formatEventTitle(_friend(), en), "🎂 Anna's birthday");
      expect(CalendarService.formatEventTitle(_friend(), de), '🎂 Geburtstag von Anna');
    });

    test('description names the birth year, localized', () {
      expect(CalendarService.formatEventDescription(_friend(), en), startsWith('Born 1990'));
      expect(CalendarService.formatEventDescription(_friend(), de), startsWith('Geboren 1990'));
    });
  });


  group('birthdayEventDetails', () {
    test('text, next birthday as an all-day day and a yearly rule', () {
      final details = CalendarService.birthdayEventDetails(_friend(), en,
          today: DateTime(2026, 6, 1));

      expect(details.title, "🎂 Anna's birthday");
      expect(details.description, startsWith('Born 1990'));
      expect(details.start, DateTime(2027, 5, 1));
      expect(details.end, DateTime(2027, 5, 2));
      expect(details.recurrence, isA<YearlyRecurrence>());
      expect(details.recurrence.toRruleString(), 'FREQ=YEARLY');
    });

    test('a birthday today is this year\'s event', () {
      final details = CalendarService.birthdayEventDetails(_friend(), en,
          today: DateTime(2026, 5, 1));
      expect(details.start, DateTime(2026, 5, 1));
    });

    test('follows a changed birth date and the language', () {
      final details = CalendarService.birthdayEventDetails(
          _friend(birthDate: DateTime(1990, 8, 15)), de,
          today: DateTime(2026, 1, 1));
      expect(details.title, '🎂 Geburtstag von Anna');
      expect(details.start, DateTime(2026, 8, 15));
      expect(details.end.difference(details.start), const Duration(days: 1));
    });
  });

  test('new events remind a day ahead', () {
    expect(CalendarService.birthdayReminderLeadTime, const Duration(days: 1));
  });

  test('synced events round-trip through persistence', () {
    final event = CalendarEvent(
      eventId: 'e1',
      friendId: 'f1',
      calendarId: 'cal',
      title: 't',
      date: DateTime(2026, 5, 1),
      createdDate: DateTime(2026, 1, 1),
      lastSynced: DateTime(2026, 1, 2),
    );
    final decoded = CalendarService.decodeSyncedEvents(
        CalendarService.encodeSyncedEvents([event]));
    expect(decoded.single.eventId, 'e1');
    expect(decoded.single.friendId, 'f1');
    expect(CalendarService.decodeSyncedEvents('garbage'), isEmpty);
    expect(CalendarService.decodeSyncedEvents(null), isEmpty);
  });

  group('isSelectionStale', () {
    test('a deleted calendar is stale, an existing one or none is not', () {
      expect(CalendarService.isSelectionStale('7', ['1', '2']), isTrue);
      expect(CalendarService.isSelectionStale('2', ['1', '2']), isFalse);
      expect(CalendarService.isSelectionStale(null, ['1']), isFalse);
    });
  });
}
