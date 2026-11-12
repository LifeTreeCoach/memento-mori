import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/cohort_engine.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/hazard_profile.dart';
import 'package:memento_mori_life_in_weeks/lifespan/life_table_set.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';

const _t2 = ChronicCondition.type2Diabetes;
const _t1 = ChronicCondition.type1Diabetes;
const _mi = ChronicCondition.heartAttack;
const _stroke = ChronicCondition.stroke;

// Same mapping as test/lifespan_engine_test.dart ('both' = raw WPP table).
Sex _fixtureSex(String name) => switch (name) {
  'female' => Sex.female,
  'male' => Sex.male,
  _ => Sex.unspecified,
};

void main() {
  group('hazard ratios', () {
    test('each condition has its published HR', () {
      expect(
        {for (final c in ChronicCondition.values) c: c.hazardRatio},
        {
          _t2: 1.9,
          _t1: 3.5,
          _mi: 2.0,
          _stroke: 2.1,
          ChronicCondition.heartFailure: 2.5,
          ChronicCondition.copd: 1.8,
          ChronicCondition.kidney: 1.6,
        },
      );
    });

    test('BMI overlap: diabetes and cardiovascular, not COPD or kidney', () {
      expect(ChronicCondition.values.where((c) => c.overlapsBmi).toSet(), {
        _t2,
        _t1,
        _mi,
        _stroke,
        ChronicCondition.heartFailure,
      });
    });
  });

  group('prevalence', () {
    const p = ConditionPrevalence(0.02, 0.10, 0.30);

    test('linear between 40/60/80, clamped outside', () {
      expect(p.at(18), 0.02);
      expect(p.at(40), 0.02);
      expect(p.at(50), closeTo(0.06, 1e-12));
      expect(p.at(60), closeTo(0.10, 1e-12));
      expect(p.at(70), closeTo(0.20, 1e-12));
      expect(p.at(80), 0.30);
      expect(p.at(100), 0.30);
    });

    test('all prevalences are plausible fractions', () {
      for (final c in ChronicCondition.values) {
        for (final age in [40.0, 60.0, 80.0]) {
          expect(c.prevalence.at(age), inExclusiveRange(0, 0.3));
        }
      }
    });
  });

  group('combinedConditionHazardRatio', () {
    test('none = 1, one condition = its HR', () {
      expect(combinedConditionHazardRatio({}), 1.0);
      for (final c in ChronicCondition.values) {
        expect(combinedConditionHazardRatio({c}), c.hazardRatio);
      }
    });

    test('strongest counts fully, the others as HR^0.85', () {
      expect(
        combinedConditionHazardRatio({_t2, _mi}),
        closeTo(2.0 * math.pow(1.9, 0.85), 1e-12),
      );
    });

    test('ERFC 2015 combinations within 10 % before the cap', () {
      double uncapped(List<double> ratios) {
        ratios.sort((a, b) => b.compareTo(a));
        return ratios
            .skip(1)
            .fold(
              ratios.first,
              (p, r) => p * math.pow(r, furtherConditionExponent),
            );
      }

      // Observed: diabetes + MI 3.71, diabetes + MI + stroke 6.92.
      expect(uncapped([1.9, 2.0]), closeTo(3.71, 0.371));
      expect(uncapped([1.9, 2.0, 2.1]), closeTo(6.92, 0.692));
    });

    test('capped at 4.0', () {
      expect(combinedConditionHazardRatio({_t2, _mi, _stroke}), 4.0);
      expect(
        combinedConditionHazardRatio(ChronicCondition.values.toSet()),
        maxCombinedConditionHazardRatio,
      );
    });
  });

  group('noConditionFactor', () {
    test('within 0.75..1 and non-increasing with age', () {
      var previous = 1.0;
      for (var age = 18.0; age <= 110; age += 1) {
        final n = noConditionFactor(age);
        expect(n, inInclusiveRange(0.75, 1.0));
        expect(n, lessThanOrEqualTo(previous));
        previous = n;
      }
      expect(noConditionFactor(60), lessThan(noConditionFactor(40)));
    });

    test('n = 1 / (1 + sum p * (HR - 1)) at 40', () {
      final excess = ChronicCondition.values.fold(
        0.0,
        (sum, c) => sum + c.prevalence.at40 * (c.hazardRatio - 1),
      );
      expect(noConditionFactor(40), closeTo(1 / (1 + excess), 1e-12));
    });
  });

  group('conditionMultiplier', () {
    test('skipped = 1, empty = n(age), with conditions = HR * n(age)', () {
      expect(conditionMultiplier(null, 40), 1.0);
      expect(conditionMultiplier({}, 40), noConditionFactor(40));
      expect(conditionMultiplier({_t1}, 40), 3.5 * noConditionFactor(40));
    });

    test('no effect under 18', () {
      expect(conditionMultiplier({_t1, _mi}, 17.9), 1.0);
      expect(conditionMultiplier({}, 10), 1.0);
      expect(conditionMultiplier({_t1}, 18), greaterThan(1.0));
    });

    test('conditionsOverlapBmi', () {
      expect(conditionsOverlapBmi(null), isFalse);
      expect(conditionsOverlapBmi({}), isFalse);
      expect(conditionsOverlapBmi({ChronicCondition.copd}), isFalse);
      expect(conditionsOverlapBmi({ChronicCondition.copd, _stroke}), isTrue);
    });
  });

  group('age attenuation', () {
    test('wd(x): 1 up to 60, 0.4 from 90', () {
      expect(diseaseAgeAttenuation(30), 1.0);
      expect(diseaseAgeAttenuation(60), 1.0);
      expect(diseaseAgeAttenuation(75), closeTo(0.7, 1e-12));
      expect(diseaseAgeAttenuation(90), closeTo(0.4, 1e-12));
      expect(diseaseAgeAttenuation(105), 0.4);
    });

    test('Md^wd(x)', () {
      expect(attenuatedConditionMultiplier(3.0, 50), 3.0);
      expect(
        attenuatedConditionMultiplier(3.0, 90),
        closeTo(math.pow(3.0, 0.4), 1e-12),
      );
    });

    test('both curves differ: lifestyle fades later than disease', () {
      expect(ageAttenuation(70), 1.0);
      expect(diseaseAgeAttenuation(70), closeTo(0.8, 1e-12));
    });
  });

  group('combinedHazardMultiplier', () {
    test('Md = 1 is exactly the lifestyle H(x)', () {
      for (final m in [0.6, 1.0, 1.7, 2.5]) {
        for (var age = 0; age <= 110; age++) {
          expect(
            combinedHazardMultiplier(
              lifestyle: m,
              condition: 1.0,
              age: age.toDouble(),
            ),
            attenuatedMultiplier(m, age.toDouble()),
          );
        }
      }
    });

    test('product of both, capped at 6.0', () {
      expect(
        combinedHazardMultiplier(lifestyle: 1.5, condition: 2.0, age: 50),
        3.0,
      );
      expect(
        combinedHazardMultiplier(lifestyle: 2.5, condition: 4.0, age: 50),
        maxTotalHazardMultiplier,
      );
      expect(
        combinedHazardMultiplier(lifestyle: 2.0, condition: 2.0, age: 90),
        closeTo(math.pow(2.0, 0.52) * math.pow(2.0, 0.4), 1e-12),
      );
    });
  });

  group('LifestyleAnswers with conditions', () {
    test('BMI counts as m^0.5 with diabetes or cardiovascular disease', () {
      const bmi = LifestyleAnswers(bmi: BmiBand.over35);
      expect(bmi.multiplier(age: 40), 1.64);
      expect(
        bmi.withConditions({_t2}).multiplier(age: 40),
        closeTo(math.sqrt(1.64), 1e-12),
      );
      expect(
        bmi.withConditions({ChronicCondition.kidney}).multiplier(age: 40),
        1.64,
      );
      expect(bmi.withConditions({}).multiplier(age: 40), 1.64);
    });

    test('isEmpty, == and hashCode include conditions', () {
      expect(const LifestyleAnswers(conditions: {}).isEmpty, isFalse);
      expect(
        const LifestyleAnswers(conditions: {_t2, _mi}),
        const LifestyleAnswers(conditions: {_mi, _t2}),
      );
      expect(
        const LifestyleAnswers(conditions: {_t2, _mi}).hashCode,
        const LifestyleAnswers(conditions: {_mi, _t2}).hashCode,
      );
      expect(
        const LifestyleAnswers(conditions: {}),
        isNot(const LifestyleAnswers()),
      );
      expect(
        const LifestyleAnswers(conditions: {_t2}),
        isNot(const LifestyleAnswers(conditions: {_t1})),
      );
    });

    test('withAnswer keeps the conditions', () {
      const answers = LifestyleAnswers(conditions: {_stroke});
      expect(
        answers.withAnswer(LifestyleFactor.smoking, Smoking.never).conditions,
        {_stroke},
      );
    });

    test('JSON round trip; empty stays "none", null stays skipped', () {
      for (final answers in const [
        LifestyleAnswers(smoking: Smoking.never, conditions: {_mi, _t2}),
        LifestyleAnswers(conditions: {}),
        LifestyleAnswers(activity: Activity.some),
      ]) {
        final json = jsonDecode(jsonEncode(answers.toJson()));
        expect(
          LifestyleAnswers.fromJson(json as Map<String, Object?>),
          answers,
        );
      }
      expect(
        const LifestyleAnswers(conditions: {_mi, _t2}).toJson()['conditions'],
        ['type2Diabetes', 'heartAttack'],
      );
      expect(
        const LifestyleAnswers().toJson().containsKey('conditions'),
        isFalse,
      );
    });

    test('unknown condition names are ignored', () {
      final answers = LifestyleAnswers.fromJson({
        'v': 1,
        'conditions': ['copd', 'gout', 7],
      });
      expect(answers.conditions, {ChronicCondition.copd});
      expect(
        LifestyleAnswers.fromJson({'conditions': 'copd'}).conditions,
        isNull,
      );
    });
  });

  group('estimator', () {
    final tables = LifeTableSet.parse(
      ByteData.sublistView(
        File('assets/lifespan/wpp2024_lt.bin').readAsBytesSync(),
      ),
    );
    final estimator = LifespanEstimator(tables);
    final now = DateTime(2026, 11, 5);

    LifespanEstimate run(int age, Set<ChronicCondition>? conditions) =>
        estimator.estimate(
          country: 'DE',
          sex: Sex.female,
          birthDate: DateTime(now.year - age, 6, 1),
          now: now,
          answers: LifestyleAnswers(conditions: conditions),
        );

    test('skipped conditions reproduce the engine fixtures exactly', () {
      final fixtures = jsonDecode(
        File('test/fixtures/lifespan_cases.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final raw in fixtures['cases'] as List) {
        final input = raw['input'] as Map<String, dynamic>;
        final expected = raw['expected'] as Map<String, dynamic>;
        final age = (input['age'] as num).toDouble();
        final h = (input['hazardMultiplier'] as num).toDouble();
        final md = conditionMultiplier(null, age);
        final table = tables.table(
          input['code'] as String,
          _fixtureSex(input['sex'] as String),
        );
        CohortResult engine(HazardMultiplier hazard) => CohortEngine.run(
          table,
          age: age,
          year: (input['year'] as num).toDouble(),
          hazardMultiplier: hazard,
        );
        final withConditions = engine(
          (x) => math.min(
            h * attenuatedConditionMultiplier(md, x.toDouble()),
            maxTotalHazardMultiplier,
          ),
        );
        final plain = engine((_) => h);
        expect(withConditions.mean, plain.mean);
        expect(withConditions.median, plain.median);
        expect(
          withConditions.mean,
          closeTo((expected['mean'] as num).toDouble(), 1e-6),
        );
      }
    });

    test('skipped conditions leave the estimate unchanged', () {
      final skipped = run(40, null),
          plain = estimator.estimate(
            country: 'DE',
            sex: Sex.female,
            birthDate: DateTime(now.year - 40, 6, 1),
            now: now,
          );
      expect(skipped.mean, plain.mean);
      expect(skipped.conditionMultiplier, 1.0);
    });

    test('"none" raises, every condition lowers the mean', () {
      final skipped = run(40, null).mean, none = run(40, {}).mean;
      expect(none, greaterThan(skipped));
      for (final c in ChronicCondition.values) {
        expect(run(40, {c}).mean, lessThan(skipped));
      }
    });

    // HR 3.5 (Lind et al., NEJM 2014) with the 2026 cohort table and the
    // disease fade-out wd(x) gives 7.37 years (male: 9.80). Livingstone et al.
    // (JAMA 2015) report ~11-13 years for an older-care cohort; the model
    // deliberately errs on the conservative side.
    test('type 1 diabetes at 20 (DE female) costs ~7.4 years vs none', () {
      final lost = run(20, {}).mean - run(20, {_t1}).mean;
      expect(lost, closeTo(7.37, 1.5));
    });

    test('conditions are ignored under 18 and never appear in gains', () {
      expect(run(10, {_t1}).mean, run(10, null).mean);
      final e = estimator.estimate(
        country: 'DE',
        sex: Sex.male,
        birthDate: DateTime(1980),
        now: now,
        answers: const LifestyleAnswers(
          smoking: Smoking.currentHeavy,
          conditions: {_t2, _mi},
        ),
      );
      expect(e.gains.keys, [LifestyleFactor.smoking]);
    });

    test('estimate exposes Md and keeps it through JSON', () {
      final e = run(40, {_mi});
      expect(
        e.conditionMultiplier,
        closeTo(2.0 * noConditionFactor(e.age), 1e-12),
      );
      final copy = LifespanEstimate.fromJson(e.toJson())!;
      expect(copy.conditionMultiplier, e.conditionMultiplier);
      final legacy = e.toJson()..remove('conditionMultiplier');
      expect(LifespanEstimate.fromJson(legacy)!.conditionMultiplier, 1.0);
    });
  });
}
