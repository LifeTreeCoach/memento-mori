import 'lifespan_estimator.dart';

/// A [LifespanEstimate] together with the number of years the user applied
/// (the fine-tune slider value), as stored under `lifespan_estimate`.
class AppliedLifespanEstimate {
  const AppliedLifespanEstimate({
    required this.estimate,
    required this.appliedYears,
  });

  static const String appliedYearsKey = 'appliedYears';

  final LifespanEstimate estimate;
  final int appliedYears;

  /// True when the user moved the slider away from the recommended value.
  bool get isFineTuned => appliedYears != estimate.recommendedYears;

  Map<String, Object?> toJson() => {
    ...estimate.toJson(),
    appliedYearsKey: appliedYears,
  };

  /// Returns null when [json] is not a valid stored estimate.
  static AppliedLifespanEstimate? fromJson(Map<String, Object?> json) {
    final estimate = LifespanEstimate.fromJson(json);
    final applied = json[appliedYearsKey];
    if (estimate == null || applied is! int) return null;
    return AppliedLifespanEstimate(estimate: estimate, appliedYears: applied);
  }
}
