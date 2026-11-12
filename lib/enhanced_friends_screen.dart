import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_settings_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/data/friends_import_export_screen.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';
import 'package:memento_mori_life_in_weeks/people/add_person_fab.dart';
import 'package:memento_mori_life_in_weeks/people/birthdays_together.dart';
import 'package:memento_mori_life_in_weeks/people/filter_sheet.dart';
import 'package:memento_mori_life_in_weeks/people/friend_actions.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';
import 'package:memento_mori_life_in_weeks/people/friend_tile.dart';
import 'package:memento_mori_life_in_weeks/people/group_filter_bar.dart';
import 'package:memento_mori_life_in_weeks/people/open_friend_detail.dart';
import 'package:memento_mori_life_in_weeks/people/people_app_bar.dart';
import 'package:memento_mori_life_in_weeks/people/people_empty_state.dart';
import 'package:memento_mori_life_in_weeks/people/people_list.dart';
import 'package:memento_mori_life_in_weeks/people/people_sections.dart';
import 'package:memento_mori_life_in_weeks/people/people_summary_row.dart';
import 'package:memento_mori_life_in_weeks/people/people_view.dart';
import 'package:memento_mori_life_in_weeks/people/query_labels.dart';
import 'package:memento_mori_life_in_weeks/people/reminders_row.dart';
import 'package:memento_mori_life_in_weeks/people/sort_sheet.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour_trigger.dart';
import 'package:memento_mori_life_in_weeks/people/tour/tour_person_row.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_flow.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// The People tab: today's birthdays, the next 30 days, and everyone.
class EnhancedFriendsScreen extends StatefulWidget {
  const EnhancedFriendsScreen({super.key, this.now, this.openFriendRequests});

  /// Fixed "today" for tests; defaults to the clock.
  final DateTime? now;

  /// Ids of friends whose detail to open (e.g. a tapped birthday
  /// reminder); unknown ids (deleted meanwhile) are ignored.
  final Stream<String>? openFriendRequests;

  @override
  State<EnhancedFriendsScreen> createState() => _EnhancedFriendsScreenState();
}

