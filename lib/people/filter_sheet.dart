import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/query_labels.dart';
import 'package:memento_mori_life_in_weeks/people/sheet_title.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// Bottom sheet with the date filters; [countFor] gives the number of
/// people each filter would show. Custom ranges are picked inline.
Future<void> showFilterSheet(
  BuildContext context, {
  required FriendQuery query,
  required int Function(DateFilter filter) countFor,
  required ValueChanged<FriendQuery> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _FilterSheet(
      initial: query,
      countFor: countFor,
      onChanged: onChanged,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.countFor,
    required this.onChanged,
  });

  final FriendQuery initial;
  final int Function(DateFilter filter) countFor;
  final ValueChanged<FriendQuery> onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late FriendQuery _query = widget.initial;

  /// Shows [next] in the sheet without applying it to the list.
  void _select(FriendQuery next) => setState(() => _query = next);

  /// Applies [next] to the list and closes the sheet.
  void _apply(FriendQuery next) {
    widget.onChanged(next);
    Navigator.pop(context);
  }

  /// Fixed ranges apply at once; a custom range waits for both dates and
  /// "Apply", so the applied filter stays until then.
  void _pickFilter(DateFilter filter) {
    final next = _query.copyWith(dateFilter: filter);
    filter == DateFilter.custom ? _select(next) : _apply(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: ScrollThread(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(l10n.translate('filter_title')),
              RadioGroup<DateFilter>(
                groupValue: _query.dateFilter,
                onChanged: (value) => _pickFilter(value!),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final filter in DateFilter.values)
                      ListTile(
                        leading: Radio<DateFilter>(value: filter),
                        title: Text(l10n.filterLabel(filter)),
                        subtitle: _countLabel(l10n, filter),
                        onTap: () => _pickFilter(filter),
                      ),
                  ],
                ),
              ),
              if (_query.dateFilter == DateFilter.custom)
                _CustomRange(
                  query: _query,
                  onChanged: _select,
                  onApply: _apply,
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _countLabel(AppLocalizations l10n, DateFilter filter) {
    if (filter == DateFilter.all || filter == DateFilter.custom) return null;
    return Text(l10n.plural('people_count', widget.countFor(filter)));
  }
}

class _CustomRange extends StatelessWidget {
  const _CustomRange({
    required this.query,
    required this.onChanged,
    required this.onApply,
  });

  final FriendQuery query;

  /// A date was picked (not applied yet).
  final ValueChanged<FriendQuery> onChanged;
  final ValueChanged<FriendQuery> onApply;

  Future<DateTime?> _pick(BuildContext context, DateTime? initial,
      DateTime first) {
    final now = DateTime.now();
    final last = now.add(const Duration(days: 366));
    var start = initial ?? first;
    if (start.isBefore(first)) start = first;
    if (start.isAfter(last)) start = last;
    return showDatePicker(
      context: context,
      initialDate: start,
      firstDate: first,
      lastDate: last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = l10n.shortDateFormat;
    String label(DateTime? d) =>
        d == null ? l10n.translate('filter_select_date') : format.format(d);
    final today = DateUtils.dateOnly(DateTime.now());
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(indent: 20, endIndent: 20),
        ListTile(
          title: Text(l10n.translate('filter_from')),
          subtitle: Text(label(query.customStart)),
          trailing: const Icon(Icons.event_outlined),
          onTap: () async {
            final date = await _pick(context, query.customStart, today);
            if (date != null) onChanged(query.copyWith(customStart: date));
          },
        ),
        ListTile(
          title: Text(l10n.translate('filter_to')),
          subtitle: Text(label(query.customEnd)),
          trailing: const Icon(Icons.event_outlined),
          onTap: () async {
            final first = query.customStart ?? today;
            final date = await _pick(
                context, query.customEnd ?? first.add(const Duration(days: 30)), first);
            if (date != null) onChanged(query.copyWith(customEnd: date));
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              // Without both dates the range would filter nothing.
              onPressed: query.hasCustomRange ? () => onApply(query) : null,
              child: Text(l10n.translate('filter_apply')),
            ),
          ),
        ),
      ],
    );
  }
}
