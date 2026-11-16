import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/applied_estimate.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result_store.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/lifespan_test_data.dart';

final DateTime _now = DateTime(2026, 11, 5);
final DateTime _birth = DateTime(1990, 6, 15);

LifespanEstimate _estimate({LifestyleAnswers? answers}) =>
    LifespanEstimator(lifespanTestData.tables).estimate(
      country: 'DE',
      sex: Sex.female,
      birthDate: _birth,
      now: _now,
      answers: answers,
    );

Future<void> _init([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  await SettingsService.initialize();
}

void main() {
  const store = SettingsLifespanResultStore();
  const answers = LifestyleAnswers(
    smoking: Smoking.quitBefore40,
    activity: Activity.guideline,
    conditions: {ChronicCondition.copd},
  );

  group('SettingsLifespanResultStore', () {
    setUp(_init);

    test('is empty before the first estimate', () {
      expect(store.load(), isNull);
    });

    test('keeps only the result of an applied profile', () async {
      final estimate = _estimate(answers: answers);
      await store.save(
        LifespanProfile.applied(estimate: estimate, answers: answers, years: 91),
      );
      expect(
        store.load(),
        LifespanResult(
          years: 91,
          mean: estimate.mean,
          p25: estimate.p25,
          p75: estimate.p75,
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {SettingsService.lifespanResultKey});
      final stored = jsonDecode(
        prefs.getString(SettingsService.lifespanResultKey)!,
      ) as Map<String, Object?>;
      expect(stored.keys, unorderedEquals(['years', 'mean', 'p25', 'p75']));
    });

    test('writes nothing without an applied estimate', () async {
      await store.save(const LifespanProfile(country: 'FR', sex: Sex.male));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('unreadable stored JSON reads as empty', () async {
      await _init({SettingsService.lifespanResultKey: '{oops'});
      expect(store.load(), isNull);
      await _init({SettingsService.lifespanResultKey: '{"years":"x"}'});
      expect(store.load(), isNull);
    });
  });

  group('LifespanResult', () {
    test('takes the applied years and the range of the estimate', () {
      final estimate = _estimate();
      final result = LifespanResult.of(
        AppliedLifespanEstimate(estimate: estimate, appliedYears: 85),
      );
      expect(result.years, 85);
      expect(result.mean, estimate.mean);
      expect(result.p25, estimate.p25);
      expect(result.p75, estimate.p75);
    });

    test('round-trips through JSON', () {
      const result = LifespanResult(years: 88, mean: 86.4, p25: 80, p75: 93.5);
      final decoded = LifespanResult.fromJson(
        jsonDecode(jsonEncode(result.toJson())) as Map<String, Object?>,
      );
      expect(decoded, result);
    });

    test('incomplete JSON is not a result', () {
      expect(LifespanResult.fromJson(const {'years': 80}), isNull);
      expect(
        LifespanResult.fromJson(const {
          'years': 80.5,
          'mean': 80,
          'p25': 75,
          'p75': 85,
        }),
        isNull,
      );
    });
  });
}
