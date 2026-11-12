import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

/// Euclidean distance of two colours in 8-bit RGB (0..441).
double _rgbDistance(Color a, Color b) {
  double channel(double x, double y) => (x - y) * 255;
  final dr = channel(a.r, b.r);
  final dg = channel(a.g, b.g);
  final db = channel(a.b, b.b);
  return math.sqrt(dr * dr + dg * dg + db * db);
}

const double _minDistinctDistance = 40;

/// CIE L*a*b* of an sRGB colour (D65).
List<double> _lab(Color c) {
  double linear(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = linear(c.r), g = linear(c.g), b = linear(c.b);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

/// Perceptual distance (CIE76 ΔE); ~2 is just noticeable, 20+ is clearly
/// a different colour.
double _deltaE(Color a, Color b) {
  final la = _lab(a), lb = _lab(b);
  return math.sqrt(
    math.pow(la[0] - lb[0], 2) +
        math.pow(la[1] - lb[1], 2) +
        math.pow(la[2] - lb[2], 2),
  );
}

/// Every two earlier tones (also neighbours in the cycle) must be clearly
/// different colours, not two shades of one.
const double _minEarlierDeltaE = 18;
const double _minEarlierRgb = 45;

void _expectEarlierDistinct(PhaseColors phases, String name) {
  final tones = phases.earlier;
  for (var i = 0; i < tones.length; i++) {
    for (var j = i + 1; j < tones.length; j++) {
      final pair = '$name: earlier[$i] ${tones[i]} vs earlier[$j] ${tones[j]}';
      expect(
        _deltaE(tones[i], tones[j]),
        greaterThan(_minEarlierDeltaE),
        reason: pair,
      );
      expect(
        _rgbDistance(tones[i], tones[j]),
        greaterThan(_minEarlierRgb),
        reason: pair,
      );
    }
  }
}

void _expectReadable(PhaseColors phases, LifePalette palette, String name) {
  final tones = [phases.current, phases.planned, ...phases.earlier];
  for (final tone in tones) {
    expect(
      contrastRatio(tone, palette.remaining),
      greaterThanOrEqualTo(PhaseColors.minToneContrast),
      reason: '$name: $tone on ${palette.remaining}',
    );
  }
}

void _expectCurrentDistinct(PhaseColors phases, String name) {
  for (final tone in phases.earlier) {
    expect(
      _rgbDistance(phases.current, tone),
      greaterThan(_minDistinctDistance),
      reason: '$name: current ${phases.current} vs earlier $tone',
    );
  }
}

/// No earlier tone may look like the current phase or its planned rest.
const double _minAccentDeltaE = 25;

void _expectEarlierClearOfAccent(PhaseColors phases, String name) {
  for (final tone in phases.earlier) {
    expect(
      _deltaE(tone, phases.current),
      greaterThan(_minAccentDeltaE),
      reason: '$name: earlier $tone vs current ${phases.current}',
    );
    expect(
      _deltaE(tone, phases.planned),
      greaterThan(_minAccentDeltaE),
      reason: '$name: earlier $tone vs planned ${phases.planned}',
    );
    expect(
      _deltaE(tone, phases.plannedTint),
      greaterThan(_minTintDeltaE),
      reason: '$name: earlier $tone vs planned tint ${phases.plannedTint}',
    );
  }
}

/// Earlier tones keep at least this ΔE from the pale planned tint (less
/// than from the accent: earlier phases lie in the past, planned weeks in
/// the future, so they never touch in the grid).
const double _minTintDeltaE = 12;

/// The planned tint reads apart from plain remaining cells (contrast and
/// ΔE) and stays paler than the current phase.
void _expectTintDistinct(PhaseColors phases, LifePalette palette, String name) {
  final tint = phases.plannedTint;
  expect(
    contrastRatio(tint, palette.remaining),
    greaterThanOrEqualTo(PhaseColors.minTintContrast),
    reason: '$name: tint $tint vs remaining ${palette.remaining}',
  );
  expect(
    _deltaE(tint, palette.remaining),
    greaterThanOrEqualTo(PhaseColors.minTintDeltaE),
    reason: '$name: tint $tint vs remaining ${palette.remaining}',
  );
  expect(
    _deltaE(tint, phases.current),
    greaterThan(PhaseColors.minTintDeltaE),
    reason: '$name: tint $tint vs current ${phases.current}',
  );
}

/// The coming week's ring keeps [PhaseColors.minRingContrast] on the
/// surface it is drawn on.
void _expectComingRingReadable(PhaseColors phases, Color surface, String name) {
  final ring = phases.comingRingOn(surface);
  expect(
    contrastRatio(ring, surface),
    greaterThanOrEqualTo(PhaseColors.minRingContrast),
    reason: '$name: ring $ring on $surface',
  );
}

void main() {
  for (final style in ThemeStyle.values) {
    for (final brightness in Brightness.values) {
      final name = '${style.name}/${brightness.name}';
      final palette = LifePalette.resolve(style, brightness);
      final phases = PhaseColors.resolve(style, brightness);

      test('$name: every phase tone is readable on remaining cells', () {
        _expectReadable(phases, palette, name);
      });

      test('$name: current differs from every earlier tone', () {
        _expectCurrentDistinct(phases, name);
      });

      test('$name: earlier tones are clear of current and planned', () {
        _expectEarlierClearOfAccent(phases, name);
      });

      test('$name: earlier tones are clearly distinct from each other', () {
        _expectEarlierDistinct(phases, name);
      });

      test('$name: current is the accent, before the lived colour', () {
        expect(phases.current, palette.accent);
        expect(phases.before, palette.lived);
        expect(phases.earlier, hasLength(4));
      });

      test('$name: planned tint stands apart from remaining cells', () {
        _expectTintDistinct(phases, palette, name);
      });

      test('$name: planned tint is the accent blended toward remaining', () {
        expect(
          phases.plannedTint,
          Color.lerp(
              palette.accent, palette.remaining, PhaseColors.plannedTintBlend),
        );
      });

      test('$name: coming-week ring is readable on the surface', () {
        final theme = AppTheme.build(style: style, brightness: brightness);
        _expectComingRingReadable(phases, theme.colorScheme.surface, name);
      });

      test('$name: theme registers the phase colours', () {
        final theme = AppTheme.build(style: style, brightness: brightness);
        expect(theme.extension<PhaseColors>(), phases);
      });
    }
  }

  test('dark variants differ from light ones', () {
    for (final style in ThemeStyle.values) {
      final light = PhaseColors.resolve(style, Brightness.light);
      final dark = PhaseColors.resolve(style, Brightness.dark);
      expect(dark, isNot(light));
      expect(dark.earlier, isNot(light.earlier));
    }
  });

  group('derive for user colour themes', () {
    for (final id in ColorThemes.themes.keys) {
      for (final brightness in Brightness.values) {
        final name = '$id/${brightness.name}';
        final palette = LifePalette.resolve(
          ThemeStyle.stoic,
          brightness,
          gridOverride: LifePaletteColors.forColorThemeId(id),
        );
        final phases = PhaseColors.derive(palette);

        test('$name: tones readable, current distinct', () {
          _expectReadable(phases, palette, name);
          _expectCurrentDistinct(phases, name);
          _expectEarlierDistinct(phases, name);
          _expectEarlierClearOfAccent(phases, name);
          _expectTintDistinct(phases, palette, name);
          final theme = AppTheme.build(
            style: ThemeStyle.stoic,
            brightness: brightness,
            gridOverride: LifePaletteColors.forColorThemeId(id),
          );
          _expectComingRingReadable(phases, theme.colorScheme.surface, name);
          expect(phases.before, palette.lived);
          expect(phases.earlier, hasLength(4));
        });
      }
    }

    test('theme with a colour theme uses derived phase colours', () {
      final override = LifePaletteColors.forColorThemeId('ocean');
      final theme = AppTheme.build(
        style: ThemeStyle.warm,
        brightness: Brightness.light,
        gridOverride: override,
      );
      final palette = theme.extension<LifePalette>()!;
      expect(theme.extension<PhaseColors>(), PhaseColors.derive(palette));
    });
  });

  test('planned is the accent blended toward remaining', () {
    final palette = LifePalette.stoicLight;
    final phases = PhaseColors.stoicLight;
    expect(
      phases.planned,
      Color.lerp(palette.accent, palette.remaining, PhaseColors.plannedBlend),
    );
    expect(phases.planned, isNot(phases.current));
  });

  test('plannedTintOn blends less when remaining is too close', () {
    const accent = Color(0xFFE3DED3);
    const remaining = Color(0xFFE0DCD2);
    expect(PhaseColors.plannedTintOn(accent, remaining), accent);
    const gold = Color(0xFFD4973A);
    final tint = PhaseColors.plannedTintOn(gold, const Color(0xFFE3DED3));
    expect(contrastRatio(tint, const Color(0xFFE3DED3)),
        greaterThanOrEqualTo(PhaseColors.minTintContrast));
  });

  test('earlierAt cycles through the earlier tones', () {
    final phases = PhaseColors.stoicLight;
    expect(phases.earlierAt(0), phases.earlier[0]);
    expect(phases.earlierAt(3), phases.earlier[3]);
    expect(phases.earlierAt(4), phases.earlier[0]);
    expect(phases.earlierAt(9), phases.earlier[1]);
  });

  test('lerp and copyWith', () {
    final light = PhaseColors.stoicLight;
    final dark = PhaseColors.stoicDark;
    expect(light.lerp(dark, 0), light);
    expect(light.lerp(dark, 1), dark);
    expect(light.lerp(null, 0.5), light);
    expect(light.copyWith(), light);
    expect(light.copyWith(current: dark.current).current, dark.current);
    expect(light.hashCode, PhaseColors.stoicLight.hashCode);
  });

  testWidgets('of reads the theme, falls back to stoic', (tester) async {
    late PhaseColors fromTheme;
    late PhaseColors fallback;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          style: ThemeStyle.warm,
          brightness: Brightness.dark,
        ),
        home: Builder(
          builder: (context) {
            fromTheme = PhaseColors.of(context);
            return Theme(
              data: ThemeData(brightness: Brightness.light),
              child: Builder(
                builder: (inner) {
                  fallback = PhaseColors.of(inner);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    expect(fromTheme, PhaseColors.warmDark);
    expect(fallback, PhaseColors.stoicLight);
  });
}
