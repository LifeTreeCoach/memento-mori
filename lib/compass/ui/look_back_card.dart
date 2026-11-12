import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/look_back.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';

/// "Look back": the moments kept per life area and decade of life, and a
/// compassionate line about the weeks already lived.
class LookBackCard extends StatelessWidget {
  const LookBackCard({super.key, required this.lookBack, this.weeksLived});

  final LookBack lookBack;

  /// Weeks lived; the compassionate line needs it.
  final int? weeksLived;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('compass_look_back'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(l10n.translate('compass_look_back')),
            const SizedBox(height: 8),
            Text(
              l10n.translate('compass_kept'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w400,
                color: LifePalette.of(context).quoteText,
              ),
            ),
            ..._group(context, l10n.translate('compass_by_area'), [
              for (final (area, count) in lookBack.byArea)
                (_areaName(l10n, area), count),
            ]),
            if (lookBack.byDecade.isNotEmpty)
              ..._group(context, l10n.translate('compass_by_decade'), [
                for (final (decade, count) in lookBack.byDecade)
                  (_decadeName(l10n, decade), count),
              ]),
            if (lookBack.byPhase.isNotEmpty)
              ..._group(context, l10n.translate('compass_by_phase'), [
                for (final (phase, count) in lookBack.byPhase)
                  (phaseDisplayName(phase, l10n), count),
              ]),
            if (weeksLived case final weeks?) _weeksLine(context, l10n, weeks),
          ],
        ),
      ),
    );
  }

  String _areaName(AppLocalizations l10n, LifeArea? area) =>
      area == null ? l10n.translate('compass_no_area') : l10n.areaLabel(area);

  String _decadeName(AppLocalizations l10n, int decade) => l10n.translate(
      'compass_decade',
      replacements: {'from': '$decade', 'to': '${decade + 9}'});

  List<Widget> _group(
      BuildContext context, String title, List<(String, int)> rows) {
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 16),
      Text(title,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final (name, count) in rows) _pill(context, name, count)],
      ),
    ];
  }

  /// "Health · 3 moments" on a soft tonal background.
  Widget _pill(BuildContext context, String name, int count) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final moments = l10n.plural('compass_moment_count', count,
        replacements: {'n': l10n.numberFormat.format(count)});
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('$name · $moments',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
    );
  }

  Widget _weeksLine(BuildContext context, AppLocalizations l10n, int weeks) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        l10n.plural('compass_weeks_lived', weeks,
            replacements: {'n': l10n.numberFormat.format(weeks)}),
        key: const ValueKey('compass_weeks_lived'),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}
