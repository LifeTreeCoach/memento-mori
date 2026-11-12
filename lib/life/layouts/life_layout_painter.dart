import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/layout_labels.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/phase_layout_colors.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/theme/layout_text.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Shared inputs of the alternative life layouts; repaints only when one
/// of them changes.
abstract class LifeLayoutPainter extends CustomPainter {
  LifeLayoutPainter({
    required this.totalItems,
    required this.itemsCompleted,
    required this.colorTheme,
    this.colors,
    required this.visualSettings,
    this.animationValue = 0.0,
    this.lifeExpectancyYears = LifeCalculator.defaultLifeExpectancyYears,
    this.labels = const LayoutLabels(),
    this.ageYears,
    this.layoutText = const LayoutText(),
    Color? milestoneColor,
    this.phaseColors,
  }) : milestoneColor = milestoneColor ?? LifePalette.stoicLight.milestone;

  /// Years between two decade markers.
  static const int decadeYears = 10;

  final int totalItems;
  final int itemsCompleted;
  final String colorTheme;

  /// Resolved grid colours (theme palette); falls back to [colorTheme].
  final ColorTheme? colors;
  final VisualizationSettings visualSettings;
  final double animationValue;

  /// The user's life expectancy; years and decade markers scale to it.
  final int lifeExpectancyYears;

  final LayoutLabels labels;

  /// The user's exact age in years (from the birth date), so every view
  /// shows the same "years lived"; null derives it from the cells.
  final double? ageYears;

  /// Colours and font of the text the layout draws over its shapes.
  final LayoutText layoutText;

  /// Decade ticks and rings; the active [LifePalette.milestone], so they
  /// match the theme style instead of a fixed gold.
  final Color milestoneColor;

  /// Life phase colours; null draws no phases.
  final PhaseLayoutColors? phaseColors;

  /// Phase colour of item [index] of [totalItems], or null outside every
  /// phase (or without phases).
  Color? colorForItem(int index) =>
      phaseColors?.colorForItem(index, totalItems);

  /// Items per year of the current view (52 weeks, 12 months or 1 year).
  int get itemsPerYear =>
      lifeExpectancyYears > 0 ? (totalItems / lifeExpectancyYears).round() : 0;

  /// Share of [itemsCompleted] in [totalItems]; 0 when there are no items.
  double get progress => totalItems > 0 ? itemsCompleted / totalItems : 0;

  /// Years lived: the exact [ageYears] when known, else [progress] of
  /// [lifeExpectancyYears] (depends on the cell size of the view).
  double get yearsLived => ageYears ?? progress * lifeExpectancyYears;

  /// Percent of life lived shown as text: from [yearsLived], so it is the
  /// same in every view (the shapes keep using the cell-based [progress]).
  double get percentLived => lifeExpectancyYears > 0
      ? (yearsLived / lifeExpectancyYears * 100).clamp(0, 100).toDouble()
      : 0;

  /// [colors], or the legacy theme named by [colorTheme].
  ColorTheme get resolvedColors => colors ?? ColorThemes.getTheme(colorTheme);

  /// The decades (10, 20, ...) up to [lifeExpectancyYears].
  Iterable<int> get decades sync* {
    for (
      var decade = decadeYears;
      decade <= lifeExpectancyYears;
      decade += decadeYears
    ) {
      yield decade;
    }
  }

  @override
  bool shouldRepaint(LifeLayoutPainter oldDelegate) {
    return oldDelegate.runtimeType != runtimeType ||
        oldDelegate.totalItems != totalItems ||
        oldDelegate.itemsCompleted != itemsCompleted ||
        oldDelegate.colorTheme != colorTheme ||
        oldDelegate.colors != colors ||
        oldDelegate.visualSettings != visualSettings ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.lifeExpectancyYears != lifeExpectancyYears ||
        oldDelegate.ageYears != ageYears ||
        oldDelegate.labels != labels ||
        oldDelegate.layoutText != layoutText ||
        oldDelegate.milestoneColor != milestoneColor ||
        oldDelegate.phaseColors != phaseColors;
  }
}

/// Lays out [text] in [style] left to right; the caller disposes it.
TextPainter layoutPainterText(
  String text,
  TextStyle style, {
  TextAlign textAlign = TextAlign.start,
}) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  textAlign: textAlign,
)..layout();
