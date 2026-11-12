import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Horizontal row of choice chips: All, each group, and Ungrouped.
/// [selected] is a stored group value, [FriendQuery.ungrouped], or null for
/// all. Chips show the localized label of predefined groups.
class GroupFilterBar extends StatelessWidget {
  const GroupFilterBar({
    super.key,
    required this.groups,
    required this.selected,
    required this.onSelected,
    this.showUngrouped = true,
  });

  final List<String> groups;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool showUngrouped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedSide =
        BorderSide(color: Theme.of(context).colorScheme.outline);
    final options = <(String?, String)>[
      (null, l10n.translate('people_group_all')),
      for (final group in groups) (group, GroupNames.label(group, l10n)),
      if (showUngrouped)
        (FriendQuery.ungrouped, l10n.translate('people_group_ungrouped')),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == value,
                side: selected == value ? selectedSide : null,
                showCheckmark: false,
                onSelected: (_) {
                  Haptics.selection();
                  onSelected(value);
                },
              ),
            ),
        ],
      ),
    );
  }
}
