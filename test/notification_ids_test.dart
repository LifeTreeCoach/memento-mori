import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';

void main() {
  group('NotificationIds', () {
    const immediateEnd = NotificationIds.immediateBirthdayStart +
        NotificationIds.immediateBirthdayCount; // exclusive

    bool inImmediateRange(int id) =>
        id >= NotificationIds.immediateBirthdayStart && id < immediateEnd;

    test('ranges are ordered and do not overlap', () {
      const weeklyEnd = NotificationIds.weeklyReflectionStart +
          NotificationIds.weeklyReflectionCount; // exclusive
      expect(ReminderService.weeklyReminderId,
          lessThan(NotificationIds.weeklyReflectionStart));
      expect(weeklyEnd, lessThanOrEqualTo(NotificationIds.immediateBirthdayStart));
      expect(NotificationIds.immediateCompassQuestion,
          greaterThan(NotificationIds.immediateTest));
      expect(NotificationIds.immediateCompassQuestion,
          lessThan(NotificationIds.scheduledBirthdayTest));
      expect(NotificationIds.immediateTest, greaterThanOrEqualTo(immediateEnd));
      expect(NotificationIds.immediateTest,
          lessThan(NotificationIds.scheduledBirthdayTest));
      expect(BirthdayReminderScheduler.testNotificationId,
          lessThan(BirthdayReminderScheduler.idRangeStart));
    });

    test('the birthday refresh note has its own id outside every range', () {
      const id = NotificationIds.birthdayRefresh;
      expect(BirthdayReminderScheduler.refreshNotificationId, id);
      expect(inImmediateRange(id), isFalse);
      expect(id, greaterThan(NotificationIds.weeklyReflectionStart +
          NotificationIds.weeklyReflectionCount));
      expect(id, lessThan(NotificationIds.scheduledBirthdayTest));
      expect(id, isNot(anyOf(NotificationIds.immediateTest,
          NotificationIds.immediateCompassQuestion, ReminderService.weeklyReminderId)));
    });

    test('immediate birthday ids stay inside their range', () {
      for (final friendId in [0, 1, 2, 39999, 40000, 123456789, -5]) {
        final id = NotificationIds.immediateBirthday(friendId);
        expect(inImmediateRange(id), isTrue, reason: 'friend $friendId -> $id');
      }
    });

    test('scheduled birthday ids never reach the lower ranges', () {
      for (final friendId in [0, 1, 1000]) {
        for (final dayBefore in [false, true]) {
          final id = BirthdayReminderScheduler.notificationIdFor(friendId,
              yearOffset: 1, dayBefore: dayBefore);
          expect(id, greaterThanOrEqualTo(NotificationIds.scheduledBirthdayStart));
        }
      }
    });
  });
}
