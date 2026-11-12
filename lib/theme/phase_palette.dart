import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

/// Colours of life phases in the life visualisation, available through
/// [PhaseColors.of] (a [ThemeExtension] registered next to [LifePalette]).
///
/// The current phase uses the palette accent, its planned rest a lighter
/// blend of it (bars, ribbons, dots; grid cells take the paler
/// [plannedTint]), earlier phases cycle through muted tones outside the
/// accent's hue family and the time before the first phase keeps the normal
/// lived colour.
@immutable
class PhaseColors extends ThemeExtension<PhaseColors> {
  const PhaseColors({
    required this.current,
    required this.planned,
    required this.plannedTint,
    required this.earlier,
    required this.before,
  }) : assert(earlier.length > 0);

  /// Phase colours of a style palette, with the given [earlier] tones.
  factory PhaseColors.fromPalette(
    LifePalette p, {
    required List<Color> earlier,
  }) {
    return PhaseColors(
      current: p.accent,
      planned: Color.lerp(p.accent, p.remaining, plannedBlend)!,
      plannedTint: plannedTintOn(p.accent, p.remaining),
      earlier: List.unmodifiable(earlier),
      before: p.lived,
    );
  }

  /// Phase colours for a user colour theme: earlier tones are muted hue and
  /// lightness shifts of [LifePalette.lived] (neighbours far apart in hue
  /// and alternating in lightness), outside the accent's hue family, kept
  /// readable on remaining and clear of the current and planned colours.
  factory PhaseColors.derive(LifePalette p) {
    final planned = Color.lerp(p.accent, p.remaining, plannedBlend)!;
    return PhaseColors.fromPalette(
      p,
      earlier: _clearOf(_derivedEarlier(p), [p.accent, planned], p.remaining),
    );
  }

  /// Colour of the current phase (palette accent).
  final Color current;

  /// Colour of the planned, not yet lived part of the current phase.
  final Color planned;

  /// Fill of a planned grid cell: a pale tint of the accent between it and
  /// remaining, still clearly apart from remaining ([plannedTintOn]).
  final Color plannedTint;

  /// Muted tones of earlier phases, cycled by index ([earlierAt]).
  final List<Color> earlier;

  /// Time before the first phase (the normal lived colour).
  final Color before;

  /// Share of the remaining colour mixed into [planned].
  static const double plannedBlend = 0.35;

  /// Minimum perceptual distance (CIE76 ΔE) of every earlier tone from the
  /// current phase and its planned rest.
  static const double minAccentDeltaE = 28;

  /// Minimum contrast of every phase tone against remaining cells.
  static const double minToneContrast = 1.3;

  /// Share of the remaining colour mixed into [plannedTint].
  static const double plannedTintBlend = 0.6;

  /// Minimum contrast and perceptual distance (ΔE) of [plannedTint] from
  /// remaining cells, so planned weeks never read as plain remaining ones.
  static const double minTintContrast = 1.15;
  static const double minTintDeltaE = 15;

  /// Minimum contrast of the coming week's gold ring on the surface: a
  /// fine line needs more than a filled cell.
  static const double minRingContrast = 2.0;

  /// The planned tint: [accent] blended [plannedTintBlend] towards
  /// [remaining], less if that would come too close to remaining.
  static Color plannedTintOn(Color accent, Color remaining) {
    for (var blend = plannedTintBlend; blend > 0; blend -= 0.05) {
      final tint = Color.lerp(accent, remaining, blend)!;
      if (_apartFrom(tint, remaining)) return tint;
    }
    return accent;
  }

  static bool _apartFrom(Color tint, Color remaining) =>
      contrastRatio(tint, remaining) >= minTintContrast &&
      deltaE(tint, remaining) >= minTintDeltaE;

  /// The coming week's ring: [current] made readable on [surface].
  Color comingRingOn(Color surface) =>
      _readableOn(current, surface, minContrast: minRingContrast);

  /// Muted tones of earlier phases for the Stoic style (gold accent), one
  /// hue family each so neighbouring phases never blur together: sage,
  /// slate blue, dusty rose and a deep grey-brown. No sand or gold, so no
  /// earlier phase can be mistaken for the current phase or its planned rest.
  static const List<Color> stoicEarlierLight = [
    Color(0xFF9DB0A6), // sage
    Color(0xFF6F7F9E), // slate blue
    Color(0xFFA77C8A), // dusty rose
    Color(0xFF5F5550), // grey-brown
  ];

  /// The Stoic families for dark backgrounds: deeper and desaturated, still
  /// clear of the dark remaining cells.
  static const List<Color> stoicEarlierDark = [
    Color(0xFF7A9A8E), // sage
    Color(0xFF56688C), // slate blue
    Color(0xFF8E5F72), // dusty rose
    Color(0xFF6A5E52), // grey-brown
  ];

