import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

/// Publishes the widget's INPUTS (see docs/widget-data-contract.md).
///
/// The native widget computes all displayed values itself, so it stays
/// correct while Flutter is not running. This class never builds strings
/// for display.
class WidgetService {
  static const int schemaVersion = 1;
  static const String widgetGroupId =
      'group.lifetree.coach.memento_mori_life_in_weeks';
  static const String androidWidgetReceiver =
      'lifetree.coach.memento_mori_life_in_weeks.widget.LifeWidgetReceiver';
  /// WidgetKit kind of ios/MementoWidget (`MementoWidget.kind`).
  static const String iOSWidgetKind = 'MementoWidget';
  static const int accentColor = 0xFFE0A84F;
  static const List<String> widgetDisplayModes = [
    'weeks',
    'months',
    'years',
    'days',
  ];

  /// ios/Runner/WatchSync.swift: sends the published inputs to the Apple Watch.
  static const MethodChannel _watchSync = MethodChannel('memento/watch_sync');

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(widgetGroupId);
    } catch (e) {
      debugPrint('Widget: app group setup failed: $e');
    }
    await publishInputs();
  }

  /// Inputs of the last successful publish; identical inputs are not
  /// written again.
  static Map<String, Object?>? _lastPublished;

  /// Writes all widget inputs and asks the OS to redraw the widget.
  /// Does nothing when the inputs are unchanged since the last publish.
  static Future<void> publishInputs() async {
    final inputs = _collectInputs();
    if (mapEquals(inputs, _lastPublished)) return;
    try {
      await _saveInputs(inputs);
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidWidgetReceiver,
        iOSName: iOSWidgetKind,
      );
      _lastPublished = inputs;
      await _syncAppleWatch();
    } catch (e) {
      debugPrint('Widget: publishing inputs failed: $e');
    }
  }

  /// Forgets the last publish, so the next [publishInputs] writes again.
  @visibleForTesting
  static void resetPublishedForTesting() => _lastPublished = null;

  /// On Android the widget receiver syncs Wear OS itself; on iOS
  /// `updateWidget` only reloads WidgetKit, so the watch is synced explicitly.
  static Future<void> _syncAppleWatch() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _watchSync.invokeMethod<void>('sync');
  }

  /// Optional keys with the dark-mode colours of a user colour theme; a null
  /// value removes the key (style palette, so the widget uses its own).
  static const List<String> darkColorKeys = [
    'color_lived_dark',
    'color_remaining_dark',
    'color_accent_dark',
  ];

  static Map<String, Object?> _collectInputs() {
    final grid = _gridColors();
    final birthDate = SettingsService.getBirthDate();
    return {
      'schema_version': schemaVersion,
      'birth_date': birthDate == null ? '' : _formatDate(birthDate),
      'life_expectancy_years': SettingsService.getLifeExpectancyYears(),
      'widget_display_mode': getWidgetDisplayMode(),
      'language': SettingsService.getLanguage(),
      'theme_style': SettingsService.getThemeStyle(),
      'brightness': SettingsService.getBrightness(),
      'color_lived': grid.lived.toARGB32(),
      'color_remaining': grid.remaining.toARGB32(),
      'color_accent': accentColor,
      ..._darkColorInputs(),
    };
  }

  /// The user colour theme adapted for dark mode exactly like the app does
  /// ([LifePalette.resolve]), so dark widgets match the dark app.
  static Map<String, Object?> _darkColorInputs() {
    final override =
        LifePaletteColors.forColorThemeId(SettingsService.getColorTheme());
    final dark = override == null
        ? null
        : LifePalette.resolve(
            ThemeStyle.fromId(SettingsService.getThemeStyle()),
            Brightness.dark,
            gridOverride: override,
          );
    final values = [dark?.lived, dark?.remaining, dark?.now];
    return {
      for (var i = 0; i < darkColorKeys.length; i++)
        darkColorKeys[i]: values[i]?.toARGB32(),
    };
  }

  /// The chosen grid colour theme, or the theme style's own palette.
  static LifePaletteColors _gridColors() {
    final override =
        LifePaletteColors.forColorThemeId(SettingsService.getColorTheme());
    if (override != null) return override;
    final brightness = AppBrightness.fromId(SettingsService.getBrightness())
        .resolve(PlatformDispatcher.instance.platformBrightness);
    final palette = LifePalette.resolve(
      ThemeStyle.fromId(SettingsService.getThemeStyle()),
      brightness,
    );
    return LifePaletteColors(
      lived: palette.lived,
      remaining: palette.remaining,
      gridLine: palette.gridLine,
    );
  }

  static Future<void> _saveInputs(Map<String, Object?> inputs) async {
    await Future.wait([
      for (final MapEntry(:key, :value) in inputs.entries)
        if (value == null)
          HomeWidget.saveWidgetData<int>(key, null, deleteFile: false)
        else if (value is int)
          HomeWidget.saveWidgetData<int>(key, value)
        else
          HomeWidget.saveWidgetData<String>(key, value as String),
    ]);
  }

  static String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${twoDigits(date.month)}-${twoDigits(date.day)}';
  }

  /// Only Android launchers can pin a widget from inside the app; on iOS the
  /// user adds it from the home screen's widget gallery.
  static bool get canRequestPin => defaultTargetPlatform == TargetPlatform.android;

  /// Asks the launcher to pin the widget. Returns false when the launcher
  /// cannot pin from inside the app, so callers can explain the manual way.
  static Future<bool> requestPinWidget() async {
    await publishInputs();
    if (!canRequestPin) return false;
    try {
      if (await HomeWidget.isRequestPinWidgetSupported() == true) {
        await HomeWidget.requestPinWidget(
          qualifiedAndroidName: androidWidgetReceiver,
        );
        return true;
      }
      debugPrint('Widget: pinning not supported by this launcher');
    } catch (e) {
      debugPrint('Widget: pin request failed: $e');
    }
    return false;
  }

  static String getWidgetDisplayMode() {
    final mode = SettingsService.getWidgetDisplayMode();
    return widgetDisplayModes.contains(mode) ? mode : 'weeks';
  }

  static Future<void> setWidgetDisplayMode(String mode) async {
    await SettingsService.setWidgetDisplayMode(mode);
    await publishInputs();
  }
}
