import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_turn.dart';

void main() {
  group('lastSundayOnOrBefore', () {
    test('a Sunday is its own', () {
      expect(
        WeekTurn.lastSundayOnOrBefore(DateTime(2026, 11, 8, 19)),
        DateTime(2026, 11, 8),
      );
    });

    test('any other day goes back to the Sunday before', () {
      for (var day = 9; day <= 14; day++) {
        expect(
          WeekTurn.lastSundayOnOrBefore(DateTime(2026, 11, day)),
          DateTime(2026, 11, 8),
          reason: 'Nov $day',
        );
      }
    });

    test('across a month and a year', () {
      expect(
        WeekTurn.lastSundayOnOrBefore(DateTime(2027, 1, 2)),
        DateTime(2026, 12, 27),
      );
    });
  });

  group('WeekTurn.on', () {
    test('the reminder Sunday ends its week, Monday starts the next', () {
      expect(
        WeekTurn.on(DateTime(2026, 11, 8)),
        const WeekTurn(endedWeek: 45, nextWeek: 46),
      );
    });

    test('later in the week it still closes the last Sunday\'s week', () {
      expect(
        WeekTurn.on(DateTime(2026, 11, 12, 9)),
        const WeekTurn(endedWeek: 45, nextWeek: 46),
      );
    });

    test('week 53 turns into week 1', () {
      // 3 Jan 2021 is the Sunday of ISO week 2020-W53.
      expect(
        WeekTurn.on(DateTime(2021, 1, 3)),
        const WeekTurn(endedWeek: 53, nextWeek: 1),
      );
    });

    test('week 52 turns into week 1', () {
      // 28 Dec 2025 is the Sunday of ISO week 2025-W52.
      expect(
        WeekTurn.on(DateTime(2025, 12, 28)),
        const WeekTurn(endedWeek: 52, nextWeek: 1),
      );
    });

    test('week 1 can start in the old year', () {
      // 29 Dec 2024 ends 2024-W52; Monday 30 Dec is 2025-W01.
      expect(
        WeekTurn.on(DateTime(2024, 12, 31)),
        const WeekTurn(endedWeek: 52, nextWeek: 1),
      );
    });

    test('a daylight saving change keeps the days', () {
      // Europe switches on Sunday 29 Mar 2026.
      expect(
        WeekTurn.on(DateTime(2026, 3, 30)),
        const WeekTurn(endedWeek: 13, nextWeek: 14),
      );
    });
  });
}
