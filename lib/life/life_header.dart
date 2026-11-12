import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Numbers shown in the header for one mode, derived from [LifeCalculator].
class LifeHeaderData {
  LifeHeaderData(LifeMode mode, LifeCalculator calc)
      : unitKey = _unitKeys[mode]!,
        current = mode.livedCells(calc) + 1,
        total = mode.totalCells(calc),
        percent = calc.percentLived.floor();

  static const Map<LifeMode, String> _unitKeys = {
    LifeMode.weeks: 'header_week',
    LifeMode.months: 'header_month',
    LifeMode.years: 'header_year',
  };

  /// Localization key of the unit label ("WEEK").
  final String unitKey;

  /// 1-based number of the unit currently being lived.
  final int current;
  final int total;

  /// Share of the grid already lived, 0..1.
  double get progress => total == 0 ? 1 : (current - 1).clamp(0, total) / total;

  /// Whole percent of life lived, floored like the native widget
  /// (see docs/widget-data-contract.md) so app and widget always agree.
  final int percent;
}

/// "WEEK / 2,047 / of 4,160 · 49% lived" with a thin progress line.
class LifeHeader extends StatelessWidget {
  const LifeHeader({super.key, required this.data});

  final LifeHeaderData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final numbers = l10n.numberFormat;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate(data.unitKey).toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: muted,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            numbers.format(data.current),
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 72,
              height: 1.05,
              fontFeatures: const [FontFeature.liningFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.translate('header_of', replacements: {
                'total': numbers.format(data.total)
              })} · ${l10n.translate('percent_lived', replacements: {
                'p': '${data.percent}'
              })}',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 14),
        LifeProgressLine(progress: data.progress),
      ],
    );
  }
}

/// A 2px line; the lived part in the "now" amber.
class LifeProgressLine extends StatelessWidget {
  const LifeProgressLine({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = LifePalette.of(context);
    final track = Theme.of(context).colorScheme.outlineVariant;
    return ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: SizedBox(
        height: 2,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: palette.now),
            ),
          ],
        ),
      ),
    );
  }
}
