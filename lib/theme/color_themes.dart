import 'package:flutter/material.dart';

/// A legacy grid colour palette (lived, remaining, border), selectable in
/// Settings > Appearance as an override of the theme style's own palette.
class ColorTheme {
  final String id;
  final String nameKey;
  final Color livedColor;
  final Color remainingColor;
  final Color borderColor;

  const ColorTheme({
    required this.id,
    required this.nameKey,
    required this.livedColor,
    required this.remainingColor,
    required this.borderColor,
  });

  @override
  bool operator ==(Object other) {
    return other is ColorTheme &&
        other.id == id &&
        other.livedColor == livedColor &&
        other.remainingColor == remainingColor &&
        other.borderColor == borderColor;
  }

  @override
  int get hashCode => Object.hash(id, livedColor, remainingColor, borderColor);
}

/// The selectable [ColorTheme] overrides, by id.
class ColorThemes {
  /// Stored id meaning "use the theme style's own grid palette".
  static const String styleDefaultId = 'default';
  static const String styleDefaultNameKey = 'theme_style_default';

  static bool isStyleDefault(String themeId) => themeId == styleDefaultId;

  /// Selectable ids for settings: the style default first, then all overrides.
  static List<String> getSelectableThemeIds() {
    return [styleDefaultId, ...themes.keys];
  }

  static const Map<String, ColorTheme> themes = {
    'classic': ColorTheme(
      id: 'classic',
      nameKey: 'theme_classic',
      livedColor: Colors.black,
      remainingColor: Colors.white,
      borderColor: Color(0xFF808080),
    ),
    'sunset': ColorTheme(
      id: 'sunset',
      nameKey: 'theme_sunset',
      livedColor: Color(0xFFFF6B35),
      remainingColor: Color(0xFFFFF3E0),
      borderColor: Color(0xFFFFB74D),
    ),
    'ocean': ColorTheme(
      id: 'ocean',
      nameKey: 'theme_ocean',
      livedColor: Color(0xFF1565C0),
      remainingColor: Color(0xFFE3F2FD),
      borderColor: Color(0xFF42A5F5),
    ),
    'forest': ColorTheme(
      id: 'forest',
      nameKey: 'theme_forest',
      livedColor: Color(0xFF2E7D32),
      remainingColor: Color(0xFFE8F5E8),
      borderColor: Color(0xFF66BB6A),
    ),
    'autumn': ColorTheme(
      id: 'autumn',
      nameKey: 'theme_autumn',
      livedColor: Color(0xFFD84315),
      remainingColor: Color(0xFFFFF8E1),
      borderColor: Color(0xFFFF8A65),
    ),
    'midnight': ColorTheme(
      id: 'midnight',
      nameKey: 'theme_midnight',
      livedColor: Color(0xFF1A237E),
      remainingColor: Color(0xFFE8EAF6),
      borderColor: Color(0xFF5C6BC0),
    ),
    'cherry': ColorTheme(
      id: 'cherry',
      nameKey: 'theme_cherry',
      livedColor: Color(0xFFC2185B),
      remainingColor: Color(0xFFFCE4EC),
      borderColor: Color(0xFFE91E63),
    ),
    'earth': ColorTheme(
      id: 'earth',
      nameKey: 'theme_earth',
      livedColor: Color(0xFF5D4037),
      remainingColor: Color(0xFFF3E5AB),
      borderColor: Color(0xFF8D6E63),
    ),
    'monochrome': ColorTheme(
      id: 'monochrome',
      nameKey: 'theme_monochrome',
      livedColor: Color(0xFF424242),
      remainingColor: Color(0xFFF5F5F5),
      borderColor: Color(0xFF9E9E9E),
    ),
  };

  /// Used for unknown ids.
  static const String fallbackId = 'classic';

  /// The theme [themeId], or the [fallbackId] theme when it is unknown.
  static ColorTheme getTheme(String themeId) {
    return themes[themeId] ?? themes[fallbackId]!;
  }
}