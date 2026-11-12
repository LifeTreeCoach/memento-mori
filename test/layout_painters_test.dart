import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/layout_labels.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/liquid_progress_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/phase_layout_colors.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/spiral_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/tree_rings_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

void main() {
  group('years lived', () {
    LiquidProgressPainter painter(int total, int lived, {double? age}) =>
        LiquidProgressPainter(
          totalItems: total,
          itemsCompleted: lived,
          colorTheme: 'default',
          visualSettings: const VisualizationSettings(),
          lifeExpectancyYears: 90,
          ageYears: age,
        );

    test('the exact age is the same in every view', () {
      const age = 36.64;
      expect(painter(4680, 1911, age: age).yearsLived, age); // weeks
      expect(painter(1080, 439, age: age).yearsLived, age); // months
      expect(painter(90, 36, age: age).yearsLived, age); // years
    });

    test('the shown percent follows the exact age in every view', () {
      const age = 36.64;
      final weeks = painter(4680, 1911, age: age).percentLived;
      expect(painter(90, 36, age: age).percentLived, closeTo(weeks, 1e-9));
      expect(weeks, closeTo(40.71, 0.01));
    });

    test('without an age it is derived from the cells', () {
      expect(painter(90, 36).yearsLived, 36);
    });
  });

  group('LiquidProgressPainter axis', () {
    const size = Size(345, 345);

    test('the container leaves a strip for the decade axis on the right', () {
      final container = LiquidProgressPainter.containerRect(size);
      expect(container.left, LiquidProgressPainter.inset);
      expect(container.right,
          size.width - LiquidProgressPainter.axisWidth);
      expect(container.bottom, size.height - LiquidProgressPainter.inset);
    });

    test('labels start right of the container, clear of the fill', () {
      final labelLeft = LiquidProgressPainter.axisLabelLeft(size);
      expect(labelLeft,
          greaterThan(LiquidProgressPainter.containerRect(size).right + 1.5));
      // Room for "100" at 12 px.
      expect(size.width - labelLeft, greaterThanOrEqualTo(24));
    });
  });

  group('LiquidProgressPainter.textShiftOffSurface', () {
    double shift(double surface) => LiquidProgressPainter.textShiftOffSurface(
        top: 100, bottom: 160, surface: surface);

    test('leaves text alone when the surface is clear of it', () {
      expect(shift(50), 0);
      expect(shift(200), 0);
    });

    test('moves text above a surface near its bottom', () {
      final s = shift(150);
      expect(s, lessThan(0));
      expect(160 + s, lessThanOrEqualTo(150 - 3)); // below the wave crest
    });

    test('moves text onto the liquid when the surface is near its top', () {
      final s = shift(105);
      expect(s, greaterThan(0));
      expect(100 + s, greaterThanOrEqualTo(105 + 3));
    });

    group('with a planned band above the liquid', () {
      double planned(double surface, double plannedTop) =>
          LiquidProgressPainter.textShiftOffSurface(
              top: 100, bottom: 160, surface: surface, plannedTop: plannedTop);

      test('keeps text clear of the planned band\'s top edge', () {
        // Text ends right on the band's top edge: moved up with a gap.
        final s = planned(200, 160);
        expect(s, lessThan(0));
        expect(160 + s, lessThanOrEqualTo(160 - 3));
      });

      test('leaves text alone well above the band', () {
        expect(planned(260, 200), 0);
      });

      test('never puts text inside a thin band', () {
        final s = planned(150, 140);
        final top = 100 + s;
        final bottom = 160 + s;
        expect(bottom <= 140 - 3 || top >= 150 + 3, isTrue);
      });
    });
  });

  group('TreeRingsLayoutPainter.centerTextScale', () {
    test('keeps full size when the text fits the disc', () {
      expect(TreeRingsLayoutPainter.centerTextScale(50, 60), 1);
      expect(TreeRingsLayoutPainter.centerTextScale(60, 60), 1);
    });

    test('shrinks the text to the disc', () {
      expect(TreeRingsLayoutPainter.centerTextScale(80, 60), closeTo(0.75, 1e-9));
    });

    test('never goes below the minimum scale', () {
      expect(TreeRingsLayoutPainter.centerTextScale(100, 10),
          TreeRingsLayoutPainter.minCenterTextScale);
      expect(TreeRingsLayoutPainter.centerTextScale(100, -5),
          TreeRingsLayoutPainter.minCenterTextScale);
    });
  });

  group('milestone colour', () {
    LiquidProgressPainter liquid(Color? color) => LiquidProgressPainter(
          totalItems: 10,
          itemsCompleted: 5,
          colorTheme: 'default',
          visualSettings: const VisualizationSettings(),
          milestoneColor: color,
        );

    test('defaults to the Stoic palette milestone, not a fixed gold', () {
      expect(liquid(null).milestoneColor, LifePalette.stoicLight.milestone);
      expect(liquid(null).milestoneColor, isNot(const Color(0xFFFFD700)));
    });

    test('a palette change repaints', () {
      final stoic = liquid(LifePalette.stoicDark.milestone);
      expect(stoic.shouldRepaint(liquid(LifePalette.stoicDark.milestone)),
          isFalse);
      expect(stoic.shouldRepaint(liquid(LifePalette.warmLight.milestone)),
          isTrue);
    });
  });

  group('painting', () {
    const settings = VisualizationSettings(enableMilestones: true);
    for (final completed in [0, 1, 459, 1000]) {
      test('liquid and tree rings paint at $completed/1000', () {
        for (final painter in <CustomPainter>[
          LiquidProgressPainter(
            totalItems: 1000,
            itemsCompleted: completed,
            colorTheme: 'default',
            visualSettings: settings,
          ),
          TreeRingsLayoutPainter(
            totalItems: 1000,
            itemsCompleted: completed,
            colorTheme: 'default',
            visualSettings: settings,
            labels: const LayoutLabels(grown: '{value}\u00A0% gewachsen'),
          ),
        ]) {
          final recorder = ui.PictureRecorder();
          painter.paint(Canvas(recorder), const Size(345, 345));
          recorder.endRecording().dispose();
        }
      });
    }
  });

  group('phase colours', () {
    final colors = PhaseColors.stoicLight;
    // 100 items, 40 lived: earlier 0..10, current 10..41, planned 41..50.
    final phases = PhaseLayoutColors(colors: colors, fractions: const [
      (from: 0.0, to: 0.1, kind: PhaseSlotKind.earlier, earlierIndex: 0),
      (from: 0.1, to: 0.41, kind: PhaseSlotKind.current, earlierIndex: -1),
      (from: 0.41, to: 0.5, kind: PhaseSlotKind.planned, earlierIndex: -1),
    ]);

    test('colour per item follows the phase it lies in', () {
      expect(phases.colorForItem(0, 100), colors.earlierAt(0));
      expect(phases.colorForItem(9, 100), colors.earlierAt(0));
      expect(phases.colorForItem(10, 100), colors.current);
      expect(phases.colorForItem(40, 100), colors.current);
      expect(phases.colorForItem(41, 100), colors.planned);
      expect(phases.colorForItem(50, 100), isNull);
      expect(phases.colorForItem(0, 0), isNull);
    });

    test('colour per share of the lifespan', () {
      expect(phases.colorForFraction(0.05), colors.earlierAt(0));
      expect(phases.colorForFraction(0.45), colors.planned);
      expect(phases.colorForFraction(0.9), isNull);
    });

    test('bands: lived phases end at the progress, planned starts there', () {
      final bands = phases.bands(0.4);
      expect(bands.map((b) => (b.from, b.to)),
          [(0.0, 0.1), (0.1, 0.4), (0.4, 0.5)]);
      expect(bands.map((b) => b.color),
          [colors.earlierAt(0), colors.current, colors.planned]);
    });

    test('equal inputs are equal, so painters do not repaint', () {
      final same = PhaseLayoutColors(
          colors: colors, fractions: List.of(phases.fractions));
      expect(same, phases);
      expect(same.hashCode, phases.hashCode);
    });

    SpiralLayoutPainter spiral(PhaseLayoutColors? p) => SpiralLayoutPainter(
          totalItems: 100,
          itemsCompleted: 40,
          colorTheme: 'default',
          visualSettings: const VisualizationSettings(),
          phaseColors: p,
        );

    test('painters without phases have no item colours', () {
      expect(spiral(null).colorForItem(5), isNull);
      expect(spiral(phases).colorForItem(5), colors.earlierAt(0));
      expect(spiral(phases).colorForItem(45), colors.planned);
    });

    test('a phase change repaints', () {
      expect(spiral(phases).shouldRepaint(spiral(phases)), isFalse);
      expect(spiral(phases).shouldRepaint(spiral(null)), isTrue);
    });

    test('every layout paints with phases', () {
      const settings = VisualizationSettings(enableSeasons: true);
      for (final painter in <CustomPainter>[
        spiral(phases),
        LiquidProgressPainter(
          totalItems: 100,
          itemsCompleted: 40,
          colorTheme: 'default',
          visualSettings: settings,
          phaseColors: phases,
        ),
        TreeRingsLayoutPainter(
          totalItems: 100,
          itemsCompleted: 40,
          colorTheme: 'default',
          visualSettings: settings,
          phaseColors: phases,
        ),
      ]) {
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), const Size(345, 345));
        recorder.endRecording().dispose();
      }
    });
  });
}
