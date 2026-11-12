import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';

/// Shared motion tokens. Motion is slow and subtle by design.
class Motion {
  Motion._();

  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 600);
  static const Duration reveal = Duration(milliseconds: 1500);
  static const Duration pulse = Duration(seconds: 4);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// False when the OS asks to reduce motion or the user turned off
  /// animations in the app's visual settings.
  ///
  /// Registers a dependency on [AppSettingsScope], so callers rebuild (and
  /// get didChangeDependencies) when the setting changes.
  static bool enabled(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return false;
    final settings = AppSettingsScope.maybeOf(context);
    if (settings != null) return settings.visualization.enableAnimations;
    return _appAnimationsEnabled();
  }

  /// [duration] when motion is enabled, otherwise [Duration.zero].
  static Duration of(BuildContext context, Duration duration) {
    return enabled(context) ? duration : Duration.zero;
  }

  static bool _appAnimationsEnabled() {
    try {
      return SettingsService.getVisualizationSettings().enableAnimations;
    } catch (_) {
      // Settings not initialised (e.g. in isolated widget tests).
      return true;
    }
  }
}

/// Thin wrappers so haptics stay consistent and easy to tune.
class Haptics {
  Haptics._();

  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> light() => HapticFeedback.lightImpact();
}
