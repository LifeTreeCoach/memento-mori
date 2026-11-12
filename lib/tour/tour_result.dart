import 'package:flutter/foundation.dart';

/// How a tour ended.
enum TourOutcome {
  /// The last step was confirmed.
  completed,

  /// Skip or system back.
  skipped,

  /// No step could be shown (every anchor missing).
  notShown,
}

/// What [runTour] reports back.
@immutable
class TourResult {
  const TourResult(this.outcome, {required this.lastIndex});

  /// Nothing was shown.
  static const TourResult nothingShown =
      TourResult(TourOutcome.notShown, lastIndex: -1);

  final TourOutcome outcome;

  /// Index (among the shown steps) of the step that was visible last;
  /// -1 when nothing was shown.
  final int lastIndex;

  bool get completed => outcome == TourOutcome.completed;
  bool get skipped => outcome == TourOutcome.skipped;

  @override
  bool operator ==(Object other) =>
      other is TourResult &&
      other.outcome == outcome &&
      other.lastIndex == lastIndex;

  @override
  int get hashCode => Object.hash(outcome, lastIndex);

  @override
  String toString() => 'TourResult($outcome, lastIndex: $lastIndex)';
}
