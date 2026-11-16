import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart'
    show encodeCompassDate, tryDecodeCompassDate;
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result.dart';
import 'package:memento_mori_life_in_weeks/security/personal_store.dart';

/// App settings. Personal values (birth date, name, life expectancy,
/// lifespan result) live in the [PersonalStore]; everything else in plain
/// `SharedPreferences`.
class SettingsService {
  static late SharedPreferences _prefs;

  static PersonalStore get _personal => PersonalStore.instance;

  /// Decoded [getVisualizationSettings], dropped on every save.
  static VisualizationSettings? _visualizationSettings;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _personal.reload();
    _visualizationSettings = null;
  }

  static DateTime? getBirthDate() {
    String? dateStr = _personal.getString(PersonalKeys.birthDate);
    if (dateStr != null) return DateTime.parse(dateStr);
    return null;
  }

  static void setBirthDate(DateTime date) {
    _personal.setString(PersonalKeys.birthDate, date.toIso8601String());
  }

  /// Stored language, or the device language if the user never chose one.
  static String getLanguage() {
    return _prefs.getString('language') ??
        languageForLocale(PlatformDispatcher.instance.locale.languageCode);
  }

  /// The device language when the app supports it, otherwise 'en'.
  static String languageForLocale(String languageCode) {
    return AppLocalizations.supportedLanguages.contains(languageCode)
        ? languageCode
        : 'en';
  }

  static void setLanguage(String language) {
    _prefs.setString('language', language);
  }

  static String getDisplayMode() {
    return _prefs.getString('display_mode') ?? 'weeks'; // Standard ist Wochen
  }

  static void setDisplayMode(String mode) {
    _prefs.setString('display_mode', mode);
  }

  /// Expected lifespan in years used for all life calculations
  /// (default [LifeCalculator.defaultLifeExpectancyYears]).
  static int getLifeExpectancyYears() {
    return _personal.getInt(PersonalKeys.lifeExpectancyYears) ??
        LifeCalculator.defaultLifeExpectancyYears;
  }

  static Future<void> setLifeExpectancyYears(int years) async {
    await _personal.setInt(PersonalKeys.lifeExpectancyYears, years);
  }

  /// Unit the home-screen widget counts down in: weeks, months, years or days.
  /// Separate from [getDisplayMode], which only supports weeks/months/years.
  static String getWidgetDisplayMode() {
    return _prefs.getString('widget_display_mode') ?? 'weeks';
  }

  static Future<void> setWidgetDisplayMode(String mode) async {
    await _prefs.setString('widget_display_mode', mode);
  }

  /// Visual style of the app/widget: stoic or warm.
  static String getThemeStyle() {
    return _prefs.getString('theme_style') ?? ThemeStyle.stoic.id;
  }

  static Future<void> setThemeStyle(String style) async {
    await _prefs.setString('theme_style', style);
  }

  /// Brightness preference: system, light or dark. Light until the user
  /// picks one (onboarding toggle or Settings); a stored choice wins.
  static String getBrightness() {
    return _prefs.getString('brightness') ?? defaultBrightness.id;
  }

  /// Brightness used until the user chooses one.
  static const AppBrightness defaultBrightness = AppBrightness.light;

  static Future<void> setBrightness(String brightness) async {
    await _prefs.setString('brightness', brightness);
  }

  static String getColorTheme() {
    // The theme style's own grid palette unless the user picked a colour theme.
    return _prefs.getString('color_theme') ?? ColorThemes.styleDefaultId;
  }

  static void setColorTheme(String themeId) {
    _prefs.setString('color_theme', themeId);
  }

  static VisualizationSettings getVisualizationSettings() {
    return _visualizationSettings ??= _readVisualizationSettings();
  }

  static VisualizationSettings _readVisualizationSettings() {
    final settingsJson = _prefs.getString('visualization_settings');
    if (settingsJson == null) return const VisualizationSettings();
    final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
    return VisualizationSettings.fromMap(settingsMap);
  }

  static void setVisualizationSettings(VisualizationSettings settings) {
    _visualizationSettings = settings;
    _prefs.setString('visualization_settings', jsonEncode(settings.toMap()));
  }

  static String getUserName() {
    return _personal.getString(PersonalKeys.userName) ?? '';
  }

  static void setUserName(String name) {
    _personal.setString(PersonalKeys.userName, name);
  }

  static bool hasCompletedOnboarding() {
    return _prefs.getBool('onboarding_completed') ?? false;
  }

  static void setOnboardingCompleted(bool completed) {
    _prefs.setBool('onboarding_completed', completed);
  }

  /// Set once the first-launch logo was shown (or skipped for people who
  /// had onboarded before it existed); never reset, not even by
  /// "Start fresh", so the logo appears only on the very first launch.
  static const String introLogoShownKey = 'intro_logo_shown';

  static bool hasShownIntroLogo() => _prefs.getBool(introLogoShownKey) ?? false;

  static Future<void> setIntroLogoShown() =>
      _prefs.setBool(introLogoShownKey, true);

  static const String weeklyReminderEnabledKey = 'weekly_reminder_enabled';
  static const String reminderRhythmKey = 'compass_reminder_rhythm';
  static const String rhythmAnchorKey = 'compass_rhythm_anchor';

  /// Whether any Compass reminder is on (legacy switch, = rhythm not off).
  static bool isWeeklyReminderEnabled() {
    return getReminderRhythm().isOn;
  }

  /// Legacy switch: on keeps every 4 weeks if chosen, else weekly; off = off.
  static void setWeeklyReminderEnabled(bool enabled) {
    final current = getReminderRhythm();
    final keepsRhythm = enabled && current == ReminderRhythm.every4Weeks;
    setReminderRhythm(keepsRhythm
        ? current
        : (enabled ? ReminderRhythm.weekly : ReminderRhythm.off));
  }

  /// The Compass reminder rhythm; migrated from the legacy weekly switch
  /// while none was stored.
  static ReminderRhythm getReminderRhythm() {
    return ReminderRhythm.fromId(_prefs.getString(reminderRhythmKey)) ??
        ReminderRhythm.fromLegacyEnabled(
            _prefs.getBool(weeklyReminderEnabledKey));
  }

  /// Stores [rhythm], keeps the legacy switch in sync and anchors the
  /// 4-week rhythm on [today] the first time it is chosen.
  static Future<void> setReminderRhythm(
    ReminderRhythm rhythm, {
    DateTime? today,
  }) {
    final setsAnchor =
        rhythm == ReminderRhythm.every4Weeks && getRhythmAnchor() == null;
    // All writes start now, so reads right after this call see them.
    return Future.wait([
      _prefs.setString(reminderRhythmKey, rhythm.id),
      _prefs.setBool(weeklyReminderEnabledKey, rhythm.isOn),
      if (setsAnchor)
        _prefs.setString(
            rhythmAnchorKey, encodeCompassDate(today ?? DateTime.now())),
    ]);
  }

  /// First day of the 4-week rhythm (local midnight), null if never set.
  static DateTime? getRhythmAnchor() {
    return tryDecodeCompassDate(_prefs.getString(rhythmAnchorKey));
  }

  // Birthday reminder settings
  /// Time of day for birthday reminders, in minutes after midnight (default 09:00).
  static int getBirthdayReminderMinutes() {
    return _prefs.getInt('birthday_reminder_minutes') ?? 9 * 60;
  }

  static Future<void> setBirthdayReminderMinutes(int minutesAfterMidnight) async {
    await _prefs.setInt('birthday_reminder_minutes', minutesAfterMidnight);
  }

  static bool isBirthdayDayBeforeReminderEnabled() {
    return _prefs.getBool('birthday_day_before_reminder') ?? false;
  }

  static Future<void> setBirthdayDayBeforeReminderEnabled(bool enabled) async {
    await _prefs.setBool('birthday_day_before_reminder', enabled);
  }

  // Friend Lifespan Visualization Settings
  static bool isLifespanVisualizationEnabled() {
    return _prefs.getBool('lifespan_visualization_enabled') ?? true;
  }

  static void setLifespanVisualizationEnabled(bool enabled) {
    _prefs.setBool('lifespan_visualization_enabled', enabled);
  }

  static bool isLifespanAnimationEnabled() {
    return _prefs.getBool('lifespan_animation_enabled') ?? true;
  }

  static void setLifespanAnimationEnabled(bool enabled) {
    _prefs.setBool('lifespan_animation_enabled', enabled);
  }

  /// Friend detail lifespan card: their life ([friendLifespanViewLife],
  /// default) or the time together ([friendLifespanViewTogether]);
  /// remembered across friends.
  static const String friendLifespanViewKey = 'friend_lifespan_view';
  static const String friendLifespanViewLife = 'life';
  static const String friendLifespanViewTogether = 'together';

  static String getFriendLifespanView() =>
      _prefs.getString(friendLifespanViewKey) ?? friendLifespanViewLife;

  static Future<void> setFriendLifespanView(String view) async {
    await _prefs.setString(friendLifespanViewKey, view);
  }

  // Personal lifespan estimate (lib/lifespan/): only its result is kept,
  // never the answers (country, sex, lifestyle, health conditions).
  static const String lifespanResultKey = PersonalKeys.lifespanResult;

  /// The last applied estimate's result, or null if none (or unreadable).
  static LifespanResult? getLifespanResult() {
    final json = _decodeJsonObject(_personal.getString(lifespanResultKey));
    return json == null ? null : LifespanResult.fromJson(json);
  }

  static Future<void> setLifespanResult(LifespanResult result) async {
    await _personal.setString(lifespanResultKey, jsonEncode(result.toJson()));
  }

  static Map<String, Object?>? _decodeJsonObject(String? text) {
    if (text == null) return null;
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Whether the hidden diagnostics entry was unlocked (7 taps on version).
  static bool isDiagnosticsUnlocked() {
    return _prefs.getBool('diagnostics_unlocked') ?? false;
  }

  static Future<void> setDiagnosticsUnlocked(bool unlocked) async {
    await _prefs.setBool('diagnostics_unlocked', unlocked);
  }
}
