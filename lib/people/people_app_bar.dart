import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';

enum PeopleMenuAction {
  sort,
  filter,
  importBirthdays,
  importExport,
  calendarSync,

  /// "How People works": replays the People tour.
  howItWorks,
}

/// Large serif "People" title with search and overflow actions; while
/// searching it turns into a pinned bar holding the search field.
class PeopleAppBar extends StatelessWidget {
  const PeopleAppBar({
    super.key,
    required this.searching,
    required this.searchController,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onMenu,
  });

  final bool searching;
  final TextEditingController searchController;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<PeopleMenuAction> onMenu;

  @override
  Widget build(BuildContext context) {
    return searching ? _searchBar(context) : _titleBar(context);
  }

  Widget _titleBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SliverAppBar.large(
      // The extra 4 aligns the title with the 20px content gutter.
      title: Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: Text(l10n.translate('people_title')),
      ),
      actions: [
        IconButton(
          tooltip: l10n.translate('people_search'),
          icon: const Icon(Icons.search),
          onPressed: onOpenSearch,
        ),
        TourAnchor(
          id: PeopleTour.menuAnchor,
          child: _OverflowMenu(onSelected: onMenu),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _searchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SliverAppBar(
      pinned: true,
      leading: IconButton(
        tooltip: l10n.translate('people_close_search'),
        icon: const Icon(Icons.arrow_back),
        onPressed: onCloseSearch,
      ),
      titleSpacing: 0,
      title: TextField(
        controller: searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: l10n.translate('people_search_hint'),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
      actions: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: searchController,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: l10n.translate('people_clear_search'),
                  icon: const Icon(Icons.close),
                  onPressed: searchController.clear,
                ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onSelected});

  final ValueChanged<PeopleMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    PopupMenuItem<PeopleMenuAction> item(
            PeopleMenuAction action, IconData icon, String key) =>
        PopupMenuItem(
          value: action,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon),
            title: Text(l10n.translate(key)),
          ),
        );
    return PopupMenuButton<PeopleMenuAction>(
      tooltip: l10n.translate('people_more'),
      icon: const Icon(Icons.more_vert),
      onSelected: onSelected,
      itemBuilder: (_) => [
        item(PeopleMenuAction.sort, Icons.sort, 'people_sort'),
        item(PeopleMenuAction.filter, Icons.filter_list, 'people_filter'),
        const PopupMenuDivider(),
        item(PeopleMenuAction.importBirthdays, Icons.cake_outlined,
            'import_birthdays'),
        item(PeopleMenuAction.importExport, Icons.import_export,
            'people_import_export'),
        item(PeopleMenuAction.calendarSync, Icons.event_outlined,
            'people_calendar_sync'),
        const PopupMenuDivider(),
        item(PeopleMenuAction.howItWorks, Icons.help_outline,
            'tour_people_help'),
      ],
    );
  }
}
