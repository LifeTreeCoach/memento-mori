import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/time_window.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// "This phase in weeks": one dot per week (or per 4, 13 or 52 weeks for
/// long phases), always with its scale caption ("1 dot = 1 week") – lived
/// weeks filled in the current phase colour, the planned rest light. With
/// [highlight], the dot of week [highlightWeek] is drawn by it instead.
class PhaseWeekDots extends StatelessWidget {
  const PhaseWeekDots({
    super.key,
    required this.weeks,
    this.highlightWeek,
    this.highlight,
  });

  final PhaseWeeks weeks;

  /// 0-based week whose dot [highlight] replaces.
  final int? highlightWeek;

  /// Widget of [dotSize] standing in for the highlighted dot.
  final Widget? highlight;

  static const double dotSize = 7;
  static const double gap = 3;

  @override
  Widget build(BuildContext context) {
    final colors = PhaseColors.of(context);
    final perDot = weeksPerDot(weeks.total);
    final total = dotsFor(weeks.total, perDot);
    final lived = (weeks.lived ~/ perDot).clamp(0, total);
    final week = highlightWeek;
    final highlighted = week == null || highlight == null ? -1 : week ~/ perDot;
    return Column(
      key: const ValueKey('intention_week_dots'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: AppLocalizations.of(context)
              .plural('intention_window_weeks', weeks.left),
          excludeSemantics: true,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < total; i++)
                i == highlighted
                    ? SizedBox.square(dimension: dotSize, child: highlight)
                    : _dot(i < lived ? colors.current : colors.planned),
            ],
          ),
        ),
        _caption(context, perDot),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _caption(BuildContext context, int perDot) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        AppLocalizations.of(context).plural('intention_dots_scale', perDot),
        key: const ValueKey('intention_dots_scale'),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
