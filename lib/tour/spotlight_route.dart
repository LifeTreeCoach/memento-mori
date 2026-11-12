import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/tour/spotlight_overlay.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// A transparent route hosting [SpotlightOverlay]; fades in and out with
/// [Motion.medium] (instantly with reduced motion). Pops a [TourResult].
class SpotlightRoute extends PageRouteBuilder<TourResult> {
  SpotlightRoute({
    required List<TourStep> steps,
    required TourStepLocator locate,
    required Duration fadeDuration,
  }) : super(
          opaque: false,
          barrierDismissible: false,
          transitionDuration: fadeDuration,
          reverseTransitionDuration: fadeDuration,
          pageBuilder: (context, animation, secondaryAnimation) =>
              SpotlightOverlay(steps: steps, locate: locate),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Motion.standard),
            child: child,
          ),
        );

  /// Fade duration from [Motion.of] in [context].
  factory SpotlightRoute.of(
    BuildContext context, {
    required List<TourStep> steps,
    required TourStepLocator locate,
  }) {
    return SpotlightRoute(
      steps: steps,
      locate: locate,
      fadeDuration: Motion.of(context, Motion.medium),
    );
  }
}
