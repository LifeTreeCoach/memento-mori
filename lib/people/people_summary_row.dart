import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Slim one-line summary: "5 people · 1 today · 2 in 30 days" ("2 of 5
/// people · …" while a filter narrows the list to [people] of [total]),
/// plus a removable chip for an active date filter.
class PeopleSummaryRow extends StatelessWidget {
  const PeopleSummaryRow({
    super.key,
    required this.people,
    required this.today,
    required this.soon,
    this.total,
    this.activeFilterLabel,
    this.onClearFilter,
  });

  final int people;
  final int today;
  final int soon;

  /// Everyone, when a filter is active; null when [people] is everyone.
  final int? total;
  final String? activeFilterLabel;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filter = activeFilterLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          Text(
            l10n.translate('people_summary', replacements: {
              'people': _peopleLabel(l10n),
              'today': '$today',
              'soon': '$soon',
            }),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (filter != null)
            InputChip(
              label: Text(filter),
              visualDensity: VisualDensity.compact,
              onDeleted: onClearFilter,
              deleteButtonTooltipMessage:
                  l10n.translate('people_clear_filters'),
            ),
        ],
      ),
    );
  }

  String _peopleLabel(AppLocalizations l10n) {
    final everyone = total;
    if (everyone == null) return l10n.plural('people_count', people);
    return l10n.plural('people_count_of', everyone,
        replacements: {'shown': '$people'});
  }
}
