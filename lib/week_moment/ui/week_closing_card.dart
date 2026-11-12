import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_parts.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_texts.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_turn.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// The final act as a card over the zoomed grid, in two steps: close the
/// week that passed ([ClosingStep.close]: what was beautiful, written down
/// only if the user likes), then plan the next one ([ClosingStep.plan]: one
/// thing that counts). Only its buttons move on; back in the plan step
/// returns to the close step.
class WeekClosingCard extends StatefulWidget {
  const WeekClosingCard({
    super.key,
    required this.texts,
    required this.story,
    required this.turn,
    required this.onKeep,
    required this.onPlan,
    required this.onEnjoy,
  });

  final WeekMomentTexts texts;
  final WeekMomentStory story;
  final WeekTurn turn;

  /// "Close the week" with what was written (maybe blank).
  final Future<void> Function(String text) onKeep;

  /// "Plan the week" with what was written (maybe blank).
  final Future<void> Function(String text) onPlan;

  /// "Enjoy life": leave without planning.
  final VoidCallback onEnjoy;

  /// Radius of the card's top corners.
  static const double radius = 28;

  @override
  State<WeekClosingCard> createState() => _WeekClosingCardState();
}

class _WeekClosingCardState extends State<WeekClosingCard> {
  ClosingStep _step = ClosingStep.close;
  bool _busy = false;
  final Map<ClosingStep, TextEditingController> _fields = {
    for (final step in ClosingStep.values) step: TextEditingController(),
  };

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _goTo(ClosingStep step) {
    if (!mounted || step == _step) return;
    FocusScope.of(context).unfocus();
    Haptics.light();
    setState(() => _step = step);
  }

  /// Runs [action] once at a time (no double saves).
  Future<void> _guarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _primary() => _guarded(() async {
    final text = _fields[_step]!.text;
    if (_step == ClosingStep.close) {
      await widget.onKeep(text);
      _goTo(ClosingStep.plan);
    } else {
      await widget.onPlan(text);
    }
  });

  void _secondary() {
    if (_busy) return;
    if (_step == ClosingStep.close) {
      _goTo(ClosingStep.plan);
    } else {
      widget.onEnjoy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == ClosingStep.close,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(ClosingStep.close);
      },
      child: _CardSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fadeThrough(context, _eyebrow()),
            Flexible(child: _scrollingBody(context)),
            SafeArea(top: false, child: _actions()),
          ],
        ),
      ),
    );
  }

  Widget _fadeThrough(BuildContext context, Widget child) =>
      WeekMomentFadeThrough(
        duration: Motion.of(context, Motion.long),
        child: child,
      );

  Widget _eyebrow() => _ClosingEyebrow(
    key: ValueKey('week_moment_${_step.name}_eyebrow'),
    step: _step,
    text: widget.texts.stepEyebrow(_step, widget.turn, widget.story),
    counter: widget.texts.stepCounter(_step),
  );

  Widget _scrollingBody(BuildContext context) => ScrollThread(
    child: SingleChildScrollView(
      padding: StepLayout.padding.copyWith(top: 8, bottom: 16),
      child: _fadeThrough(
        context,
        _ClosingStepBody(
          key: ValueKey(_step),
          step: _step,
          texts: widget.texts,
          controller: _fields[_step]!,
        ),
      ),
    ),
  );

  Widget _actions() => StepActions(
    action: FilledButton(
      key: ValueKey('week_moment_${_step.name}_primary'),
      onPressed: _busy ? null : _primary,
      child: Text(widget.texts.primaryAction(_step)),
    ),
    secondaryAction: TextButton(
      key: ValueKey('week_moment_${_step.name}_secondary'),
      onPressed: _busy ? null : _secondary,
      child: Text(widget.texts.secondaryAction(_step)),
    ),
  );
}

/// The card itself: a slightly lighter surface with rounded top corners.
class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    return Material(
      key: const ValueKey('week_moment_closing_card'),
      color: light ? scheme.surfaceContainerLowest : scheme.surfaceContainerHigh,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(WeekClosingCard.radius),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.only(top: 24), child: child),
    );
  }
}

/// A small square in the phase colour, then the step's eyebrow
/// ("WEEK 45 · COMPLETE") and "1 of 2" at the end. The square is solid for
/// the week that ended and only framed for the one still to come.
class _ClosingEyebrow extends StatelessWidget {
  const _ClosingEyebrow({
    super.key,
    required this.step,
    required this.text,
    required this.counter,
  });

  final ClosingStep step;
  final String text;
  final String counter;

  @override
  Widget build(BuildContext context) {
    final style = PhaseStyle.eyebrow(context);
    return Padding(
      padding: StepLayout.padding.copyWith(top: 0, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 10),
            child: _WeekSquare(filled: step == ClosingStep.close),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text.toUpperCase(), style: style),
            ),
          ),
          const SizedBox(width: 12),
          Text(counter, key: const ValueKey('week_moment_step_counter'),
              style: style),
        ],
      ),
    );
  }
}

/// One week as a small square: [filled] for a lived week, framed for the
/// coming one.
class _WeekSquare extends StatelessWidget {
  const _WeekSquare({required this.filled});

  final bool filled;

  static const double size = 10;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = PhaseColors.of(context).current;
    return Container(
      key: ValueKey(filled ? 'week_square_filled' : 'week_square_framed'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? phase : null,
        borderRadius: BorderRadius.circular(2.5),
        border: filled ? null : Border.all(color: scheme.onSurface, width: 1.5),
      ),
    );
  }
}

/// Title (announced when the step changes), question, and the optional
/// text field with its label above it.
class _ClosingStepBody extends StatelessWidget {
  const _ClosingStepBody({
    super.key,
    required this.step,
    required this.texts,
    required this.controller,
  });

  final ClosingStep step;
  final WeekMomentTexts texts;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = texts.closingLines(step);
    final label = texts.fieldLabel(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            lines.main,
            key: const ValueKey('week_moment_step_title'),
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 12),
        Text(lines.detail ?? '', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 20),
        ExcludeSemantics(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _field(label),
      ],
    );
  }

  Widget _field(String label) => Semantics(
    label: label,
    child: TextField(
      key: ValueKey('week_moment_${step.name}_field'),
      controller: controller,
      minLines: 3,
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: texts.fieldHint(step),
        hintMaxLines: 3,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
