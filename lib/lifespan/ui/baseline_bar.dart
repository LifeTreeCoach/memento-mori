import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/lifespan_bar.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// A slim bar of the population baseline in years, against
/// [estimateMaxYears]. Shows no number (the result page does); changes
/// glide (unless motion is off). Empty while [years] is unknown.
class BaselineBar extends StatelessWidget {
  const BaselineBar({super.key, required this.years});

  final int? years;

  static const double height = 6;

  /// Share of the bar filled for [years].
  static double fractionOf(int? years) =>
      years == null ? 0 : (years / estimateMaxYears).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = LifePalette.of(context);
    final share = fractionOf(years);
    return LifespanBar(
      key: const ValueKey('lifespan_baseline_bar'),
      height: height,
      semanticsLabel: AppLocalizations.of(context)
          .translate('estimate_baseline_bar'),
      fractions: LifespanBarFractions(
        phaseStart: share,
        today: share,
        plannedEnd: share,
      ),
      colors: LifespanBarColors(
        lived: palette.lived,
        phase: palette.lived,
        planned: palette.lived,
        remaining: palette.remaining,
      ),
    );
  }
}
