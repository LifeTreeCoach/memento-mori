import 'dart:math' as math;

import 'condition_model.dart';
import 'lifestyle_model.dart';

/// Upper bound of the total hazard multiplier at any age.
const double maxTotalHazardMultiplier = 6.0;

/// H(x) = min(Ml^w(x) * Md^wd(x), [maxTotalHazardMultiplier]).
///
/// [lifestyle] is the clamped lifestyle multiplier Ml, [condition] the chronic
/// condition multiplier Md, both fixed at the current age; w and wd fade them
/// with the attained age [age]. With Md = 1 this equals [attenuatedMultiplier]
/// exactly (1^wd = 1 and Ml <= 2.5 < 6).
double combinedHazardMultiplier({
  required double lifestyle,
  required double condition,
  required double age,
}) {
  final hazard =
      attenuatedMultiplier(lifestyle, age) *
      attenuatedConditionMultiplier(condition, age);
  return math.min(hazard, maxTotalHazardMultiplier);
}
