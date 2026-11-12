import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/people/group_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 8);

Friend _friend(String id, String? group) => Friend(
      id: id,
      name: 'Person $id',
      birthDate: DateTime(1990, 5, 1),
      groupName: group,
      createdDate: _now,
      lastUpdated: _now,
    );

String _stored(List<Friend> friends) =>
    json.encode([for (final f in friends) f.toMap()]);

Future<Map<String, String?>> _groups() async => {
      for (final f in await FriendsService.getAllFriends()) f.id: f.groupName,
    };

void main() {
  setUp(() => FriendsService.clearCacheForTesting());

  test('migrate maps exact labels of every language and keeps the rest', () {
    final migrated = GroupMigration.migrate([
      _friend('a', ' familie '),
      _friend('b', 'Amigos'),
      _friend('c', 'Familienfeier'),
      _friend('d', null),
      _friend('e', '@family'),
    ])!;
    expect(migrated.map((f) => f.groupName),
        ['@family', '@friends', 'Familienfeier', null, '@family']);
    expect(GroupMigration.migrate([_friend('x', 'Chor')]), isNull);
  });

  test('runs once on load, saves and bumps the revision', () async {
    SharedPreferences.setMockInitialValues({
      'friends_data': _stored([_friend('a', 'Familie'), _friend('b', 'Chor')]),
    });
    final before = FriendsService.revision.value;
    expect(await _groups(), {'a': '@family', 'b': 'Chor'});
    expect(FriendsService.revision.value, before + 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(GroupMigration.doneKey), isTrue);
    expect(prefs.getString('friends_data'), contains('@family'));

    // Typed later (e.g. by an older build): not migrated again.
    await prefs.setString(
        'friends_data', _stored([_friend('c', 'Freunde')]));
    await FriendsService.clearCacheForTesting();
    final again = FriendsService.revision.value;
    expect(await _groups(), {'c': 'Freunde'});
    expect(FriendsService.revision.value, again);
  });

  test('no revision bump when nothing changes', () async {
    SharedPreferences.setMockInitialValues({
      'friends_data': _stored([_friend('a', 'Chor')]),
    });
    final before = FriendsService.revision.value;
    expect(await _groups(), {'a': 'Chor'});
    expect(FriendsService.revision.value, before);
  });

  test('backup round-trip keeps ids; legacy labels import as ids', () async {
    SharedPreferences.setMockInitialValues({});
    final backup = FriendsService.encodeBackup(
        [_friend('a', '@family'), _friend('b', 'Freunde')],
        now: _now);
    expect(FriendsService.decodeBackup(backup).first.groupName, '@family');

    await FriendsService.importBackupEntries(
        FriendsService.decodeBackupEntries(backup));
    final imported = (await FriendsService.getAllFriends())
        .map((f) => f.groupName)
        .toList();
    expect(imported, ['@family', '@friends']);
  });
}
