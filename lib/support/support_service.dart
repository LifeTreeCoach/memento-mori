import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/support/support_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence of the support prompt schedule ([SupportPrompt]).
///
/// Never a notification: the prompt is only a card on the Life tab, and
/// never in the session that recorded the first use.
class SupportService {
  const SupportService._();

  static const String firstUseKey = 'first_use_date';
  static const String lastShownKey = 'support_last_shown';
  static const String optOutKey = 'support_opt_out';
  static const String doneKey = 'support_done';

  static SharedPreferences? _prefs;

  /// True in the session that recorded [firstUseKey] (first launch, or the
  /// first launch after the update that introduced it).
  static bool _firstSession = false;

  /// Set from Diagnostics: shows the card now, ignoring the schedule.
  static bool _forced = false;

  /// Bumped on every change, so the Life tab can show or hide the card.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// Loads the preferences and records the first use ([today], default
  /// the clock) when it isn't stored yet.
  static Future<void> initialize({DateTime? today}) async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    _forced = false;
    _firstSession = prefs.getString(firstUseKey) == null;
    if (_firstSession) {
      await prefs.setString(firstUseKey, _format(today ?? DateTime.now()));
    }
  }

  static DateTime? get firstUse => _parse(_prefs?.getString(firstUseKey));
  static DateTime? get lastShown => _parse(_prefs?.getString(lastShownKey));
  static bool get optedOut => _prefs?.getBool(optOutKey) ?? false;
  static bool get alreadySupported => _prefs?.getBool(doneKey) ?? false;

  /// Whether the Life tab shows the card on [today].
  static bool isDue(DateTime today) {
    if (_forced) return true;
    final start = firstUse;
    if (start == null || _firstSession) return false;
    return SupportPrompt.isDue(
      today: today,
      firstUse: start,
      lastShown: lastShown,
      optedOut: optedOut,
      alreadySupported: alreadySupported,
    );
  }

  /// "Support" or "Not now": the card waits for the next milestone.
  static Future<void> markShown(DateTime today) async {
    _forced = false;
    await _prefs?.setString(lastShownKey, _format(today));
    _changed();
  }

  /// "I already did, thanks": no more prompts.
  static Future<void> markSupported(DateTime today) async {
    _forced = false;
    await _prefs?.setBool(doneKey, true);
    await _prefs?.setString(lastShownKey, _format(today));
    _changed();
  }

  /// The Settings switch "Remind me now and then": on unless opted out or
  /// "I already did, thanks" was chosen (no prompt will come either way).
  static bool get remindersEnabled => !optedOut && !alreadySupported;

  /// Sets the Settings switch; turning it on also clears "already did",
  /// so the card comes back at the next milestone.
  static Future<void> setRemindersEnabled(bool enabled) async {
    await _prefs?.setBool(optOutKey, !enabled);
    if (enabled) await _prefs?.remove(doneKey);
    _changed();
  }

  /// Diagnostics: show the card now.
  static void showNow() {
    _forced = true;
    _changed();
  }

  /// Diagnostics: start the schedule over from [today].
  static Future<void> resetSchedule(DateTime today) async {
    final prefs = _prefs;
    _forced = false;
    if (prefs != null) {
      await prefs.setString(firstUseKey, _format(today));
      await prefs.remove(lastShownKey);
      await prefs.remove(optOutKey);
      await prefs.remove(doneKey);
    }
    _changed();
  }

  static void _changed() => revision.value++;

  /// `yyyy-MM-dd`.
  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parse(String? text) {
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    return parsed == null ? null : SupportPrompt.dateOnly(parsed);
  }
}
