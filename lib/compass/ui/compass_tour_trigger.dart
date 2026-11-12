import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_tour.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_trigger.dart';

/// Starts the [CompassTour]: once by itself ([startIfDue]) or on request
/// (the help button, [show]). A tour that was shown counts as seen,
/// whether it was finished or put off with "Not now".
class CompassTourTrigger {
  CompassTourTrigger({
    required BuildContext Function() contextOf,
    required TourAnchors anchors,
  }) : _trigger = TourTrigger(contextOf: contextOf, anchors: anchors);

  final TourTrigger _trigger;

  /// Shows the tour unless it was seen, the tab is hidden, a sheet, dialog
  /// or pushed screen lies above the tab, or [blocked] (the setup is due).
  Future<void> startIfDue({
    required bool Function() tabVisible,
    required bool Function() blocked,
  }) =>
      _trigger.startIfDue(CompassTour.id, CompassTour.steps,
          tabVisible: tabVisible, blocked: blocked);

  /// Runs the tour now, seen or not. It counts as seen as soon as a step
  /// shows (so closing the app mid-tour does not bring it back).
  Future<TourResult> show() =>
      _trigger.show(CompassTour.id, CompassTour.steps);
}
