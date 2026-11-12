import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// The highlighted week dot of the look back: readable gold with a fine
/// ring, breathing a few times (like the life grid's now cell) and then
/// resting. Still when motion is off.
class BreathingDot extends StatefulWidget {
  const BreathingDot({super.key});

  /// Breaths before the dot rests.
  static const int breaths = 3;

  /// Largest scale while breathing.
  static const double maxScale = 1.45;

  @override
  State<BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: Motion.pulse ~/ 2,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !Motion.enabled(context)) return;
    _started = true;
    _breath.repeat(reverse: true, count: BreathingDot.breaths * 2);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dot = DecoratedBox(
      key: const ValueKey('reflection_week_dot'),
      decoration: BoxDecoration(
        color: PhaseStyle.readableGold(context),
        shape: BoxShape.circle,
        border: Border.all(color: scheme.onSurface, width: 1),
      ),
    );
    return ScaleTransition(
      scale: _breath.drive(
        Tween(
          begin: 1.0,
          end: BreathingDot.maxScale,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: dot,
    );
  }
}
