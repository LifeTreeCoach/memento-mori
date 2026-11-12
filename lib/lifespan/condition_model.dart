/// Chronic-condition hazard multipliers for the cohort engine (optional).
///
/// Each condition has a published all-cause mortality hazard ratio (HR) versus
/// people WITHOUT that condition, and an approximate adult prevalence p(age)
/// in high-income countries. Because the population life tables already
/// include sick people, a "none of these" answer lowers the hazard by the
/// reference factor n(age) = 1 / (1 + sum p_i(age) * (HR_i - 1)), and an
/// answer with conditions applies Md = combinedHR * n(age). Skipped (null) is
/// Md = 1.0 (population average); an empty set means "none of these".
///
/// The effects are observational associations, not causal guarantees, and
/// fade in old age ([diseaseAgeAttenuation]).
library;

import 'dart:math' as math;

/// Adult prevalence at ages 40, 60 and 80 (fractions of the population).
class ConditionPrevalence {
  const ConditionPrevalence(this.at40, this.at60, this.at80);

  final double at40;
  final double at60;
  final double at80;

  /// Linear interpolation between 40/60/80, clamped outside that range.
  double at(double age) {
    if (age <= 40) return at40;
    if (age >= 80) return at80;
    if (age <= 60) return at40 + (at60 - at40) * (age - 40) / 20.0;
    return at60 + (at80 - at60) * (age - 60) / 20.0;
  }
}

/// The chronic conditions a person can tick (diagnosed by a doctor).
///
/// Prevalences are rounded approximations of DIAGNOSED adult prevalence in
/// high-income countries (Germany / US / Western Europe), from: RKI
/// Diabetes-Surveillance and GEDA 2014/2015-EHIS (Heidemann C et al.); CDC
/// National Diabetes Statistics Report 2023; AHA Heart Disease and Stroke
/// Statistics 2023 Update, Circulation 2023;147:e93-e621 (MI, stroke, heart
/// failure by age); Groenewegen A et al., Eur J Heart Fail 2020;22:1342-1356
/// (heart failure); Adeloye D et al., Lancet Respir Med 2022;10:447-458 and
/// GEDA (COPD); Girndt M et al., Dtsch Arztebl Int 2016;113:85-91 (DEGS1,
/// eGFR < 60) and Hill NR et al., PLoS One 2016;11:e0158765 (CKD).
enum ChronicCondition {
  /// Emerging Risk Factors Collaboration (ERFC), Di Angelantonio E et al.
  /// Association of cardiometabolic multimorbidity with mortality.
  /// JAMA 2015;314:52-60: HR ~1.9 vs no diabetes.
  type2Diabetes(1.9, ConditionPrevalence(0.03, 0.12, 0.22)),

  /// Lind M et al. Glycemic control and excess mortality in type 1 diabetes.
  /// N Engl J Med 2014;371:1972-1982: overall adjusted all-cause HR ~3.5 vs
  /// matched population controls (primary source).
  /// Context: Livingstone SJ et al., JAMA 2015;313:37-44 (Scotland 2008-2010)
  /// report ~11-13 years lost at age 20; that reflects an older-care cohort,
  /// and this model deliberately errs on the conservative side (~7-10 years at
  /// 20 with the disease fade-out [diseaseAgeAttenuation]).
  type1Diabetes(3.5, ConditionPrevalence(0.004, 0.004, 0.003)),

  /// Past myocardial infarction. ERFC, JAMA 2015;314:52-60: HR ~2.0.
  heartAttack(2.0, ConditionPrevalence(0.005, 0.04, 0.10)),

  /// Past stroke. ERFC, JAMA 2015;314:52-60: HR ~2.1.
  stroke(2.1, ConditionPrevalence(0.004, 0.025, 0.08)),

  /// Heart failure. Stolfo D et al. Persistent high burden of heart failure
  /// across the ejection fraction spectrum in a nationwide setting. J Am
  /// Heart Assoc 2022;11:e026708 (PMC9750084): HR 2.53 vs a sex-, age- and
  /// county-matched population without heart failure: HR 2.5.
  heartFailure(2.5, ConditionPrevalence(0.002, 0.015, 0.08)),

