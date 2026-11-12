import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_actions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_week.dart';
import 'package:memento_mori_life_in_weeks/life/compass_week_card.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/life/alternative_layout_view.dart';
import 'package:memento_mori_life_in_weeks/life/cell_detail_sheet.dart';
import 'package:memento_mori_life_in_weeks/life/life_empty_state.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_view.dart';
import 'package:memento_mori_life_in_weeks/life/life_header.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode_selector.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:memento_mori_life_in_weeks/life/moment_marks.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/phase_legend.dart';
import 'package:memento_mori_life_in_weeks/life/quote_card.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_actions.dart';
import 'package:memento_mori_life_in_weeks/people/open_friend_detail.dart';
import 'package:memento_mori_life_in_weeks/life/quote_service.dart';
import 'package:memento_mori_life_in_weeks/settings/sponsor_link.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/support/recommend_card.dart';
import 'package:memento_mori_life_in_weeks/support/store_listing.dart';
import 'package:memento_mori_life_in_weeks/support/support_card.dart';
import 'package:memento_mori_life_in_weeks/support/support_prompt.dart';
import 'package:memento_mori_life_in_weeks/support/support_scope.dart';
import 'package:memento_mori_life_in_weeks/support/support_service.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// The Life tab: header, mode selector, the life grid (or another layout),
/// quote of the day and the next friend birthday.
/// Mean Gregorian year length, for the exact age shown by the layouts.
const double _averageDaysPerYear = 365.2425;

