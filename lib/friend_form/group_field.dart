import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';

/// Free-text group input with tappable chips: the predefined groups
/// (always) and the custom groups in use. A chip puts its localized label
/// into the field; saving stores [GroupNames.normalize] of the text.
class GroupField extends StatelessWidget {
  const GroupField({
    super.key,
    required this.controller,
    required this.existingGroups,
    required this.onGroupSelected,
  });

  final TextEditingController controller;

  /// Stored group values in use (ids of predefined groups or custom names).
  final List<String> existingGroups;

  /// Called with the label of the tapped chip.
  final ValueChanged<String> onGroupSelected;

  /// The predefined groups followed by the other [existing] groups, sorted
  /// by label.
  static List<String> chipGroups(
      Iterable<String> existing, String Function(String) labelOf) {
    final custom = existing.toSet()
        .where((group) => !GroupNames.isPredefined(group))
        .toList()
      ..sort((a, b) =>
          labelOf(a).toLowerCase().compareTo(labelOf(b).toLowerCase()));
    return [...GroupNames.predefined, ...custom];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.translate('form_group_label'),
            hintText: l10n.translate('form_group_hint'),
            helperText: l10n.translate('form_group_helper'),
            prefixIcon: const Icon(Icons.group_outlined),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        _existingGroupsLabel(context, l10n),
        const SizedBox(height: 6),
        _chips(l10n),
      ],
    );
  }

  Widget _existingGroupsLabel(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Text(
      l10n.translate('form_group_existing'),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _chips(AppLocalizations l10n) {
    final labelOf = GroupNames.labelerFor(l10n);
    final current = GroupNames.normalize(controller.text);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final group in chipGroups(existingGroups, labelOf))
          ChoiceChip(
            label: Text(labelOf(group)),
            selected: current == group,
            onSelected: (_) => onGroupSelected(labelOf(group)),
          ),
      ],
    );
  }
}
