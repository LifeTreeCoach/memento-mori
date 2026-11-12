import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_due.dart';

void main() {
  // 2026-11-15 is a Sunday.
  final sunday = DateTime(2026, 11, 15);
  final sundayReminder = DateTime(2026, 11, 15, 19);
  final midWeekAnchor = DateTime(2026, 11, 11); // Wednesday -> Sunday 15th
  final longAgo = DateTime(2020);

  bool due(
    DateTime now, {
    ReminderRhythm rhythm = ReminderRhythm.weekly,
    DateTime? anchor,
    bool enabled = true,
    bool onboarded = true,
    bool hasBirthDate = true,
    DateTime? lastShown,
    DateTime? since,
  }) =>
      WeekMomentDue.catchUpDue(
        now: now,
        rhythm: rhythm,
        anchor: anchor,
        enabled: enabled,
        onboarded: onboarded,
        hasBirthDate: hasBirthDate,
        lastShown: lastShown,
        since: since ?? longAgo,
      );

  group('reminderDayOf', () {
    test('drops the time', () {
      expect(WeekMomentDue.reminderDayOf(sundayReminder), sunday);
    });
  });

  group('latestReminder weekly', () {
    test('Sunday 18:59 is still the previous Sunday', () {
      expect(
          WeekMomentDue.latestReminder(
              DateTime(2026, 11, 15, 18, 59), ReminderRhythm.weekly),
          DateTime(2026, 11, 8, 19));
    });

    test('Sunday 19:00 is this Sunday', () {
      expect(WeekMomentDue.latestReminder(sundayReminder, ReminderRhythm.weekly),
          sundayReminder);
    });

    test('mid-week is the past Sunday', () {
      expect(
          WeekMomentDue.latestReminder(
              DateTime(2026, 11, 18, 8), ReminderRhythm.weekly),
          sundayReminder);
    });

    test('off has none', () {
      expect(
          WeekMomentDue.latestReminder(sundayReminder, ReminderRhythm.off),
          isNull);
    });
  });

  group('latestReminder every 4 weeks', () {
    const rhythm = ReminderRhythm.every4Weeks;

    test('null without anchor', () {
      expect(WeekMomentDue.latestReminder(sundayReminder, rhythm), isNull);
    });

    test('mid-week anchor starts on the following Sunday', () {
      expect(
          WeekMomentDue.latestReminder(sundayReminder, rhythm,
              anchor: midWeekAnchor),
          sundayReminder);
    });

    test('null before the first check-in', () {
      expect(
          WeekMomentDue.latestReminder(DateTime(2026, 11, 15, 18, 59), rhythm,
              anchor: midWeekAnchor),
          isNull);
      expect(
          WeekMomentDue.latestReminder(DateTime(2026, 11, 12), rhythm,
              anchor: midWeekAnchor),
          isNull);
    });

    test('stays on the first check-in for the next 4 weeks', () {
      expect(
          WeekMomentDue.latestReminder(DateTime(2026, 12, 13, 18, 59), rhythm,
              anchor: midWeekAnchor),
          sundayReminder);
    });

    test('moves 28 days on at the next check-in', () {
      expect(
          WeekMomentDue.latestReminder(DateTime(2026, 12, 13, 19), rhythm,
              anchor: midWeekAnchor),
          DateTime(2026, 12, 13, 19));
    });

    test('several intervals later', () {
      expect(
          WeekMomentDue.latestReminder(DateTime(2027, 3, 1), rhythm,
              anchor: midWeekAnchor),
          DateTime(2027, 2, 7, 19));
    });
  });

  group('catchUpWindow', () {
    test('3 days weekly, 7 days every 4 weeks', () {
      expect(WeekMomentDue.catchUpWindow(ReminderRhythm.weekly),
          const Duration(days: 3));
      expect(WeekMomentDue.catchUpWindow(ReminderRhythm.every4Weeks),
          const Duration(days: 7));
    });
  });

  group('catchUpDue weekly', () {
    test('Sunday 18:59 uses last week, outside its window', () {
      expect(due(DateTime(2026, 11, 15, 18, 59)), isFalse);
    });

    test('due from Sunday 19:00', () {
      expect(due(sundayReminder), isTrue);
    });

    test('due on Monday', () {
      expect(due(DateTime(2026, 11, 16, 9)), isTrue);
    });

    test('due until Wednesday 18:59, not from 19:00', () {
      expect(due(DateTime(2026, 11, 18, 18, 59)), isTrue);
      expect(due(DateTime(2026, 11, 18, 19)), isFalse);
    });

    test('since on the reminder day: not due', () {
      expect(due(DateTime(2026, 11, 16), since: sunday), isFalse);
    });

    test('since after the reminder day: not due', () {
      expect(due(DateTime(2026, 11, 17), since: DateTime(2026, 11, 16)),
          isFalse);
    });

    test('since the day before: due', () {
      expect(due(DateTime(2026, 11, 16), since: DateTime(2026, 11, 14, 23)),
          isTrue);
    });

    test('already shown for this reminder: not due', () {
      expect(due(DateTime(2026, 11, 16), lastShown: sunday), isFalse);
    });

    test('shown for an older reminder: due', () {
      expect(due(DateTime(2026, 11, 16), lastShown: DateTime(2026, 11, 8)),
          isTrue);
    });

    test('gates: disabled, off, no birth date, not onboarded', () {
      final now = DateTime(2026, 11, 16);
      expect(due(now, enabled: false), isFalse);
      expect(due(now, rhythm: ReminderRhythm.off), isFalse);
      expect(due(now, hasBirthDate: false), isFalse);
      expect(due(now, onboarded: false), isFalse);
    });
  });

  group('catchUpDue every 4 weeks', () {
    const rhythm = ReminderRhythm.every4Weeks;

    test('due within 7 days, not from the 7th day at 19:00', () {
      expect(due(DateTime(2026, 11, 22, 18, 59),
              rhythm: rhythm, anchor: midWeekAnchor),
          isTrue);
      expect(due(DateTime(2026, 11, 22, 19),
              rhythm: rhythm, anchor: midWeekAnchor),
          isFalse);
    });

    test('not due before the first check-in or without anchor', () {
      expect(due(DateTime(2026, 11, 14), rhythm: rhythm, anchor: midWeekAnchor),
          isFalse);
      expect(due(DateTime(2026, 11, 16), rhythm: rhythm), isFalse);
    });

    test('not due in the weeks between check-ins', () {
      expect(due(DateTime(2026, 12, 1), rhythm: rhythm, anchor: midWeekAnchor),
          isFalse);
    });
  });

  group('showOnTap', () {
    bool tap({
      bool enabled = true,
      bool hasBirthDate = true,
      DateTime? lastShown,
    }) =>
        WeekMomentDue.showOnTap(
          enabled: enabled,
          hasBirthDate: hasBirthDate,
          lastShown: lastShown,
          reminderDay: sunday,
        );

    test('shows when enabled, with birth date, not shown yet', () {
      expect(tap(), isTrue);
      expect(tap(lastShown: DateTime(2026, 11, 8)), isTrue);
    });

    test('not when shown for this reminder day', () {
      expect(tap(lastShown: sunday), isFalse);
    });

    test('not when disabled or without birth date', () {
      expect(tap(enabled: false), isFalse);
      expect(tap(hasBirthDate: false), isFalse);
      expect(tap(enabled: false, hasBirthDate: false), isFalse);
    });
  });
}
