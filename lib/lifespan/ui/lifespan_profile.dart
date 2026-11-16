import 'package:memento_mori_life_in_weeks/lifespan/applied_estimate.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';

/// What the estimate flow asked and what it produced: country, sex, the
/// optional answers and the applied estimate. In memory only: never
/// serialized; a `LifespanResultStore` keeps just its `LifespanResult`.
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

  final String? country;
  final Sex? sex;
  final LifestyleAnswers answers;
  final AppliedLifespanEstimate? applied;

}
