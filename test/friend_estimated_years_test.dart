import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Friend _anna({int? estimatedYears, int lifespan = 86}) => Friend(
  id: 'a',
  name: 'Anna',
  birthDate: DateTime(1995, 9, 1),
  customLifespan: lifespan,
  createdDate: DateTime(2026),
  lastUpdated: DateTime(2026),
  estimatedYears: estimatedYears,
);

void main() {
  group('Friend.estimatedYears', () {
    test('JSON round trip with an estimate', () {
      final friend = _anna(estimatedYears: 86);
      final map = friend.toMap();
      expect(map[Friend.estimatedYearsKey], 86);
      final restored = Friend.fromJson(friend.toJson());
      expect(restored, friend);
      expect(restored.lifespanFromEstimate, isTrue);
    });

    test('is written only when set', () {
      final map = _anna().toMap();
      expect(map.containsKey(Friend.estimatedYearsKey), isFalse);
      expect(Friend.fromMap(map).estimatedYears, isNull);
    });

    test('the former lifespanEstimate key and unknown keys are ignored', () {
      final map = _anna().toMap()
        ..['lifespanEstimate'] = {'country': 'DEU', 'answers': {}}
        ..['somethingNew'] = {'x': 1};
      final restored = Friend.fromMap(map);
      expect(restored.estimatedYears, isNull);
      expect(restored.customLifespan, 86);
      expect(restored.lifespanFromEstimate, isFalse);
      expect(restored.toMap().containsKey('lifespanEstimate'), isFalse);
    });

    test('a value that is not a number reads as none', () {
      final map = _anna().toMap()..[Friend.estimatedYearsKey] = 'x';
      expect(Friend.fromMap(map).estimatedYears, isNull);
    });

    test('lifespanFromEstimate is false once the number was moved', () {
      expect(
        _anna(estimatedYears: 86, lifespan: 90).lifespanFromEstimate,
        isFalse,
      );
    });

    test('copyWith keeps, replaces and clears the estimated years', () {
      final friend = _anna(estimatedYears: 86);
      expect(friend.copyWith(name: 'Ann').estimatedYears, 86);
      expect(friend.copyWith(clearEstimatedYears: true).estimatedYears, isNull);
      expect(friend.copyWith(estimatedYears: 88).estimatedYears, 88);
      expect(friend.toString(), contains('estimatedYears: 86'));
      expect(friend == _anna(), isFalse);
    });
  });

  group('backup', () {
    test('round trip keeps the estimated years', () {
      final friend = _anna(estimatedYears: 86);
      final backup = FriendsService.encodeBackup([friend]);
      final restored = FriendsService.decodeBackup(backup).single;
      expect(restored.estimatedYears, 86);
      expect(restored.lifespanFromEstimate, isTrue);
    });

    test('export has estimatedYears and no estimate answers', () {
      final backup = FriendsService.encodeBackup([_anna(estimatedYears: 86)]);
      final entry = (jsonDecode(backup)['friends'] as List).single as Map;
      expect(entry[Friend.estimatedYearsKey], 86);
      expect(entry.containsKey('lifespanEstimate'), isFalse);
      expect(backup, isNot(contains('answers')));
    });

    test('decode rejects a backup from a newer major version', () {
      final backup = jsonEncode({
        'version': '3.0',
        'friends': [_anna().toMap()..remove('avatarPath')],
      });
      expect(
        () => FriendsService.decodeBackup(backup),
        throwsA(isA<FriendsBackupException>().having((e) => e.messageKey,
            'messageKey', 'import_export_error_invalid_format')),
      );
    });

    test('a 1.4 backup without estimates still imports', () {
      final entry = _anna(lifespan: 77).toMap()..remove('avatarPath');
      final backup = jsonEncode({
        'version': '1.4',
        'friends': [entry],
      });
      final restored = FriendsService.decodeBackup(backup).single;
      expect(restored.customLifespan, 77);
      expect(restored.estimatedYears, isNull);
    });
  });

  group('importBackupEntries', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await FriendsService.clearCacheForTesting();
    });

    Future<String> storedFriends() async =>
        (await SharedPreferences.getInstance()).getString('friends_data')!;

    test('keeps the estimated years', () async {
      final backup = FriendsService.encodeBackup([_anna(estimatedYears: 86)]);
      await FriendsService.importBackupEntries(
          FriendsService.decodeBackupEntries(backup));
      await FriendsService.lastAvatarCleanup;
      final imported = (await FriendsService.getAllFriends()).single;
      expect(imported.estimatedYears, 86);
      expect(imported.lifespanFromEstimate, isTrue);
    });

    test('a 1.5 lifespanEstimate with health answers is never stored',
        () async {
      final entry = _anna(lifespan: 79).toMap()
        ..remove('avatarPath')
        ..['lifespanEstimate'] = {
          'country': 'DEU',
          'answers': {
            'conditions': ['copd'],
          },
          'appliedYears': 79,
        };
      final backup = jsonEncode({
        'version': '1.5',
        'friends': [entry],
      });
      await FriendsService.importBackupEntries(
          FriendsService.decodeBackupEntries(backup));
      await FriendsService.lastAvatarCleanup;

      final stored = await storedFriends();
      expect(stored, contains('Anna'));
      for (final leaked in ['copd', 'conditions', 'lifespanEstimate']) {
        expect(stored, isNot(contains(leaked)));
      }
      final imported = (await FriendsService.getAllFriends()).single;
      expect(imported.customLifespan, 79);
      expect(imported.estimatedYears, isNull);
    });
  });
}
