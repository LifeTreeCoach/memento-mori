import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_catch_up.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';
import 'package:flutter/material.dart';

const int nineAm = 9 * 60;
final int dayOfId = BirthdayReminderScheduler.notificationIdFor(7);
final int dayBeforeId = BirthdayReminderScheduler.notificationIdFor(7, dayBefore: true);

Friend friend(String id, DateTime birthDate, {bool active = true, int notificationId = 7}) {
  final created = DateTime(2020);
  return Friend(
    id: id,
    name: 'Anna',
    birthDate: birthDate,
    createdDate: created,
    lastUpdated: created,
    isActive: active,
    notificationId: notificationId,
  );
}

BirthdayCatchUpPlan plan(
  List<Friend> friends,
  DateTime now, {
  bool enabled = true,
  bool dayBefore = false,
  Set<int> pending = const {},
  BirthdayCatchUpState previous = const BirthdayCatchUpState(),
  int minutes = nineAm,
}) {
  return BirthdayCatchUpPolicy.plan(
    friends: friends,
    now: now,
    reminderMinutes: minutes,
    remindersEnabled: enabled,
    dayBeforeEnabled: dayBefore,
    pendingIds: pending,
    previous: previous,
  );
}

void main() {
  final birthdayToday = DateTime(1990, 11, 2);
  final evening = DateTime(2026, 11, 2, 18);

  group('BirthdayCatchUpPolicy.plan', () {
    test('friend added after reminder time -> shown once', () {
      final first = plan([friend('a', birthdayToday)], evening);
      expect(first.toShow.map((f) => f.id), ['a']);
      expect(first.nextState.notifiedOn, containsPair('a', '2026-11-02'));
    });

    test('second reschedule the same day -> no duplicate', () {
      final friends = [friend('a', birthdayToday)];
      final first = plan(friends, evening);
      final second = plan(friends, evening.add(const Duration(hours: 1)),
          previous: first.nextState);
      expect(second.toShow, isEmpty);
    });

    test('scheduled reminder fired earlier today -> no catch-up, ever', () {
      final friends = [friend('a', birthdayToday)];
      final morning = plan(friends, DateTime(2026, 11, 2, 8));
      expect(morning.toShow, isEmpty);
      expect(morning.nextState.scheduledDayOf['a'], DateTime(2026, 11, 2, 9));

      final afterFire = plan(friends, evening, previous: morning.nextState);
      expect(afterFire.toShow, isEmpty);
      final later = plan(friends, evening.add(const Duration(hours: 2)),
          previous: afterFire.nextState);
      expect(later.toShow, isEmpty);
    });

    test('before reminder time -> nothing (the scheduled one will fire)', () {
      expect(plan([friend('a', birthdayToday)], DateTime(2026, 11, 2, 8, 59)).toShow, isEmpty);
    });

    test('global toggle off -> none', () {
      final result = plan([friend('a', birthdayToday)], evening, enabled: false);
      expect(result.toShow, isEmpty);
      expect(result.nextState.scheduledDayOf, isEmpty);
    });

    test('per-friend reminders off -> none', () {
      expect(plan([friend('a', birthdayToday, active: false)], evening).toShow, isEmpty);
      expect(plan([friend('a', birthdayToday, notificationId: 0)], evening).toShow, isEmpty);
    });

    test('birthday not today -> none', () {
      expect(plan([friend('a', DateTime(1990, 11, 3))], evening).toShow, isEmpty);
    });

    test('overdue day-of reminder still pending -> shown once', () {
      final friends = [friend('a', birthdayToday)];
      final morning = plan(friends, DateTime(2026, 11, 2, 8));
      final overdue = plan(friends, DateTime(2026, 11, 2, 9, 20),
          pending: {dayOfId}, previous: morning.nextState);
      expect(overdue.toShow.map((f) => f.id), ['a']);
      // The reschedule put next year's reminder under the same id.
      final again = plan(friends, DateTime(2026, 11, 2, 9, 30),
          pending: {dayOfId}, previous: overdue.nextState);
      expect(again.toShow, isEmpty);
    });

    test('day-of reminder delivered (no longer pending) -> not shown', () {
      final friends = [friend('a', birthdayToday)];
      final morning = plan(friends, DateTime(2026, 11, 2, 8));
      final delivered = plan(friends, DateTime(2026, 11, 2, 9, 20),
          pending: {dayBeforeId}, previous: morning.nextState);
      expect(delivered.toShow, isEmpty);
      expect(delivered.nextState.notifiedOn, containsPair('a', '2026-11-02'));
    });

    group('day-before', () {
      final birthdayTomorrow = DateTime(1990, 11, 3);
      final friends = [friend('a', birthdayTomorrow)];
      late BirthdayCatchUpState morning;
      setUp(() => morning = plan(friends, DateTime(2026, 11, 2, 8), dayBefore: true).nextState);

      test('records the scheduled day-before moment', () {
        expect(morning.scheduledDayBefore['a'], DateTime(2026, 11, 2, 9));
      });

      test('overdue and pending the same evening -> shown once', () {
        final overdue = plan(friends, evening,
            dayBefore: true, pending: {dayBeforeId}, previous: morning);
        expect(overdue.toShowDayBefore.map((f) => f.id), ['a']);
        expect(overdue.toShow, isEmpty);
        expect(overdue.nextState.notifiedDayBeforeOn, containsPair('a', '2026-11-02'));
        final again = plan(friends, evening.add(const Duration(minutes: 5)),
            dayBefore: true, pending: {dayBeforeId}, previous: overdue.nextState);
        expect(again.toShowDayBefore, isEmpty);
      });

      test('delivered -> not shown', () {
        expect(plan(friends, evening, dayBefore: true, previous: morning).toShowDayBefore,
            isEmpty);
      });

      test('after midnight of the birthday -> never shown as day-before', () {
        final result = plan(friends, DateTime(2026, 11, 3, 0, 30),
            dayBefore: true, pending: {dayBeforeId}, previous: morning);
        expect(result.toShowDayBefore, isEmpty);
        expect(result.toShow, isEmpty);
      });

      test('day-before setting off -> not shown', () {
        expect(plan(friends, evening, pending: {dayBeforeId}, previous: morning).toShowDayBefore,
            isEmpty);
      });
    });

    group('deleted and re-imported with a new id the same day', () {
      final original = friend('a', birthdayToday);
      final reimported = friend('b', birthdayToday, notificationId: 8);

      test('caught-up friend -> no second notification', () {
        final shown = plan([original], evening);
        expect(shown.toShow, hasLength(1));
        final deleted = plan([], evening, previous: shown.nextState);
        final back = plan([reimported], evening, previous: deleted.nextState);
        expect(back.toShow, isEmpty);
      });

      test('scheduled reminder fired -> no catch-up for the re-import', () {
        final morning = plan([original], DateTime(2026, 11, 2, 8));
        final deleted = plan([], evening, previous: morning.nextState);
        final back = plan([reimported], evening, previous: deleted.nextState);
        expect(back.toShow, isEmpty);
      });

      test('both in one reschedule -> no catch-up', () {
        final morning = plan([original], DateTime(2026, 11, 2, 8));
        expect(plan([reimported], evening, previous: morning.nextState).toShow, isEmpty);
      });

      test('identity ignores case and surrounding spaces', () {
        expect(original.copyWith(name: '  ANNA ').identityKey, original.identityKey);
        expect(original.identityKey, 'anna|1990-11-02');
      });
    });

    test('a different person with the same name is still caught up', () {
      final shown = plan([friend('a', birthdayToday)], evening);
      final other = friend('b', DateTime(1985, 11, 2), notificationId: 8);
      expect(plan([other], evening, previous: shown.nextState).toShow, hasLength(1));
    });

    test('markers of earlier days are pruned', () {
      final result = plan([], evening,
          previous: const BirthdayCatchUpState(notifiedOn: {'old': '2025-11-02'}));
      expect(result.nextState.notifiedOn, isEmpty);
    });
  });

  group('reminder time moved later the same day', () {
    final anna = friend('a', birthdayToday);
    final reimported = friend('b', birthdayToday, notificationId: 8);

    /// What the reschedule after [state] schedules for [f] at [now] / [minutes].
    List<DateTime> scheduled(BirthdayCatchUpState state, Friend f, DateTime now, int minutes,
        {bool dayBefore = false}) {
      return BirthdayReminderScheduler.upcomingReminders(f.birthDate, now,
          reminderMinutes: minutes,
          daysBefore: dayBefore ? 1 : 0,
          skipToday: state.isNotifiedToday(f, now, dayBefore: dayBefore));
    }

    test('catch-up shown, then time moved to 10:04 and 23:02 -> nothing today', () {
      final at = DateTime(2026, 11, 2, 9, 30);
      final shown = plan([anna], at);
      expect(shown.toShow, hasLength(1));
      expect(scheduled(shown.nextState, anna, at, 10 * 60 + 4).first.year, 2027);

      final later = DateTime(2026, 11, 2, 9, 40);
      final moved = plan([anna], later, minutes: 10 * 60 + 4, previous: shown.nextState);
      expect(moved.toShow, isEmpty);
      expect(moved.nextState.scheduledDayOf['a'], DateTime(2027, 11, 2, 10, 4));
      final again = plan([anna], DateTime(2026, 11, 2, 10, 30),
          minutes: 23 * 60 + 2, previous: moved.nextState);
      expect(scheduled(again.nextState, anna, DateTime(2026, 11, 2, 10, 30), 23 * 60 + 2),
          [DateTime(2027, 11, 2, 23, 2), DateTime(2028, 11, 2, 23, 2)]);
    });

    test('scheduled reminder fired at 09:00, then moved to 23:00 -> nothing today', () {
      final morning = plan([anna], DateTime(2026, 11, 2, 8));
      final at = DateTime(2026, 11, 2, 9, 30);
      final fired = plan([anna], at, minutes: 23 * 60, previous: morning.nextState);
      expect(fired.toShow, isEmpty);
      expect(fired.nextState.isNotifiedToday(anna, at, dayBefore: false), isTrue);
      expect(scheduled(fired.nextState, anna, at, 23 * 60),
          [DateTime(2027, 11, 2, 23), DateTime(2028, 11, 2, 23)]);
    });

    test('not notified yet, time moved later -> still scheduled today', () {
      final at = DateTime(2026, 11, 2, 8);
      final state = plan([anna], at, minutes: 23 * 60).nextState;
      expect(scheduled(state, anna, at, 23 * 60).first, DateTime(2026, 11, 2, 23));
    });

    test('re-imported (new id) after a catch-up -> nothing today', () {
      final at = DateTime(2026, 11, 2, 9, 30);
      final shown = plan([anna], at);
      final back = plan([reimported], at, minutes: 22 * 60, previous: shown.nextState);
      expect(scheduled(back.nextState, reimported, at, 22 * 60).first.year, 2027);
    });

    test('markers of yesterday do not suppress today', () {
      final state = plan([anna], DateTime(2026, 11, 1, 20)).nextState;
      expect(state.isNotifiedToday(anna, DateTime(2026, 11, 2, 8), dayBefore: false), isFalse);
    });

    group('day-before', () {
      final annaTomorrow = friend('a', DateTime(1990, 11, 3));
      final morning = DateTime(2026, 11, 2, 8);

      test('caught up, then moved later -> no second day-before today', () {
        final first = plan([annaTomorrow], morning, dayBefore: true).nextState;
        final overdue = plan([annaTomorrow], evening,
            dayBefore: true, pending: {dayBeforeId}, previous: first);
        expect(overdue.toShowDayBefore, hasLength(1));
        expect(scheduled(overdue.nextState, annaTomorrow, evening, 23 * 60, dayBefore: true),
            [DateTime(2027, 11, 2, 23), DateTime(2028, 11, 2, 23)]);
      });

      test('fired at 09:00 -> marked, nothing scheduled today', () {
        final first = plan([annaTomorrow], morning, dayBefore: true).nextState;
        final fired = plan([annaTomorrow], evening,
            dayBefore: true, minutes: 23 * 60, previous: first);
        expect(fired.toShowDayBefore, isEmpty);
        expect(fired.nextState.notifiedDayBeforeOn, containsPair('a', '2026-11-02'));
        expect(fired.nextState.scheduledDayBefore['a'], DateTime(2027, 11, 2, 23));
        expect(scheduled(fired.nextState, annaTomorrow, evening, 23 * 60, dayBefore: true)
            .first.year, 2027);
      });

      test('not shown yet -> still scheduled today; day-of tomorrow unaffected', () {
        final state = plan([annaTomorrow], morning, dayBefore: true, minutes: 23 * 60).nextState;
        expect(scheduled(state, annaTomorrow, morning, 23 * 60, dayBefore: true).first,
            DateTime(2026, 11, 2, 23));
        expect(scheduled(state, annaTomorrow, morning, 23 * 60).first, DateTime(2026, 11, 3, 23));
      });
    });
  });

  group('BirthdayCatchUp.run', () {
    // An existing (possibly empty) state: catch-up has run before.
    setUp(() => SharedPreferences.setMockInitialValues(
        {BirthdayCatchUpStore.scheduledKey: '{}'}));

    test('first run after an update only records state', () async {
      SharedPreferences.setMockInitialValues({});
      final shown = <String>[];
      await BirthdayCatchUp().run(
        friends: [friend('a', birthdayToday)],
        now: evening,
        reminderMinutes: nineAm,
        remindersEnabled: true,
        dayBeforeEnabled: true,
        pendingIds: {dayOfId},
        show: (f) async => shown.add(f.id),
        showDayBefore: (f) async => shown.add(f.id),
      );
      expect(shown, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(BirthdayCatchUpStore.scheduledKey), isTrue);
    });

    test('persists state so a later run shows nothing again', () async {
      final shown = <String>[];
      Future<void> run() => BirthdayCatchUp().run(
            friends: [friend('a', birthdayToday)],
            now: evening,
            reminderMinutes: nineAm,
            remindersEnabled: true,
            dayBeforeEnabled: false,
            pendingIds: const {},
            show: (f) async => shown.add(f.id),
            showDayBefore: (f) async => fail('no day-before expected'),
          );
      await run();
      await run();
      expect(shown, ['a']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(BirthdayCatchUpStore.notifiedKey),
          '{"a":"2026-11-02","anna|1990-11-02":"2026-11-02"}');
    });
  });

  group('BirthdayCatchUp.run day-before', () {
    test('shows an overdue pending day-before reminder via showDayBefore', () async {
      SharedPreferences.setMockInitialValues({BirthdayCatchUpStore.scheduledKey: '{}'});
      final friends = [friend('a', DateTime(1990, 11, 3))];
      final dayOf = <String>[];
      final dayBefore = <String>[];
      Future<void> run(DateTime now) => BirthdayCatchUp().run(
            friends: friends,
            now: now,
            reminderMinutes: nineAm,
            remindersEnabled: true,
            dayBeforeEnabled: true,
            pendingIds: {dayBeforeId},
            show: (f) async => dayOf.add(f.id),
            showDayBefore: (f) async => dayBefore.add(f.id),
          );
      await run(DateTime(2026, 11, 2, 8));
      await run(evening);
      await run(evening.add(const Duration(minutes: 1)));
      expect(dayBefore, ['a']);
      expect(dayOf, isEmpty);
    });
  });

  group('NotificationService channels', () {
    test('keep their ids and are named in the app language', () {
      final de = AppLocalizations(const Locale('de'));
      final birthday = NotificationService.birthdayChannel(de);
      final weekly = NotificationService.weeklyChannel(de);
      expect(birthday.id, 'birthday_reminders');
      expect(weekly.id, 'weekly_reminders');
      expect(birthday.name, 'Geburtstagserinnerungen');
      expect(weekly.description, de.translate('notification_channel_weekly_description'));
      expect(NotificationService.birthdayChannel(AppLocalizations(const Locale('en'))).name,
          'Birthday reminders');
    });
  });
}