/// Life phases placed on the timeline and their runs in one [LifeMode].
typedef _PhaseLayout = ({List<PhaseSpan> spans, List<PhaseCellRun> runs});

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenSettings,
    this.onOpenCompass,
    this.now,
    this.openSupportLink = openSponsorLink,
  });

  /// Switches to the Settings tab (used by the empty state).
  final VoidCallback? onOpenSettings;

  /// Switches to the Compass tab (used by the question-of-the-week card,
  /// which is hidden without it).
  final VoidCallback? onOpenCompass;

  /// Fixed "today" for tests; defaults to the clock.
  final DateTime? now;

  /// Opens the sponsor page from the support card; injectable for tests.
  final SponsorLinkOpener openSupportLink;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _birthDate;
  int _lifeExpectancyYears = LifeCalculator.defaultLifeExpectancyYears;
  LifeMode _mode = LifeMode.weeks;
  VisualizationSettings _visualSettings = const VisualizationSettings();
  String _colorThemeId = ColorThemes.styleDefaultId;
  List<Friend> _friends = const [];
  bool _gridZoomed = false;

  /// Phase layout cached with the inputs it was computed from (Compass
  /// revision, mode, birth date, life expectancy, day), so rebuilds don't
  /// recompute the runs.
  ({Object key, _PhaseLayout layout})? _phaseCache;
  late final FriendActions _friendActions = FriendActions(onChanged: _loadFriends);
  late final CompassActions _compassActions = CompassActions(
    contextOf: () => _scaffoldContext,
    today: () => _today,
    birthDate: () => _birthDate,
    onSavedToSomeday: () {},
  );

  /// The tab owns its messenger (as People does), so snackbars such as the
  /// delete undo land in this Scaffold, above the shell's navigation bar,
  /// and never on a screen pushed above the shell.
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// A context below this tab's [ScaffoldMessenger].
  BuildContext get _scaffoldContext => _scaffoldKey.currentContext ?? context;

  DateTime get _today => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _readSettings();
    FriendsService.revision.addListener(_loadFriends);
    CompassService.revision.addListener(_onCompassChanged);
    SupportService.revision.addListener(_onSupportChanged);
    _loadFriends();
  }

  /// The shell rebuilds tabs on navigation; pick up settings changed
  /// elsewhere (friend changes arrive via [FriendsService.revision]).
  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readSettings();
  }

  @override
  void dispose() {
    FriendsService.revision.removeListener(_loadFriends);
    CompassService.revision.removeListener(_onCompassChanged);
    SupportService.revision.removeListener(_onSupportChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readSettings();
  }

  void _readSettings() {
    _birthDate = SettingsService.getBirthDate();
    _lifeExpectancyYears = SettingsService.getLifeExpectancyYears();
    _mode = LifeMode.fromId(SettingsService.getDisplayMode());
    _visualSettings = SettingsService.getVisualizationSettings();
    _colorThemeId = SettingsService.getColorTheme();
  }

  /// The question card and the grid's moment marks follow Compass changes
  /// (dismissed, swapped, moments, hidden in Settings).
  void _onCompassChanged() {
    if (mounted) setState(() {});
  }

  /// The support card follows its schedule, Settings and Diagnostics.
  void _onSupportChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFriends() async {
    final friends = await FriendsService.getAllFriends();
    if (mounted) setState(() => _friends = friends);
  }

  Future<void> _openFriend(Friend friend) =>
      openFriendDetail(_scaffoldContext, friend, _friendActions);

  void _changeMode(LifeMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    SettingsService.setDisplayMode(mode.id);
  }

  void _openCell(LifeCalculator calc, int index) {
    Haptics.light();
    final period = LifePeriod.of(_mode, index, calc);
    showCellDetailSheet(
      context,
      period: period,
      friends: _friends,
      moments: CompassService.momentsIn(period),
      onAddMoment: (date) => _compassActions.addMoment(initialDate: date),
      phase: _cellPhase(calc, index),
    );
  }

  /// The life phase holding cell [index], when phases are shown.
  CellPhase? _cellPhase(LifeCalculator calc, int index) {
    final layout = _shownPhases(calc);
    final run = runAt(layout.runs, index);
    if (run == null) return null;
    final span = layout.spans.firstWhere((s) => s.phase.id == run.phaseId);
    return CellPhase(
      name: phaseDisplayName(span.phase, AppLocalizations.of(context)),
      planned: run.kind == PhaseSlotKind.planned,
    );
  }

  /// Phases and runs of the current mode; empty when hidden in Settings.
  _PhaseLayout _shownPhases(LifeCalculator calc) {
    if (!_visualSettings.showPhases) return (spans: const [], runs: const []);
    return _phaseLayout(calc);
  }

  _PhaseLayout _phaseLayout(LifeCalculator calc) {
    final key = (CompassService.revision.value, _mode, calc.birthDate,
        _lifeExpectancyYears, calc.today);
    final cached = _phaseCache;
    if (cached != null && cached.key == key) return cached.layout;
    final spans = resolvePhases(CompassService.data.phases, calc.today);
    final layout = (
      spans: spans,
      runs: phaseRuns(
        spans: spans,
        mode: _mode,
        birthDate: calc.birthDate,
        totalCells: _mode.totalCells(calc),
        livedCells: _mode.livedCells(calc),
        lifeExpectancyYears: _lifeExpectancyYears,
      ),
    );
    _phaseCache = (key: key, layout: layout);
    return layout;
  }

  @override
  Widget build(BuildContext context) {
    final birthDate = _birthDate;
    return ScaffoldMessenger(
      child: Scaffold(
        key: _scaffoldKey,
        body: SafeArea(
          bottom: false,
          child: birthDate == null
              ? Center(child: LifeEmptyState(onOpenSettings: widget.onOpenSettings))
              : _buildContent(context, _calculatorFor(birthDate)),
        ),
      ),
    );
  }

  LifeCalculator _calculatorFor(DateTime birthDate) => LifeCalculator(
        birthDate: birthDate,
        lifeExpectancyYears: _lifeExpectancyYears,
        now: _today,
      );

  Widget _buildContent(BuildContext context, LifeCalculator calc) {
    final upcoming = UpcomingBirthday.soonest(_friends, calc.today);
    final language = AppLocalizations.of(context).locale.languageCode;
    return ScrollThread(
      enabled: !_gridZoomed,
      child: CustomScrollView(
        physics: _gridZoomed ? const NeverScrollableScrollPhysics() : null,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            sliver: SliverList.list(children: [
              ?_supportCard(),
              LifeHeader(data: LifeHeaderData(_mode, calc)),
              const SizedBox(height: 24),
              LifeModeSelector(mode: _mode, onChanged: _changeMode),
              ?_phaseLegend(context, calc),
              const SizedBox(height: 24),
              _animatedVisualization(context, calc),
              const SizedBox(height: 32),
              QuoteCard(
                quote: QuoteService.quoteOfTheDay(
                  language,
                  date: calc.today,
                  ageYears: calc.ageYears,
                ),
              ),
              ?_compassCard(),
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: 12),
                UpcomingBirthdayCard(upcoming: upcoming, onOpen: _openFriend),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  /// The occasional support card above everything else, when due
  /// ([SupportService.isDue]); every button puts it away.
  Widget? _supportCard() {
    if (!SupportService.isDue(_today)) return null;
    final firstUse = SupportService.firstUse ?? _today;
    final usage = SupportPrompt.usage(firstUse: firstUse, today: _today);
    final setup = SupportScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: setup.showsLink
          ? SupportCard(
              usage: usage,
              onSupport: () {
                widget.openSupportLink(_scaffoldContext);
                SupportService.markShown(_today);
              },
              onNotNow: () => SupportService.markShown(_today),
              onAlreadySupported: () => SupportService.markSupported(_today),
            )
          : _recommendCard(setup, usage),
    );
  }

  /// The store builds' card: rate or recommend instead of the coffee link.
  Widget _recommendCard(SupportSetup setup, SupportUsage usage) {
    void actAndPutAway(Future<void> Function(BuildContext, StoreListing) action) {
      action(_scaffoldContext, setup.listing);
      SupportService.markShown(_today);
    }

    return RecommendCard(
      usage: usage,
      canRate: setup.listing.canRate,
      onRate: () => actAndPutAway(setup.actions.rate),
      onRecommend: () => actAndPutAway(setup.actions.recommend),
      onNotNow: () => SupportService.markShown(_today),
      onAlreadyDid: () => SupportService.markSupported(_today),
    );
  }

  /// This week's Compass question below the quote, unless hidden in
  /// Settings or put away for the week.
  Widget? _compassCard() {
    final onOpen = widget.onOpenCompass;
    if (onOpen == null || !CompassService.showLifeCard) return null;
    final week = CompassWeek.of(_today, birthDate: _birthDate);
    if (week.state.dismissed) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CompassWeekCard(week: week, onOpen: onOpen),
    );
  }

  /// The phase legend below the mode selector, while phases colour the
  /// visualisation.
  Widget? _phaseLegend(BuildContext context, LifeCalculator calc) {
    final layout = _shownPhases(calc);
    if (layout.runs.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: PhaseLegend(
        entries: phaseLegendEntries(
          spans: layout.spans,
          runs: layout.runs,
          birthDate: calc.birthDate,
          l10n: AppLocalizations.of(context),
        ),
      ),
    );
  }

  Widget _animatedVisualization(BuildContext context, LifeCalculator calc) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('${_visualSettings.layoutType.name}-${_mode.id}'),
        child: _visualization(context, calc),
      ),
    );
  }

  Widget _visualization(BuildContext context, LifeCalculator calc) {
    final total = _mode.totalCells(calc);
    final lived = _mode.livedCells(calc);
    final label = _semanticsLabel(context, LifeHeaderData(_mode, calc));
    final runs = _shownPhases(calc).runs;
    if (_visualSettings.layoutType != LayoutType.grid) {
      return AlternativeLayoutView(
        settings: _visualSettings,
        totalItems: total,
        itemsCompleted: lived,
        colorThemeId: _colorThemeId,
        lifeExpectancyYears: _lifeExpectancyYears,
        semanticsLabel: label,
        ageYears: calc.daysLived / _averageDaysPerYear,
        phaseFractions: runFractions(runs, total),
      );
    }
    return LifeGridView(
      mode: _mode,
      totalCells: total,
      livedCells: lived,
      semanticsLabel: label,
      showMilestones: _visualSettings.enableMilestones,
      showSeasons: _visualSettings.enableSeasons,
      onCellTap: (index) => _openCell(calc, index),
      onZoomChanged: (zoomed) => setState(() => _gridZoomed = zoomed),
      momentCells: _momentCells(calc, total),
      phaseRuns: runs,
    );
  }

  /// Cells marked with a moment dot; none when hidden in Settings.
  Set<int> _momentCells(LifeCalculator calc, int totalCells) {
    if (!CompassService.showGridMarks) return const {};
    return momentCellIndices(
      moments: CompassService.data.moments,
      mode: _mode,
      birthDate: calc.birthDate,
      totalCells: totalCells,
    );
  }

  String _semanticsLabel(BuildContext context, LifeHeaderData data) {
    final l10n = AppLocalizations.of(context);
    final numbers = l10n.numberFormat;
    return l10n.translate(
      'grid_semantics_${_mode.id}',
      replacements: {
        'n': numbers.format(data.current),
        'total': numbers.format(data.total),
        'p': '${data.percent}',
      },
    );
  }
}
