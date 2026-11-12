import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// "50 months so far · 11 % of your life so far · 14 months still
/// planned": three quiet tiles about the current phase. The share needs a
/// birth date; without a planned end the last tile says "open".
class PhaseStatTiles extends StatelessWidget {
  const PhaseStatTiles({
    super.key,
    required this.span,
    required this.today,
    required this.birthDate,
  });

  final PhaseSpan span;
  final DateTime today;
  final DateTime? birthDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final months = monthsIn(span, today);
    final birth = birthDate;
    final share = birth == null ? null : shareOfLifeSoFar(months, birth, today);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          _tile(context, 'phase_stat_months', l10n.numberFormat.format(months),
              l10n.plural('phase_stat_months', months)),
          if (share != null)
            _tile(context, 'phase_stat_share', _percent(l10n, share),
                l10n.translate('phase_stat_life_share')),
          _plannedTile(context, l10n),
        ],
      ),
    );
  }

  String _percent(AppLocalizations l10n, double share) {
    final percent = (share * 100).round();
    final p = percent < 1 && share > 0 ? '<1' : l10n.numberFormat.format(percent);
    return l10n.translate('phase_stat_percent', replacements: {'p': p});
  }

  /// Months (or, in the last month, weeks) still planned; "open" without
  /// a planned end.
  Widget _plannedTile(BuildContext context, AppLocalizations l10n) {
    final gold = PhaseStyle.readableGold(context);
    if (span.phase.plannedEnd == null) {
      return _tile(context, 'phase_stat_left', l10n.translate('phase_stat_open'),
          l10n.translate('phase_stat_open_label'), color: gold);
    }
    final months = plannedMonthsLeft(span, today) ?? 0;
    final weeks = plannedWeeksLeft(span, today) ?? 0;
    final inWeeks = months == 0 && weeks > 0;
    final n = inWeeks ? weeks : months;
    return _tile(context, 'phase_stat_left', l10n.numberFormat.format(n),
        l10n.plural(inWeeks ? 'phase_stat_weeks_left' : 'phase_stat_left', n),
        color: gold);
  }

  Widget _tile(BuildContext context, String key, String value, String label,
      {Color? color}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        key: ValueKey(key),
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Fraunces', color: color)),
            const SizedBox(height: 4),
            Text(label, style: PhaseStyle.muted(context)),
          ],
        ),
      ),
    );
  }
}
