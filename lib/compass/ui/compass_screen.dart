import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_meta.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_actions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_tour.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_tour_trigger.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_week.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/lived_section.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/now_section.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_actions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_empty_header.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_header.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/question_card.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/compass_setup_entry.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/show_question_link.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/someday_section.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/week_note.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_launcher.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// The Compass tab: the current life phase, the question of the week, at
/// most three intentions "Now", the calm "Someday" list and the moments
/// already lived.
///
/// A gentle life to-do: no streaks, due dates, overdue states or scores.
class CompassScreen extends StatefulWidget {
  const CompassScreen({
    super.key,
    this.now,
    this.autoOpenSetup = false,
    this.weekMoments = const WeekMomentLauncher(),
  });

  /// Fixed "today" for tests; defaults to the clock.
  final DateTime? now;

  /// Open the Compass setup by itself the first time this screen becomes
  /// visible with an empty Compass (the app shell's tab), then the
  /// [CompassTour] once, unless it was seen.
  final bool autoOpenSetup;

  /// Replays the weekly moment from the app bar.
  final WeekMomentLauncher weekMoments;

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  /// The tab owns its messenger (as Life and People do), so snackbars land
  /// above the shell's navigation bar and never on a pushed screen.
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final CompassActions _actions = CompassActions(
    contextOf: () => _scaffoldKey.currentContext ?? context,
    today: () => _today,
    birthDate: () => _birthDate,
    onSavedToSomeday: () => setState(() => _somedayExpanded = true),
    lifeExpectancyYears: () => _lifeExpectancyYears,
  );

  late final PhaseActions _phaseActions = PhaseActions(
    contextOf: () => _scaffoldKey.currentContext ?? context,
    today: () => _today,
    birthDate: () => _birthDate,
    lifeExpectancyYears: () => _lifeExpectancyYears,
  );

  late final CompassSetupEntry _setup = CompassSetupEntry(
    contextOf: () => _scaffoldKey.currentContext ?? context,
    today: () => _today,
    birthDate: () => _birthDate,
    lifeExpectancyYears: () => _lifeExpectancyYears,
  );

  final TourAnchors _tourAnchors = TourAnchors();

  late final CompassTourTrigger _tour = CompassTourTrigger(
    contextOf: () => _scaffoldKey.currentContext ?? context,
    anchors: _tourAnchors,
  );

  DateTime? _birthDate;
  late int _lifeExpectancyYears;
  bool _somedayExpanded = false;

  /// The tab is shown (tickers on); hidden tabs live on in the shell.
  bool _visible = false;

