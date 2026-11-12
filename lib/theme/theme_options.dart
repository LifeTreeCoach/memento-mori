import 'package:flutter/material.dart';

/// Visual style of the app. Persisted by [id] ('stoic' | 'warm').
enum ThemeStyle {
  stoic('stoic', 'theme_style_stoic'),
  warm('warm', 'theme_style_warm');

  const ThemeStyle(this.id, this.labelKey);

  final String id;

  /// Localization key for the user-facing name.
  final String labelKey;

  static ThemeStyle fromId(String? id) {
    return ThemeStyle.values.firstWhere(
      (style) => style.id == id,
      orElse: () => ThemeStyle.stoic,
    );
  }
}

/// Brightness preference. Persisted by [id] ('system' | 'light' | 'dark').
enum AppBrightness {
  system('system', 'brightness_system', ThemeMode.system),
  light('light', 'brightness_light', ThemeMode.light),
  dark('dark', 'brightness_dark', ThemeMode.dark);

  const AppBrightness(this.id, this.labelKey, this.themeMode);

  final String id;

  /// Localization key for the user-facing name.
  final String labelKey;

  final ThemeMode themeMode;

  static AppBrightness fromId(String? id) {
    return AppBrightness.values.firstWhere(
      (brightness) => brightness.id == id,
      orElse: () => AppBrightness.system,
    );
  }

  /// Concrete brightness, resolving [system] with the platform value.
  Brightness resolve(Brightness platformBrightness) {
    switch (this) {
      case AppBrightness.system:
        return platformBrightness;
      case AppBrightness.light:
        return Brightness.light;
      case AppBrightness.dark:
        return Brightness.dark;
    }
  }
}
