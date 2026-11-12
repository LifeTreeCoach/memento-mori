import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('ReminderService.sampleFriend (diagnostics test reminder)', () {
    test('has a birthday today, so the text is consistent', () {
      final now = DateTime(2026, 11, 4, 15);
      final sample = ReminderService.sampleFriend(now);
      expect(sample.isBirthdayToday(today: now), isTrue);
      final age = BirthdayReminderScheduler.ageOnBirthdayFor(sample.birthDate, now, 0);
      final content = BirthdayReminderScheduler.buildContent(
          sample, age, AppLocalizations(const Locale('en')));
      expect(content.body, 'Alex turns 30 today 🎂');
    });
  });

  group('ReminderService.nextWeeklyReminderTime', () {
    tz.TZDateTime at(int y, int m, int d, [int h = 0]) => tz.TZDateTime(tz.UTC, y, m, d, h);

    test('from a Monday -> upcoming Sunday 19:00', () {
      expect(ReminderService.nextWeeklyReminderTime(at(2026, 11, 2, 10)), at(2026, 11, 8, 19));
    });

    test('Sunday before 19:00 -> same day', () {
      expect(ReminderService.nextWeeklyReminderTime(at(2026, 11, 8, 18)), at(2026, 11, 8, 19));
    });

    test('Sunday after 19:00 -> next Sunday', () {
      expect(ReminderService.nextWeeklyReminderTime(at(2026, 11, 8, 20)), at(2026, 11, 15, 19));
    });
  });

  group('ReminderService rhythm', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({'weekly_reminder_enabled': false});
      await SettingsService.initialize();
    });

    test('reads the legacy switch as the rhythm', () {
      expect(ReminderService.rhythm(), ReminderRhythm.off);
      expect(ReminderService.isReminderEnabled(), isFalse);
    });

    test('setRhythm stores the choice even if scheduling fails', () async {
      // No notification plugin in unit tests: scheduling throws and is logged.
      await ReminderService.setRhythm(ReminderRhythm.every4Weeks);
      expect(ReminderService.rhythm(), ReminderRhythm.every4Weeks);
      expect(ReminderService.isReminderEnabled(), isTrue);
      expect(SettingsService.getRhythmAnchor(), isNotNull);
      await ReminderService.setRhythm(ReminderRhythm.weekly);
      expect(ReminderService.rhythm(), ReminderRhythm.weekly);
    });
  });

  group('ReminderService.immediateCompassReminder (diagnostics)', () {
    final now = tz.TZDateTime(tz.UTC, 2026, 11, 4, 10);

    Future<void> init(ReminderRhythm rhythm) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'language': 'de',
        'birth_date': DateTime(1990, 1, 1).toIso8601String(),
        'compass_reminder_rhythm': rhythm.id,
        'weekly_reminder_enabled': rhythm.isOn,
      });
      await SettingsService.initialize();
      CompassService.clearCacheForTesting();
      await CompassService.initialize();
    }

    Future<void> seedPhaseWithTask() async {
      await CompassService.startPhase(
          name: 'Umbruch', start: DateTime(2026, 10, 1), today: now);
      await CompassService.addIntention(
          title: 'Bewerbung schreiben',
          kind: IntentionKind.doTask,
          today: now);
    }

    test('every 4 weeks: the phase check-in with the open task', () async {
      await init(ReminderRhythm.every4Weeks);
      await seedPhaseWithTask();
      final reminder = ReminderService.immediateCompassReminder(now);
      expect(reminder.id, NotificationIds.immediateCompassQuestion);
      expect(reminder.title, 'Kompass · Check-in');
      expect(reminder.body,
          'Wie geht es mit „Bewerbung schreiben“ voran? Und was war in '
          'deiner Phase „Umbruch“ zuletzt gut?');
    });

    test('every 4 weeks without open tasks: asks about the phase', () async {
      await init(ReminderRhythm.every4Weeks);
      await CompassService.startPhase(
          name: 'Umbruch', start: DateTime(2026, 10, 1), today: now);
      expect(ReminderService.immediateCompassReminder(now).body,
          'Wo stehst du in deiner Phase „Umbruch“ – und was war gut?');
    });

    test('weekly: this week\'s Compass question', () async {
      await init(ReminderRhythm.weekly);
      await seedPhaseWithTask();
      final reminder = ReminderService.immediateCompassReminder(now);
      final weekly = WeeklyReflectionPlanner.reflectionAt(now,
          id: NotificationIds.immediateCompassQuestion,
          birthDate: DateTime(1990, 1, 1),
          gentleOnly: false,
          l10n: AppLocalizations(const Locale('de')),
          swapped: false);
      expect(reminder.title, weekly.title);
      expect(reminder.body, weekly.body);
      expect(reminder.title, isNot('Kompass · Check-in'));
    });

    test('weekly: phase questions name the current phase', () async {
      await init(ReminderRhythm.weekly);
      await CompassService.startPhase(
          name: 'Umbruch', start: DateTime(2026, 10, 1), today: now);
      final bodies = [
        for (var w = 0; w < 16; w++)
          ReminderService.immediateCompassReminder(
                  now.add(Duration(days: 7 * w)))
              .body,
      ];
      expect(bodies.where((b) => b.contains('„Umbruch“')), isNotEmpty);
      expect(bodies.where((b) => b.contains('{')), isEmpty);
    });
  });
}