  /// Muted tones of earlier phases for the Warm style (terracotta accent):
  /// sage, slate blue, plum and olive. No clay, peach or terracotta.
  static const List<Color> warmEarlierLight = [
    Color(0xFF9DB0A6), // sage
    Color(0xFF55708F), // slate blue
    Color(0xFF9A6E96), // plum
    Color(0xFF7A7A4C), // olive
  ];

  /// The Warm families for dark backgrounds.
  static const List<Color> warmEarlierDark = [
    Color(0xFF7A9A8E), // sage
    Color(0xFF4C6584), // slate blue
    Color(0xFF8E6088), // plum
    Color(0xFF76764A), // olive
  ];

  static final PhaseColors stoicLight = PhaseColors.fromPalette(
    LifePalette.stoicLight,
    earlier: stoicEarlierLight,
  );
  static final PhaseColors stoicDark = PhaseColors.fromPalette(
    LifePalette.stoicDark,
    earlier: stoicEarlierDark,
  );
  static final PhaseColors warmLight = PhaseColors.fromPalette(
    LifePalette.warmLight,
    earlier: warmEarlierLight,
  );
  static final PhaseColors warmDark = PhaseColors.fromPalette(
    LifePalette.warmDark,
    earlier: warmEarlierDark,
  );

  /// Phase colours of a style/brightness combination (no colour theme).
  static PhaseColors resolve(ThemeStyle style, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (style) {
      case ThemeStyle.stoic:
        return isDark ? stoicDark : stoicLight;
      case ThemeStyle.warm:
        return isDark ? warmDark : warmLight;
    }
  }

  /// Phase colours matching a resolved [palette]: derived when a user
  /// colour theme replaced the grid colours, the style constants otherwise.
  static PhaseColors forTheme(
    ThemeStyle style,
    Brightness brightness,
    LifePalette palette, {
    required bool userColorTheme,
  }) {
    return userColorTheme
        ? PhaseColors.derive(palette)
        : resolve(style, brightness);
  }

