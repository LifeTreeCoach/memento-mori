import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';

void main() {
  group('normalisation', () {
    for (final factor in LifestyleFactor.values) {
      test('${factor.name}: shares sum to 1 and sum(p * m) ~ 1', () {
        final categories = factor.options.map((o) => o.category);
        final shares = categories.fold(0.0, (sum, c) => sum + c.prevalence);
        final weighted = categories.fold(
          0.0,
          (sum, c) => sum + c.prevalence * c.multiplier,
        );
        expect(shares, closeTo(1.0, 1e-9));
        expect(weighted, closeTo(1.0, 0.01));
      });

      test('${factor.name}: m ~ HR / sum(p * HR)', () {
        final categories = factor.options.map((o) => o.category).toList();
        final average = categories.fold(
          0.0,
          (sum, c) => sum + c.prevalence * c.hazardRatio,
        );
        for (final c in categories) {
          expect(c.multiplier, closeTo(c.hazardRatio / average, 0.01));
        }
      });
    }

    test('best category is the lowest multiplier', () {
      expect(LifestyleFactor.smoking.best, Smoking.never);
      expect(LifestyleFactor.activity.best, Activity.high);
      expect(LifestyleFactor.alcohol.best, Alcohol.upTo7);
      expect(LifestyleFactor.bmi.best, BmiBand.healthy);
      expect(LifestyleFactor.social.best, SocialConnection.wellConnected);
    });
  });

  group('combined multiplier', () {
    test('skipped answers give 1.0', () {
      expect(const LifestyleAnswers().multiplier(age: 40), 1.0);
      expect(const LifestyleAnswers().isEmpty, isTrue);
    });

    test('product of answered factors', () {
      const answers = LifestyleAnswers(
        smoking: Smoking.never,
        activity: Activity.guideline,
      );
      expect(answers.multiplier(age: 40), closeTo(0.70 * 0.95, 1e-12));
    });

    test('clamped to [0.6, 2.5]', () {
      const best = LifestyleAnswers(
        smoking: Smoking.never,
        activity: Activity.high,
        alcohol: Alcohol.upTo7,
        bmi: BmiBand.healthy,
        social: SocialConnection.wellConnected,
      );
      const worst = LifestyleAnswers(
        smoking: Smoking.currentHeavy,
        activity: Activity.inactive,
        alcohol: Alcohol.over28,
        bmi: BmiBand.over40,
        social: SocialConnection.oftenLonely,
      );
      expect(best.multiplier(age: 40), 0.6);
      expect(worst.multiplier(age: 40), 2.5);
    });

    test('ignored under 18', () {
      const answers = LifestyleAnswers(smoking: Smoking.currentHeavy);
      expect(answers.multiplier(age: 17.9), 1.0);
      expect(answers.multiplier(age: 18), 2.10);
    });
  });

  group('age attenuation', () {
    test('w(x)', () {
      expect(ageAttenuation(0), 1.0);
      expect(ageAttenuation(70), 1.0);
      expect(ageAttenuation(82.5), closeTo(0.7, 1e-12));
      expect(ageAttenuation(95), closeTo(0.4, 1e-12));
      expect(ageAttenuation(110), 0.4);
    });

    test('H(x) = M^w(x)', () {
      expect(attenuatedMultiplier(2.0, 50), 2.0);
      expect(attenuatedMultiplier(2.0, 100), closeTo(1.3195079, 1e-6));
    });
  });

  group('bmiBandFor', () {
    double weightFor(double bmi) => bmi * 1.8 * 1.8;

    test('band boundaries (lower bound inclusive)', () {
      expect(bmiBandFor(180, weightFor(18.49)), BmiBand.under18_5);
      expect(bmiBandFor(180, weightFor(18.5)), BmiBand.healthy);
      expect(bmiBandFor(180, weightFor(24.99)), BmiBand.healthy);
      expect(bmiBandFor(180, weightFor(25)), BmiBand.over25);
      expect(bmiBandFor(180, weightFor(30)), BmiBand.over30);
      expect(bmiBandFor(180, weightFor(35)), BmiBand.over35);
      expect(bmiBandFor(180, weightFor(39.99)), BmiBand.over35);
      expect(bmiBandFor(180, weightFor(40)), BmiBand.over40);
    });

    test('missing or implausible input gives null', () {
      expect(bmiBandFor(null, 70), isNull);
      expect(bmiBandFor(180, null), isNull);
      expect(bmiBandFor(0, 70), isNull);
      expect(bmiBandFor(180, 0), isNull);
    });
  });

  group('LifestyleAnswers JSON', () {
    test('round trip', () {
      const answers = LifestyleAnswers(
        smoking: Smoking.quitBefore40,
        activity: Activity.some,
        bmi: BmiBand.over30,
        social: SocialConnection.sometimes,
      );
      final json = answers.toJson();
      expect(json['v'], LifestyleAnswers.jsonVersion);
      expect(json.containsKey('alcohol'), isFalse);
      expect(LifestyleAnswers.fromJson(json), answers);
    });

    test('unknown values become null; no raw height or weight stored', () {
      final answers = LifestyleAnswers.fromJson({
        'v': 1,
        'smoking': 'pipe',
        'activity': 42,
        'alcohol': 'over28',
      });
      expect(answers.smoking, isNull);
      expect(answers.activity, isNull);
      expect(answers.alcohol, Alcohol.over28);
      final keys = const LifestyleAnswers(bmi: BmiBand.healthy).toJson().keys;
      expect(keys, isNot(contains('height')));
      expect(keys, isNot(contains('weight')));
    });
  });
}
