import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/widget_service.dart';

/// App-wide appearance and language state, backed by [SettingsService].
///
/// The app root listens to it, so changes rebuild [MaterialApp] live.
class AppSettingsController extends ChangeNotifier {
  AppSettingsController() {
    _readFromSettings();
  }

  late ThemeStyle _themeStyle;
  late AppBrightness _brightness;
  late String _colorThemeId;
  late String _language;

  ThemeStyle get themeStyle => _themeStyle;
  AppBrightness get brightness => _brightness;
  String get colorThemeId => _colorThemeId;
  String get language => _language;

  Locale get locale => Locale(_language);
  ThemeMode get themeMode => _brightness.themeMode;

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  /// Built themes; notifications that don't change the theme inputs
  /// (e.g. language) reuse them instead of rebuilding ThemeData.
  final Map<(ThemeStyle, String, Brightness), ThemeData> _themes = {};

  ThemeData _buildTheme(Brightness brightness) {
    return _themes[(_themeStyle, _colorThemeId, brightness)] ??=
        AppTheme.build(
      style: _themeStyle,
      brightness: brightness,
      gridOverride: LifePaletteColors.forColorThemeId(_colorThemeId),
    );
  }

  void _readFromSettings() {
    _themeStyle = ThemeStyle.fromId(SettingsService.getThemeStyle());
    _brightness = AppBrightness.fromId(SettingsService.getBrightness());
    _colorThemeId = SettingsService.getColorTheme();
    _language = SettingsService.getLanguage();
  }

  /// Re-reads settings changed elsewhere (e.g. language or grid palette
  /// written straight to [SettingsService]) and rebuilds the app.
  void reload() {
    _readFromSettings();
    notifyListeners();
  }

  Future<void> setThemeStyle(ThemeStyle style) async {
    if (style == _themeStyle) return;
    _themeStyle = style;
    notifyListeners();
    await SettingsService.setThemeStyle(style.id);
    await WidgetService.publishInputs();
  }

  Future<void> setBrightness(AppBrightness brightness) async {
    if (brightness == _brightness) return;
    _brightness = brightness;
    notifyListeners();
    await SettingsService.setBrightness(brightness.id);
    await WidgetService.publishInputs();
  }

  Future<void> setColorTheme(String colorThemeId) async {
    if (colorThemeId == _colorThemeId) return;
    _colorThemeId = colorThemeId;
    SettingsService.setColorTheme(colorThemeId);
    notifyListeners();
    await WidgetService.publishInputs();
  }

  Future<void> setLanguage(String language) async {
    if (language == _language) return;
    _language = language;
    SettingsService.setLanguage(language);
    notifyListeners();
    await WidgetService.publishInputs();
  }

  // Life settings. Read straight from [SettingsService] because the Life tab
  // also writes the display mode; setters notify so every tab rebuilds.

  DateTime? get birthDate => SettingsService.getBirthDate();
  int get lifeExpectancyYears => SettingsService.getLifeExpectancyYears();
  String get displayMode => SettingsService.getDisplayMode();
  VisualizationSettings get visualization =>
      SettingsService.getVisualizationSettings();

  Future<void> setBirthDate(DateTime date) async {
    SettingsService.setBirthDate(date);
    notifyListeners();
    await WidgetService.publishInputs();
  }

  Future<void> setLifeExpectancyYears(int years) async {
    if (years == lifeExpectancyYears) return;
    await SettingsService.setLifeExpectancyYears(years);
    notifyListeners();
    await WidgetService.publishInputs();
  }

  void setDisplayMode(String mode) {
    if (mode == displayMode) return;
    SettingsService.setDisplayMode(mode);
    notifyListeners();
  }

  void setVisualization(VisualizationSettings settings) {
    SettingsService.setVisualizationSettings(settings);
    notifyListeners();
  }

  /// Lifespan rings on the People tab, and their wave animation.
  bool get lifespanVisualization =>
      SettingsService.isLifespanVisualizationEnabled();
  bool get lifespanAnimation => SettingsService.isLifespanAnimationEnabled();

  void setLifespanVisualization(bool enabled) {
    SettingsService.setLifespanVisualizationEnabled(enabled);
    notifyListeners();
  }

  void setLifespanAnimation(bool enabled) {
    SettingsService.setLifespanAnimationEnabled(enabled);
    notifyListeners();
  }
}

/// Exposes the [AppSettingsController] to the widget tree.
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found in context');
    return scope!.notifier!;
  }

  /// Like [of] but returns null outside the scope (e.g. isolated tests).
  static AppSettingsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
  }
}
