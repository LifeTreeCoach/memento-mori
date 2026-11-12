import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_trigger.dart';

/// Starts the matching [PeopleTour]: the empty one while nobody is listed,
/// the list one afterwards; once by itself ([startIfDue]) or on request
/// ("How People works", [show]).
class PeopleTourTrigger {
  PeopleTourTrigger({
    required BuildContext Function() contextOf,
    required TourAnchors anchors,
  }) : _trigger = TourTrigger(contextOf: contextOf, anchors: anchors);

  final TourTrigger _trigger;

  /// Shows the tour for an [empty] list or not, unless it was seen, the
  /// tab is hidden, something lies above the tab or [blocked]. Someone
  /// who already has people never needs the empty tour: it counts as seen.
  Future<TourResult> startIfDue({
    required bool empty,
    required bool Function() tabVisible,
    required bool Function() blocked,
  }) async {
    if (!empty && tabVisible()) {
      await TourProgressStore.markSeen(PeopleTour.emptyId);
    }
    return _trigger.startIfDue(
      PeopleTour.idFor(empty: empty),
      PeopleTour.stepsFor(empty: empty),
      tabVisible: tabVisible,
      blocked: blocked,
    );
  }

  /// Runs the tour for an [empty] list or not now, seen or not.
  Future<TourResult> show({required bool empty}) => _trigger.show(
      PeopleTour.idFor(empty: empty), PeopleTour.stepsFor(empty: empty));
}
