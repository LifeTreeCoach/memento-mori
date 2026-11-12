import 'package:memento_mori_life_in_weeks/lifespan/applied_estimate.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';

/// What the estimate flow asked and what it produced: country, sex, the
/// optional answers and the applied estimate. A plain value; where it is
/// kept is up to a `LifespanProfileStore`.
class LifespanProfile {
  const LifespanProfile({
    this.country,
    this.sex,
    this.answers = const LifestyleAnswers(),
    this.applied,
  });

  /// The profile after applying [estimate] with [years].
  factory LifespanProfile.applied({
    required LifespanEstimate estimate,
    required LifestyleAnswers answers,
    required int years,
  }) => LifespanProfile(
    country: estimate.country,
    sex: estimate.sex,
    answers: answers,
    applied: AppliedLifespanEstimate(estimate: estimate, appliedYears: years),
  );

  /// Reads [json] tolerantly: unknown or broken fields are left empty.
  factory LifespanProfile.fromJson(Map<String, Object?> json) {
    final country = json[countryKey];
    final answers = json[answersKey];
    final applied = json[appliedKey];
    return LifespanProfile(
      country: country is String ? country : null,
      sex: Sex.fromName(_stringOrNull(json[sexKey])),
      answers: answers is Map<String, Object?>
          ? LifestyleAnswers.fromJson(answers)
          : const LifestyleAnswers(),
      applied: applied is Map<String, Object?>
          ? AppliedLifespanEstimate.fromJson(applied)
          : null,
    );
  }

  static const String countryKey = 'country';
  static const String sexKey = 'sex';
  static const String answersKey = 'answers';
  static const String appliedKey = 'applied';

  final String? country;
  final Sex? sex;
  final LifestyleAnswers answers;
  final AppliedLifespanEstimate? applied;

  /// The country, falling back to the applied estimate's.
  String? get effectiveCountry => country ?? applied?.estimate.country;

  /// The sex, falling back to the applied estimate's.
  Sex? get effectiveSex => sex ?? applied?.estimate.sex;

  /// Only the fields that are set; empty answers are left out.
  Map<String, Object?> toJson() => {
    if (country != null) countryKey: country,
    if (sex != null) sexKey: sex!.name,
    if (!answers.isEmpty) answersKey: answers.toJson(),
    if (applied != null) appliedKey: applied!.toJson(),
  };

  static String? _stringOrNull(Object? value) => value is String ? value : null;
}
