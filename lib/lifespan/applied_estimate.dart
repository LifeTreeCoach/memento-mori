import 'lifespan_estimator.dart';

/// A [LifespanEstimate] together with the number of years the user applied
/// (the fine-tune slider value). In memory only: what is kept is a
/// `LifespanResult`.
class AppliedLifespanEstimate {
  const AppliedLifespanEstimate({
    required this.estimate,
    required this.appliedYears,
  });

  final LifespanEstimate estimate;
  final int appliedYears;

  /// True when the user moved the slider away from the recommended value.
  bool get isFineTuned => appliedYears != estimate.recommendedYears;
}
