import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/query_labels.dart';
import 'package:memento_mori_life_in_weeks/people/sheet_title.dart';

/// Bottom sheet to pick the sort order; picking the current option again
/// (or its arrow) reverses the direction.
Future<void> showSortSheet(
  BuildContext context, {
  required FriendQuery query,
  required ValueChanged<FriendQuery> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _SortSheet(
      query: query,
      onPicked: (next) {
        onChanged(next);
        Navigator.pop(sheetContext);
      },
    ),
  );
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.query, required this.onPicked});

  final FriendQuery query;
  final ValueChanged<FriendQuery> onPicked;

  void _pick(SortOption option) {
    final reverse = option == query.sort;
    onPicked(query.copyWith(
      sort: option,
      ascending: reverse ? !query.ascending : true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.translate('sort_title')),
          RadioGroup<SortOption>(
            groupValue: query.sort,
            onChanged: (value) => _pick(value!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in SortOption.values)
                  ListTile(
                    leading: Radio<SortOption>(value: option),
                    title: Text(l10n.sortLabel(option)),
                    trailing: option == query.sort
                        ? IconButton(
                            tooltip: l10n.translate('sort_toggle_direction'),
                            icon: Icon(query.ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward),
                            onPressed: () => _pick(option),
                          )
                        : null,
                    onTap: () => _pick(option),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
