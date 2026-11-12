import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/liquid_progress_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/spiral_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/layout_text.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

ThemeData _theme(ThemeStyle style, Brightness brightness, String colorThemeId) =>
    AppTheme.build(
      style: style,
      brightness: brightness,
      gridOverride: LifePaletteColors.forColorThemeId(colorThemeId),
    );

void main() {
  group('contrast', () {
    test('black on white is 21:1, a colour on itself 1:1', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
      expect(contrastRatio(Colors.red, Colors.red), 1);
    });

    test('mostReadableOn picks the candidate with the higher contrast', () {
      const candidates = [Colors.white, Colors.black];
      expect(mostReadableOn(const Color(0xFF1F1F21), candidates), Colors.white);
      expect(mostReadableOn(const Color(0xFFE3DED3), candidates), Colors.black);
    });
  });

  group('LayoutText.fromTheme', () {
    for (final brightness in Brightness.values) {
      for (final style in ThemeStyle.values) {
        for (final id in ColorThemes.getSelectableThemeIds()) {
          test('$id ${style.name} ${brightness.name}: text >= 4.5:1 on '
              'lived, remaining and background', () {
            final theme = _theme(style, brightness, id);
            final palette = theme.extension<LifePalette>()!;
            final text = LayoutText.fromTheme(theme);
            for (final background in [
              palette.lived,
              palette.remaining,
              text.background,
            ]) {
              expect(
                contrastRatio(text.colorOn(background), background),
                greaterThanOrEqualTo(4.5),
                reason: 'on $background',
              );
            }
          });
        }
      }
    }

    test('uses the app font and haloes text in the opposite colour', () {
      final theme = _theme(ThemeStyle.stoic, Brightness.dark, 'default');
      final text = LayoutText.fromTheme(theme);
      final style = text.styleOn(text.background, fontSize: 12);
      expect(style.fontFamily, AppTheme.sansFamily);
      expect(style.color, text.light);
      expect(style.shadows!.single.color.withValues(alpha: 1), text.dark);
    });
  });

  group('LiquidProgressPainter.backgroundAt', () {
    const size = Size(200, 240);
    final colors = ColorThemes.getTheme('ocean');

    test('is the liquid below the surface and the container above it', () {
      final surface = LiquidProgressPainter.liquidTopFor(size, 0.5);
      expect(surface, 120);
      expect(LiquidProgressPainter.backgroundAt(130, size, 0.5, colors),
          colors.livedColor);
      expect(LiquidProgressPainter.backgroundAt(110, size, 0.5, colors),
          colors.remainingColor);
    });
  });

  test('painters repaint when the text colours change', () {
    SpiralLayoutPainter painter(LayoutText text) => SpiralLayoutPainter(
          totalItems: 10,
          itemsCompleted: 5,
          colorTheme: 'default',
          visualSettings: const VisualizationSettings(),
          layoutText: text,
        );
    final light = painter(const LayoutText());
    expect(light.shouldRepaint(painter(const LayoutText())), isFalse);
    expect(
      light.shouldRepaint(painter(const LayoutText(background: Colors.black))),
      isTrue,
    );
  });
}
