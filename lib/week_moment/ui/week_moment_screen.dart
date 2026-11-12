import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_pose.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_closing_card.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_parts.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_stage.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_texts.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_notes.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_result.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_turn.dart';

/// The weekly moment: a calm full screen that plays [story]'s acts one
/// after another (the week, the phase, the life), then closes the week and
/// plans the next one on a card over the zoomed grid ([WeekClosingCard]).
///
/// Each act enters (fill or camera move) and then holds; a tap ends the
/// entry or moves on, "Skip" jumps to the card's first step. Only the
/// card's buttons move through its steps. With reduced motion the acts land
/// at once but still hold; with a screen reader they only move on by tap.
/// Pops [WeekMomentResult.continued] ("Plan the week", the caller opens the
/// Compass) or [WeekMomentResult.closed] ("Enjoy life", back).
class WeekMomentScreen extends StatefulWidget {
  const WeekMomentScreen({
    super.key,
    required this.story,
    this.address = PersonalAddress.none,
    this.turn,
    this.notes = const WeekMomentNotes(),
    this.timing = const WeekMomentTiming(),
  });

  final WeekMomentStory story;

  /// How the closing title greets the user (by name, or plainly).
  final PersonalAddress address;

  /// The weeks the card names; null: the turn seen from today.
  final WeekTurn? turn;

  /// Saves what the user writes on the card.
  final WeekMomentNotes notes;
  final WeekMomentTiming timing;

  @override
  State<WeekMomentScreen> createState() => _WeekMomentScreenState();
}

class _WeekMomentScreenState extends State<WeekMomentScreen>
    with SingleTickerProviderStateMixin {
  late final List<WeekMomentAct> _acts = widget.story.acts;
  late MomentState _state = MomentState.initial(_acts);

  /// The act the camera comes from while [_state]'s act enters.
  late WeekMomentAct _from = _acts.first;
  late final AnimationController _enter = AnimationController(vsync: this)
    ..addStatusListener(_onEnterStatus);
  late final WeekTurn _turn = widget.turn ?? WeekTurn.on(DateTime.now());
  Timer? _hold;
  bool _motion = true;
  bool _autoAdvance = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = Motion.enabled(context);
    _autoAdvance = !MediaQuery.accessibleNavigationOf(context);
    if (!_autoAdvance) _hold?.cancel();
    if (_started) return;
    _started = true;
    if (!_motion) _enter.value = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runEnter(_state.act);
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _enter.dispose();
    super.dispose();
  }

  void _onEnterStatus(AnimationStatus status) {
    if (status.isCompleted) _dispatch(MomentEvent.entered);
  }

  void _dispatch(MomentEvent event) {
    if (!mounted) return;
    final previous = _state;
    final next = reduce(previous, event, _acts);
    if (next == previous) return;
    setState(() => _state = next);
    _apply(previous, next);
  }

  /// Starts what [next] needs: the entry of a new act, or the hold once
  /// it landed.
  void _apply(MomentState previous, MomentState next) {
    _hold?.cancel();
    if (next.act != previous.act) {
      _from = previous.act;
      _runEnter(next.act);
    } else if (_enter.isAnimating) {
      _enter.value = 1;
    }
    if (next.phase == MomentPhase.holding) _land(next);
  }

  /// Plays [act]'s entry from the start (at once with reduced motion).
  void _runEnter(WeekMomentAct act) {
    _enter.duration = _motion ? widget.timing.enter(act) : Duration.zero;
    _enter.forward(from: 0);
  }

  /// The act landed: a light tap, then the hold (unless only taps move
  /// on).
  void _land(MomentState state) {
    Haptics.light();
    final hold = widget.timing.hold(state.act);
    if (hold != null && _autoAdvance) {
      _hold = Timer(hold, () => _dispatch(MomentEvent.holdElapsed));
    }
  }

  void _close(WeekMomentResult result) => Navigator.of(context).pop(result);

  /// "Close the week": what was beautiful becomes a lived moment.
  Future<void> _keep(String text) =>
      widget.notes.keepMoment(text, day: DateTime.now());

  /// "Plan the week": the one thing goes to "Now" (or "Someday" when full,
  /// said in a snackbar), then the caller opens the Compass.
  Future<void> _plan(String text) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    final saved = await widget.notes.planIntention(text, day: DateTime.now());
    if (!mounted) return;
    if (saved?.nowLimitReached ?? false) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.translate('compass_now_full_saved'))),
      );
    }
    _close(WeekMomentResult.continued);
  }

  StagePose _pose() {
    final act = _state.act;
    if (act == WeekMomentAct.week) return StagePose.at(act, fill: _enter.value);
    final landed = _state.phase == MomentPhase.holding && _enter.isCompleted;
    return StagePose(
      from: _from,
      to: act,
      t: _enter.value,
      pulse: _state.isFinal && landed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = WeekMomentTexts(
      AppLocalizations.of(context),
      address: widget.address,
    );
    return Scaffold(
      key: const ValueKey('week_moment'),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, box) => _layout(context, texts, box.maxHeight),
        ),
      ),
    );
  }

  /// Share of the screen height the act texts may take at most; longer
  /// texts (large font sizes) scroll, so the stage always keeps some room.
  static const double _maxTextShare = 0.5;

  /// Share of the screen height the closing card may take at most; its
  /// texts and field scroll above its buttons.
  static const double _maxCardShare = 0.72;

  Widget _layout(BuildContext context, WeekMomentTexts texts, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _tappableStory(context, texts, height)),
        if (_state.isFinal)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height * _maxCardShare),
            child: _FadeIn(child: _card(texts)),
          ),
      ],
    );
  }

  /// The eyebrow, the stage and, before the final act, the act's lines;
  /// a tap anywhere here lands or moves on (the card stays out of it).
  Widget _tappableStory(
    BuildContext context,
    WeekMomentTexts texts,
    double height,
  ) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: () => _dispatch(MomentEvent.tap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeekMomentTopRow(
          eyebrow: texts.eyebrow(_state.act),
          showSkip: !_state.isFinal,
          onSkip: () => _dispatch(MomentEvent.skip),
        ),
        Expanded(child: _stage(context)),
        if (!_state.isFinal)
          SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height * _maxTextShare),
              child: SingleChildScrollView(child: _textBlock(texts)),
            ),
          ),
      ],
    ),
  );

  Widget _card(WeekMomentTexts texts) => WeekClosingCard(
    texts: texts,
    story: widget.story,
    turn: _turn,
    onKeep: _keep,
    onPlan: _plan,
    onEnjoy: () => _close(WeekMomentResult.closed),
  );

  /// The stage, labelled for screen readers, with a tap to move on.
  Widget _stage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canAdvance = !_state.isFinal;
    return Semantics(
      key: const ValueKey('week_moment_stage'),
      container: true,
      label: l10n.translate('week_moment_stage_label'),
      onTapHint: canAdvance ? l10n.translate('week_moment_tap_hint') : null,
      onTap: canAdvance ? () => _dispatch(MomentEvent.tap) : null,
      child: AnimatedBuilder(
        animation: _enter,
        builder: (context, _) =>
            WeekMomentStage(story: widget.story, pose: _pose()),
      ),
    );
  }

  Widget _textBlock(WeekMomentTexts texts) => WeekMomentTextBlock(
    actKey: ValueKey(_state.act),
    lines: texts.linesFor(_state.act, widget.story),
  );
}

/// Fades [child] in once when it first appears (at once with reduced
/// motion).
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.of(context, Motion.long),
    curve: Motion.standard,
    builder: (context, opacity, child) =>
        Opacity(opacity: opacity, child: child),
    child: child,
  );
}