class _EnhancedFriendsScreenState extends State<EnhancedFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final FriendActions _actions = FriendActions(onChanged: _loadFriends);

  /// The tab owns its messenger so snackbars land in this Scaffold and the
  /// Add FAB moves up with them (the shell's outer Scaffold has no FAB).
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// A context below this tab's [ScaffoldMessenger].
  BuildContext get _scaffoldContext => _scaffoldKey.currentContext ?? context;

  final TourAnchors _tourAnchors = TourAnchors();
  late final PeopleTourTrigger _tour = PeopleTourTrigger(
    contextOf: () => _scaffoldContext,
    anchors: _tourAnchors,
  );

  /// The tab is shown (tickers on); hidden tabs live on in the shell.
  bool _visible = false;

  /// Adding someone or the import (incl. its undo offer) is under way, as
  /// a count since they can overlap: no tour meanwhile.
  int _busyCount = 0;

  /// A delayed tour start (see [PeopleTour.settleDelay]).
  Timer? _tourTimer;

  StreamSubscription<String>? _openFriendSubscription;
  List<Friend> _allFriends = [];
  FriendQuery _query = const FriendQuery();

  /// Language of the group labeler in [_query].
  String? _groupLabelLanguage;
  bool _isLoading = true;
  bool _searching = false;
  bool _fabExtended = true;
  bool _remindersEnabled = true;

  /// Last computed view; reused while friends, query and day are unchanged
  /// (e.g. when only the FAB collapses on scroll).
  PeopleView? _cachedView;

  PeopleView get _view => _cachedView =
      PeopleView.reuseOrCompute(_cachedView, _allFriends, _query, _today);

  DateTime get _today => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _remindersEnabled = ReminderService.isBirthdayNotificationsEnabled();
    FriendsService.revision.addListener(_loadFriends);
    _openFriendSubscription =
        widget.openFriendRequests?.listen(_openFriendById);
    _loadFriends();
  }

  /// The shell rebuilds tabs on navigation; the reminders flag is shared
  /// with Settings, so pick up changes made there.
  @override
  void didUpdateWidget(EnhancedFriendsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _remindersEnabled = ReminderService.isBirthdayNotificationsEnabled();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _useGroupLabelsOf(AppLocalizations.of(context));
    final visible = TickerMode.valuesOf(context).enabled;
    final becameVisible = visible && !_visible;
    _visible = visible;
    if (becameVisible) _scheduleTour();
  }

  /// Search and sort see predefined groups by their label in the app
  /// language; a new query only when the language changed (keeps the view
  /// cache).
  void _useGroupLabelsOf(AppLocalizations l10n) {
    final language = l10n.locale.languageCode;
    if (language == _groupLabelLanguage) return;
    _groupLabelLanguage = language;
    _query = _query.copyWith(groupLabel: GroupNames.labelerFor(l10n));
  }

  @override
  void dispose() {
    FriendsService.revision.removeListener(_loadFriends);
    _openFriendSubscription?.cancel();
    _tourTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text == _query.search) return;
    setState(() => _query = _query.copyWith(search: _searchController.text));
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await FriendsService.getAllFriends();
      if (!mounted) return;
      final appeared =
          !_isLoading && _allFriends.isEmpty && friends.isNotEmpty;
      setState(() {
        _allFriends = friends;
        _isLoading = false;
        if (!_groups.contains(_query.group) &&
            _query.group != FriendQuery.ungrouped) {
          _query = _query.copyWith(clearGroup: true);
        }
      });
      _scheduleTour(delay: appeared ? PeopleTour.settleDelay : Duration.zero);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('people_load_error', {'error': '$e'});
    }
  }

  void _showMessage(String key, [Map<String, String>? values]) {
    final text = AppLocalizations.of(context).translate(key, replacements: values);
    ScaffoldMessenger.of(_scaffoldContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  List<String> get _groups =>
      PeopleView.groupsOf(_allFriends, _query.groupLabel);

  bool get _hasUngrouped => _view.hasUngrouped;

  // Navigation -------------------------------------------------------------

  Future<T?> _push<T>(Widget screen) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

  Future<void> _addFriend() => _whileBusy(_addFriendNow);

  Future<void> _addFriendNow() async {
    final isFirstFriend = _allFriends.isEmpty;
    final result = await _push<Friend>(AddFriendScreen(firstPerson: isFirstFriend));
    if (result == null) return;
    if (isFirstFriend && _remindersEnabled) {
      await NotificationService.requestPermission();
    }
    await _loadFriends();
  }

  /// Contacts / vCard import; the result snackbar (with undo) lands in
  /// this tab's messenger, the list reloads via [FriendsService.revision].
  /// Busy until the undo offer is gone, so the tour never covers it.
  Future<void> _importBirthdays() => _whileBusy(() => startBirthdayImport(
        context,
        messenger: ScaffoldMessenger.of(_scaffoldContext),
      ));

  Future<void> _editFriend(Friend friend) async {
    final result = await _push<Friend>(AddFriendScreen(friend: friend));
    if (result != null) await _loadFriends();
  }

  Future<void> _openFriend(Friend friend) =>
      openFriendDetail(_scaffoldContext, friend, _actions);

  Future<void> _openFriendById(String id) async {
    final friends = await FriendsService.getAllFriends();
    final friend = friends.where((f) => f.id == id).firstOrNull;
    if (friend == null || !mounted) return;
    await _openFriend(friend);
  }

  Future<void> _onMenu(PeopleMenuAction action) async {
    switch (action) {
      case PeopleMenuAction.sort:
        _openSort();
      case PeopleMenuAction.filter:
        _openFilter();
      case PeopleMenuAction.importBirthdays:
        await _importBirthdays();
      case PeopleMenuAction.importExport:
        await _push<void>(const FriendsImportExportScreen());
        await _loadFriends();
      case PeopleMenuAction.calendarSync:
        await _push<void>(const CalendarSettingsScreen());
      case PeopleMenuAction.howItWorks:
        await _tour.show(empty: _allFriends.isEmpty);
    }
  }

  // Tour -------------------------------------------------------------------

  /// Runs [action] (adding someone, the import) with the tour held back,
  /// then offers it once things settled.
  Future<void> _whileBusy(Future<void> Function() action) async {
    _busyCount++;
    try {
      await action();
    } finally {
      _busyCount--;
    }
    _scheduleTour(delay: PeopleTour.settleDelay);
  }

  bool _tabVisible() => mounted && _visible;

  /// No tour while loading, searching or busy.
  bool _tourBlocked() => _isLoading || _searching || _busyCount > 0;

  /// Starts the matching People tour after [delay], if it is due by then.
  /// A pending delayed start is kept (things are still settling).
  void _scheduleTour({Duration delay = Duration.zero}) {
    if (_tourTimer?.isActive ?? false) {
      if (delay == Duration.zero) return;
      _tourTimer!.cancel();
    }
    if (delay == Duration.zero) {
      _startTourIfDue();
    } else {
      _tourTimer = Timer(delay, _startTourIfDue);
    }
  }

  /// After the next frame (so the anchors are laid out).
  Future<void> _startTourIfDue() async {
    if (!_tabVisible()) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!_tabVisible() || _tourBlocked()) return;
    await _tour.startIfDue(
      empty: _allFriends.isEmpty,
      tabVisible: _tabVisible,
      blocked: _tourBlocked,
    );
  }

  // Query ------------------------------------------------------------------

  void _setQuery(FriendQuery query) => setState(() => _query = query);

  void _openSort() =>
      showSortSheet(context, query: _query, onChanged: _setQuery);

  void _openFilter() => showFilterSheet(
        context,
        query: _query,
        countFor: (filter) => FriendQuery(dateFilter: filter)
            .apply(_allFriends, _today)
            .length,
        onChanged: _setQuery,
      );

  void _clearFilters() {
    _searchController.clear();
    _setQuery(FriendQuery(
      sort: _query.sort,
      ascending: _query.ascending,
      groupLabel: _query.groupLabel,
    ));
  }

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() {
    _searchController.clear();
    setState(() => _searching = false);
  }

  // Reminders --------------------------------------------------------------

  Future<void> _toggleReminders(bool enabled) async {
    try {
      if (enabled) await NotificationService.requestPermission();
      await ReminderService.setBirthdayNotificationsEnabled(enabled);
      if (!mounted) return;
      setState(() => _remindersEnabled = enabled);
      _showMessage(enabled ? 'people_reminders_on' : 'people_reminders_off');
    } catch (e) {
      if (mounted) _showMessage('people_reminders_error', {'error': '$e'});
    }
  }

  // Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final showFab = !_isLoading && !_searching && _allFriends.isNotEmpty;
    return TourAnchorScope(
      anchors: _tourAnchors,
      child: ScaffoldMessenger(child: _scaffold(showFab)),
    );
  }

  Widget _scaffold(bool showFab) {
    return Scaffold(
      key: _scaffoldKey,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: _onScroll,
        child: RefreshIndicator(
          onRefresh: _loadFriends,
          edgeOffset: 120,
          child: ScrollThread(
            bottomInset: showFab ? _fabClearance : 0,
            child: CustomScrollView(slivers: _slivers()),
          ),
        ),
      ),
      floatingActionButton: showFab
          ? TourAnchor(
              id: PeopleTour.fabAnchor,
              child:
                  AddPersonFab(extended: _fabExtended, onPressed: _addFriend),
            )
          : null,
    );
  }

  /// Space kept free below the scroll thread while the FAB is shown:
  /// 56 FAB height + 16 endFloat margin + a little air.
  static const double _fabClearance = 88;

  bool _onScroll(ScrollUpdateNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final extended = notification.metrics.pixels <= 8;
    if (extended != _fabExtended) setState(() => _fabExtended = extended);
    return false;
  }

  List<Widget> _slivers() {
    final appBar = PeopleAppBar(
      searching: _searching,
      searchController: _searchController,
      onOpenSearch: _openSearch,
      onCloseSearch: _closeSearch,
      onMenu: _onMenu,
    );
    if (_isLoading) {
      return [
        appBar,
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_allFriends.isEmpty) {
      return [
        appBar,
        SliverFillRemaining(
          hasScrollBody: false,
          child: PeopleEmptyState(onAdd: _addFriend, onImport: _importBirthdays),
        ),
      ];
    }
    return [appBar, ..._contentSlivers()];
  }

  List<Widget> _contentSlivers() {
    final view = _view;
    final visible = view.visible;
    final sections = view.sections;
    final groups = view.groups;
    final rowSettings = _RowSettings.read(tourPersonRowOf(sections));
    return [
      if (groups.isNotEmpty)
        SliverToBoxAdapter(
          child: TourAnchor(
            id: PeopleTour.groupsAnchor,
            child: GroupFilterBar(
              groups: groups,
              selected: _query.group,
              showUngrouped: _hasUngrouped,
              onSelected: (group) => _setQuery(group == null
                  ? _query.copyWith(clearGroup: true)
                  : _query.copyWith(group: group)),
            ),
          ),
        ),
      SliverToBoxAdapter(child: _summary(visible.length, sections)),
      if (visible.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: PeopleNoMatchState(onClear: _clearFilters),
        )
      else
        PeopleList(
          sections: sections,
          searching: _query.isSearching,
          rowBuilder: (birthday, section) =>
              _row(birthday, section, rowSettings),
          everyoneTrailing: _sortButton(),
          everyoneLeading: TourAnchor(
            id: PeopleTour.remindersAnchor,
            child: RemindersRow(
              enabled: _remindersEnabled,
              onChanged: _toggleReminders,
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 96)), // FAB space
    ];
  }

  /// Counts for the [shown] people (in [sections]) the query selects.
  Widget _summary(int shown, PeopleSections sections) {
    final l10n = AppLocalizations.of(context);
    final filtered = _query.effectiveDateFilter != DateFilter.all;
    return PeopleSummaryRow(
      people: shown,
      total: _query.isFiltered ? _allFriends.length : null,
      today: sections.todayCount,
      soon: sections.soonCount,
      activeFilterLabel: filtered ? l10n.filterLabel(_query.effectiveDateFilter) : null,
      onClearFilter: () =>
          _setQuery(_query.copyWith(dateFilter: DateFilter.all)),
    );
  }

  Widget _sortButton() {
    final l10n = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: _openSort,
      iconAlignment: IconAlignment.end,
      icon: Icon(
        _query.ascending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 16,
      ),
      label: Text(l10n.sortLabel(_query.sort)),
    );
  }

  Widget _row(
      UpcomingBirthday birthday, String section, _RowSettings settings) {
    final friend = birthday.friend;
    return Dismissible(
      key: ValueKey('$section-${friend.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) {
        // A new list (not removeWhere) so the cached view is recomputed.
        setState(() => _allFriends = [
              for (final f in _allFriends)
                if (f.id != friend.id) f,
            ]);
        _actions.deleteWithUndo(_scaffoldContext, friend);
      },
      child: _anchoredIf(
        settings.tourRow == (section: section, friendId: friend.id),
        PeopleTour.personAnchor,
        FriendTile(
          birthday: birthday,
          currentAge: FriendQuery.ageOf(friend, _today),
          birthdaysTogether: _birthdaysTogether(friend, settings),
          showLifespan: settings.showLifespan,
          onTap: () => _openFriend(friend),
          onLongPress: () => _showFriendMenu(friend),
          horizontalPadding: section == 'today' ? todayRowPadding : 20,
        ),
      ),
    );
  }

  static Widget _anchoredIf(bool anchored, String id, Widget child) =>
      anchored ? TourAnchor(id: id, child: child) : child;

  int? _birthdaysTogether(Friend friend, _RowSettings settings) {
    final userBirthDate = settings.userBirthDate;
    if (userBirthDate == null) return null;
    return BirthdaysTogether.count(
      friend: friend,
      userBirthDate: userBirthDate,
      userLifeExpectancyYears: settings.lifeExpectancyYears,
      today: _today,
    );
  }

  void _showFriendMenu(Friend friend) {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.translate('people_edit')),
              onTap: () {
                Navigator.pop(sheetContext);
                _editFriend(friend);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: error),
              title: Text(l10n.translate('people_delete'),
                  style: TextStyle(color: error)),
              onTap: () {
                Navigator.pop(sheetContext);
                _actions.confirmAndDelete(_scaffoldContext, friend);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Settings every row needs, read once per build instead of per row, and
/// the row the tour points at.
class _RowSettings {
  _RowSettings.read(this.tourRow)
      : showLifespan = SettingsService.isLifespanVisualizationEnabled(),
        userBirthDate = SettingsService.getBirthDate(),
        lifeExpectancyYears = SettingsService.getLifeExpectancyYears();

  final bool showLifespan;
  final DateTime? userBirthDate;
  final int lifeExpectancyYears;
  final TourPersonRow? tourRow;
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.errorContainer,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}
