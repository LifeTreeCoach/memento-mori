import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// A tour starts only when it was never seen, its tab is visible, its
/// route is the top one and nothing else (a dialog, the setup, another
/// prompt) [blocked] it.
bool shouldStartTour({
  required bool seen,
  required bool tabVisible,
  required bool routeIsCurrent,
  bool blocked = false,
}) {
  return !seen && tabVisible && routeIsCurrent && !blocked;
}

/// The steps that can be shown: centred ones always, anchored ones only
/// when [isAnchored] knows their anchor. The step counter counts these.
List<TourStep> availableSteps(
  List<TourStep> steps,
  bool Function(String anchorId) isAnchored,
) {
  return [
    for (final step in steps)
      if (step.anchorId == null || isAnchored(step.anchorId!)) step,
  ];
}
