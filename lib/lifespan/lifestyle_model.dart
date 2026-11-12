/// Lifestyle hazard multipliers for the cohort engine.
///
/// Each category has a published all-cause mortality hazard ratio (HR, relative
/// to the paper's reference group) and an assumed adult population share p. The
/// multiplier applied to the population life table is the HR normalised to the
/// population average, m = HR / sum(p * HR), so that "average" answers leave the
/// population table unchanged (sum(p * m) = 1). The m values are rounded to two
/// decimals. A skipped/unknown answer counts as m = 1.0 (population average).
///
/// The effects are observational associations, not causal guarantees; the
/// factors are treated as independent (multiplicative), which overstates the
/// combined effect somewhat, hence the clamp in [LifestyleAnswers.multiplier].
library;

import 'dart:math' as math;

import 'condition_model.dart';

/// One category of a lifestyle factor: its multiplier and the data behind it.
class LifestyleCategory {
  const LifestyleCategory({
    required this.multiplier,
    required this.hazardRatio,
    required this.prevalence,
  });

  /// Normalised multiplier m (rounded).
  final double multiplier;

  /// Published hazard ratio relative to the study's reference category.
  final double hazardRatio;

  /// Assumed share of adults in this category.
  final double prevalence;
}

/// Common interface of the lifestyle answer enums.
abstract interface class LifestyleOption implements Enum {
  LifestyleCategory get category;
}

/// Cigarette smoking.
///
/// Jha P et al. 21st-century hazards of smoking and benefits of cessation in the
/// United States. N Engl J Med 2013;368:341-350. Current smokers ~3x the
/// all-cause mortality of never-smokers; quitting before 40 avoids ~90 % of the
/// excess risk, quitting later about two thirds.
enum Smoking implements LifestyleOption {
  never(
    LifestyleCategory(multiplier: 0.70, hazardRatio: 1.00, prevalence: 0.515),
  ),
  quitBefore40(
    LifestyleCategory(multiplier: 0.81, hazardRatio: 1.16, prevalence: 0.15),
  ),
  quit40plus(
    LifestyleCategory(multiplier: 1.05, hazardRatio: 1.50, prevalence: 0.13),
  ),

  /// Fewer than 10 cigarettes per day.
  currentLight(
    LifestyleCategory(multiplier: 1.54, hazardRatio: 2.20, prevalence: 0.09),
  ),

  /// 10 or more cigarettes per day.
  currentHeavy(
    LifestyleCategory(multiplier: 2.10, hazardRatio: 3.00, prevalence: 0.115),
  );

  const Smoking(this.category);
  @override
  final LifestyleCategory category;
}

/// Leisure-time moderate-to-vigorous physical activity.
///
/// Arem H et al. Leisure time physical activity and mortality: a detailed
/// pooled analysis of the dose-response relationship. JAMA Intern Med
/// 2015;175:959-967. HR vs no activity: <150 min/wk 0.80, 150-300 0.69, >300 ~0.63.
enum Activity implements LifestyleOption {
  inactive(
    LifestyleCategory(multiplier: 1.38, hazardRatio: 1.00, prevalence: 0.10),
  ),

  /// Some activity, under 150 minutes per week.
  some(
    LifestyleCategory(multiplier: 1.10, hazardRatio: 0.80, prevalence: 0.25),
  ),

  /// 150-300 minutes per week (WHO guideline).
  guideline(
    LifestyleCategory(multiplier: 0.95, hazardRatio: 0.69, prevalence: 0.30),
  ),

  /// More than 300 minutes per week.
  high(
    LifestyleCategory(multiplier: 0.87, hazardRatio: 0.63, prevalence: 0.35),
  );

  const Activity(this.category);
  @override
  final LifestyleCategory category;
}

/// Alcohol, in standard drinks per week.
///
/// Wood AM et al. Risk thresholds for alcohol consumption: combined analysis of
/// individual-participant data for 599 912 current drinkers in 83 prospective
/// studies. Lancet 2018;391:1513-1523. Zhao J et al. Association between daily
/// alcohol intake and risk of all-cause mortality. JAMA Netw Open
/// 2023;6:e236185. No protective effect of light drinking is assumed.
enum Alcohol implements LifestyleOption {
  /// None up to 7 drinks per week.
  upTo7(
    LifestyleCategory(multiplier: 0.96, hazardRatio: 1.00, prevalence: 0.70),
  ),
  from8to14(
    LifestyleCategory(multiplier: 1.01, hazardRatio: 1.05, prevalence: 0.17),
  ),
  from15to28(
    LifestyleCategory(multiplier: 1.16, hazardRatio: 1.21, prevalence: 0.09),
  ),
  over28(
    LifestyleCategory(multiplier: 1.44, hazardRatio: 1.50, prevalence: 0.04),
  );

