import 'cohort_engine.dart';
import 'hazard_profile.dart';
import 'life_table_set.dart';
import 'lifestyle_model.dart';
import 'sex.dart';

/// App bounds of the life expectancy setting
/// (mirrors `lib/settings/life_expectancy_sheet.dart`, which imports Flutter).
const int estimateMinYears = 50;
const int estimateMaxYears = 110;

/// Gains below this many years are not shown.
const double minimumShownGainYears = 0.5;

/// Result of [LifespanEstimator.estimate]; all ages in years.
class LifespanEstimate {
  const LifespanEstimate({
    required this.country,
    required this.sex,
    required this.age,
    required this.mean,
    required this.p25,
    required this.median,
    required this.p75,
    required this.reach80,
    required this.reach90,
    required this.multiplier,
    required this.recommendedYears,
    required this.gains,
    this.conditionMultiplier = 1.0,
  });

  static const int jsonVersion = 1;

  /// Resolved location key (`WLD` when the country is unknown).
  final String country;
  final Sex sex;

  /// Exact age at the time of the estimate.
  final double age;

  /// Expected age at death.
  final double mean;
  final double p25;
  final double median;
  final double p75;

  /// Probability of reaching 80 / 90 (null if already that old).
  final double? reach80;
  final double? reach90;

  /// Combined lifestyle multiplier M (1.0 without answers or under 18).
  final double multiplier;

  /// Chronic condition multiplier Md at [age] (1.0 when skipped or under 18).
  final double conditionMultiplier;

  /// round(mean) clamped to the app's 50..110 years.
  final int recommendedYears;

  /// Years the mean would rise per answered factor at its best category
  /// (only gains >= [minimumShownGainYears]), largest first.
  final Map<LifestyleFactor, double> gains;

  Map<String, Object?> toJson() => {
    'v': jsonVersion,
    'country': country,
    'sex': sex.name,
    'age': age,
    'mean': mean,
    'p25': p25,
    'median': median,
    'p75': p75,
    'reach80': reach80,
    'reach90': reach90,
    'multiplier': multiplier,
    'conditionMultiplier': conditionMultiplier,
    'recommendedYears': recommendedYears,
    'gains': {for (final e in gains.entries) e.key.name: e.value},
  };

  /// Returns null when [json] is not a valid stored estimate.
  static LifespanEstimate? fromJson(Map<String, Object?> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    final sex = Sex.fromName(json['sex'] as String?);
    final country = json['country'];
    final mean = number('mean'), p25 = number('p25');
    final median = number('median'), p75 = number('p75');
    final age = number('age'), multiplier = number('multiplier');
    final recommended = json['recommendedYears'];
    if (sex == null ||
        country is! String ||
        mean == null ||
        p25 == null ||
        median == null ||
        p75 == null ||
        age == null ||
        multiplier == null ||
        recommended is! int) {
      return null;
    }
    final rawGains = json['gains'];
    final gains = <LifestyleFactor, double>{};
    if (rawGains is Map) {
      for (final factor in LifestyleFactor.values) {
        final value = rawGains[factor.name];
        if (value is num) gains[factor] = value.toDouble();
      }
    }
    return LifespanEstimate(
      country: country,
      sex: sex,
      age: age,
      mean: mean,
      p25: p25,
      median: median,
      p75: p75,
      reach80: number('reach80'),
      reach90: number('reach90'),
      multiplier: multiplier,
      recommendedYears: recommended,
      gains: gains,
      conditionMultiplier: number('conditionMultiplier') ?? 1.0,
    );
  }
}

/// Personal cohort life expectancy from the WPP 2024 tables plus lifestyle.
class LifespanEstimator {
  const LifespanEstimator(this.tables);

  final LifeTableSet tables;

  static const double _daysPerYear = 365.2425;

  LifespanEstimate estimate({
    required String? country,
    required Sex sex,
    required DateTime birthDate,
    required DateTime now,
    LifestyleAnswers? answers,
  }) {
    final age = exactAge(birthDate, now);
    final year = fractionalYear(now);
    final code = tables.resolve(country);
    final lifestyle = answers ?? const LifestyleAnswers();
    final multiplier = lifestyle.multiplier(age: age);
    final condition = lifestyle.conditionMultiplierAt(age: age);
    final result = _run(code, sex, age, year, multiplier, condition);
    return LifespanEstimate(
      country: code,
      sex: sex,
      age: age,
      mean: result.mean,
      p25: result.p25,
      median: result.median,
      p75: result.p75,
      reach80: result.reach80,
      reach90: result.reach90,
      multiplier: multiplier,
      recommendedYears: recommendedYearsFor(result.mean),
      gains: _gains(code, sex, age, year, lifestyle, result.mean),
      conditionMultiplier: condition,
    );
  }

  /// [Sex.unspecified] is a 50/50 mixture of the female and male curves rather
  /// than the WPP "Both" table: WPP derives Both from the sexes, and for ~23
  /// micro-states and migrant-heavy countries shifting sex ratios make its
  /// single-year series jagged or push its cohort e(a) outside the female..male
  /// range (tool/README.md, validation b). The mixture is always between them.
  CohortResult _run(
    String code,
    Sex sex,
    double age,
    double year,
    double multiplier,
    double condition,
  ) {
    double hazard(int ageYears) => combinedHazardMultiplier(
      lifestyle: multiplier,
      condition: condition,
      age: ageYears.toDouble(),
    );
    SurvivalCurve curve(Sex tableSex) => CohortEngine.survival(
      tables.table(code, tableSex),
      age: age,
      year: year,
      hazardMultiplier: hazard,
    );
    if (sex == Sex.unspecified) {
      return CohortEngine.mixture(curve(Sex.female), curve(Sex.male));
    }
    return curve(sex).summarize();
  }

  Map<LifestyleFactor, double> _gains(
    String code,
    Sex sex,
    double age,
    double year,
    LifestyleAnswers answers,
    double mean,
  ) {
    final gains = <LifestyleFactor, double>{};
    final condition = answers.conditionMultiplierAt(age: age);
    for (final factor in LifestyleFactor.values) {
      final answer = answers.answerFor(factor);
      if (answer == null || answer == factor.best) continue;
      final improved = answers.withAnswer(factor, factor.best);
      final better = _run(
        code,
        sex,
        age,
        year,
        improved.multiplier(age: age),
        condition,
      );
      final gain = better.mean - mean;
      if (gain >= minimumShownGainYears) gains[factor] = gain;
    }
    final sorted = gains.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// round([mean]) clamped to the app's life expectancy range.
  static int recommendedYearsFor(double mean) =>
      mean.round().clamp(estimateMinYears, estimateMaxYears).toInt();

  /// Age in years from the calendar dates (days / 365.2425), never negative.
  static double exactAge(DateTime birthDate, DateTime now) {
    final birth = DateTime.utc(birthDate.year, birthDate.month, birthDate.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    final days = today.difference(birth).inDays;
    return days <= 0 ? 0.0 : days / _daysPerYear;
  }

  /// Calendar time as a fractional year, e.g. 2026-11-05 -> ~2026.85.
  static double fractionalYear(DateTime now) {
    final start = DateTime.utc(now.year);
    final end = DateTime.utc(now.year + 1);
    final current = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    return now.year +
        current.difference(start).inSeconds / end.difference(start).inSeconds;
  }
}
