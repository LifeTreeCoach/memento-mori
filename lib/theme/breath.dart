import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Maps overall progress 0..1 to [cycles] smooth breaths that start and
/// end at full glow (1), so settling never jumps.
class BreathTween extends Animatable<double> {
  const BreathTween(this.cycles);

  final int cycles;

  @override
  double transform(double t) => 0.5 + 0.5 * math.cos(2 * math.pi * cycles * t);
}

/// A few slow breaths that run once whenever their owner becomes visible
/// (first shown, tab re-selected, app resumed), then settle with no ticker,
/// so an idle screen doesn't repaint. With motion off it stays settled.
///
/// The owner forwards its motion and visibility through [update] (from
/// didChangeDependencies) and calls [dispose].
class BreathCycle with WidgetsBindingObserver {
  BreathCycle({required TickerProvider vsync, this.cycles = defaultCycles})
      : progress = AnimationController(
          vsync: vsync,
          duration: Motion.pulse * cycles,
          value: 1,
        ) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Number of breaths before settling.
  static const int defaultCycles = 3;

  final int cycles;

  /// Runs once from 0 to 1 over all breaths; settled at 1.
  final AnimationController progress;

  /// 1 at rest and at the start/end of every breath, 0 at its deepest.
  late final Animation<double> breath = progress.drive(BreathTween(cycles));

  bool _motion = false;
  bool _visible = false;

  /// Breathes when the owner just became visible or motion was turned on;
  /// settles at once when motion is off.
  void update({required bool motion, required bool visible}) {
    final becameVisible = visible && !_visible;
    final motionChanged = motion != _motion;
    _motion = motion;
    _visible = visible;
    if (!motion) {
      _settle();
    } else if (becameVisible || motionChanged) {
      _breathe();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _motion && _visible) _breathe();
  }

  void _breathe() => progress.forward(from: 0);

  void _settle() {
    progress
      ..stop()
      ..value = 1;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    progress.dispose();
  }
}
