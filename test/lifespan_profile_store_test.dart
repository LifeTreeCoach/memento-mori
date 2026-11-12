import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/applied_estimate.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_profile_store.dart';
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
  const store = SettingsLifespanProfileStore();
  const answers = LifestyleAnswers(
    smoking: Smoking.quitBefore40,
    activity: Activity.guideline,
    conditions: {ChronicCondition.copd},
  );

  group('SettingsLifespanProfileStore', () {
    setUp(_init);

    test('is empty before the first estimate', () {
      final profile = store.load();
      expect(profile.country, isNull);
      expect(profile.sex, isNull);
      expect(profile.answers.isEmpty, isTrue);
      expect(profile.applied, isNull);
    });

    test('round-trips a profile', () async {
      final estimate = _estimate(answers: answers);
      await store.save(
        LifespanProfile.applied(
          estimate: estimate,
          answers: answers,
          years: 91,
        ),
      );
      final loaded = store.load();
      expect(loaded.country, 'DE');
      expect(loaded.sex, Sex.female);
      expect(loaded.answers.smoking, Smoking.quitBefore40);
      expect(loaded.answers.conditions, {ChronicCondition.copd});
      expect(loaded.applied!.appliedYears, 91);
      expect(loaded.applied!.estimate.mean, estimate.mean);
    });

    test('writes nothing without an applied estimate', () async {
      await store.save(const LifespanProfile(country: 'FR', sex: Sex.male));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k.startsWith('lifespan_')), isEmpty);
    });

    test('keeps the legacy keys and their format', () async {
      final estimate = _estimate(answers: answers);
      await store.save(
        LifespanProfile.applied(
          estimate: estimate,
          answers: answers,
          years: 88,
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lifespan_country'), 'DE');
      expect(prefs.getString('lifespan_sex'), 'female');
      expect(
        jsonDecode(prefs.getString('lifespan_answers')!),
        jsonDecode(jsonEncode(answers.toJson())),
      );
      final stored = AppliedLifespanEstimate.fromJson(
        jsonDecode(prefs.getString('lifespan_estimate')!)
            as Map<String, Object?>,
      )!;
      expect(stored.appliedYears, 88);
    });

    test('reads data stored by earlier versions', () async {
      final estimate = _estimate(answers: answers);
      await _init({
        'lifespan_country': 'DE',
        'lifespan_sex': 'female',
        'lifespan_answers': jsonEncode(answers.toJson()),
        'lifespan_estimate': jsonEncode(
          AppliedLifespanEstimate(
            estimate: estimate,
            appliedYears: 87,
          ).toJson(),
        ),
      });
      final loaded = store.load();
      expect(loaded.country, 'DE');
      expect(loaded.sex, Sex.female);
      expect(loaded.answers.activity, Activity.guideline);
      expect(loaded.answers.conditions, {ChronicCondition.copd});
      expect(loaded.applied!.appliedYears, 87);
    });

    test('unreadable stored JSON reads as empty', () async {
      await _init({'lifespan_answers': '{oops', 'lifespan_estimate': '[]'});
      final loaded = store.load();
      expect(loaded.answers.isEmpty, isTrue);
      expect(loaded.applied, isNull);
    });
  });

  group('LifespanProfile JSON', () {
    test('round-trips every field', () {
      final estimate = _estimate(answers: answers);
      final profile = LifespanProfile.applied(
        estimate: estimate,
        answers: answers,
        years: 90,
      );
      final decoded = LifespanProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, Object?>,
      );
      expect(decoded.country, 'DE');
      expect(decoded.sex, Sex.female);
      expect(decoded.answers.smoking, Smoking.quitBefore40);
      expect(decoded.answers.conditions, {ChronicCondition.copd});
      expect(decoded.applied!.appliedYears, 90);
      expect(decoded.applied!.estimate.p75, estimate.p75);
      expect(decoded.applied!.estimate.gains, estimate.gains);
    });

    test('an empty profile is an empty object', () {
      expect(const LifespanProfile().toJson(), isEmpty);
      final decoded = LifespanProfile.fromJson(const {});
      expect(decoded.country, isNull);
      expect(decoded.answers.isEmpty, isTrue);
      expect(decoded.applied, isNull);
    });

    test('ignores broken or unknown fields', () {
      final decoded = LifespanProfile.fromJson(const {
        'country': 42,
        'sex': 'robot',
        'answers': 'nope',
        'applied': {'appliedYears': 'x'},
        'future': true,
      });
      expect(decoded.country, isNull);
      expect(decoded.sex, isNull);
      expect(decoded.answers.isEmpty, isTrue);
      expect(decoded.applied, isNull);
    });

    test('falls back to the estimate for country and sex', () {
      final profile = LifespanProfile(
        applied: AppliedLifespanEstimate(
          estimate: _estimate(),
          appliedYears: 85,
        ),
      );
      expect(profile.effectiveCountry, 'DE');
      expect(profile.effectiveSex, Sex.female);
    });
  });
}
