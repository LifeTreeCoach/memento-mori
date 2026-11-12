import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/data/backup_avatar.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A tiny "JPEG": the signature is all the store and codec look at.
final Uint8List _jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);
final Uint8List _png =
    Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 9]);

Friend _friend(String id, String name, {String? avatarPath}) => Friend(
      id: id,
      name: name,
      birthDate: DateTime(1990, 5, 1),
      avatarPath: avatarPath,
      createdDate: DateTime(2026),
      lastUpdated: DateTime(2026),
    );

void main() {
  late Directory exporting;
  late Directory importing;
  late AvatarStore exportStore;
  late AvatarStore importStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FriendsService.clearCacheForTesting();
    exporting = await Directory.systemTemp.createTemp('avatars_export');
    importing = await Directory.systemTemp.createTemp('avatars_import');
    exportStore = AvatarStore(baseDirectory: () async => exporting);
    importStore = AvatarStore(baseDirectory: () async => importing);
  });

  tearDown(() async {
    await exporting.delete(recursive: true);
    await importing.delete(recursive: true);
  });

  group('BackupAvatar', () {
    test('detects JPEG, PNG, GIF and WebP from their bytes', () {
      expect(BackupAvatar.sniffMime(_jpeg), 'image/jpeg');
      expect(BackupAvatar.sniffMime(_png), 'image/png');
      expect(BackupAvatar.sniffMime(ascii.encode('GIF89a')), 'image/gif');
      expect(BackupAvatar.sniffMime(ascii.encode('RIFF\x00\x00\x00\x00WEBPVP8')),
          'image/webp');
      expect(BackupAvatar.sniffMime(ascii.encode('<html>')), isNull);
      expect(BackupAvatar.sniffMime(const []), isNull);
    });

    test('round-trips through JSON', () {
      final json = BackupAvatar.fromBytes(_png)!.toJson();
      expect(json['mime'], 'image/png');
      final decoded = BackupAvatar.fromJson(jsonDecode(jsonEncode(json)))!;
      expect(decoded.bytes, _png);
      expect(decoded.extension, 'png');
    });

    test('ignores missing, corrupt, non-image and oversized data', () {
      expect(BackupAvatar.fromJson(null), isNull);
      expect(BackupAvatar.fromJson('x'), isNull);
      expect(BackupAvatar.fromJson({'mime': 'image/jpeg'}), isNull);
      expect(BackupAvatar.fromJson({'mime': 'image/jpeg', 'data': '!!not base64!!'}),
          isNull);
      expect(
          BackupAvatar.fromJson(
              {'mime': 'image/jpeg', 'data': base64Encode(utf8.encode('hello'))}),
          isNull);
      final huge = Uint8List(BackupAvatar.maxBytes + 1)..setAll(0, _jpeg);
      expect(BackupAvatar.fromBytes(huge), isNull);
      expect(BackupAvatar.fromJson({'mime': 'image/jpeg', 'data': base64Encode(huge)}),
          isNull);
    });

    test('trusts the bytes, not the declared mime', () {
      final avatar = BackupAvatar.fromJson(
          {'mime': 'image/gif', 'data': base64Encode(_jpeg)})!;
      expect(avatar.mime, 'image/jpeg');
    });
  });

  group('backup with photos', () {
    test('round-trips a friend photo into a new file in the avatars folder',
        () async {
      final original = await exportStore.save(_jpeg);
      final backup = await FriendsService.exportBackup(
        [_friend('a', 'Anna', avatarPath: original), _friend('b', 'Ben')],
        avatarStore: exportStore,
      );

      final friends = (jsonDecode(backup) as Map)['friends'] as List;
      expect(friends.first, isNot(contains('avatarPath')));
      expect(friends.first['avatar']['mime'], 'image/jpeg');
      expect(friends.last, isNot(contains('avatar')));
      expect((jsonDecode(backup) as Map)['version'], '1.5');

      final (added, _) = await FriendsService.importBackupEntries(
        FriendsService.decodeBackupEntries(backup),
        avatarStore: importStore,
      );
      expect(added, 2);
      final imported = await FriendsService.getAllFriends();
      final anna = imported.firstWhere((f) => f.name == 'Anna');
      expect(anna.avatarPath, isNot(original));
      expect(anna.avatarPath, startsWith('${importing.path}/avatars/'));
      expect(anna.avatarPath, endsWith('.jpg'));
      expect(await File(anna.avatarPath!).readAsBytes(), _jpeg);
      expect(imported.firstWhere((f) => f.name == 'Ben').avatarPath, isNull);
    });

    test('a missing photo file is left out of the export', () async {
      final backup = await FriendsService.exportBackup(
        [_friend('a', 'Anna', avatarPath: '${exporting.path}/gone.jpg')],
        avatarStore: exportStore,
      );
      expect(backup, isNot(contains('"avatar"')));
    });

    test('an old 1.0 backup imports without photos and ignores foreign paths',
        () async {
      final backup = jsonEncode({
        'version': '1.0',
        'friends': [
          _friend('a', 'Anna',
                  avatarPath: '/data/user/0/other.app/avatars/avatar_1.jpg')
              .toMap(),
        ],
      });
      await FriendsService.importBackupEntries(
        FriendsService.decodeBackupEntries(backup),
        avatarStore: importStore,
      );
      expect((await FriendsService.getAllFriends()).single.avatarPath, isNull);
      expect(Directory('${importing.path}/avatars').existsSync(), isFalse);
    });

    test('a corrupt photo is ignored, the friend is still imported', () async {
      final entry = _friend('a', 'Anna').toMap()
        ..['avatar'] = {'mime': 'image/jpeg', 'data': 'not*base64'};
      final backup = jsonEncode({'version': '1.1', 'friends': [entry]});
      final entries = FriendsService.decodeBackupEntries(backup);
      expect(entries.single.avatar, isNull);
      await FriendsService.importBackupEntries(entries, avatarStore: importStore);
      final anna = (await FriendsService.getAllFriends()).single;
      expect(anna.name, 'Anna');
      expect(anna.avatarPath, isNull);
    });

    test('photos of skipped (existing) friends are not written', () async {
      await FriendsService.addFriend(_friend('x', 'Anna'));
      final backup = FriendsService.encodeBackup(
        [_friend('a', 'Anna')],
        avatars: {'a': BackupAvatar.fromBytes(_jpeg)!},
      );
      final (added, skipped) = await FriendsService.importBackupEntries(
        FriendsService.decodeBackupEntries(backup),
        avatarStore: importStore,
      );
      expect((added, skipped), (0, 1));
      expect(Directory('${importing.path}/avatars').existsSync(), isFalse);
    });
  });
  test('export finds photos stored with an old container path', () async {
    final photo = await exportStore.save(_jpeg);
    final fileName = photo.split(Platform.pathSeparator).last;
    final backup = await FriendsService.exportBackup([
      _friend('a', 'Anna',
          avatarPath: '/old/container/Documents/avatars/$fileName'),
    ], avatarStore: exportStore);
    final entry = FriendsService.decodeBackupEntries(backup).single;
    expect(entry.avatar?.bytes, _jpeg);
  });

  group('orphaned avatar cleanup', () {
    late AvatarStore store;
    setUp(() => store = importStore);

    Future<List<String>> files() async {
      final directory = Directory('${importing.path}/avatars');
      if (!directory.existsSync()) return [];
      return [
        for (final file in directory.listSync())
          file.path.split(Platform.pathSeparator).last,
      ]..sort();
    }

    String name(String path) => path.split(Platform.pathSeparator).last;

    test('removes photos no stored friend uses, keeps the others', () async {
      final kept = await store.save(_jpeg);
      final orphan = await store.save(_jpeg);
      await FriendsService.addFriend(_friend('a', 'Anna', avatarPath: kept));
      expect(await FriendsService.removeOrphanedAvatars(avatarStore: store), 1);
      expect(await files(), [name(kept)]);
      expect(File(orphan).existsSync(), isFalse);
    });

    test('a deleted friend keeps the photo for undo until the next start',
        () async {
      final photo = await store.save(_jpeg);
      final anna = _friend('a', 'Anna', avatarPath: photo);
      await FriendsService.addFriend(anna);
      await FriendsService.deleteFriend('a');

      // Same session (e.g. an import while the undo is still offered).
      expect(await FriendsService.removeOrphanedAvatars(avatarStore: store), 0);
      await FriendsService.addFriend(anna); // undo
      expect((await FriendsService.getAllFriends()).single.avatarPath, photo);
      expect(File(photo).existsSync(), isTrue);

      // Deleted for good, then the app starts again.
      await FriendsService.deleteFriend('a');
      await FriendsService.clearCacheForTesting();
      expect(await FriendsService.removeOrphanedAvatars(avatarStore: store), 1);
      expect(File(photo).existsSync(), isFalse);
    });

    test('matches by file name, so a moved app container keeps photos',
        () async {
      final photo = await store.save(_jpeg);
      await FriendsService.addFriend(_friend('a', 'Anna',
          avatarPath: '/old/container/Documents/avatars/${name(photo)}'));
      expect(await FriendsService.removeOrphanedAvatars(avatarStore: store), 0);
      expect(File(photo).existsSync(), isTrue);
    });

    test('unreadable stored friends delete nothing', () async {
      final photo = await store.save(_jpeg);
      SharedPreferences.setMockInitialValues({'friends_data': 'not json'});
      await FriendsService.clearCacheForTesting();
      expect(await FriendsService.removeOrphanedAvatars(avatarStore: store), 0);
      expect(File(photo).existsSync(), isTrue);
    });

    test('no avatars folder: nothing to do', () async {
      expect(await FriendsService.removeOrphanedAvatars(avatarStore: store), 0);
      expect(Directory('${importing.path}/avatars').existsSync(), isFalse);
    });

    test('an import cleans up photos left from earlier sessions', () async {
      final orphan = await store.save(_jpeg);
      final backup = FriendsService.encodeBackup(
        [_friend('b', 'Ben')],
        avatars: {'b': BackupAvatar.fromBytes(_png)!},
      );
      await FriendsService.importBackupEntries(
        FriendsService.decodeBackupEntries(backup),
        avatarStore: store,
      );
      expect(await FriendsService.lastAvatarCleanup, 1);
      final ben = (await FriendsService.getAllFriends()).single;
      expect(File(orphan).existsSync(), isFalse);
      expect(await files(), [name(ben.avatarPath!)]);
    });
  });
}
