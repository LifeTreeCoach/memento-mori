import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// The optional appointment of an enjoy intention: "Date – no rush, but not
/// without a date"; tap picks a day from [today] on, the cross removes it.
/// Picking a day leaves the keyboard closed.
class DueDateRow extends StatelessWidget {
  const DueDateRow({
    super.key,
    required this.dueDate,
    required this.today,
    required this.onChanged,
  });

  final DateTime? dueDate;
  final DateTime today;
  final ValueChanged<DateTime?> onChanged;

  /// Suggested day when none is set yet: two weeks ahead.
  static DateTime suggestedDay(DateTime today) =>
      DateTime(today.year, today.month, today.day + 14);

  Future<void> _pick(BuildContext context) async {
    // Close the keyboard for good: without this the dialog hands focus back
    // to the title field when it closes and the keyboard pops up again.
    FocusManager.instance.primaryFocus?.unfocus();
    final first = compassDate(today);
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? suggestedDay(first),
      firstDate: first,
      lastDate: DateTime(first.year + 50, 12, 31),
    );
    if (picked != null) onChanged(compassDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final due = dueDate;
    return ListTile(
      key: const ValueKey('intention_due_date'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(l10n.translate('intention_due_label')),
      subtitle: Text(
        due == null
            ? l10n.translate('intention_due_hint')
            : l10n.dayText(due, today: today),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: due == null
          ? null
          : IconButton(
              key: const ValueKey('intention_due_clear'),
              tooltip: l10n.translate('intention_due_clear'),
              icon: const Icon(Icons.close_rounded),
              onPressed: () => onChanged(null),
            ),
      onTap: () => _pick(context),
    );
  }
}
