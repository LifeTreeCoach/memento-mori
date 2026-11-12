/// Every notification id the app uses, in non-overlapping ranges:
///
/// | id                     | notification                                    |
/// |------------------------|-------------------------------------------------|
/// | 1                      | legacy repeating weekly reflection (cancelled)  |
/// | 10 .. 13               | weekly reflection with the Compass question     |
/// |                        | (next 4 Sundays, one-off each), or the phase    |
/// |                        | check-in every 4 weeks (10 .. 12; never both)   |
/// | 50000 .. 89999         | birthday shown immediately (one per friend)     |
/// | 90000                  | "test notification" shown immediately           |
/// | 90001                  | diagnostics: Compass question shown immediately |
/// | 90002                  | scheduled "open the app" birthday refresh       |
/// | 99999                  | diagnostics: scheduled test birthday reminder   |
/// | 100000 ..              | scheduled birthday reminders (4 per friend)     |
class NotificationIds {
  NotificationIds._();

  /// The weekly reflection used to be one repeating notification with
  /// this id; it is only cancelled now (migration).
  static const int weeklyReminder = 1;

  /// One-off weekly reflections, one id per upcoming occurrence.
  static const int weeklyReflectionStart = 10;
  static const int weeklyReflectionCount = 4;

  static const int immediateBirthdayStart = 50000;
  static const int immediateBirthdayCount = 40000;

  static const int immediateTest = 90000;
  static const int immediateCompassQuestion = 90001;

  /// The "open the app so the next birthday reminders get planned" note,
  /// scheduled after the last reminder that fit the OS budget.
  static const int birthdayRefresh = 90002;

  static const int scheduledBirthdayStart = 100000;
  static const int scheduledBirthdayTest = scheduledBirthdayStart - 1;

  /// Id of the immediate birthday notification for the friend with
  /// [friendNotificationId] (stable per friend, inside its own range).
  static int immediateBirthday(int friendNotificationId) =>
      immediateBirthdayStart +
      friendNotificationId.abs() % immediateBirthdayCount;
}
