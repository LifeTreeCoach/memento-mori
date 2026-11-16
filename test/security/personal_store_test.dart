import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_catch_up.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_fingerprints.dart';
import 'package:memento_mori_life_in_weeks/security/personal_store.dart';
import 'package:memento_mori_life_in_weeks/security/shared_prefs_personal_store.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PersonalStore.instance', () {
    test('throws when nothing is configured', () {
      final configured = PersonalStore.instance;
      addTearDown(() => PersonalStore.configure(configured));

      PersonalStore.resetForTesting();
      expect(PersonalStore.isConfigured, isFalse);
      expect(() => PersonalStore.instance, throwsStateError);
    });

    test('tests run with the SharedPreferences store', () {
      expect(PersonalStore.instance, isA<SharedPrefsPersonalStore>());
    });
  });

  group('SharedPrefsPersonalStore', () {
    test('reload picks up new mock values', () async {
      final store = SharedPrefsPersonalStore();
      SharedPreferences.setMockInitialValues({'user_name': 'Ada'});
      await store.reload();
      expect(store.getString('user_name'), 'Ada');

      SharedPreferences.setMockInitialValues({'user_name': 'Grace'});
      await store.reload();
      expect(store.getString('user_name'), 'Grace');
    });

    test('writes every type', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPrefsPersonalStore();
      await store.reload();
      await store.setString('s', 'x');
      await store.setInt('i', 1);
      await store.setBool('b', true);
      await store.setStringList('l', ['a']);
      expect(
        [
          store.getString('s'),
          store.getInt('i'),
          store.getBool('b'),
          store.getStringList('l'),
        ],
        [
          'x',
          1,
          true,
          ['a'],
        ],
      );
      await store.remove('s');
      expect(store.containsKey('s'), isFalse);
    });
  });

  test('PersonalKeys match the services\' keys', () {
    expect(PersonalKeys.all, hasLength(12));
    expect(
      PersonalKeys.all,
      containsAll(<String>[
        SettingsService.lifespanResultKey,
        CompassService.dataKey,
        BirthdayCatchUpStore.notifiedKey,
        BirthdayCatchUpStore.scheduledKey,
        BirthdayCatchUpStore.notifiedDayBeforeKey,
        BirthdayCatchUpStore.scheduledDayBeforeKey,
        ReminderFingerprints.key,
        'birth_date',
        'user_name',
        'life_expectancy_years',
        'friends_data',
        'calendar_synced_events',
      ]),
    );
  });
}
