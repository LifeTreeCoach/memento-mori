import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';

/// Answers [pendingNotificationRequests] and records cancels.
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final List<PendingNotificationRequest> pending;
  final List<int> cancelled = [];

  _FakePlugin(this.pending);

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async => pending;

  @override
  Future<void> cancel({required int id, String? tag}) async => cancelled.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final plugin = _FakePlugin(const [
    PendingNotificationRequest(100028, 't', 'b', 'birthday:a'),
    PendingNotificationRequest(100029, 't', 'b', 'birthday:a'),
    PendingNotificationRequest(1, 't', 'b', 'weekly_reminder'),
    PendingNotificationRequest(99999, 't', 'b', 'birthday-test:a'),
  ]);

  test('pendingReminderIds lists only scheduled birthday reminders', () async {
    expect(await BirthdayReminderScheduler(plugin).pendingReminderIds(), {100028, 100029});
  });

  test('cancelAll cancels exactly those', () async {
    await BirthdayReminderScheduler(plugin).cancelAll();
    expect(plugin.cancelled, [100028, 100029]);
  });
}
