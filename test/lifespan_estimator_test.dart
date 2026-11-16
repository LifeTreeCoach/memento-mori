import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/cohort_engine.dart';
import 'package:memento_mori_life_in_weeks/lifespan/life_table_set.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';

const healthy = LifestyleAnswers(
  smoking: Smoking.never,
  activity: Activity.guideline,
  bmi: BmiBand.healthy,
  social: SocialConnection.wellConnected,
);
const risky = LifestyleAnswers(
  smoking: Smoking.currentHeavy,
  activity: Activity.inactive,
  bmi: BmiBand.over35,
);

void main() {
  final tables = LifeTableSet.parse(
    ByteData.sublistView(
      File('assets/lifespan/wpp2024_lt.bin').readAsBytesSync(),
    ),
  );
  final estimator = LifespanEstimator(tables);
  final now = DateTime(2026, 11, 5);
  final birth36 = DateTime(1990, 6, 15);

  LifespanEstimate run(
    Sex sex, {
    LifestyleAnswers? answers,
    String? country = 'DE',
  }) => estimator.estimate(
    country: country,
    sex: sex,
    birthDate: birth36,
    now: now,
    answers: answers,
  );

  test('age and calendar time', () {
    expect(
      LifespanEstimator.exactAge(DateTime(2000, 1, 1), DateTime(2001, 1, 1)),
      closeTo(366 / 365.2425, 1e-12),
    );
    expect(LifespanEstimator.exactAge(DateTime(2030), now), 0.0);
    expect(LifespanEstimator.fractionalYear(DateTime(2026)), 2026.0);
    expect(
      LifespanEstimator.fractionalYear(DateTime(2026, 7, 2, 12)),
      closeTo(2026.5, 1e-9),
    );
  });

  test('matches the cohort engine directly (female, no answers)', () {
    final e = run(Sex.female);
    final direct = CohortEngine.run(
      tables.table('DE', Sex.female),
      age: LifespanEstimator.exactAge(birth36, now),
      year: LifespanEstimator.fractionalYear(now),
    );
    expect(e.mean, closeTo(direct.mean, 1e-12));
    expect(e.median, closeTo(direct.median, 1e-12));
  });

  test('skipped answers are identical to the population estimate', () {
    for (final sex in Sex.values) {
      final none = run(sex);
      final skipped = run(sex, answers: const LifestyleAnswers());
      expect(skipped.mean, none.mean);
      expect(skipped.p25, none.p25);
      expect(skipped.p75, none.p75);
      expect(skipped.multiplier, 1.0);
      expect(skipped.conditionMultiplier, 1.0);
      expect(skipped.gains, isEmpty);
    }
  });

  test('unspecified is the female/male mixture, strictly between them', () {
    final f = run(Sex.female), m = run(Sex.male), u = run(Sex.unspecified);
    expect(u.mean, closeTo((f.mean + m.mean) / 2, 1e-12));
    expect(u.mean, greaterThan(m.mean));
    expect(u.mean, lessThan(f.mean));
    expect(u.median, inExclusiveRange(m.median, f.median));
    expect(u.reach80!, inExclusiveRange(m.reach80!, f.reach80!));
  });

  test('lifestyle moves the estimate in the right direction', () {
    for (final sex in Sex.values) {
      final base = run(sex).mean;
      expect(run(sex, answers: healthy).mean, greaterThan(base));
      expect(run(sex, answers: risky).mean, lessThan(base));
    }
  });

  test('answers are ignored for children', () {
    final child = estimator.estimate(
      country: 'DE',
      sex: Sex.male,
      birthDate: DateTime(2016, 1, 1),
      now: now,
      answers: risky,
    );
    expect(child.multiplier, 1.0);
    expect(child.gains, isEmpty);
  });

  test('unknown country falls back to WLD', () {
    expect(run(Sex.male, country: 'ZZ').country, 'WLD');
    expect(
      run(Sex.male, country: null).mean,
      run(Sex.male, country: 'WLD').mean,
    );
  });

  test(
    'gains: only answered, non-best factors with gains >= 0.5 y, largest first',
    () {
      // Unclamped: M = 1.54 * 1.38 = 2.13, both factors have a gain.
      final e = run(
        Sex.male,
        answers: const LifestyleAnswers(
          smoking: Smoking.currentLight,
          activity: Activity.inactive,
          alcohol: Alcohol.upTo7,
        ),
      );
      expect(
        e.gains.keys,
        containsAll([LifestyleFactor.smoking, LifestyleFactor.activity]),
      );
      expect(
        e.gains.keys,
        isNot(contains(LifestyleFactor.alcohol)),
      ); // already best
      expect(
        e.gains.keys,
        isNot(contains(LifestyleFactor.bmi)),
      ); // not answered
      // Clamped at 2.5: improving BMI alone (M 4.75 -> 2.43) barely moves the mean.
      expect(run(Sex.male, answers: risky).gains.keys, [
        LifestyleFactor.smoking,
      ]);
      expect(e.gains.values.every((g) => g >= 0.5), isTrue);
      final values = e.gains.values.toList();
      for (var i = 1; i < values.length; i++) {
        expect(values[i], lessThanOrEqualTo(values[i - 1]));
      }
      // Already at the 0.6 floor: nothing left to gain.
      expect(run(Sex.male, answers: healthy).gains, isEmpty);
    },
  );

  test('recommendedYears = round(mean) clamped to 50..110', () {
    expect(LifespanEstimator.recommendedYearsFor(84.4), 84);
    expect(LifespanEstimator.recommendedYearsFor(84.5), 85);
    expect(LifespanEstimator.recommendedYearsFor(42.0), 50);
    expect(LifespanEstimator.recommendedYearsFor(113.2), 110);
    final old = estimator.estimate(
      country: 'JP',
      sex: Sex.female,
      birthDate: DateTime(1913, 1, 1),
      now: now,
    );
    expect(old.mean, greaterThan(110.5));
    expect(old.recommendedYears, 110);
    expect(run(Sex.female).recommendedYears, run(Sex.female).mean.round());
  });

  test('sample outputs (DE, age 36)', () {
    String fmt(LifespanEstimate e) =>
        'mean ${e.mean.toStringAsFixed(2)} p25 ${e.p25.toStringAsFixed(1)} '
        'median ${e.median.toStringAsFixed(1)} p75 ${e.p75.toStringAsFixed(1)} '
        'reach80 ${e.reach80!.toStringAsFixed(3)} reach90 ${e.reach90!.toStringAsFixed(3)} '
        'M ${e.multiplier.toStringAsFixed(3)} rec ${e.recommendedYears} '
        'gains ${e.gains.map((k, v) => MapEntry(k.name, v.toStringAsFixed(2)))}';
    for (final (label, answers) in [
      ('none', null),
      ('healthy', healthy),
      ('risky', risky),
    ]) {
      for (final sex in Sex.values) {
        // ignore: avoid_print
        print('SAMPLE $label ${sex.name}: ${fmt(run(sex, answers: answers))}');
      }
    }
  });
}
