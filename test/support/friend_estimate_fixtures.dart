import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/people/friend_lifespan_estimate.dart';

/// An applied profile for a person (Germany, female, two answers incl. a
/// health condition) whose result is [years].
LifespanProfile appliedFriendProfile({int years = 86}) =>
    LifespanProfile.applied(
      estimate: LifespanEstimate(
        country: 'DEU',
        sex: Sex.female,
        age: 31.2,
        mean: 85.4,
        p25: 79.0,
        median: 86.0,
        p75: 92.0,
        reach80: 0.72,
        reach90: 0.35,
        multiplier: 0.8,
        recommendedYears: 86,
        gains: const {LifestyleFactor.activity: 1.5},
        conditionMultiplier: 1.2,
      ),
      answers: const LifestyleAnswers(
        smoking: Smoking.never,
        conditions: {ChronicCondition.copd},
      ),
      years: years,
    );

FriendLifespanEstimate friendEstimate({int years = 86}) =>
    FriendLifespanEstimate(appliedFriendProfile(years: years));