  /// Mannino DM et al. Obstructive lung disease and low lung function in
  /// adults in the United States. Thorax 2003;58:388-393; Shavelle RM et al.
  /// Life expectancy and years of life lost in COPD. Int J Chron Obstruct
  /// Pulmon Dis 2009;4:137-148: HR ~1.8.
  copd(1.8, ConditionPrevalence(0.015, 0.06, 0.10)),

  /// Chronic kidney disease, not on dialysis. Chronic Kidney Disease
  /// Prognosis Consortium, Matsushita K et al. Lancet 2010;375:2073-2081:
  /// HR ~1.6 at eGFR 30-60 vs normal.
  kidney(1.6, ConditionPrevalence(0.01, 0.05, 0.15));

  const ChronicCondition(this.hazardRatio, this.prevalence);

  /// All-cause mortality HR vs people without the condition.
  final double hazardRatio;

  /// Approximate adult prevalence by age.
  final ConditionPrevalence prevalence;

  /// Conditions whose risk already includes much of the BMI effect.
  bool get overlapsBmi => switch (this) {
    type2Diabetes ||
    type1Diabetes ||
    heartAttack ||
    stroke ||
    heartFailure => true,
    copd || kidney => false,
  };
}

/// Exponent for every condition after the strongest one (sub-multiplicative).
const double furtherConditionExponent = 0.85;

/// Upper bound of the combined condition HR.
const double maxCombinedConditionHazardRatio = 4.0;

/// Lower bound of the reference factor n(age).
const double minNoConditionFactor = 0.75;

/// Conditions only count from this age on.
const double conditionAdultAge = 18;

/// Combined HR: sorted descending, the first counts fully, each further one as
/// HR^0.85; capped at [maxCombinedConditionHazardRatio]. 1.0 for none.
///
/// Check against ERFC, JAMA 2015;314:52-60 (observed HRs): diabetes + MI
/// 2.0 * 1.9^0.85 = 3.45 vs 3.71; diabetes + MI + stroke 6.53 vs 6.92 (both
/// within 10 %). The cap then limits the triple to 4.0, a deliberately
/// conservative choice for a self-reported, unstaged answer.
double combinedConditionHazardRatio(Set<ChronicCondition> conditions) {
  final ratios = conditions.map((c) => c.hazardRatio).toList()
    ..sort((a, b) => b.compareTo(a));
  var combined = 1.0;
  for (var i = 0; i < ratios.length; i++) {
    combined *= i == 0
        ? ratios[i]
        : math.pow(ratios[i], furtherConditionExponent).toDouble();
  }
  return math.min(combined, maxCombinedConditionHazardRatio);
}

/// Reference factor for "none of these": n = 1 / (1 + sum p_i * (HR_i - 1)),
/// floored at [minNoConditionFactor]. The floor matters from about 60 on: the
/// additive sum counts people with several conditions several times
/// (multimorbidity), which overstates the population's excess risk.
double noConditionFactor(double age) {
  var excess = 0.0;
  for (final condition in ChronicCondition.values) {
    excess += condition.prevalence.at(age) * (condition.hazardRatio - 1.0);
  }
  return math.max(1.0 / (1.0 + excess), minNoConditionFactor);
}

/// Md at the current [age]: 1.0 when skipped (null) or under 18, otherwise
/// combinedHR * n(age) (n alone for an empty set = "none of these").
double conditionMultiplier(Set<ChronicCondition>? conditions, double age) {
  if (conditions == null || age < conditionAdultAge) return 1.0;
  return combinedConditionHazardRatio(conditions) * noConditionFactor(age);
}

/// Whether the BMI factor should only count as m_bmi^0.5 (the condition's HR
/// already carries much of the excess risk of a high BMI).
bool conditionsOverlapBmi(Set<ChronicCondition>? conditions) =>
    conditions?.any((c) => c.overlapsBmi) ?? false;

/// Disease age attenuation wd(x): 1 up to 60, linear down to 0.4 at 90, 0.4
/// after (relative risks of chronic disease shrink with age, e.g. ERFC 2015).
double diseaseAgeAttenuation(double age) {
  if (age <= 60) return 1.0;
  if (age >= 90) return 0.4;
  return 1.0 - 0.6 * (age - 60) / 30.0;
}

/// Md^wd(x).
double attenuatedConditionMultiplier(double multiplier, double age) =>
    math.pow(multiplier, diseaseAgeAttenuation(age)).toDouble();