  const Alcohol(this.category);
  @override
  final LifestyleCategory category;
}

/// Body-mass index band.
///
/// Global BMI Mortality Collaboration. Body-mass index and all-cause mortality:
/// individual-participant-data meta-analysis of 239 prospective studies in four
/// continents. Lancet 2016;388:776-786. HR vs BMI 18.5-25 (never-smokers):
/// <18.5 ~1.5, 25-30 ~1.12, 30-35 1.45, 35-40 1.94, >=40 2.76.
enum BmiBand implements LifestyleOption {
  under18_5(
    LifestyleCategory(multiplier: 1.26, hazardRatio: 1.50, prevalence: 0.02),
  ),

  /// 18.5 to under 25.
  healthy(
    LifestyleCategory(multiplier: 0.84, hazardRatio: 1.00, prevalence: 0.42),
  ),

  /// 25 to under 30.
  over25(
    LifestyleCategory(multiplier: 0.94, hazardRatio: 1.12, prevalence: 0.35),
  ),

  /// 30 to under 35.
  over30(
    LifestyleCategory(multiplier: 1.22, hazardRatio: 1.45, prevalence: 0.15),
  ),

  /// 35 to under 40.
  over35(
    LifestyleCategory(multiplier: 1.64, hazardRatio: 1.95, prevalence: 0.04),
  ),

  /// 40 or more.
  over40(
    LifestyleCategory(multiplier: 2.33, hazardRatio: 2.77, prevalence: 0.02),
  );

  const BmiBand(this.category);
  @override
  final LifestyleCategory category;
}

/// BMI band from height and weight; null for missing or implausible values.
/// Only the band is ever stored, never the raw height or weight.
BmiBand? bmiBandFor(double? heightCm, double? weightKg) {
  if (heightCm == null || weightKg == null) return null;
  if (heightCm < 50 || heightCm > 280 || weightKg < 10 || weightKg > 500) {
    return null;
  }
  final meters = heightCm / 100.0;
  // Rounded to 0.01 so that e.g. exactly 25.0 is not lost to floating-point noise.
  final bmi = (weightKg / (meters * meters) * 100).round() / 100;
  if (bmi < 18.5) return BmiBand.under18_5;
  if (bmi < 25) return BmiBand.healthy;
  if (bmi < 30) return BmiBand.over25;
  if (bmi < 35) return BmiBand.over30;
  if (bmi < 40) return BmiBand.over35;
  return BmiBand.over40;
}

/// Social connection / loneliness.
///
/// Holt-Lunstad J, Smith TB, Layton JB. Social relationships and mortality
/// risk: a meta-analytic review. PLoS Med 2010;7:e1000316. Holt-Lunstad J et al.
/// Loneliness and social isolation as risk factors for mortality: a
/// meta-analytic review. Perspect Psychol Sci 2015;10:227-237 (loneliness
/// OR ~1.26-1.29).
enum SocialConnection implements LifestyleOption {
  oftenLonely(
    LifestyleCategory(multiplier: 1.20, hazardRatio: 1.29, prevalence: 0.15),
  ),
  sometimes(
    LifestyleCategory(multiplier: 1.02, hazardRatio: 1.10, prevalence: 0.35),
  ),
  wellConnected(
    LifestyleCategory(multiplier: 0.93, hazardRatio: 1.00, prevalence: 0.50),
  );

  const SocialConnection(this.category);
  @override
  final LifestyleCategory category;
}

/// The lifestyle factors, in questionnaire order.
enum LifestyleFactor {
  smoking(Smoking.values),
  activity(Activity.values),
  alcohol(Alcohol.values),
  bmi(BmiBand.values),
  social(SocialConnection.values);

  const LifestyleFactor(this.options);

  final List<LifestyleOption> options;

  /// The lowest-risk category of this factor.
  LifestyleOption get best {
    var best = options.first;
    for (final option in options) {
      if (option.category.multiplier < best.category.multiplier) best = option;
    }
    return best;
  }
}

/// Optional lifestyle answers; null = skipped (population average).
class LifestyleAnswers {
  const LifestyleAnswers({
    this.smoking,
    this.activity,
    this.alcohol,
    this.bmi,
    this.social,
    this.conditions,
  });

  static const int jsonVersion = 1;
  static const double minMultiplier = 0.6;
  static const double maxMultiplier = 2.5;
  static const double adultAge = 18;

  final Smoking? smoking;
  final Activity? activity;
  final Alcohol? alcohol;
  final BmiBand? bmi;
  final SocialConnection? social;

  /// Chronic conditions; null = skipped, empty = "none of these".
  final Set<ChronicCondition>? conditions;

  bool get isEmpty =>
      conditions == null &&
      LifestyleFactor.values.every((f) => answerFor(f) == null);

