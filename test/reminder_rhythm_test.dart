import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _init(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  await SettingsService.initialize();
  return SharedPreferences.getInstance();
}

void main() {
  group('ReminderRhythm ids', () {
    test('round-trip and unknown ids', () {
      for (final rhythm in ReminderRhythm.values) {
        expect(ReminderRhythm.fromId(rhythm.id), rhythm);
      }
      expect(ReminderRhythm.fromId('hourly'), isNull);
      expect(ReminderRhythm.fromId(null), isNull);
    });

    test('isOn', () {
      expect(ReminderRhythm.weekly.isOn, isTrue);
      expect(ReminderRhythm.every4Weeks.isOn, isTrue);
      expect(ReminderRhythm.off.isOn, isFalse);
    });
  });

  group('migration from the weekly switch', () {
    test('nothing stored -> weekly', () async {
      await _init({});
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.weekly);
      expect(SettingsService.isWeeklyReminderEnabled(), isTrue);
    });

    test('switch on -> weekly', () async {
      await _init({'weekly_reminder_enabled': true});
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.weekly);
    });

    test('switch off -> off', () async {
      await _init({'weekly_reminder_enabled': false});
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.off);
      expect(SettingsService.isWeeklyReminderEnabled(), isFalse);
    });

    test('a stored rhythm wins over the switch', () async {
      await _init({
        'weekly_reminder_enabled': false,
        'compass_reminder_rhythm': 'every_4_weeks',
      });
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.every4Weeks);
    });

    test('an unknown stored rhythm falls back to the switch', () async {
      await _init({
        'weekly_reminder_enabled': false,
        'compass_reminder_rhythm': 'hourly',
      });
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.off);
    });
  });

  group('setReminderRhythm', () {
    test('keeps the legacy switch in sync', () async {
      final prefs = await _init({});
      await SettingsService.setReminderRhythm(ReminderRhythm.off);
      expect(prefs.getBool('weekly_reminder_enabled'), isFalse);
      expect(prefs.getString('compass_reminder_rhythm'), 'off');
      await SettingsService.setReminderRhythm(ReminderRhythm.every4Weeks,
          today: DateTime(2026, 11, 6));
      expect(prefs.getBool('weekly_reminder_enabled'), isTrue);
      await SettingsService.setReminderRhythm(ReminderRhythm.weekly);
      expect(prefs.getBool('weekly_reminder_enabled'), isTrue);
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.weekly);
    });

    test('anchors every 4 weeks once', () async {
      final prefs = await _init({});
      await SettingsService.setReminderRhythm(ReminderRhythm.weekly,
          today: DateTime(2026, 1, 1));
      expect(SettingsService.getRhythmAnchor(), isNull);

      await SettingsService.setReminderRhythm(ReminderRhythm.every4Weeks,
          today: DateTime(2026, 11, 6, 18, 30));
      expect(prefs.getString('compass_rhythm_anchor'), '2026-11-06');
      expect(SettingsService.getRhythmAnchor(), DateTime(2026, 11, 6));

      await SettingsService.setReminderRhythm(ReminderRhythm.off);
      await SettingsService.setReminderRhythm(ReminderRhythm.every4Weeks,
          today: DateTime(2027, 2, 1));
      expect(SettingsService.getRhythmAnchor(), DateTime(2026, 11, 6));
    });

    test('an unreadable anchor counts as missing', () async {
      await _init({'compass_rhythm_anchor': 'not a date'});
      expect(SettingsService.getRhythmAnchor(), isNull);
    });
  });

  group('legacy setWeeklyReminderEnabled', () {
    test('true -> weekly, false -> off', () async {
      final prefs = await _init({'weekly_reminder_enabled': false});
      SettingsService.setWeeklyReminderEnabled(true);
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.weekly);
      expect(prefs.getBool('weekly_reminder_enabled'), isTrue);
      SettingsService.setWeeklyReminderEnabled(false);
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.off);
      expect(prefs.getBool('weekly_reminder_enabled'), isFalse);
    });

    test('true keeps every 4 weeks', () async {
      await _init({'compass_reminder_rhythm': 'every_4_weeks'});
      SettingsService.setWeeklyReminderEnabled(true);
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.every4Weeks);
    });
  });
}
