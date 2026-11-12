import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/layout_labels.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/liquid_progress_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/phase_layout_colors.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/spiral_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/tree_rings_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/breath.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/theme/layout_text.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// Spiral, liquid and tree-ring layouts. Animations only run while motion
/// is enabled and the tab is visible (via [TickerMode]): spiral and liquid
/// loop; tree rings let their "now" ring breathe a few times whenever they
/// become visible, then stay still.
class AlternativeLayoutView extends StatefulWidget {
  const AlternativeLayoutView({
    super.key,
    required this.settings,
    required this.totalItems,
    required this.itemsCompleted,
    required this.colorThemeId,
    required this.lifeExpectancyYears,
    required this.semanticsLabel,
    this.ageYears,
    this.phaseFractions = const [],
  });

  final VisualizationSettings settings;
  final int totalItems;
  final int itemsCompleted;
  final String colorThemeId;
  final int lifeExpectancyYears;
  final String semanticsLabel;

  /// Exact age in years, shown as "years lived" in every view.
  final double? ageYears;

  /// Life phase runs as shares of the lifespan (empty: no phases).
  final List<PhaseFraction> phaseFractions;

  @override
  State<AlternativeLayoutView> createState() => _AlternativeLayoutViewState();
}

class _AlternativeLayoutViewState extends State<AlternativeLayoutView>
    with TickerProviderStateMixin {
  /// Endless loop for the spiral pulse and the liquid wave.
  late final AnimationController _animation =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  /// A few calm breaths of the tree rings' "now" ring, then still.
  late final BreathCycle _emphasis = BreathCycle(vsync: this);

  late final Listenable _repaint =
      Listenable.merge([_animation, _emphasis.progress]);

  bool get _isTreeRings =>
      widget.settings.layoutType == LayoutType.treeRings ||
      widget.settings.layoutType == LayoutType.grid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(AlternativeLayoutView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final animate = Motion.enabled(context) && widget.settings.enableAnimations;
    _syncLoop(animate && !_isTreeRings);
    _emphasis.update(
      motion: animate && _isTreeRings,
      visible: TickerMode.valuesOf(context).enabled,
    );
  }

  void _syncLoop(bool loop) {
    if (loop && !_animation.isAnimating) {
      _animation.repeat();
    } else if (!loop) {
      _animation.stop();
    }
  }

  /// 0 at rest, rising to 1 at the height of each breath.
  double get _boundaryEmphasis => 1 - _emphasis.breath.value;

  @override
  void dispose() {
    _animation.dispose();
    _emphasis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = LifePalette.of(context);
    final colors = palette.toColorTheme();
    final labels = _labels(context);
    final text = LayoutText.fromTheme(Theme.of(context));
    final phases = widget.phaseFractions.isEmpty
        ? null
        : PhaseLayoutColors(
            fractions: widget.phaseFractions,
            colors: PhaseColors.of(context),
          );
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _repaint,
            builder: (context, _) => CustomPaint(
              painter: _painterFor(colors, palette.milestone, labels, text,
                  phases, _animation.isAnimating ? _animation.value : 0),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  LayoutLabels _labels(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutLabels(
      yearsLived: l10n.translate('layout_years_lived'),
      yearsStacked: l10n.translate('layout_years_stacked'),
      grown: l10n.translate('layout_grown'),
      percent: l10n.translate('layout_percent'),
      decimalSeparator: l10n.translate('layout_decimal_separator'),
    );
  }

  CustomPainter _painterFor(
    ColorTheme colors,
    Color milestoneColor,
    LayoutLabels labels,
    LayoutText text,
    PhaseLayoutColors? phases,
    double t,
  ) {
    switch (widget.settings.layoutType) {
      case LayoutType.spiral:
        return SpiralLayoutPainter(
          totalItems: widget.totalItems,
          itemsCompleted: widget.itemsCompleted,
          colorTheme: widget.colorThemeId,
          colors: colors,
          visualSettings: widget.settings,
          animationValue: t,
          lifeExpectancyYears: widget.lifeExpectancyYears,
          ageYears: widget.ageYears,
          labels: labels,
          layoutText: text,
          milestoneColor: milestoneColor,
          phaseColors: phases,
        );
      case LayoutType.liquid:
        return LiquidProgressPainter(
          totalItems: widget.totalItems,
          itemsCompleted: widget.itemsCompleted,
          colorTheme: widget.colorThemeId,
          colors: colors,
          visualSettings: widget.settings,
          animationValue: t,
          lifeExpectancyYears: widget.lifeExpectancyYears,
          ageYears: widget.ageYears,
          labels: labels,
          layoutText: text,
          milestoneColor: milestoneColor,
          phaseColors: phases,
        );
      case LayoutType.treeRings:
      case LayoutType.grid:
        return TreeRingsLayoutPainter(
          totalItems: widget.totalItems,
          itemsCompleted: widget.itemsCompleted,
          colorTheme: widget.colorThemeId,
          colors: colors,
          visualSettings: widget.settings,
          animationValue: t,
          lifeExpectancyYears: widget.lifeExpectancyYears,
          ageYears: widget.ageYears,
          labels: labels,
          layoutText: text,
          milestoneColor: milestoneColor,
          phaseColors: phases,
          boundaryEmphasis: _boundaryEmphasis,
        );
    }
  }
}
