import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/liquid_progress_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/phase_layout_colors.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/spiral_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/tree_rings_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/layout_text.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

double _weakest(Color text, List<Color> backgrounds) => backgrounds
    .map((b) => contrastRatio(text, b))
    .reduce((a, b) => a < b ? a : b);

void main() {
  final colors = PhaseColors.stoicLight;
  final theme = ColorThemes.getTheme('default');
  const layoutText = LayoutText();
  const darkBand = Color(0xFF5F5550);
  const lightBand = Color(0xFFB27D68);

  group('LayoutText.colorOnAll', () {
    test('one background behaves like colorOn', () {
      expect(layoutText.colorOnAll([darkBand]), layoutText.colorOn(darkBand));
    });

    test('text over a dark and a light band stays legible on the dark one',
        () {
      final both = layoutText.colorOnAll([lightBand, darkBand]);
      // colorOn(lightBand) alone picks dark text, unreadable on darkBand.
      final onLightOnly = layoutText.colorOn(lightBand);
      expect(_weakest(both, [lightBand, darkBand]),
          greaterThan(_weakest(onLightOnly, [lightBand, darkBand])));
      expect(contrastRatio(both, darkBand), greaterThan(3));
    });
  });

  group('liquid text on phase bands', () {
    // A dark earlier band (grey-brown) up to 52 %, the current phase above.
    final phases = PhaseLayoutColors(colors: colors, fractions: const [
      (from: 0.0, to: 0.52, kind: PhaseSlotKind.earlier, earlierIndex: 3),
      (from: 0.52, to: 0.6, kind: PhaseSlotKind.current, earlierIndex: -1),
    ]);
    final painter = LiquidProgressPainter(
      totalItems: 100,
      itemsCompleted: 60,
      colorTheme: 'default',
      visualSettings: const VisualizationSettings(),
      phaseColors: phases,
    );
    const size = Size(345, 345);

    test('a line straddling two bands sees both band colours', () {
      final backgrounds = painter.backgroundsBetween(160, 185, size, theme);
      expect(backgrounds,
          containsAll([colors.earlierAt(3), colors.current]));
    });

    test('a line fully on the dark band gets light text', () {
      final backgrounds = painter.backgroundsBetween(200, 220, size, theme);
      expect(backgrounds, [colors.earlierAt(3)]);
      final text = layoutText.colorOnAll(backgrounds);
      expect(contrastRatio(text, colors.earlierAt(3)),
          greaterThanOrEqualTo(LayoutText.minContrast));
    });
  });

  group('tree rings centre text on phase rings', () {
    final phases = PhaseLayoutColors(colors: colors, fractions: const [
      (from: 0.0, to: 0.1, kind: PhaseSlotKind.earlier, earlierIndex: 0),
      (from: 0.1, to: 0.45, kind: PhaseSlotKind.current, earlierIndex: -1),
    ]);
    TreeRingsLayoutPainter rings(PhaseLayoutColors? p) =>
        TreeRingsLayoutPainter(
          totalItems: 90,
          itemsCompleted: 40,
          colorTheme: 'default',
          visualSettings: const VisualizationSettings(),
          lifeExpectancyYears: 90,
          ageYears: 40,
          phaseColors: p,
        );

    test('the text sees the phase rings it covers', () {
      final backgrounds = rings(phases).centerBackgrounds(theme, 150, 30);
      expect(backgrounds, containsAll([colors.earlierAt(0), colors.current]));
      final text = layoutText.colorOnAll(backgrounds);
      expect(_weakest(text, backgrounds), greaterThan(2.5));
    });

    test('without phases the centre is the lived colour', () {
      expect(rings(null).centerBackgrounds(theme, 150, 30), [theme.livedColor]);
    });
  });

  group('spiral with phases', () {
    final phases = PhaseLayoutColors(colors: colors, fractions: const [
      (from: 0.0, to: 0.5, kind: PhaseSlotKind.earlier, earlierIndex: 0),
      (from: 0.5, to: 0.6, kind: PhaseSlotKind.current, earlierIndex: -1),
    ]);
    // Weeks view: 52 items a year, decade 10 starts at item 520.
    SpiralLayoutPainter spiral(PhaseLayoutColors? p) => SpiralLayoutPainter(
          totalItems: 52 * 90,
          itemsCompleted: 52 * 40,
          colorTheme: 'default',
          visualSettings: const VisualizationSettings(enableMilestones: true),
          lifeExpectancyYears: 90,
          milestoneColor: LifePalette.stoicLight.milestone,
          phaseColors: p,
        );
    const decadeItem = 520;
    const normalItem = 100;

    test('decades keep the normal size and get a milestone outline', () {
      final painter = spiral(phases);
      final decade = painter.dotFor(decadeItem, theme);
      final normal = painter.dotFor(normalItem, theme);
      expect(decade.radius, normal.radius);
      expect(decade.color, colors.earlierAt(0));
      expect(decade.ring, LifePalette.stoicLight.milestone);
      expect(normal.ring, isNull);
    });

    test('only the first item of a decade year gets the outline', () {
      final painter = spiral(phases);
      // The rest of the decade year (weeks 2..52) stays a plain phase dot,
      // so 52 overlapping rings never merge into a solid blob.
      for (final item in [decadeItem + 1, decadeItem + 26, decadeItem + 51]) {
        expect(painter.dotFor(item, theme).ring, isNull, reason: '$item');
      }
      expect(painter.dotFor(decadeItem * 2, theme).ring,
          LifePalette.stoicLight.milestone);
    });

    test('the current item is outlined in the text colour', () {
      final painter = spiral(phases);
      final current = painter.dotFor(52 * 40, theme);
      expect(current.ring, layoutText.colorOn(layoutText.background));
      expect(current.ring, isNot(LifePalette.stoicLight.milestone));
      expect(current.radius, painter.dotFor(normalItem, theme).radius);
    });

    test('without phases decades stay larger and have no outline', () {
      final painter = spiral(null);
      final decade = painter.dotFor(decadeItem, theme);
      final normal = painter.dotFor(normalItem, theme);
      expect(decade.radius, greaterThan(normal.radius));
      expect(decade.ring, isNull);
      expect(painter.dotFor(52 * 40, theme).ring, isNull);
    });

    test('the start mark with phases is smaller than a few dots', () {
      final normal = spiral(phases).dotFor(normalItem, theme);
      expect(SpiralLayoutPainter.phaseCenterRadius,
          lessThanOrEqualTo(normal.radius));
    });
  });
}
