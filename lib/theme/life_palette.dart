import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

/// Grid colours that override the style palette (from a user-chosen
/// [ColorTheme]). Only lived/remaining cells and grid lines change.
@immutable
class LifePaletteColors {
  const LifePaletteColors({
    required this.lived,
    required this.remaining,
    required this.gridLine,
  });

  factory LifePaletteColors.fromColorTheme(ColorTheme theme) {
    return LifePaletteColors(
      lived: theme.livedColor,
      remaining: theme.remainingColor,
      gridLine: theme.borderColor,
    );
  }

  /// Override for a stored colour theme id, or null for the style default.
  static LifePaletteColors? forColorThemeId(String id) {
    if (ColorThemes.isStyleDefault(id)) return null;
    return LifePaletteColors.fromColorTheme(ColorThemes.getTheme(id));
  }

  final Color lived;
  final Color remaining;
  final Color gridLine;

  /// Share of the lived colour mixed into the dark remaining cells.
  static const double darkRemainingTint = 0.2;

  /// Minimum contrast of lived against remaining cells in dark mode.
  static const double minDarkLivedContrast = 3;

  /// These colours on a dark [base]: colour themes are designed for light
  /// backgrounds, so remaining cells become a dark tint of the lived colour,
  /// grid lines follow [base], and lived is lightened until it stands out.
  LifePaletteColors darkenedFor(LifePalette base) {
    final darkRemaining =
        Color.lerp(base.remaining, lived, darkRemainingTint)!;
    return LifePaletteColors(
      lived: _lightenUntilReadable(lived, darkRemaining),
      remaining: darkRemaining,
      gridLine: base.gridLine,
    );
  }

  static Color _lightenUntilReadable(Color color, Color background) {
    var result = color;
    for (var t = 0.1;
        contrastRatio(result, background) < minDarkLivedContrast && t <= 1;
        t += 0.1) {
      result = Color.lerp(color, const Color(0xFFFFFFFF), t)!;
    }
    return result;
  }
}

/// Semantic colours of the life visualisation, available through
/// `Theme.of(context).extension<LifePalette>()` or [LifePalette.of].
@immutable
class LifePalette extends ThemeExtension<LifePalette> {
  const LifePalette({
    required this.lived,
    required this.remaining,
    required this.now,
    required this.milestone,
    required this.gridLine,
    required this.accent,
    required this.quoteText,
    required this.moment,
  });

  /// The warm amber that marks "now" across the app and widget.
  static const Color amber = Color(0xFFE0A84F);

  static const LifePalette stoicDark = LifePalette(
    lived: Color(0xFFA39D92),
    remaining: Color(0xFF1F1F21),
    now: amber,
    milestone: Color(0xFF9C8360),
    gridLine: Color(0xFF141415),
    accent: amber,
    quoteText: Color(0xFFCFC9BD),
    moment: Color(0xFF2E7069),
  );

  static const LifePalette stoicLight = LifePalette(
    lived: Color(0xFF1F1E1C),
    remaining: Color(0xFFE3DED3),
    now: Color(0xFFD4973A),
    milestone: Color(0xFF8A6A3A),
    gridLine: Color(0xFFEDE9E0),
    accent: Color(0xFFD4973A),
    quoteText: Color(0xFF3A3835),
    moment: Color(0xFF4A8079),
  );

  static const LifePalette warmLight = LifePalette(
    lived: Color(0xFFEFA27F),
    remaining: Color(0xFFF2D9C6),
    now: Color(0xFFB4532A),
    milestone: Color(0xFFE0A84F),
    gridLine: Color(0xFFFFF4EA),
    accent: Color(0xFFB4532A),
    quoteText: Color(0xFF5A4438),
    moment: Color(0xFF2F6B66),
  );

  static const LifePalette warmDark = LifePalette(
    lived: Color(0xFFE6936E),
    remaining: Color(0xFF33281F),
    now: Color(0xFFFFD08A),
    milestone: Color(0xFFB98B6E),
    gridLine: Color(0xFF221A16),
    accent: Color(0xFFFFB591),
    quoteText: Color(0xFFE8D5C8),
    moment: Color(0xFF2E7069),
  );

  /// Base palette of a style/brightness combination, optionally with the
  /// grid colours replaced by [gridOverride] (subdued in dark mode).
  static LifePalette resolve(
    ThemeStyle style,
    Brightness brightness, {
    LifePaletteColors? gridOverride,
  }) {
    final base = _base(style, brightness);
    if (gridOverride == null) return base;
    final grid = brightness == Brightness.dark
        ? gridOverride.darkenedFor(base)
        : gridOverride;
    return base.copyWith(
      lived: grid.lived,
      remaining: grid.remaining,
      gridLine: grid.gridLine,
    );
  }

  static LifePalette _base(ThemeStyle style, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (style) {
      case ThemeStyle.stoic:
        return isDark ? stoicDark : stoicLight;
      case ThemeStyle.warm:
        return isDark ? warmDark : warmLight;
    }
  }

  /// Palette of the ambient theme; falls back to stoic for its brightness.
  static LifePalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<LifePalette>() ??
        _base(ThemeStyle.stoic, theme.brightness);
  }

  final Color lived;
  final Color remaining;
  final Color now;
  final Color milestone;
  final Color gridLine;
  final Color accent;
  final Color quoteText;

  /// Dot marking a cell that holds a Compass moment; a calm teal that
  /// stays visible on both lived and remaining cells
  /// ([minMomentContrast]). Flutter only: the native palettes need no
  /// moment colour (widgets and watches show no moments).
  final Color moment;

  /// Minimum contrast of [moment] against lived and remaining cells.
  static const double minMomentContrast = 2;

  /// Adapter for painters that still take the legacy [ColorTheme].
  ColorTheme toColorTheme() {
    return ColorTheme(
      id: ColorThemes.styleDefaultId,
      nameKey: ColorThemes.styleDefaultNameKey,
      livedColor: lived,
      remainingColor: remaining,
      borderColor: gridLine,
    );
  }

  @override
  LifePalette copyWith({
    Color? lived,
    Color? remaining,
    Color? now,
    Color? milestone,
    Color? gridLine,
    Color? accent,
    Color? quoteText,
    Color? moment,
  }) {
    return LifePalette(
      lived: lived ?? this.lived,
      remaining: remaining ?? this.remaining,
      now: now ?? this.now,
      milestone: milestone ?? this.milestone,
      gridLine: gridLine ?? this.gridLine,
      accent: accent ?? this.accent,
      quoteText: quoteText ?? this.quoteText,
      moment: moment ?? this.moment,
    );
  }

  @override
  LifePalette lerp(ThemeExtension<LifePalette>? other, double t) {
    if (other is! LifePalette) return this;
    return LifePalette(
      lived: Color.lerp(lived, other.lived, t)!,
      remaining: Color.lerp(remaining, other.remaining, t)!,
      now: Color.lerp(now, other.now, t)!,
      milestone: Color.lerp(milestone, other.milestone, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      quoteText: Color.lerp(quoteText, other.quoteText, t)!,
      moment: Color.lerp(moment, other.moment, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LifePalette &&
        other.lived == lived &&
        other.remaining == remaining &&
        other.now == now &&
        other.milestone == milestone &&
        other.gridLine == gridLine &&
        other.accent == accent &&
        other.quoteText == quoteText &&
        other.moment == moment;
  }

  @override
  int get hashCode => Object.hash(
      lived, remaining, now, milestone, gridLine, accent, quoteText, moment);
}
