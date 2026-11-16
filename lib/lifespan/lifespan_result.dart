import 'applied_estimate.dart';

/// What is kept of an applied lifespan estimate: the applied years and the
/// range shown in Settings. Never the answers (country, sex, lifestyle,
/// health conditions) that led to it.
class LifespanResult {
  const LifespanResult({
    required this.years,
    required this.mean,
    required this.p25,
    required this.p75,
  });

  /// The result of [applied].
  factory LifespanResult.of(AppliedLifespanEstimate applied) => LifespanResult(
    years: applied.appliedYears,
    mean: applied.estimate.mean,
    p25: applied.estimate.p25,
    p75: applied.estimate.p75,
  );

  static const String yearsKey = 'years';
  static const String meanKey = 'mean';
  static const String p25Key = 'p25';
  static const String p75Key = 'p75';

  /// The years the estimate applied (the life expectancy it set).
  final int years;
  final double mean;
  final double p25;
  final double p75;

  Map<String, Object?> toJson() => {
    yearsKey: years,
    meanKey: mean,
    p25Key: p25,
    p75Key: p75,
  };

  /// Null when [json] is not a complete result.
  static LifespanResult? fromJson(Map<String, Object?> json) {
    final years = json[yearsKey];
    final mean = json[meanKey], p25 = json[p25Key], p75 = json[p75Key];
    if (years is! int || mean is! num || p25 is! num || p75 is! num) {
      return null;
    }
    return LifespanResult(
      years: years,
      mean: mean.toDouble(),
      p25: p25.toDouble(),
      p75: p75.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LifespanResult &&
      other.years == years &&
      other.mean == mean &&
      other.p25 == p25 &&
      other.p75 == p75;

  @override
  int get hashCode => Object.hash(years, mean, p25, p75);
}
