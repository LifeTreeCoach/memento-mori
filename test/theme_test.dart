import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

const _combos = [
  (ThemeStyle.stoic, Brightness.light),
  (ThemeStyle.stoic, Brightness.dark),
  (ThemeStyle.warm, Brightness.light),
  (ThemeStyle.warm, Brightness.dark),
];

ThemeData _build(ThemeStyle style, Brightness brightness) =>
    AppTheme.build(style: style, brightness: brightness);

void main() {
  group('AppTheme.build', () {
    for (final (style, brightness) in _combos) {
      final name = '${style.id}/${brightness.name}';

      test('$name uses Material 3 with matching brightness', () {
        final theme = _build(style, brightness);
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme.brightness, brightness);
        expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
      });

      test('$name exposes a LifePalette extension', () {
        final palette = _build(style, brightness).extension<LifePalette>();
        expect(palette, isNotNull);
        expect(palette, LifePalette.resolve(style, brightness));
      });

      test('$name uses the expected font families', () {
        final text = _build(style, brightness).textTheme;
        final heading = style == ThemeStyle.stoic
            ? AppTheme.serifFamily
            : AppTheme.roundedFamily;
        expect(text.displayLarge?.fontFamily, heading);
        expect(text.headlineMedium?.fontFamily, heading);
        expect(text.titleLarge?.fontFamily, heading);
        expect(text.bodyLarge?.fontFamily, AppTheme.sansFamily);
        expect(text.bodyMedium?.fontFamily, AppTheme.sansFamily);
        expect(text.labelLarge?.fontFamily, AppTheme.sansFamily);
      });

      test('$name primary text pairs reach 4.5:1', () {
        final s = _build(style, brightness).colorScheme;
        final pairs = {
          'onSurface/surface': (s.onSurface, s.surface),
          'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
          'onSurface/surfaceContainerHigh': (s.onSurface, s.surfaceContainerHigh),
          'onPrimary/primary': (s.onPrimary, s.primary),
          'primary/surface': (s.primary, s.surface),
          'onPrimaryContainer/primaryContainer':
              (s.onPrimaryContainer, s.primaryContainer),
          'onSecondaryContainer/secondaryContainer':
              (s.onSecondaryContainer, s.secondaryContainer),
          'onInverseSurface/inverseSurface':
              (s.onInverseSurface, s.inverseSurface),
        };
        pairs.forEach((label, pair) {
          expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5),
              reason: '$name $label');
        });
      });
    }

    test('stoic onSurface vs surface reaches 7:1 (AAA)', () {
      for (final brightness in Brightness.values) {
        final s = _build(ThemeStyle.stoic, brightness).colorScheme;
        expect(contrastRatio(s.onSurface, s.surface), greaterThanOrEqualTo(7),
            reason: 'stoic/${brightness.name}');
      }
    });

    test('stoic dark is ink on paper', () {
      final s = _build(ThemeStyle.stoic, Brightness.dark).colorScheme;
      expect(s.surface, const Color(0xFF0F0F10));
      expect(s.onSurface, const Color(0xFFF4F1EA));
    });

    test('card radius differs between styles', () {
      double radius(ThemeStyle style) {
        final shape = _build(style, Brightness.light).cardTheme.shape
            as RoundedRectangleBorder;
        return (shape.borderRadius as BorderRadius).topLeft.x;
      }

      expect(radius(ThemeStyle.stoic), 12);
      expect(radius(ThemeStyle.warm), 20);
    });
  });

  group('LifePalette', () {
    test('equal palettes compare equal, so theme changes do not animate', () {
      final copy = LifePalette.stoicDark.copyWith();
      expect(identical(copy, LifePalette.stoicDark), isFalse);
      expect(copy, LifePalette.stoicDark);
      expect(copy.hashCode, LifePalette.stoicDark.hashCode);
      expect(LifePalette.stoicDark.copyWith(now: LifePalette.stoicLight.now),
          isNot(LifePalette.stoicDark));
    });

    test('grid override replaces only lived/remaining/gridLine', () {
      final ocean = ColorThemes.getTheme('ocean');
      final palette = AppTheme.build(
        style: ThemeStyle.stoic,
        brightness: Brightness.light,
        gridOverride: LifePaletteColors.fromColorTheme(ocean),
      ).extension<LifePalette>()!;
      expect(palette.lived, ocean.livedColor);
      expect(palette.remaining, ocean.remainingColor);
      expect(palette.gridLine, ocean.borderColor);
      expect(palette.now, LifePalette.stoicLight.now);
    });

    for (final id in ColorThemes.themes.keys) {
      for (final style in ThemeStyle.values) {
        test('$id on ${style.name} dark keeps remaining cells subdued', () {
          final base = LifePalette.resolve(style, Brightness.dark);
          final palette = LifePalette.resolve(style, Brightness.dark,
              gridOverride: LifePaletteColors.forColorThemeId(id));
          expect(contrastRatio(palette.remaining, base.remaining),
              lessThan(1.5), reason: 'remaining close to the style default');
          expect(contrastRatio(palette.lived, palette.remaining),
              greaterThanOrEqualTo(LifePaletteColors.minDarkLivedContrast));
          expect(palette.gridLine, base.gridLine);
        });
      }
    }

    test('style default id yields no override', () {
      expect(LifePaletteColors.forColorThemeId(ColorThemes.styleDefaultId),
          isNull);
      expect(LifePaletteColors.forColorThemeId('sunset'), isNotNull);
    });

    test('lerp interpolates and copyWith overrides', () {
      final mid = LifePalette.stoicDark.lerp(LifePalette.stoicLight, 0.5);
      expect(mid.lived,
          Color.lerp(LifePalette.stoicDark.lived, LifePalette.stoicLight.lived, 0.5));
      final copy = LifePalette.stoicDark.copyWith(now: const Color(0xFF123456));
      expect(copy.now, const Color(0xFF123456));
      expect(copy.lived, LifePalette.stoicDark.lived);
    });

    test('stoic now marker is the amber accent', () {
      expect(LifePalette.stoicDark.now, LifePalette.amber);
    });
  });

  group('theme options', () {
    test('ids round-trip and unknown ids fall back', () {
      for (final style in ThemeStyle.values) {
        expect(ThemeStyle.fromId(style.id), style);
      }
      for (final b in AppBrightness.values) {
        expect(AppBrightness.fromId(b.id), b);
      }
      expect(ThemeStyle.fromId('nope'), ThemeStyle.stoic);
      expect(AppBrightness.fromId(null), AppBrightness.system);
    });

    test('AppBrightness resolves system to platform value', () {
      expect(AppBrightness.system.resolve(Brightness.dark), Brightness.dark);
      expect(AppBrightness.light.resolve(Brightness.dark), Brightness.light);
      expect(AppBrightness.dark.themeMode, ThemeMode.dark);
    });
  });

  test('language defaults follow device locale', () {
    expect(SettingsService.languageForLocale('de'), 'de');
    expect(SettingsService.languageForLocale('en'), 'en');
    expect(SettingsService.languageForLocale('it'), 'en');
  });
}
