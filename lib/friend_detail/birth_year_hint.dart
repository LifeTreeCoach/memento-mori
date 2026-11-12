import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Shown instead of the lifespan and "Together" views for a friend saved
/// without a birth year: a gentle note and a button that opens the form.
class BirthYearHint extends StatelessWidget {
  const BirthYearHint({super.key, this.onAddBirthYear});

  /// Opens the edit form; the button is hidden when null.
  final VoidCallback? onAddBirthYear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onAdd = onAddBirthYear;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hourglass_empty,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.translate('friend_no_year_hint'),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: Text(l10n.translate('friend_no_year_add')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