  /// Phase colours of the ambient theme; falls back to stoic.
  static PhaseColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PhaseColors>() ??
        resolve(ThemeStyle.stoic, theme.brightness);
  }

  /// Tone of the [index]-th earlier phase (cycles through [earlier]).
  Color earlierAt(int index) => earlier[index % earlier.length];

  /// Hue offsets from the start hue: neighbouring tones (also the last
  /// and the first, as they cycle) sit opposite or at right angles: every
  /// two tones are at least 90° apart.
  static const List<double> _hueShifts = [0, 180, 90, 270];

  /// Lightness alternates, so tones also differ in value.
  static const List<double> _lightLightness = [0.70, 0.46, 0.58, 0.34];
  static const List<double> _darkLightness = [0.58, 0.38, 0.48, 0.28];
  static const double _minSaturation = 0.16;
  static const double _maxSaturation = 0.26;

  static List<Color> _derivedEarlier(LifePalette p) {
    final base = HSLColor.fromColor(p.lived);
    final onDark = p.remaining.computeLuminance() < 0.5;
    final lightness = onDark ? _darkLightness : _lightLightness;
    final startHue = _hueClearOfAccent(
      base.hue,
      HSLColor.fromColor(p.accent).hue,
    );
    return [
      for (var i = 0; i < _hueShifts.length; i++)
        _readableOn(
          _mutedTone(base, (startHue + _hueShifts[i]) % 360, lightness[i]),
          p.remaining,
        ),
    ];
  }

  /// Step between the start hues tried by [_hueClearOfAccent].
  static const double _hueStep = 15;

  /// The start hue closest to [livedHue] whose tones (at [_hueShifts]) all
  /// keep the largest possible hue distance from [accentHue], so no earlier
  /// phase shares the hue family of the current phase or its planned rest.
  static double _hueClearOfAccent(double livedHue, double accentHue) {
    var bestHue = livedHue;
    var bestClearance = -1.0;
    for (var offset = 0.0; offset < 360; offset += _hueStep) {
      // Try offsets in both directions, nearest to the lived hue first.
      for (final sign in const [1, -1]) {
        final hue = (livedHue + sign * offset) % 360;
        final clearance = _minHueDistance(hue, accentHue);
        if (clearance > bestClearance + 0.5) {
          bestClearance = clearance;
          bestHue = hue;
        }
      }
    }
    return bestHue;
  }

  static double _minHueDistance(double startHue, double accentHue) {
    var result = 180.0;
    for (final shift in _hueShifts) {
      final diff = ((startHue + shift - accentHue) % 360).abs();
      final distance = diff > 180 ? 360 - diff : diff;
      if (distance < result) result = distance;
    }
    return result;
  }

  static Color _mutedTone(HSLColor base, double hue, double lightness) {
    // Grey lived colours still get distinct (muted) hues.
    final saturation = base.saturation
        .clamp(_minSaturation, _maxSaturation)
        .toDouble();
    return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
  }

  /// [tones] adjusted one by one so each is [minAccentDeltaE] from every
  /// colour in [avoid], clearly distinct from the other tones and
  /// readable on [background]. A tone that already is stays unchanged;
  /// otherwise the smallest saturation/lightness change that works wins.
  static List<Color> _clearOf(
    List<Color> tones,
    List<Color> avoid,
    Color background,
  ) {
    final result = [...tones];
    for (var i = 0; i < result.length; i++) {
      final others = [
        for (var j = 0; j < result.length; j++)
          if (j != i) result[j],
      ];
      bool clear(Color c) =>
          avoid.every((a) => deltaE(c, a) >= minAccentDeltaE) &&
          others.every(
            (o) =>
                deltaE(c, o) >= _minEarlierDeltaE &&
                _rgbDistance(c, o) >= _minEarlierRgb,
          ) &&
          contrastRatio(c, background) >= minToneContrast;
      if (clear(result[i])) continue;
      final adjusted = _adjustments(HSLColor.fromColor(result[i]))
          .firstWhere(clear, orElse: () => result[i]);
      result[i] = adjusted;
    }
    return result;
  }

  /// Minimum distances kept between adjusted earlier tones: perceptual
  /// (ΔE) and in 8-bit RGB, so they also differ on screens.
  static const double _minEarlierDeltaE = 20;
  static const double _minEarlierRgb = 48;

  static double _rgbDistance(Color a, Color b) {
    final dr = (a.r - b.r) * 255, dg = (a.g - b.g) * 255;
    final db = (a.b - b.b) * 255;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  /// Variants of [hsl] with less saturation and/or shifted lightness,
  /// smallest change first.
  static Iterable<Color> _adjustments(HSLColor hsl) {
    final variants = <(double, Color)>[];
    for (var dl = -0.3; dl <= 0.3001; dl += 0.03) {
      final lightness = hsl.lightness + dl;
      if (lightness < 0.08 || lightness > 0.92) continue;
      for (var ds = 0.0; ds <= hsl.saturation; ds += 0.04) {
        final color = hsl
            .withLightness(lightness)
            .withSaturation(hsl.saturation - ds)
            .toColor();
        variants.add((dl.abs() * 2 + ds, color));
      }
    }
    variants.sort((a, b) => a.$1.compareTo(b.$1));
    return variants.map((v) => v.$2);
  }

  /// [color] pushed away from [background] until it has [minContrast].
  static Color _readableOn(
    Color color,
    Color background, {
    double minContrast = minToneContrast,
  }) {
    final target = background.computeLuminance() < 0.5
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    var result = color;
    for (
      var t = 0.1;
      contrastRatio(result, background) < minContrast && t <= 1;
      t += 0.1
    ) {
      result = Color.lerp(color, target, t)!;
    }
    return result;
  }

  @override
  PhaseColors copyWith({
    Color? current,
    Color? planned,
    Color? plannedTint,
    List<Color>? earlier,
    Color? before,
  }) {
    return PhaseColors(
      current: current ?? this.current,
      planned: planned ?? this.planned,
      plannedTint: plannedTint ?? this.plannedTint,
      earlier: earlier ?? this.earlier,
      before: before ?? this.before,
    );
  }

  @override
  PhaseColors lerp(ThemeExtension<PhaseColors>? other, double t) {
    if (other is! PhaseColors) return this;
    return PhaseColors(
      current: Color.lerp(current, other.current, t)!,
      planned: Color.lerp(planned, other.planned, t)!,
      plannedTint: Color.lerp(plannedTint, other.plannedTint, t)!,
      earlier: _lerpEarlier(other.earlier, t),
      before: Color.lerp(before, other.before, t)!,
    );
  }

  List<Color> _lerpEarlier(List<Color> other, double t) {
    if (other.length != earlier.length) return t < 0.5 ? earlier : other;
    return [
      for (var i = 0; i < earlier.length; i++)
        Color.lerp(earlier[i], other[i], t)!,
    ];
  }

  @override
  bool operator ==(Object other) {
    return other is PhaseColors &&
        other.current == current &&
        other.planned == planned &&
        other.plannedTint == plannedTint &&
        listEquals(other.earlier, earlier) &&
        other.before == before;
  }

  @override
  int get hashCode =>
      Object.hash(current, planned, plannedTint, Object.hashAll(earlier), before);
}
