import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Friend _friend(String id, {String name = 'Anna', DateTime? birthDate}) {
  final now = DateTime(2026, 1, 1);
  return Friend(
    id: id,
    name: name,
    birthDate: birthDate ?? DateTime(1990, 5, 1),
    createdDate: now,
    lastUpdated: now,
  );
}

Future<List<dynamic>> _storedFriends() async {
  final prefs = await SharedPreferences.getInstance();
  return json.decode(prefs.getString('friends_data') ?? '[]') as List<dynamic>;
}

void main() {
  late int changes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FriendsService.clearCacheForTesting();
    changes = 0;
    FriendsService.onFriendsChanged = () async => changes++;
  });

  tearDown(() => FriendsService.onFriendsChanged = null);

  test('addFriends stores all friends, assigns ids and notifies once', () async {
    await FriendsService.addFriends([_friend('a'), _friend('b', name: 'Ben')]);

    final friends = await FriendsService.getAllFriends();
    expect(friends.map((f) => f.id), ['a', 'b']);
    expect(friends.map((f) => f.notificationId).toSet(), {1, 2});
    expect(await _storedFriends(), hasLength(2));
    expect(changes, 1);
  });

  test('addFriends rejects duplicate ids without changing anything', () async {
    await FriendsService.addFriend(_friend('a'));
    await expectLater(
        FriendsService.addFriends([_friend('b'), _friend('a')]), throwsException);
    expect((await FriendsService.getAllFriends()).map((f) => f.id), ['a']);
    expect(changes, 1);
  });

  test('deleteFriend removes the friend from memory and storage', () async {
    await FriendsService.addFriends([_friend('a'), _friend('b')]);
    await FriendsService.deleteFriend('a');

    expect((await FriendsService.getAllFriends()).map((f) => f.id), ['b']);
    final stored = await _storedFriends();
    expect(stored.map((m) => m['id']), ['b']);
    expect(changes, 2);
    await expectLater(FriendsService.deleteFriend('missing'), throwsException);
  });

  test('clearAllData removes friends but keeps the reminder setting', () async {
    await FriendsService.addFriend(_friend('a'));
    await FriendsService.setBirthdayNotificationsEnabled(false);
    await FriendsService.clearAllData();

    expect(await FriendsService.getAllFriends(), isEmpty);
    expect(FriendsService.isBirthdayNotificationsEnabled(), isFalse);
  });

  test('initialize removes the legacy birthday_notifications store', () async {
    SharedPreferences.setMockInitialValues({'birthday_notifications': '[]'});
    await FriendsService.initialize();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('birthday_notifications'), isFalse);
  });

  group('backup', () {
    test('encode/decode round-trips friends', () {
      final backup = FriendsService.encodeBackup([_friend('a')]);
      final decoded = FriendsService.decodeBackup(backup);
      expect(decoded.single.name, 'Anna');
      expect(decoded.single.birthDate, DateTime(1990, 5, 1));
    });

    test('decode accepts legacy JSON-string entries and skips broken ones', () {
      final backup = json.encode({
        'version': '1.0',
        'friends': [_friend('a').toJson(), 'not json', 42],
      });
      expect(FriendsService.decodeBackup(backup), hasLength(1));
    });

    test('decode rejects invalid files with localized error keys', () {
      Matcher error(String key) => isA<FriendsBackupException>()
          .having((e) => e.messageKey, 'messageKey', key);
      expect(() => FriendsService.decodeBackup('nope'),
          throwsA(error('import_export_error_invalid_format')));
      expect(() => FriendsService.decodeBackup('{"friends": []}'),
          throwsA(error('import_export_error_invalid_format')));
      expect(() => FriendsService.decodeBackup('{"version": "1.0", "friends": []}'),
          throwsA(error('import_export_error_no_valid_friends')));
    });

    test('importFriends skips existing people and adds the rest at once', () async {
      await FriendsService.addFriend(_friend('a', name: 'Anna'));
      changes = 0;

      final (added, skipped) = await FriendsService.importFriends([
        _friend('x', name: 'ANNA'),
        _friend('y', name: 'Ben'),
        _friend('z', name: 'Cleo'),
      ]);

      expect((added, skipped), (2, 1));
      final names = (await FriendsService.getAllFriends()).map((f) => f.name);
      expect(names, ['Anna', 'Ben', 'Cleo']);
      expect(changes, 1);
    });
  });

  group('birth date persistence and removal hook', () {
    String backupWith(Object birthDate) => jsonEncode({
          'version': '1.0',
          'friends': [
            {
              'id': 'x',
              'name': 'Anna',
              'birthDate': birthDate,
              'createdDate': 0,
              'lastUpdated': 0,
            },
          ],
        });

    test('decodeBackup accepts date strings and legacy millis', () {
      final legacy = DateTime(1990, 5, 1).millisecondsSinceEpoch;
      for (final stored in <Object>['1990-05-01', legacy]) {
        final friend = FriendsService.decodeBackup(backupWith(stored)).single;
        expect(friend.birthDate, DateTime(1990, 5, 1));
      }
    });

    test('stored friends keep birthDate as yyyy-MM-dd', () async {
      await FriendsService.addFriend(_friend('a', birthDate: DateTime(1990, 5, 1)));
      final stored = await _storedFriends();
      expect((stored.single as Map)['birthDate'], '1990-05-01');
    });

    test('deleteFriend and clearAllData report removed ids', () async {
      final removed = <List<String>>[];
      FriendsService.onFriendsRemoved = (ids) async => removed.add(ids);
      addTearDown(() => FriendsService.onFriendsRemoved = null);
      await FriendsService.addFriends([_friend('a'), _friend('b', name: 'Ben'), _friend('c', name: 'Cleo')]);

      await FriendsService.deleteFriend('a');
      await FriendsService.clearAllData();

      expect(removed, [
        ['a'],
        ['b', 'c'],
      ]);
    });
  });

  group('applyChanges', () {
    test('adds, updates and removes in one save and one notification',
        () async {
      await FriendsService.addFriends(
          [_friend('a'), _friend('b', name: 'Ben'), _friend('c', name: 'Cleo')]);
      final removed = <List<String>>[];
      FriendsService.onFriendsRemoved = (ids) async => removed.add(ids);
      addTearDown(() => FriendsService.onFriendsRemoved = null);
      changes = 0;

      await FriendsService.applyChanges(
        add: [_friend('d', name: 'Dora')],
        update: [_friend('b', name: 'Benno')],
        remove: ['c'],
      );

      final friends = await FriendsService.getAllFriends();
      expect(friends.map((f) => f.name), ['Anna', 'Benno', 'Dora']);
      expect(friends.last.notificationId, isPositive);
      expect((await _storedFriends()).map((m) => m['id']), ['a', 'b', 'd']);
      expect(removed, [
        ['c'],
      ]);
      expect(changes, 1);
    });

    test('rejects unknown ids and duplicates without changing anything',
        () async {
      await FriendsService.addFriend(_friend('a'));
      changes = 0;
      for (final call in [
        () => FriendsService.applyChanges(update: [_friend('x')]),
        () => FriendsService.applyChanges(remove: ['x']),
        () => FriendsService.applyChanges(add: [_friend('a')]),
        () => FriendsService.applyChanges(add: [_friend('n'), _friend('n')]),
        () => FriendsService.applyChanges(
            add: [_friend('n')], remove: ['missing']),
      ]) {
        await expectLater(call(), throwsException);
      }
      expect((await FriendsService.getAllFriends()).map((f) => f.id), ['a']);
      expect(changes, 0);
    });

    test('returns once saved, without waiting for slow follow-ups',
        () async {
      await FriendsService.addFriend(_friend('a'));
      final reschedule = Completer<void>();
      final calendarRemoval = Completer<void>();
      FriendsService.onFriendsChanged = () => reschedule.future;
      FriendsService.onFriendsRemoved = (_) => calendarRemoval.future;
      addTearDown(() => FriendsService.onFriendsRemoved = null);
      final revision = FriendsService.revision.value;

      await FriendsService.applyChanges(
        add: [_friend('b', name: 'Ben')],
        remove: ['a'],
      );

      expect(reschedule.isCompleted, isFalse);
      expect(calendarRemoval.isCompleted, isFalse);
      expect(FriendsService.revision.value, revision + 1);
      expect((await _storedFriends()).map((m) => m['id']), ['b']);
      reschedule.complete();
      calendarRemoval.complete();
    });

    test('an empty batch does nothing', () async {
      await FriendsService.applyChanges();
      expect(changes, 0);
    });
  });

  test('importFriends skips known people and repeats within the backup',
      () async {
    await FriendsService.addFriend(_friend('a'));
    final (added, skipped) = await FriendsService.importFriends([
      _friend('x'), // same as the saved Anna
      _friend('y', name: 'Ben'),
      _friend('z', name: ' ben '), // same person again
    ]);
    expect((added, skipped), (1, 2));
    expect((await FriendsService.getAllFriends()).map((f) => f.name),
        ['Anna', 'Ben']);
  });

  test('importFriends stays fast for thousands of people', () async {
    await FriendsService.addFriends([
      for (var i = 0; i < 3000; i++)
        _friend('s$i', name: 'Saved $i', birthDate: DateTime(1980, 1, 1)),
    ]);
    final watch = Stopwatch()..start();
    final (added, skipped) = await FriendsService.importFriends([
      for (var i = 0; i < 3000; i++)
        _friend('i$i', name: 'Saved ${i * 2}', birthDate: DateTime(1980, 1, 1)),
    ]);
    watch.stop();
    expect((added, skipped), (1500, 1500));
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  });
}
