import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/tour/spotlight_route.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_rules.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// Shows [steps] as coach marks over the current screen, in one route.
///
/// Steps whose anchor is missing are dropped up front (the counter only
/// counts shown steps; an anchor inside a lazy list counts only once it
/// is built); with none left nothing is pushed and the result
/// is [TourResult.nothingShown]. Marking a tour as seen is the caller's job.
Future<TourResult> runTour(
  BuildContext context,
  List<TourStep> steps,
  TourAnchors anchors,
) async {
  final shown = availableSteps(steps, anchors.contains);
  if (shown.isEmpty) return TourResult.nothingShown;
  final navigator = Navigator.of(context);
  final overlayBox = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final route = SpotlightRoute.of(
    context,
    steps: shown,
    locate: (step) => locateTourStep(step, anchors, overlayBox),
  );
  final result = await navigator.push(route);
  return result ?? const TourResult(TourOutcome.skipped, lastIndex: 0);
}

/// Scrolls [step]'s anchor into view (30% from the top), waits a frame
/// and returns its bounds in [ancestor]'s coordinates; null for a centred
/// step or an anchor that went away.
Future<Rect?> locateTourStep(
  TourStep step,
  TourAnchors anchors,
  RenderBox ancestor,
) async {
  final id = step.anchorId;
  if (id == null) return null;
  final target = anchors.contextOf(id);
  if (target == null) return null;
  await Scrollable.ensureVisible(
    target,
    alignment: 0.3,
    duration: Motion.of(target, Motion.medium),
    curve: Motion.standard,
  );
  await WidgetsBinding.instance.endOfFrame;
  return anchors.rectOf(id, ancestor: ancestor);
}
