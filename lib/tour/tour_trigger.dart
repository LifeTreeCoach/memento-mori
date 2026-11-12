import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_rules.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_runner.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// Starts the tours of one screen: once by itself ([startIfDue]) or on
/// request ([show]). A tour that was shown counts as seen, whether it was
/// finished or skipped. Only one tour runs at a time.
class TourTrigger {
  TourTrigger({required this.contextOf, required this.anchors});

  /// A context inside the screen's route.
  final BuildContext Function() contextOf;
  final TourAnchors anchors;

  bool _running = false;

  /// Whether a tour is showing (or about to).
  bool get isRunning => _running;

  /// Shows tour [id] unless it was seen, the tab is hidden, a sheet, dialog
  /// or pushed screen lies above the screen, or [blocked].
  Future<TourResult> startIfDue(
    String id,
    List<TourStep> steps, {
    required bool Function() tabVisible,
    required bool Function() blocked,
  }) async {
    await TourProgressStore.initialize();
    final context = contextOf();
    if (!context.mounted) return TourResult.nothingShown;
    final due = shouldStartTour(
      seen: TourProgressStore.isSeen(id),
      tabVisible: tabVisible(),
      routeIsCurrent: ModalRoute.isCurrentOf(context) ?? true,
      blocked: _running || blocked(),
    );
    return due ? show(id, steps) : TourResult.nothingShown;
  }

  /// Runs tour [id] now, seen or not. It counts as seen as soon as a step
  /// shows (so closing the app mid-tour does not bring it back).
  Future<TourResult> show(String id, List<TourStep> steps) async {
    if (_running) return TourResult.nothingShown;
    _running = true;
    try {
      if (availableSteps(steps, anchors.contains).isEmpty) {
        return TourResult.nothingShown;
      }
      final context = contextOf();
      await TourProgressStore.markSeen(id);
      if (!context.mounted) return TourResult.nothingShown;
      return await runTour(context, steps, anchors);
    } finally {
      _running = false;
    }
  }
}
