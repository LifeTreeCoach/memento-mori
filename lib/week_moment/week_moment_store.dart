import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence of the weekly moment: the Settings switch, the reminder day
/// it was last shown for, and the day the feature arrived on this device
/// ([since]: no catch-up for reminders before it).
class WeekMomentStore {
  const WeekMomentStore._();

  static const String enabledKey = 'week_moment_enabled';
  static const String lastShownKey = 'week_moment_last_shown';
  static const String sinceKey = 'week_moment_since';

  /// Since date set by [resetForDiagnostics]: every reminder is after it.
  static final DateTime diagnosticsSince = DateTime(2000);

  static SharedPreferences? _prefs;

  /// Bumped on every change.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// Loads the preferences and records [sinceKey] ([today], default the
  /// clock) when it isn't stored yet.
  static Future<void> initialize({DateTime? today}) async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    if (prefs.getString(sinceKey) == null) {
      await prefs.setString(sinceKey, _format(today ?? DateTime.now()));
    }
  }

  /// The Settings switch (default on).
  static bool get enabled => _prefs?.getBool(enabledKey) ?? true;

  static Future<void> setEnabled(bool enabled) async {
    await _prefs?.setBool(enabledKey, enabled);
    _changed();
  }

  /// The reminder day the moment was last shown for (date only).
  static DateTime? get lastShown => _parse(_prefs?.getString(lastShownKey));

  /// The day the feature arrived (date only); today before [initialize].
  static DateTime get since =>
      _parse(_prefs?.getString(sinceKey)) ?? _dateOnly(DateTime.now());

  /// Records that the moment was shown for the reminder of [day].
  static Future<void> markShown(DateTime day) async {
    await _prefs?.setString(lastShownKey, _format(day));
    _changed();
  }

  /// Diagnostics: the latest reminder counts as due again.
  static Future<void> resetForDiagnostics() async {
    await _prefs?.remove(lastShownKey);
    await _prefs?.setString(sinceKey, _format(diagnosticsSince));
    _changed();
  }

  /// Forgets the cached preferences (tests).
  @visibleForTesting
  static void clearCacheForTesting() => _prefs = null;

  static void _changed() => revision.value++;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// `yyyy-MM-dd`.
  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parse(String? text) {
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    return parsed == null ? null : _dateOnly(parsed);
  }
}
