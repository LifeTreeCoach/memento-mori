import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_catch_up.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_budget.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';

Friend _friend(int n, DateTime birthDate) => Friend(
      id: 'f$n',
      name: 'Friend $n',
      birthDate: birthDate,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
      notificationId: n,
    );

List<BirthdayOccurrence> _occurrences(List<Friend> friends, DateTime now,
        {bool dayBefore = false, NotifiedToday? notifiedToday}) =>
    ReminderBudget.occurrences(
      friends: friends,
      now: now,
      reminderMinutes: 9 * 60,
      dayBeforeEnabled: dayBefore,
      notifiedToday: notifiedToday,
    );

void main() {
  group('ReminderBudget limits', () {
    test('Android keeps 400, iOS 64 - 4 Compass - 1 reserve', () {
      expect(ReminderBudget.limitFor(ReminderPlatform.android), 400);
      expect(ReminderBudget.limitFor(ReminderPlatform.ios), 59);
    });
  });

  group('ReminderBudget.occurrences', () {
    final now = DateTime(2026, 6, 1, 12);

    test('next two birthdays, day-of and day-before, with their ids', () {
      final friend = _friend(7, DateTime(1990, 6, 15));
      final all = _occurrences([friend], now, dayBefore: true);
      expect({for (final o in all) o.id: o.at}, {
        BirthdayReminderScheduler.notificationIdFor(7): DateTime(2026, 6, 15, 9),
        BirthdayReminderScheduler.notificationIdFor(7, yearOffset: 1): DateTime(2027, 6, 15, 9),
        BirthdayReminderScheduler.notificationIdFor(7, dayBefore: true): DateTime(2026, 6, 14, 9),
        BirthdayReminderScheduler.notificationIdFor(7, yearOffset: 1, dayBefore: true):
            DateTime(2027, 6, 14, 9),
      });
      expect(all.first.age, 36);
    });

    test('friends without reminders are left out', () {
      final off = _friend(0, DateTime(1990, 6, 15));
      expect(_occurrences([off], now), isEmpty);
    });

    test('a reminder already shown today is skipped (catch-up)', () {
      final friend = _friend(1, DateTime(1990, 6, 1));
      final morning = DateTime(2026, 6, 1, 8);
      final all = _occurrences([friend], morning,
          notifiedToday: (_, {required dayBefore}) => !dayBefore);
      expect(all.map((o) => o.at), [DateTime(2027, 6, 1, 9), DateTime(2028, 6, 1, 9)]);
    });
  });

  group('ReminderBudget.select', () {
    // Dec 25, Jan 2 and Feb 29 birthdays seen from just before Christmas.
    final now = DateTime(2026, 12, 20, 12);
    final friends = [
      _friend(1, DateTime(1980, 12, 25)),
      _friend(2, DateTime(1985, 1, 2)),
      _friend(3, DateTime(2000, 2, 29)),
    ];

    test('keeps the earliest across the year boundary and Feb 29', () {
      final plan = ReminderBudget.select(_occurrences(friends, now), limit: 4);
      expect(plan.kept.map((o) => o.at), [
        DateTime(2026, 12, 25, 9),
        DateTime(2027, 1, 2, 9),
        DateTime(2027, 2, 28, 9), // Feb 29 falls on Feb 28 in 2027
      ]);
      expect(plan.truncated, isTrue);
      expect(plan.refreshAt, DateTime(2027, 2, 28, 9, 1));
      expect(plan.notificationCount, 4);
    });

    test('the leap year keeps Feb 29', () {
      final plan = ReminderBudget.select(_occurrences(friends, now), limit: 100);
      expect(plan.kept.map((o) => o.at), [
        DateTime(2026, 12, 25, 9),
        DateTime(2027, 1, 2, 9),
        DateTime(2027, 2, 28, 9),
        DateTime(2027, 12, 25, 9),
        DateTime(2028, 1, 2, 9),
        DateTime(2028, 2, 29, 9),
      ]);
    });

    test('no refresh note when everything fits (exactly the limit)', () {
      final plan = ReminderBudget.select(_occurrences(friends, now), limit: 6);
      expect(plan.kept, hasLength(6));
      expect(plan.truncated, isFalse);
      expect(plan.refreshAt, isNull);
    });

    test('equal fire times are ordered by id', () {
      final twins = [_friend(9, DateTime(1990, 3, 3)), _friend(4, DateTime(1991, 3, 3))];
      final plan = ReminderBudget.select(_occurrences(twins, now), limit: 3);
      expect(plan.kept.map((o) => o.friend.notificationId), [4, 9]);
    });

    test('300 friends: at most 400 on Android and 59 on iOS', () {
      final many = [
        for (var i = 1; i <= 300; i++) _friend(i, DateTime(1970 + i % 40, 1 + i % 12, 1 + i % 28)),
      ];
      final all = _occurrences(many, now, dayBefore: true);
      expect(all, hasLength(1200));
      for (final (platform, limit) in [
        (ReminderPlatform.android, 400),
        (ReminderPlatform.ios, 59),
      ]) {
        final plan = ReminderBudget.select(all, limit: ReminderBudget.limitFor(platform));
        expect(plan.notificationCount, limit);
        expect(plan.kept, hasLength(limit - 1));
        final latestKept = plan.kept.last.at;
        final dropped = all.where((o) => !plan.kept.contains(o));
        expect(dropped.every((o) => !o.at.isBefore(latestKept)), isTrue);
      }
    });
  });

  group('catch-up after a budget cut', () {
    test('a left-out reminder counts as missed, a kept one as delivered', () {
      final kept = _friend(1, DateTime(1990, 6, 1));
      final cut = _friend(2, DateTime(1991, 6, 1));
      final before = DateTime(2026, 5, 20);
      final plan = ReminderBudget.select(_occurrences([kept, cut], before), limit: 2);
      expect(plan.kept.single.friend, kept);

      final state = const BirthdayCatchUpState().withScheduled(plan.kept);
      expect(state.scheduledDayOf.keys, containsAll(BirthdayCatchUpPolicy.markerKeys(kept)));
      for (final key in BirthdayCatchUpPolicy.markerKeys(cut)) {
        expect(state.scheduledDayOf.containsKey(key), isFalse);
      }

      final birthdayNoon = DateTime(2026, 6, 1, 12);
      final catchUp = BirthdayCatchUpPolicy.plan(
        friends: [kept, cut],
        now: birthdayNoon,
        reminderMinutes: 9 * 60,
        remindersEnabled: true,
        dayBeforeEnabled: false,
        pendingIds: const {},
        previous: state,
      );
      expect(catchUp.toShow, [cut]);
    });
  });

  group('ReminderService.shouldRefreshOnResume', () {
    final last = DateTime(2026, 11, 7, 10);

    test('first resume refreshes', () {
      expect(ReminderService.shouldRefreshOnResume(null, last), isTrue);
    });

    test('same day within 6 hours does not', () {
      expect(ReminderService.shouldRefreshOnResume(last, DateTime(2026, 11, 7, 15, 59)), isFalse);
    });

    test('after 6 hours it does', () {
      expect(ReminderService.shouldRefreshOnResume(last, DateTime(2026, 11, 7, 16)), isTrue);
    });

    test('a new day does, however soon', () {
      final lateEvening = DateTime(2026, 11, 7, 23, 50);
      expect(ReminderService.shouldRefreshOnResume(lateEvening, DateTime(2026, 11, 8, 0, 5)),
          isTrue);
    });
  });
}
