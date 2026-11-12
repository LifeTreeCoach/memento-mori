import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/tour/spotlight_painter.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_card.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_card_layout.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_geometry.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// Scrolls a step's target into view and measures it in overlay
/// coordinates; null = centred card.
typedef TourStepLocator = Future<Rect?> Function(TourStep step);

/// The dim layer plus card of a running tour. Steps advance inside this
/// one widget, so the dim layer never flickers; pops a [TourResult].
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({super.key, required this.steps, required this.locate});

  final List<TourStep> steps;
  final TourStepLocator locate;

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay> {
  int _index = 0;
  Rect? _target;
  bool _ready = false;
  bool _busy = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    // Locating may scroll; never during this build (scroll listeners
    // such as app bars would rebuild mid-frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goTo(0);
    });
  }

  Future<void> _goTo(int index) async {
    _busy = true;
    final target = await widget.locate(widget.steps[index]);
    if (!mounted || _finished) return;
    setState(() {
      _index = index;
      _target = target;
      _ready = true;
      _busy = false;
    });
  }

  void _next() {
    if (_busy) return;
    if (_index >= widget.steps.length - 1) {
      _finish(TourOutcome.completed);
    } else {
      _goTo(_index + 1);
    }
  }

  void _finish(TourOutcome outcome) {
    if (_finished) return;
    _finished = true;
    Navigator.of(context).pop(TourResult(outcome, lastIndex: _index));
  }

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.medium);
    return PopScope<TourResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(TourOutcome.skipped);
      },
      child: Stack(fit: StackFit.expand, children: [
        AbsorbPointer(child: _dimLayer(context, duration)),
        if (_ready) _card(context, duration),
      ]),
    );
  }

  /// The dim layer; the hole glides between anchored steps. Without a
  /// hole there is no tween, so the hole never grows out of a corner.
  Widget _dimLayer(BuildContext context, Duration duration) {
    final scheme = Theme.of(context).colorScheme;
    Widget paint(Rect? hole) => CustomPaint(
          key: const ValueKey('tour_spotlight'),
          painter: SpotlightPainter.themed(scheme, hole: hole),
        );
    final target = _target;
    if (target == null) return paint(null);
    return TweenAnimationBuilder<Rect?>(
      tween: RectTween(end: TourGeometry.holeFor(target)),
      duration: duration,
      curve: Motion.standard,
      builder: (context, hole, _) => paint(hole),
    );
  }

  Widget _card(BuildContext context, Duration duration) {
    final step = widget.steps[_index];
    return CustomSingleChildLayout(
      delegate: TourCardLayout(
          target: _target, padding: MediaQuery.paddingOf(context)),
      child: AnimatedSwitcher(
        duration: duration,
        child: TourCard(
          key: ValueKey('tour_card_${step.id}'),
          step: step,
          index: _index,
          count: widget.steps.length,
          onPrimary: _next,
          onSecondary: () => _finish(TourOutcome.skipped),
        ),
      ),
    );
  }
}
