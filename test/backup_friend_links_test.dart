import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Friend _friend(String id, String name) => Friend(
      id: id,
      name: name,
      birthDate: DateTime(1990, 5, 1),
      createdDate: DateTime(2026),
      lastUpdated: DateTime(2026),
    );

Intention _timeWith(String id, String? friendId) => Intention(
      id: id,
      title: 'Time with $id',
      friendId: friendId,
      createdAt: DateTime(2026, 2, 3),
    );

Future<void> _init({List<Friend> stored = const []}) async {
  SharedPreferences.setMockInitialValues({
    if (stored.isNotEmpty)
      'friends_data': jsonEncode([for (final f in stored) f.toMap()]),
  });
  await FriendsService.clearCacheForTesting();
  CompassService.clearCacheForTesting();
  await CompassService.initialize();
}

/// Imports [backup] the way the import screen does: friends, then Compass.
Future<FriendsImportResult> _import(String backup) async {
  final contents = FriendsService.decodeBackupContents(backup);
  final result = await FriendsService.importBackup(contents.entries);
  await CompassService.importDataCounts(contents.compass!,
      friendIds: result.friendIds);
  return result;
}

String? _linkOf(String intentionId) => CompassService.data.intentions
    .firstWhere((i) => i.id == intentionId)
    .friendId;

Future<Friend> _named(String name) async =>
    (await FriendsService.getAllFriends()).firstWhere((f) => f.name == name);

void main() {
  test('a new person keeps the link under their new id', () async {
    await _init();
    final backup = FriendsService.encodeBackup([_friend('old-peter', 'Peter')],
        compass: CompassData(intentions: [_timeWith('i', 'old-peter')]));

    final result = await _import(backup);

    final peter = await _named('Peter');
    expect(peter.id, isNot('old-peter'));
    expect(result.friendIds['old-peter'], peter.id);
    expect(_linkOf('i'), peter.id);
    expect(
        await CompassService.openIntentionForFriend(peter.id, title: 'other'),
        isNotNull);
  });

  test('a skipped duplicate links to the person already here', () async {
    await _init(stored: [_friend('here', 'Peter')]);
    final backup = FriendsService.encodeBackup(
        [_friend('old-peter', 'Peter'), _friend('old-peter-2', 'peter')],
        compass: CompassData(intentions: [
          _timeWith('i', 'old-peter'),
          _timeWith('j', 'old-peter-2'),
        ]));

    final result = await _import(backup);

    expect(result.added, 0);
    expect(result.skipped, 2);
    expect(_linkOf('i'), 'here');
    expect(_linkOf('j'), 'here', reason: 'repeat within the backup');
  });

  test('a repeat within the backup links to the friend just added', () async {
    await _init();
    final backup = FriendsService.encodeBackup(
        [_friend('a1', 'Anna'), _friend('a2', 'Anna')],
        compass: CompassData(intentions: [_timeWith('j', 'a2')]));

    await _import(backup);

    expect(_linkOf('j'), (await _named('Anna')).id);
  });

  test('a link to nobody known is dropped', () async {
    await _init();
    final backup = FriendsService.encodeBackup([_friend('a', 'Anna')],
        compass: CompassData(intentions: [_timeWith('i', 'gone')]));

    await _import(backup);

    expect(_linkOf('i'), isNull);
  });

  test('a backup from this device keeps links to people still here',
      () async {
    await _init(stored: [_friend('here', 'Peter')]);
    final backup = FriendsService.encodeBackup([],
        compass: CompassData(intentions: [_timeWith('i', 'here')]));

    await _import(backup);

    expect(_linkOf('i'), 'here');
  });

  test('re-importing adds nothing and keeps the link', () async {
    await _init();
    final backup = FriendsService.encodeBackup([_friend('old-peter', 'Peter')],
        compass: CompassData(intentions: [_timeWith('i', 'old-peter')]));

    await _import(backup);
    final again = await _import(backup);

    expect(again.added, 0);
    expect(CompassService.data.intentions, hasLength(1));
    expect(await FriendsService.getAllFriends(), hasLength(1));
    expect(_linkOf('i'), (await _named('Peter')).id);
  });

  test('without friendIds links are kept as they are (undo)', () async {
    await _init();
    await CompassService.importData(
        CompassData(intentions: [_timeWith('i', 'someone')]));

    expect(_linkOf('i'), 'someone');
  });

  test('withFriend can set and clear the link', () {
    final intention = _timeWith('i', 'a');
    expect(intention.withFriend('b').friendId, 'b');
    expect(intention.withFriend(null).friendId, isNull);
    expect(intention.withFriend(null).title, intention.title);
  });
}
