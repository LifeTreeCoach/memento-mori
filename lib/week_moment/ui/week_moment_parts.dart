import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_texts.dart';

/// The eyebrow of the current act (fading through per act; none on the
/// final act, whose card has its own) and "Skip", which keeps its place but
/// is hidden on the final act.
class WeekMomentTopRow extends StatelessWidget {
  const WeekMomentTopRow({
    super.key,
    required this.eyebrow,
    required this.showSkip,
    required this.onSkip,
  });

  final String? eyebrow;
  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: StepLayout.padding.left, right: 8),
      child: Row(
        children: [
          Expanded(child: _eyebrow(context)),
          Visibility(
            visible: showSkip,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: TextButton(
              key: const ValueKey('week_moment_skip'),
              onPressed: onSkip,
              child: Text(
                AppLocalizations.of(context).translate('week_moment_skip'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(BuildContext context) {
    final eyebrow = this.eyebrow;
    return WeekMomentFadeThrough(
      duration: Motion.of(context, Motion.long),
      child: eyebrow == null
          ? const SizedBox.shrink(key: ValueKey('no_eyebrow'))
          : Semantics(
              key: ValueKey(eyebrow),
              header: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: PhaseEyebrow(eyebrow),
              ),
            ),
    );
  }
}

/// Fades its keyed [child] through to the next one: the old child fades out
/// in the first half of [duration], the new one fades in in the second, so
/// two texts never show on top of each other. Instant with a zero
/// [duration] (reduced motion). Outgoing children leave the semantics tree
/// at once, so only the current text is announced.
class WeekMomentFadeThrough extends StatelessWidget {
  const WeekMomentFadeThrough({
    super.key,
    required this.duration,
    required this.child,
  });

  /// The incoming half: nothing before the midpoint.
  static const Curve fadeCurve = Interval(0.5, 1, curve: Curves.easeInOut);

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: duration,
    // The outgoing child runs the animation backwards (1 -> 0), so the
    // same interval makes it vanish in the first half.
    switchInCurve: fadeCurve,
    switchOutCurve: fadeCurve,
    layoutBuilder: _alignStart,
    child: child,
  );

  /// Stacks the children at the top start, so a shorter text never jumps
  /// to the centre; outgoing ones are hidden from screen readers.
  static Widget _alignStart(Widget? current, List<Widget> previous) => Stack(
    alignment: AlignmentDirectional.topStart,
    children: [
      for (final child in previous) ExcludeSemantics(child: child),
      ?current,
    ],
  );
}

/// The act's lines, fading through per act and announced by screen readers.
class WeekMomentTextBlock extends StatelessWidget {
  const WeekMomentTextBlock({
    super.key,
    required this.actKey,
    required this.lines,
  });

  /// Identifies the act, so its lines fade through to the next act's.
  final Key actKey;
  final WeekMomentLines lines;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.long);
    return Padding(
      padding: StepLayout.padding.copyWith(top: 16, bottom: 8),
      child: _resizing(
        duration,
        WeekMomentFadeThrough(
          duration: duration,
          child: _ActLines(key: actKey, lines: lines),
        ),
      ),
    );
  }

  /// Eases height changes between acts; none with reduced motion
  /// (AnimatedSize must not run with a zero duration).
  static Widget _resizing(Duration duration, Widget child) {
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: Motion.standard,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// The main line in serif and the detail quietly beneath, read out as one
/// sentence whenever the act changes.
class _ActLines extends StatelessWidget {
  const _ActLines({super.key, required this.lines});

  final WeekMomentLines lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = lines.detail;
    return Semantics(
      liveRegion: true,
      container: true,
      label: lines.spoken,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lines.main,
              key: const ValueKey('week_moment_main'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFeatures: const [FontFeature.liningFigures()],
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                key: const ValueKey('week_moment_detail'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
