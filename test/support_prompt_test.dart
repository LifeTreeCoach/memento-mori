import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/support/support_prompt.dart';
import 'package:memento_mori_life_in_weeks/support/support_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _firstUse = DateTime(2026, 1, 10);

DateTime? _next({
  DateTime? lastShown,
  bool optedOut = false,
  bool done = false,
}) => SupportPrompt.nextDue(
  firstUse: _firstUse,
  lastShown: lastShown,
  optedOut: optedOut,
  alreadySupported: done,
);

bool _due(DateTime today, {DateTime? lastShown}) => SupportPrompt.isDue(
  today: today,
  firstUse: _firstUse,
  lastShown: lastShown,
);

void main() {
  group('SupportPrompt.nextDue', () {
    test('the first prompt is due 30 days after the first use', () {
      expect(_next(), DateTime(2026, 2, 9));
      expect(_due(DateTime(2026, 2, 8)), isFalse);
      expect(_due(DateTime(2026, 2, 9)), isTrue);
    });

    test('after the first prompt: 6 calendar months after the first use', () {
      expect(_next(lastShown: DateTime(2026, 2, 9)), DateTime(2026, 7, 10));
    });

    test('then yearly: 18, 30, 42 months after the first use', () {
      expect(_next(lastShown: DateTime(2026, 7, 10)), DateTime(2027, 7, 10));
      expect(_next(lastShown: DateTime(2027, 7, 10)), DateTime(2028, 7, 10));
      expect(_next(lastShown: DateTime(2028, 7, 12)), DateTime(2029, 7, 10));
    });

    test('missed milestones collapse into one prompt', () {
      // Away for two years: the card is due once on return ...
      expect(_due(DateTime(2028, 3, 1)), isTrue);
      // ... and once shown, waits for the next milestone after that day.
      expect(_next(lastShown: DateTime(2028, 3, 1)), DateTime(2028, 7, 10));
    });

    test('never twice in a row: shown today means not due today', () {
      final today = DateTime(2026, 2, 9);
      expect(_due(today), isTrue);
      expect(_due(today, lastShown: today), isFalse);
      expect(_due(DateTime(2026, 7, 9), lastShown: today), isFalse);
      expect(_due(DateTime(2026, 7, 10), lastShown: today), isTrue);
    });

    test('opted out or already supported: never due', () {
      expect(_next(optedOut: true), isNull);
      expect(_next(done: true), isNull);
      expect(
        SupportPrompt.isDue(
          today: DateTime(2030),
          firstUse: _firstUse,
          optedOut: true,
        ),
        isFalse,
      );
    });

    test('calendar months clamp to the end of a short month', () {
      expect(
        SupportPrompt.addMonths(DateTime(2026, 8, 31), 6),
        DateTime(2027, 2, 28),
      );
      expect(
        SupportPrompt.addMonths(DateTime(2027, 8, 31), 6),
        DateTime(2028, 2, 29),
      );
    });

    test('ignores the time of day', () {
      expect(
        SupportPrompt.isDue(
          today: DateTime(2026, 2, 9, 0, 1),
          firstUse: DateTime(2026, 1, 10, 23, 59),
        ),
        isTrue,
      );
    });
  });

  group('SupportPrompt.usage', () {
    SupportUsage at(DateTime today) =>
        SupportPrompt.usage(firstUse: _firstUse, today: today);

    test('a month, half a year, then whole years', () {
      expect(at(DateTime(2026, 2, 9)), const SupportUsage.month());
      expect(at(DateTime(2026, 7, 10)), const SupportUsage.halfYear());
      expect(at(DateTime(2027, 1, 9)), const SupportUsage.halfYear());
      expect(at(DateTime(2027, 7, 10)), const SupportUsage.years(1));
      expect(at(DateTime(2028, 7, 10)), const SupportUsage.years(2));
    });
  });

  group('SupportService', () {
    Future<void> init(Map<String, Object> values, {DateTime? today}) async {
      SharedPreferences.setMockInitialValues(values);
      await SupportService.initialize(today: today ?? DateTime(2026, 11, 2));
    }

    test(
      'records the first use once, and never prompts in that session',
      () async {
        await init({});
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('first_use_date'), '2026-11-02');
        expect(SupportService.isDue(DateTime(2027, 1, 1)), isFalse);

        // Next launch: the stored date stays, the schedule applies.
        await SupportService.initialize(today: DateTime(2027, 1, 1));
        expect(prefs.getString('first_use_date'), '2026-11-02');
        expect(SupportService.isDue(DateTime(2026, 12, 1)), isFalse);
        expect(SupportService.isDue(DateTime(2026, 12, 2)), isTrue);
      },
    );

    test('shown, opt-out and done are persisted', () async {
      await init({'first_use_date': '2026-01-10'});
      final today = DateTime(2026, 2, 9);
      expect(SupportService.isDue(today), isTrue);

      await SupportService.markShown(today);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('support_last_shown'), '2026-02-09');
      expect(SupportService.isDue(today), isFalse);
      expect(SupportService.isDue(DateTime(2026, 7, 10)), isTrue);

      await SupportService.setRemindersEnabled(false);
      expect(prefs.getBool('support_opt_out'), isTrue);
      expect(SupportService.isDue(DateTime(2030)), isFalse);
      await SupportService.setRemindersEnabled(true);
      expect(SupportService.isDue(DateTime(2030)), isTrue);

      await SupportService.markSupported(DateTime(2030));
      expect(prefs.getBool('support_done'), isTrue);
      expect(SupportService.isDue(DateTime(2040)), isFalse);
    });

    test('"already did" turns the reminder switch off; on again clears it',
        () async {
      await init({'first_use_date': '2026-01-10'});
      expect(SupportService.remindersEnabled, isTrue);

      await SupportService.markSupported(DateTime(2026, 2, 9));
      expect(SupportService.remindersEnabled, isFalse);

      await SupportService.setRemindersEnabled(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('support_done'), isFalse);
      expect(SupportService.alreadySupported, isFalse);
      expect(SupportService.remindersEnabled, isTrue);
      expect(SupportService.isDue(DateTime(2026, 7, 10)), isTrue);

      await SupportService.setRemindersEnabled(false);
      expect(SupportService.remindersEnabled, isFalse);
      expect(SupportService.isDue(DateTime(2030)), isFalse);
    });

    test('Diagnostics: show now, then reset the schedule', () async {
      await init({
        'first_use_date': '2026-01-10',
        'support_done': true,
        'support_opt_out': true,
        'support_last_shown': '2026-02-09',
      });
      final today = DateTime(2026, 11, 2);
      expect(SupportService.isDue(today), isFalse);
      SupportService.showNow();
      expect(SupportService.isDue(today), isTrue);

      await SupportService.resetSchedule(today);
      expect(SupportService.firstUse, today);
      expect(SupportService.lastShown, isNull);
      expect(SupportService.optedOut, isFalse);
      expect(SupportService.alreadySupported, isFalse);
      expect(SupportService.isDue(today), isFalse);
      expect(SupportService.isDue(DateTime(2026, 12, 2)), isTrue);
    });
  });
}
