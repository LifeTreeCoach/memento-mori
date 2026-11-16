import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/lost_alarm_check.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_budget.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_fingerprints.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/scheduled_alarm_probe.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Keeps the plugin's saved pending list: scheduling adds, cancelling removes.
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final Map<int, PendingNotificationRequest> pending = {};
  final List<int> scheduled = [];

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      pending.values.toList();

  @override
  Future<void> cancel({required int id, String? tag}) async => pending.remove(id);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #zonedSchedule) {
      final args = invocation.namedArguments;
      final id = args[#id] as int;
      scheduled.add(id);
      pending[id] = PendingNotificationRequest(
          id, args[#title] as String?, args[#body] as String?, args[#payload] as String?);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

/// The OS alarms: armed ids, or a failing platform.
class _FakeProbe implements ScheduledAlarmProbe {
  final Set<int> armed;
  final bool fails;
  final List<int> asked = [];

  _FakeProbe(this.armed, {this.fails = false});

  @override
  Future<bool> hasScheduledAlarm(int id) async {
    asked.add(id);
    if (fails) throw PlatformException(code: 'error');
    return armed.contains(id);
  }
}

Friend _friend(int n, String name, DateTime birthDate) => Friend(
      id: 'f$n',
      name: name,
      birthDate: birthDate,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
      notificationId: n,
    );

void main() {
  final now = DateTime(2026, 3, 1, 12);
  final friends = [
    _friend(1, 'Anna', DateTime(1990, 5, 10)),
    _friend(2, 'Ben', DateTime(1985, 8, 20)),
  ];
  late _FakePlugin plugin;

  BirthdayReminderScheduler scheduler() =>
      BirthdayReminderScheduler(plugin, ReminderFingerprints(), ReminderPlatform.android);

  LostAlarmCheck check(_FakeProbe probe) =>
      LostAlarmCheck(probe: probe, pendingIds: scheduler().pendingReminderIds);

  setUpAll(() => tz.setLocalLocation(tz.UTC));

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await SettingsService.initialize();
    await FriendsService.setBirthdayNotificationsEnabled(true);
    plugin = _FakePlugin();
    await scheduler().rescheduleAll(friends, now: now);
    plugin.scheduled.clear();
  });

  test('force stop (pending list kept, alarms gone): cleared, then all re-armed', () async {
    final expected = plugin.pending.keys.toSet();
    final probe = _FakeProbe({});
    expect(await check(probe).run(), isTrue);
    expect(probe.asked, hasLength(1));
    expect(await ReminderFingerprints().load(), isNull);

    await scheduler().rescheduleAll(friends, now: now);
    expect(plugin.scheduled.toSet(), expected);
  });

  test('alarms present: fingerprints kept, nothing rescheduled', () async {
    final stored = await ReminderFingerprints().load();
    final probe = _FakeProbe(plugin.pending.keys.toSet());
    expect(await check(probe).run(), isFalse);
    expect(probe.asked, hasLength(LostAlarmCheck.maxProbes));
    expect(probe.asked, orderedEquals([...probe.asked]..sort()));
    expect(await ReminderFingerprints().load(), stored);

    await scheduler().rescheduleAll(friends, now: now);
    expect(plugin.scheduled, isEmpty);
  });

  test('one missing alarm among the probed ones is enough', () async {
    final ids = plugin.pending.keys.toList()..sort();
    final probe = _FakeProbe(ids.toSet()..remove(ids[1]));
    expect(await check(probe).run(), isTrue);
    expect(await ReminderFingerprints().load(), isNull);
  });

  test('a platform error changes nothing', () async {
    final stored = await ReminderFingerprints().load();
    expect(await check(_FakeProbe({}, fails: true)).run(), isFalse);
    expect(await ReminderFingerprints().load(), stored);
  });

  test('without fingerprints or pending reminders nothing is probed', () async {
    final probe = _FakeProbe({});
    plugin.pending.clear();
    expect(await check(probe).run(), isFalse);
    await ReminderFingerprints().clear();
    expect(await check(probe).run(), isFalse);
    expect(probe.asked, isEmpty);
  });

  group('ReminderService.forgetScheduledRemindersIfAlarmsLost', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('runs the check on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final probe = _FakeProbe({});
      expect(await ReminderService.forgetScheduledRemindersIfAlarmsLost(check: check(probe)), isTrue);
      expect(await ReminderFingerprints().load(), isNull);
    });

    test('is a no-op on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final probe = _FakeProbe({});
      expect(await ReminderService.forgetScheduledRemindersIfAlarmsLost(check: check(probe)), isFalse);
      expect(probe.asked, isEmpty);
      expect(await ReminderFingerprints().load(), isNotNull);
    });
  });

  test('the channel probe passes the id as a plain int', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannelScheduledAlarmProbe.channel, (call) async {
      calls.add(call);
      return false;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannelScheduledAlarmProbe.channel, null));
    expect(await const MethodChannelScheduledAlarmProbe().hasScheduledAlarm(100004), isFalse);
    expect(calls.single.method, 'hasScheduledAlarm');
    expect(calls.single.arguments, 100004);
  });
}
