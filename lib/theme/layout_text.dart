import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';

/// Text colours and font for text that painters draw on top of their own
/// shapes: each label picks the [light] or [dark] colour that contrasts
/// best with what lies beneath it, plus a soft halo in the other colour.
@immutable
class LayoutText {
  const LayoutText({
    this.light = Colors.white,
    this.dark = Colors.black,
    this.background = Colors.white,
    this.fontFamily,
  });

  /// Light/dark text from the scheme's surface and onSurface colours.
  factory LayoutText.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return LayoutText(
      light: isDark ? scheme.onSurface : scheme.surface,
      dark: isDark ? scheme.surface : scheme.onSurface,
      background: scheme.surface,
      fontFamily: theme.textTheme.bodyMedium?.fontFamily,
    );
  }

  final Color light;
  final Color dark;

  /// What the layout is drawn on, for text outside its shapes.
  final Color background;
  final String? fontFamily;

  /// WCAG AA contrast for normal text.
  static const double minContrast = 4.5;

  /// [light] or [dark], whichever is more legible on [background]; pure
  /// white or black when neither reaches [minContrast] (mid-tone fills).
  Color colorOn(Color background) {
    final themed = mostReadableOn(background, [light, dark]);
    if (contrastRatio(themed, background) >= minContrast) return themed;
    return mostReadableOn(background, const [Colors.white, Colors.black]);
  }

  /// Text colour for text that spans several [backgrounds] (e.g. two
  /// phase bands): the candidate whose weakest contrast is highest, the
  /// themed [light]/[dark] when that reaches [minContrast] on every one.
  Color colorOnAll(List<Color> backgrounds) {
    assert(backgrounds.isNotEmpty);
    if (backgrounds.length == 1) return colorOn(backgrounds.single);
    final themed = _bestOnAll(backgrounds, [light, dark]);
    if (_weakestContrast(themed, backgrounds) >= minContrast) return themed;
    return _bestOnAll(backgrounds, [light, dark, Colors.white, Colors.black]);
  }

  static Color _bestOnAll(List<Color> backgrounds, List<Color> candidates) =>
      candidates.reduce(
        (best, next) =>
            _weakestContrast(next, backgrounds) >
                _weakestContrast(best, backgrounds)
            ? next
            : best,
      );

  static double _weakestContrast(Color text, List<Color> backgrounds) =>
      backgrounds
          .map((b) => contrastRatio(text, b))
          .reduce((a, b) => a < b ? a : b);

  /// A text style legible on [background], haloed against stray shapes.
  TextStyle styleOn(
    Color background, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) => styleOnAll([background], fontSize: fontSize, fontWeight: fontWeight);

  /// A text style legible on every one of [backgrounds] (text crossing
  /// shapes of different colours), haloed in the opposite colour.
  TextStyle styleOnAll(
    List<Color> backgrounds, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    final color = colorOnAll(backgrounds);
    final halo = mostReadableOn(color, [light, dark]);
    return TextStyle(
      color: color,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      shadows: [Shadow(color: halo.withValues(alpha: 0.6), blurRadius: 3)],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LayoutText &&
      other.light == light &&
      other.dark == dark &&
      other.background == background &&
      other.fontFamily == fontFamily;

  @override
  int get hashCode => Object.hash(light, dark, background, fontFamily);
}
