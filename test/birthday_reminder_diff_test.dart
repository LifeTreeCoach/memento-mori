import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_budget.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_fingerprints.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Keeps pending requests like the real plugin: scheduling an id replaces
/// it, cancelling removes it. Records every schedule and cancel.
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final Map<int, PendingNotificationRequest> pending = {};
  final Map<int, tz.TZDateTime> fireTimes = {};
  final Map<int, NotificationDetails> details = {};
  final List<int> scheduled = [];
  final List<int> cancelled = [];

  void resetCalls() {
    scheduled.clear();
    cancelled.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      pending.values.toList();

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #zonedSchedule) {
      final args = invocation.namedArguments;
      final id = args[#id] as int;
      scheduled.add(id);
      fireTimes[id] = args[#scheduledDate] as tz.TZDateTime;
      details[id] = args[#notificationDetails] as NotificationDetails;
      pending[id] = PendingNotificationRequest(
          id, args[#title] as String?, args[#body] as String?, args[#payload] as String?);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

Friend _friend(int n, DateTime birthDate, {String? name}) => Friend(
      id: 'f$n',
      name: name ?? 'Friend $n',
      birthDate: birthDate,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
      notificationId: n,
    );

int _id(int n, {int yearOffset = 0}) =>
    BirthdayReminderScheduler.notificationIdFor(n, yearOffset: yearOffset);

void main() {
  final now = DateTime(2026, 3, 1, 12);
  late _FakePlugin plugin;

  BirthdayReminderScheduler scheduler([ReminderPlatform platform = ReminderPlatform.android]) =>
      BirthdayReminderScheduler(plugin, ReminderFingerprints(), platform);

  setUpAll(() => tz.setLocalLocation(tz.UTC));

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await SettingsService.initialize();
    await FriendsService.setBirthdayNotificationsEnabled(true);
    plugin = _FakePlugin();
  });

  final anna = _friend(1, DateTime(1990, 5, 10), name: 'Anna');
  final ben = _friend(2, DateTime(1985, 8, 20), name: 'Ben');

  test('first run without fingerprints replaces everything pending', () async {
    plugin.pending[_id(9)] = const PendingNotificationRequest(100036, 't', 'b', 'birthday:old');
    await scheduler().rescheduleAll([anna, ben], now: now);
    expect(plugin.cancelled, [_id(9)]);
    expect(plugin.scheduled.toSet(), {_id(1), _id(1, yearOffset: 1), _id(2), _id(2, yearOffset: 1)});
    expect(plugin.fireTimes[_id(1)], tz.TZDateTime.utc(2026, 5, 10, 9));
  });

  test('scheduled reminders are grouped in the iOS birthdays thread', () async {
    await scheduler(ReminderPlatform.ios).rescheduleAll([anna], now: now);
    expect(plugin.details[_id(1)]!.iOS!.threadIdentifier, 'birthdays');
    expect(plugin.details[_id(1)]!.android!.channelId, 'birthday_reminders');
  });

  test('an unchanged second run touches nothing', () async {
    await scheduler().rescheduleAll([anna, ben], now: now);
    plugin.resetCalls();
    await scheduler().rescheduleAll([anna, ben], now: now);
    expect(plugin.scheduled, isEmpty);
    expect(plugin.cancelled, isEmpty);
  });

  test('a renamed friend reschedules only their reminders', () async {
    await scheduler().rescheduleAll([anna, ben], now: now);
    plugin.resetCalls();
    final renamed = anna.copyWith(name: 'Annie');
    await scheduler().rescheduleAll([renamed, ben], now: now);
    expect(plugin.scheduled.toSet(), {_id(1), _id(1, yearOffset: 1)});
    expect(plugin.cancelled, isEmpty);
    expect(plugin.pending[_id(1)]!.title, contains('Annie'));
  });

  test('a removed friend cancels only their reminders', () async {
    await scheduler().rescheduleAll([anna, ben], now: now);
    plugin.resetCalls();
    await scheduler().rescheduleAll([anna], now: now);
    expect(plugin.cancelled.toSet(), {_id(2), _id(2, yearOffset: 1)});
    expect(plugin.scheduled, isEmpty);
  });

  test('a reminder no longer pending (delivered, cleared) is scheduled again', () async {
    await scheduler().rescheduleAll([anna, ben], now: now);
    plugin.pending.remove(_id(2));
    plugin.resetCalls();
    await scheduler().rescheduleAll([anna, ben], now: now);
    expect(plugin.scheduled, [_id(2)]);
    expect(plugin.cancelled, isEmpty);
  });

  test('fingerprints present but nothing pending (alarms gone): all scheduled', () async {
    await scheduler().rescheduleAll([anna, ben], now: now);
    final expected = plugin.pending.keys.toSet();
    plugin.pending.clear();
    plugin.resetCalls();
    await scheduler().rescheduleAll([anna, ben], now: now);
    expect(plugin.scheduled.toSet(), expected);
    expect(plugin.cancelled, isEmpty);
  });

  test('restored data: cleared fingerprints replace the stale pending list', () async {
    // Restored preferences: fingerprints and the plugin's list both claim
    // reminders that the OS never restored.
    await scheduler().rescheduleAll([anna, ben], now: now);
    final expected = plugin.pending.keys.toSet();
    plugin.resetCalls();
    await ReminderFingerprints().clear();
    await scheduler().rescheduleAll([anna, ben], now: now);
    expect(plugin.cancelled.toSet(), expected);
    expect(plugin.scheduled.toSet(), expected);
  });

  test('a passed reminder moves to the next year (time changed)', () async {
    await scheduler().rescheduleAll([anna], now: now);
    plugin.resetCalls();
    await scheduler().rescheduleAll([anna], now: DateTime(2026, 5, 10, 10));
    expect(plugin.scheduled.toSet(), {_id(1), _id(1, yearOffset: 1)});
    expect(plugin.fireTimes[_id(1)], tz.TZDateTime.utc(2027, 5, 10, 9));
  });

  test('corrupt fingerprints fall back to a full reschedule', () async {
    await scheduler().rescheduleAll([anna, ben], now: now);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ReminderFingerprints.key, 'not json');
    plugin.resetCalls();
    await scheduler().rescheduleAll([anna, ben], now: now);
    expect(plugin.cancelled.toSet(), plugin.pending.keys.toSet());
    expect(plugin.scheduled, hasLength(4));
  });

  test('other notifications are never touched', () async {
    plugin.pending[NotificationIds.weeklyReflectionStart] =
        const PendingNotificationRequest(10, 't', 'b', 'compass');
    plugin.pending[NotificationIds.scheduledBirthdayTest] =
        const PendingNotificationRequest(99999, 't', 'b', 'birthday-test:test');
    await scheduler().rescheduleAll([anna], now: now);
    await FriendsService.setBirthdayNotificationsEnabled(false);
    await scheduler().rescheduleAll([anna], now: now);
    expect(plugin.pending.keys.toSet(),
        {NotificationIds.weeklyReflectionStart, NotificationIds.scheduledBirthdayTest});
  });

  test('turning reminders off cancels every birthday reminder', () async {
    await scheduler().rescheduleAll([anna, ben], now: now);
    await FriendsService.setBirthdayNotificationsEnabled(false);
    plugin.resetCalls();
    await scheduler().rescheduleAll([anna, ben], now: now);
    expect(plugin.cancelled, hasLength(4));
    expect(plugin.pending, isEmpty);
  });

  group('budget', () {
    final many = [
      for (var i = 1; i <= 300; i++) _friend(i, DateTime(1970 + i % 40, 1 + i % 12, 1 + i % 28)),
    ];

    test('300 friends: at most 400 pending on Android, 59 on iOS', () async {
      await SettingsService.setBirthdayDayBeforeReminderEnabled(true);
      await scheduler().rescheduleAll(many, now: now);
      expect(plugin.pending, hasLength(400));

      plugin = _FakePlugin();
      await scheduler(ReminderPlatform.ios).rescheduleAll(many, now: now);
      expect(plugin.pending, hasLength(59));
    });

    test('the refresh note follows the last kept reminder', () async {
      final plan = await scheduler(ReminderPlatform.ios).rescheduleAll(many, now: now);
      final refresh = plugin.pending[BirthdayReminderScheduler.refreshNotificationId]!;
      expect(refresh.payload, BirthdayReminderScheduler.refreshPayload);
      expect(refresh.body, contains('Open Memento Mori'));
      final last = plan.kept.last.at;
      expect(plugin.fireTimes[BirthdayReminderScheduler.refreshNotificationId],
          tz.TZDateTime.utc(last.year, last.month, last.day, last.hour, last.minute + 1));
      // Not a birthday reminder for the catch-up.
      expect(await scheduler().pendingReminderIds(),
          isNot(contains(BirthdayReminderScheduler.refreshNotificationId)));
    });

    test('the refresh note goes once everything fits again', () async {
      await scheduler(ReminderPlatform.ios).rescheduleAll(many, now: now);
      plugin.resetCalls();
      await scheduler(ReminderPlatform.ios).rescheduleAll([anna], now: now);
      expect(plugin.cancelled, contains(BirthdayReminderScheduler.refreshNotificationId));
      expect(plugin.pending.keys.toSet(), {_id(1), _id(1, yearOffset: 1)});
    });
  });
}
