import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

/// Hand-tuned Material 3 colour schemes for each style and brightness.
///
/// Stoic: ink #0F0F10 / paper #F4F1EA, monochrome primary, amber tertiary.
/// Warm: cream and peach with a terracotta primary.
class AppColorSchemes {
  AppColorSchemes._();

  static const Color ink = Color(0xFF0F0F10);
  static const Color paper = Color(0xFFF4F1EA);
  static const Color amber = Color(0xFFE0A84F);

  static ColorScheme of(ThemeStyle style, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (style) {
      case ThemeStyle.stoic:
        return isDark ? stoicDark : stoicLight;
      case ThemeStyle.warm:
        return isDark ? warmDark : warmLight;
    }
  }

  static const ColorScheme stoicDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFECE7DC),
    onPrimary: ink,
    primaryContainer: Color(0xFF2A2926),
    onPrimaryContainer: paper,
    secondary: Color(0xFFB9B3A8),
    onSecondary: Color(0xFF1A1A1C),
    secondaryContainer: Color(0xFF2C2B29),
    onSecondaryContainer: Color(0xFFE7E2D8),
    tertiary: amber,
    onTertiary: Color(0xFF2A1C05),
    tertiaryContainer: Color(0xFF4A3612),
    onTertiaryContainer: Color(0xFFFBDDA8),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: ink,
    onSurface: paper,
    onSurfaceVariant: Color(0xFFA9A49B),
    surfaceDim: ink,
    surfaceBright: Color(0xFF333336),
    surfaceContainerLowest: Color(0xFF0A0A0B),
    surfaceContainerLow: Color(0xFF151517),
    surfaceContainer: Color(0xFF1A1A1C),
    surfaceContainerHigh: Color(0xFF222225),
    surfaceContainerHighest: Color(0xFF2A2A2D),
    outline: Color(0xFF5A5752),
    outlineVariant: Color(0xFF2E2D2B),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: paper,
    onInverseSurface: Color(0xFF1A1A1C),
    inversePrimary: Color(0xFF3A3833),
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme stoicLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1C1B1A),
    onPrimary: paper,
    primaryContainer: Color(0xFFE4DFD4),
    onPrimaryContainer: Color(0xFF1C1B1A),
    secondary: Color(0xFF5E5A53),
    onSecondary: paper,
    secondaryContainer: Color(0xFFE6E1D6),
    onSecondaryContainer: Color(0xFF2A2825),
    tertiary: Color(0xFF8A5A12),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFF6DFB5),
    onTertiaryContainer: Color(0xFF2E1E04),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: paper,
    onSurface: Color(0xFF141414),
    onSurfaceVariant: Color(0xFF57534C),
    surfaceDim: Color(0xFFE2DED5),
    surfaceBright: Color(0xFFFAF8F3),
    surfaceContainerLowest: Color(0xFFFBF9F4),
    surfaceContainerLow: Color(0xFFEFEBE3),
    surfaceContainer: Color(0xFFEAE6DD),
    surfaceContainerHigh: Color(0xFFE4E0D6),
    surfaceContainerHighest: Color(0xFFDEDACF),
    outline: Color(0xFF8C877E),
    outlineVariant: Color(0xFFD6D1C6),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF1C1B1A),
    onInverseSurface: paper,
    inversePrimary: Color(0xFFD9D3C7),
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme warmLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB4532A),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFDCC8),
    onPrimaryContainer: Color(0xFF3A1606),
    secondary: Color(0xFF7A5A48),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFBE3D3),
    onSecondaryContainer: Color(0xFF2E1A10),
    tertiary: Color(0xFF8A5A12),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFBE0B0),
    onTertiaryContainer: Color(0xFF2E1E04),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFFF8F1),
    onSurface: Color(0xFF2B2420),
    onSurfaceVariant: Color(0xFF6B5B50),
    surfaceDim: Color(0xFFF1E4D8),
    surfaceBright: Color(0xFFFFFBF7),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFFF3E8),
    surfaceContainer: Color(0xFFFDEBDD),
    surfaceContainerHigh: Color(0xFFF9E2D0),
    surfaceContainerHighest: Color(0xFFF4D9C4),
    outline: Color(0xFF9A8576),
    outlineVariant: Color(0xFFEBD5C5),
    shadow: Color(0xFF3A2418),
    scrim: Colors.black,
    inverseSurface: Color(0xFF3A2E28),
    onInverseSurface: Color(0xFFFFEDE2),
    inversePrimary: Color(0xFFFFB591),
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme warmDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB591),
    onPrimary: Color(0xFF4A1E08),
    primaryContainer: Color(0xFF6B3418),
    onPrimaryContainer: Color(0xFFFFDCC8),
    secondary: Color(0xFFE5BFA9),
    onSecondary: Color(0xFF42291B),
    secondaryContainer: Color(0xFF4A362A),
    onSecondaryContainer: Color(0xFFFBE3D3),
    tertiary: Color(0xFFF2C27A),
    onTertiary: Color(0xFF3A2604),
    tertiaryContainer: Color(0xFF5A4012),
    onTertiaryContainer: Color(0xFFFBE0B0),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF1E1714),
    onSurface: Color(0xFFF6E9DF),
    onSurfaceVariant: Color(0xFFD2BFB2),
    surfaceDim: Color(0xFF1E1714),
    surfaceBright: Color(0xFF453A33),
    surfaceContainerLowest: Color(0xFF18120F),
    surfaceContainerLow: Color(0xFF241C18),
    surfaceContainer: Color(0xFF2A211C),
    surfaceContainerHigh: Color(0xFF342A24),
    surfaceContainerHighest: Color(0xFF3F332C),
    outline: Color(0xFF9C8A7E),
    outlineVariant: Color(0xFF4A3D35),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFF6E9DF),
    onInverseSurface: Color(0xFF2A211C),
    inversePrimary: Color(0xFFB4532A),
    surfaceTint: Colors.transparent,
  );
}