  LifestyleOption? answerFor(LifestyleFactor factor) => switch (factor) {
    LifestyleFactor.smoking => smoking,
    LifestyleFactor.activity => activity,
    LifestyleFactor.alcohol => alcohol,
    LifestyleFactor.bmi => bmi,
    LifestyleFactor.social => social,
  };

  /// A copy with [factor] set to [option] (which must belong to that factor).
  LifestyleAnswers withAnswer(
    LifestyleFactor factor,
    LifestyleOption? option,
  ) => LifestyleAnswers(
    smoking: factor == LifestyleFactor.smoking ? option as Smoking? : smoking,
    activity: factor == LifestyleFactor.activity
        ? option as Activity?
        : activity,
    alcohol: factor == LifestyleFactor.alcohol ? option as Alcohol? : alcohol,
    bmi: factor == LifestyleFactor.bmi ? option as BmiBand? : bmi,
    social: factor == LifestyleFactor.social
        ? option as SocialConnection?
        : social,
    conditions: conditions,
  );

  /// A copy with the chronic [conditions] answer replaced.
  LifestyleAnswers withConditions(Set<ChronicCondition>? conditions) =>
      LifestyleAnswers(
        smoking: smoking,
        activity: activity,
        alcohol: alcohol,
        bmi: bmi,
        social: social,
        conditions: conditions,
      );

  /// Combined multiplier M = product of the answered m, clamped to
  /// [[minMultiplier], [maxMultiplier]]; 1.0 below [adultAge].
  double multiplier({required double age}) {
    if (age < adultAge) return 1.0;
    var product = 1.0;
    for (final factor in LifestyleFactor.values) {
      product *= _factorMultiplier(factor);
    }
    return product.clamp(minMultiplier, maxMultiplier).toDouble();
  }

  /// m of one factor (1.0 when skipped). BMI counts only as m^0.5 when a
  /// ticked condition already carries much of its risk (no double counting).
  double _factorMultiplier(LifestyleFactor factor) {
    final m = answerFor(factor)?.category.multiplier ?? 1.0;
    final halved =
        factor == LifestyleFactor.bmi && conditionsOverlapBmi(conditions);
    return halved ? math.sqrt(m) : m;
  }

  /// Chronic condition multiplier Md at [age] (see [conditionMultiplier]).
  double conditionMultiplierAt({required double age}) =>
      conditionMultiplier(conditions, age);

  Map<String, Object?> toJson() => {
    'v': jsonVersion,
    for (final factor in LifestyleFactor.values)
      if (answerFor(factor) != null) factor.name: answerFor(factor)!.name,
    if (conditions != null)
      conditionsJsonKey: [
        for (final c in ChronicCondition.values)
          if (conditions!.contains(c)) c.name,
      ],
  };

  static const String conditionsJsonKey = 'conditions';

  /// A list of names becomes a set (unknown names ignored); else null.
  static Set<ChronicCondition>? _conditionsFromJson(Object? value) {
    if (value is! List) return null;
    return {
      for (final condition in ChronicCondition.values)
        if (value.contains(condition.name)) condition,
    };
  }

  /// Unknown or missing values become null (skipped).
  factory LifestyleAnswers.fromJson(Map<String, Object?> json) {
    T? pick<T extends LifestyleOption>(LifestyleFactor factor) {
      final value = json[factor.name];
      for (final option in factor.options) {
        if (option.name == value) return option as T;
      }
      return null;
    }

    return LifestyleAnswers(
      smoking: pick(LifestyleFactor.smoking),
      activity: pick(LifestyleFactor.activity),
      alcohol: pick(LifestyleFactor.alcohol),
      bmi: pick(LifestyleFactor.bmi),
      social: pick(LifestyleFactor.social),
      conditions: _conditionsFromJson(json[conditionsJsonKey]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LifestyleAnswers &&
      LifestyleFactor.values.every((f) => answerFor(f) == other.answerFor(f)) &&
      _sameConditions(conditions, other.conditions);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(LifestyleFactor.values.map(answerFor)),
    conditions == null ? null : Object.hashAllUnordered(conditions!),
  );

  static bool _sameConditions(
    Set<ChronicCondition>? a,
    Set<ChronicCondition>? b,
  ) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }
}

/// Age attenuation weight w(x): relative risk factors weaken in old age.
/// 1 up to 70, linear down to 0.4 at 95, 0.4 after.
double ageAttenuation(double age) {
  if (age <= 70) return 1.0;
  if (age >= 95) return 0.4;
  return 1.0 - 0.6 * (age - 70) / 25.0;
}

/// H(x) = M^w(x).
double attenuatedMultiplier(double multiplier, double age) =>
    math.pow(multiplier, ageAttenuation(age)).toDouble();