  DateTime get _today => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _readSettings();
    CompassService.revision.addListener(_onCompassChanged);
    CompassSetupStore.revision.addListener(_onCompassChanged);
    CompassService.load().then((_) => _onCompassChanged());
    CompassSetupStore.load().then((_) => _onCompassChanged());
  }

  /// The shell builds every tab at start; the setup may only open by
  /// itself once this tab is actually shown.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    final becameVisible = visible && !_visible;
    _visible = visible;
    if (becameVisible && widget.autoOpenSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _guideVisit());
    }
  }

  bool _stillVisible() => mounted && _visible;

  /// New users get the setup first and the tour once it closed (a frame
  /// later, so the screen shows what the setup saved); everyone else gets
  /// the tour right away, once.
  Future<void> _guideVisit() async {
    await _setup.autoOpenIfDue(_stillVisible);
    await WidgetsBinding.instance.endOfFrame;
    if (!_stillVisible()) return;
    await _tour.startIfDue(
        tabVisible: _stillVisible, blocked: () => _setup.autoOpenDue);
  }

  /// The shell rebuilds tabs on navigation; pick up a changed birth date
  /// or life expectancy.
  @override
  void didUpdateWidget(CompassScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readSettings();
  }

  void _readSettings() {
    _birthDate = SettingsService.getBirthDate();
    _lifeExpectancyYears = SettingsService.getLifeExpectancyYears();
  }

  @override
  void dispose() {
    CompassService.revision.removeListener(_onCompassChanged);
    CompassSetupStore.revision.removeListener(_onCompassChanged);
    super.dispose();
  }

  void _onCompassChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _dismissQuestion() => CompassService.dismissQuestion(_today);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final week = CompassWeek.of(_today, birthDate: _birthDate);
    return TourAnchorScope(
      anchors: _tourAnchors,
      child: ScaffoldMessenger(child: _scaffold(l10n, week)),
    );
  }

  Widget _scaffold(AppLocalizations l10n, CompassWeek week) {
    return Scaffold(
      key: _scaffoldKey,
      body: ScrollThread(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(l10n.translate('nav_compass')),
              ),
              actions: [
                if (_birthDate != null) _weekMomentButton(l10n),
                _helpButton(l10n),
                const SizedBox(width: 4),
              ],
            ),
            // A built column, not a lazy list: the tour's anchors further
            // down must exist before it starts.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _content(context, week),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "See your week": the weekly moment again; Compass stays open after
  /// it, whichever way it ends.
  Widget _weekMomentButton(AppLocalizations l10n) {
    return IconButton(
      key: const ValueKey('compass_week_moment'),
      tooltip: l10n.translate('week_moment_replay'),
      icon: const Icon(Icons.calendar_view_week_rounded),
      onPressed: _replayWeekMoment,
    );
  }

  Future<void> _replayWeekMoment() =>
      widget.weekMoments.replay(context, now: _today);

  /// "How Compass works": the tour again, seen or not.
  Widget _helpButton(AppLocalizations l10n) {
    return IconButton(
      key: const ValueKey('compass_tour_help'),
      tooltip: l10n.translate('tour_compass_help'),
      icon: const Icon(Icons.help_outline),
      onPressed: _tour.show,
    );
  }

  List<Widget> _content(BuildContext context, CompassWeek week) {
    final data = CompassService.data;
    return [
      _subtitle(context),
      const SizedBox(height: 20),
      if (_setup.checklist() case final card?) ...[
        card,
        const SizedBox(height: 24),
      ],
      TourAnchor(id: CompassTour.phaseAnchor, child: _phase()),
      const SizedBox(height: 24),
      ..._question(context, week),
      NowSection(
        intentions: data.withStatus(IntentionStatus.now),
        actions: _actions,
        current: currentSpan(data.phases, _today),
        today: _today,
      ),
      SomedaySection(
        intentions: data.withStatus(IntentionStatus.someday),
        expanded: _somedayExpanded,
        onToggle: () => setState(() => _somedayExpanded = !_somedayExpanded),
        actions: _actions,
      ),
      LivedSection(
        moments: data.moments,
        actions: _actions,
        birthDate: _birthDate,
        weeksLived: week.weeksLived,
        phaseNoteOf: (moment) => _phaseNote(context, moment, data),
        phases: resolvePhases(data.phases, _today),
        intentions: data.intentions,
      ),
    ];
  }

  String? _phaseNote(BuildContext context, Moment moment, CompassData data) {
    final phaseYear = phaseYearOf(moment, data);
    return phaseYear == null
        ? null
        : AppLocalizations.of(context).phaseYearText(phaseYear);
  }

  Widget _subtitle(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      AppLocalizations.of(context).translate('compass_subtitle'),
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }

  Widget _phase() {
    final spans = resolvePhases(CompassService.data.phases, _today);
    if (spans.isEmpty) return PhaseEmptyHeader(onSet: _phaseActions.setPhase);
    return PhaseHeader(
      spans: spans,
      today: _today,
      birthDate: _birthDate,
      lifeExpectancyYears: _lifeExpectancyYears,
      onEdit: _phaseActions.editCurrent,
      onExtend: _phaseActions.extendCurrent,
      onClose: _phaseActions.closeCurrent,
      onOpen: _phaseActions.openSheet,
    );
  }

  List<Widget> _question(BuildContext context, CompassWeek week) {
    final l10n = AppLocalizations.of(context);
    if (week.state.dismissed) {
      return [
        ShowQuestionLink(
            onPressed: () => CompassService.restoreQuestion(_today)),
      ];
    }
    return [
      TourAnchor(
        id: CompassTour.questionAnchor,
        child: QuestionCard(
          week: week,
          onMakeIntention: () =>
              _actions.addIntention(initialNote: week.questionText(l10n)),
          onNoteMoment: _actions.addMoment,
          onSwap: week.state.swapped
              ? null
              : () => CompassService.swapQuestion(_today),
          onDismiss: _dismissQuestion,
        ),
      ),
      if (week.showsNote) WeekNote(week.noteText(l10n)),
    ];
  }
}
