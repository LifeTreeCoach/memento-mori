import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// A small ring showing how much of an expected lifespan has passed.
class LifespanRing extends StatelessWidget {
  const LifespanRing({
    super.key,
    required this.progress,
    this.size = 26,
    this.highlight = false,
  });

  /// Ring for [age] out of [lifespanYears]; a lifespan of 0 or less
  /// counts as fully lived instead of dividing by zero.
  const LifespanRing.ofAge({
    super.key,
    required int age,
    required int lifespanYears,
    this.size = 26,
    this.highlight = false,
  }) : progress = lifespanYears > 0 ? age / lifespanYears : 1.0;

  /// Share of the lifespan lived, clamped to 0..1.
  final double progress;
  final double size;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = LifePalette.of(context);
    final value = progress.clamp(0.0, 1.0);
    final percent = (value * 100).round();
    return Semantics(
      excludeSemantics: true,
      label: AppLocalizations.of(context).translate(
        'people_lifespan_semantics',
        replacements: {'p': '$percent'},
      ),
      child: SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: 2.5,
          strokeCap: StrokeCap.round,
          backgroundColor: scheme.outlineVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            highlight ? palette.accent : palette.lived,
          ),
        ),
      ),
    );
  }
}
