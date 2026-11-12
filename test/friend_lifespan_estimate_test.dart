import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/people/friend_lifespan_estimate.dart';

import 'support/friend_estimate_fixtures.dart';

Friend _anna({FriendLifespanEstimate? estimate, int lifespan = 86}) => Friend(
  id: 'a',
  name: 'Anna',
  birthDate: DateTime(1995, 9, 1),
  customLifespan: lifespan,
  createdDate: DateTime(2026),
  lastUpdated: DateTime(2026),
  lifespanEstimate: estimate,
);

void main() {
  group('FriendLifespanEstimate', () {
    test('round-trips country, sex, answers, conditions and the result', () {
      final restored = FriendLifespanEstimate.fromJson(
        jsonDecode(jsonEncode(friendEstimate().toJson())),
      )!;
      expect(restored, friendEstimate());
      expect(restored.profile.effectiveCountry, 'DEU');
      expect(restored.profile.effectiveSex, Sex.female);
      expect(restored.profile.answers.conditions, {ChronicCondition.copd});
      expect(restored.appliedYears, 86);
    });

    test('leaves out the gains', () {
      final applied = friendEstimate().toJson()['applied'] as Map;
      expect(applied.containsKey('gains'), isFalse);
      expect(applied['appliedYears'], 86);
    });

    test('reads tolerantly', () {
      expect(FriendLifespanEstimate.fromJson(null), isNull);
      expect(FriendLifespanEstimate.fromJson('broken'), isNull);
      final partial = FriendLifespanEstimate.fromJson({
        'country': 'FRA',
        'applied': {'nonsense': true},
        'future': 1,
      })!;
      expect(partial.profile.country, 'FRA');
      expect(partial.appliedYears, isNull);
    });
  });

  group('Friend.lifespanEstimate', () {
    test('JSON round trip with an estimate', () {
      final friend = _anna(estimate: friendEstimate());
      final restored = Friend.fromJson(friend.toJson());
      expect(restored, friend);
      expect(restored.lifespanFromEstimate, isTrue);
    });

    test('is written only when set', () {
      final map = _anna().toMap();
      expect(map.containsKey(Friend.lifespanEstimateKey), isFalse);
      expect(Friend.fromMap(map).lifespanEstimate, isNull);
    });

    test('legacy JSON without the key and with unknown keys still reads', () {
      final map = _anna().toMap()
        ..remove(Friend.lifespanEstimateKey)
        ..['somethingNew'] = {'x': 1};
      final restored = Friend.fromMap(map);
      expect(restored.lifespanEstimate, isNull);
      expect(restored.customLifespan, 86);
      expect(restored.lifespanFromEstimate, isFalse);
    });

    test('lifespanFromEstimate is false once the number was moved', () {
      expect(
        _anna(estimate: friendEstimate(), lifespan: 90).lifespanFromEstimate,
        isFalse,
      );
    });

    test('copyWith keeps, replaces and clears the estimate', () {
      final friend = _anna(estimate: friendEstimate());
      expect(friend.copyWith(name: 'Ann').lifespanEstimate, friendEstimate());
      expect(
        friend.copyWith(clearLifespanEstimate: true).lifespanEstimate,
        isNull,
      );
      expect(
        friend
            .copyWith(lifespanEstimate: friendEstimate(years: 88))
            .lifespanEstimate!
            .appliedYears,
        88,
      );
      expect(friend.toString(), contains('lifespanEstimate'));
      expect(friend == _anna(), isFalse);
    });
  });

  group('backup', () {
    test('1.5 round trip keeps the estimate', () {
      final friend = _anna(estimate: friendEstimate());
      final backup = FriendsService.encodeBackup([friend]);
      expect(jsonDecode(backup)['version'], '1.5');
      final restored = FriendsService.decodeBackup(backup).single;
      expect(restored.lifespanEstimate, friendEstimate());
      expect(restored.lifespanFromEstimate, isTrue);
    });

    test('a 1.4 backup without estimates still imports', () {
      final entry = _anna(lifespan: 77).toMap()..remove('avatarPath');
      final backup = jsonEncode({
        'version': '1.4',
        'friends': [entry],
      });
      final restored = FriendsService.decodeBackup(backup).single;
      expect(restored.customLifespan, 77);
      expect(restored.lifespanEstimate, isNull);
    });
  });
}
