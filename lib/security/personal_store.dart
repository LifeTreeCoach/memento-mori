import 'package:flutter/foundation.dart';

/// Key-value store for personal data (birth date, people, Compass, ...).
///
/// Mirrors the subset of `SharedPreferences` the services use, so a service
/// can switch from plaintext preferences to the encrypted vault without
/// changing its logic. Reads are synchronous (served from memory), writes
/// are asynchronous.
abstract class PersonalStore {
  String? getString(String key);
  int? getInt(String key);
  bool? getBool(String key);
  List<String>? getStringList(String key);
  bool containsKey(String key);

  Future<bool> setString(String key, String value);
  Future<bool> setInt(String key, int value);
  Future<bool> setBool(String key, bool value);
  Future<bool> setStringList(String key, List<String> value);
  Future<bool> remove(String key);

  /// Re-reads the backing data (called by the services' `initialize()`).
  Future<void> reload();

  /// True while the latest write of some key failed (e.g. a full disk): the
  /// app shows the newest value, but it would be lost on the next start.
  /// Stores that can't fail this way keep it false.
  ValueListenable<bool> get hasUnsavedChanges => _alwaysSaved;

  /// Writes the current values of every key whose latest write failed
  /// again; true when nothing is left unsaved.
  Future<bool> retryUnsaved() async => true;

  static final ValueNotifier<bool> _alwaysSaved = ValueNotifier(false);

  static PersonalStore? _instance;

  /// The configured store.
  ///
  /// Throws a [StateError] when nothing is configured: production must never
  /// fall back to plaintext storage silently.
  static PersonalStore get instance {
    final store = _instance;
    if (store == null) {
      throw StateError(
        'PersonalStore is not configured; call PersonalStore.configure().',
      );
    }
    return store;
  }

  /// Whether [configure] has been called.
  static bool get isConfigured => _instance != null;

  static void configure(PersonalStore store) => _instance = store;

  @visibleForTesting
  static void resetForTesting() => _instance = null;
}

/// The preference keys holding personal data, i.e. everything that belongs
/// in the [PersonalStore] instead of plain `SharedPreferences`.
abstract final class PersonalKeys {
  /// `SettingsService`: the user's birth date.
  static const String birthDate = 'birth_date';

  /// `SettingsService`: the user's optional first name.
  static const String userName = 'user_name';

  /// `SettingsService`: the user's life expectancy in years.
  static const String lifeExpectancyYears = 'life_expectancy_years';

  /// `SettingsService.lifespanResultKey`: the applied estimate's result.
  static const String lifespanResult = 'lifespan_result';

  /// `FriendsService`: all people (JSON).
  static const String friendsData = 'friends_data';

  /// `CompassService.dataKey`: phases, intentions, moments (JSON).
  static const String compassData = 'compass_data';

  /// `CalendarService`: synced calendar events per person.
  static const String calendarSyncedEvents = 'calendar_synced_events';

  /// `BirthdayCatchUp` bookkeeping (who was notified when).
  static const String birthdayCatchUpShown = 'birthday_catchup_shown';
  static const String birthdayCatchUpScheduledDayOf =
      'birthday_catchup_scheduled_day_of';
  static const String birthdayCatchUpShownDayBefore =
      'birthday_catchup_shown_day_before';
  static const String birthdayCatchUpScheduledDayBefore =
      'birthday_catchup_scheduled_day_before';

  /// `ReminderFingerprints.key`: scheduled birthday notifications (names).
  static const String birthdayScheduledFingerprints =
      'birthday_scheduled_fingerprints';

  static const Set<String> all = {
    birthDate,
    userName,
    lifeExpectancyYears,
    lifespanResult,
    friendsData,
    compassData,
    calendarSyncedEvents,
    birthdayCatchUpShown,
    birthdayCatchUpScheduledDayOf,
    birthdayCatchUpShownDayBefore,
    birthdayCatchUpScheduledDayBefore,
    birthdayScheduledFingerprints,
  };
}
