import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// The coach-mark card: "Tip i of n" (not for a single tip), title, body,
/// Skip (not on the last step) and Next/Done.
class TourCard extends StatelessWidget {
  const TourCard({
    super.key,
    required this.step,
    required this.index,
    required this.count,
    required this.onPrimary,
    required this.onSecondary,
  });

  final TourStep step;

  /// Zero-based index among the shown steps.
  final int index;
  final int count;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  bool get isLast => index >= count - 1;

  /// The default "Skip" is pointless next to "Done" on the last step (Back
  /// still skips); a step's own secondary choice (e.g. "Not now") stays.
  bool get showsSecondary => !isLast || step.secondaryLabelKey != null;

  /// "Tip 1 of 1" says nothing; a single tip goes without a counter.
  bool get showsCounter => count > 1;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 6,
      shadowColor: scheme.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._texts(context),
            const SizedBox(height: 8),
            _buttons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _texts(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counter = l10n.translate('tour_step_counter',
        replacements: {'i': '${index + 1}', 'n': '$count'});
    return [
      if (showsCounter) ...[
        Text(counter,
            key: const ValueKey('tour_counter'),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 6),
      ],
      Semantics(
        header: true,
        liveRegion: true,
        child: Text(l10n.translate(step.titleKey),
            key: const ValueKey('tour_title'),
            style: theme.textTheme.titleMedium),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(l10n.translate(step.bodyKey),
            key: const ValueKey('tour_body'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ),
    ];
  }

  Widget _buttons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primaryKey =
        step.primaryLabelKey ?? (isLast ? 'tour_done' : 'tour_next');
    return OverflowBar(
      alignment: MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      spacing: 8,
      children: [
        if (showsSecondary)
          TextButton(
            key: const ValueKey('tour_skip'),
            onPressed: onSecondary,
            child: Text(l10n.translate(step.secondaryLabelKey ?? 'tour_skip')),
          ),
        FilledButton(
          key: ValueKey(isLast ? 'tour_done' : 'tour_next'),
          autofocus: true,
          onPressed: onPrimary,
          child: Text(l10n.translate(primaryKey)),
        ),
      ],
    );
  }
}
