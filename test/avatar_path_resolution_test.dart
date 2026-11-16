import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/people/encrypted_file_image.dart';
import 'package:memento_mori_life_in_weeks/people/friend_avatar.dart';

/// Stored avatar paths are absolute; on iOS the app container moves on
/// updates, restores and device transfers, so photos are resolved by file
/// name against the current documents directory.
void main() {
  const documents = '/new/container/Documents';
  const oldPath = '/old/container/Documents/avatars/avatar_1_0.jpg';

  group('AvatarStore.resolvePath', () {
    test('null or empty: no photo', () {
      expect(AvatarStore.resolvePath(null, documentsPath: documents), isNull);
      expect(AvatarStore.resolvePath('', documentsPath: documents), isNull);
    });

    test('an old container path is resolved by file name', () {
      expect(
        AvatarStore.resolvePath(oldPath,
            documentsPath: documents, exists: (_) => false),
        '$documents/avatars/avatar_1_0.jpg',
      );
    });

    test('an existing stored file is used as is', () {
      expect(
        AvatarStore.resolvePath(oldPath,
            documentsPath: documents, exists: (path) => path == oldPath),
        oldPath,
      );
    });

    test('a path in the current avatars folder needs no file check', () {
      const current = '$documents/avatars/avatar_1_0.jpg';
      expect(
        AvatarStore.resolvePath(current,
            documentsPath: documents,
            exists: (_) => fail('no file system access expected')),
        current,
      );
    });

    test('a bare file name resolves into the avatars folder', () {
      expect(
        AvatarStore.resolvePath('avatar_1_0.jpg',
            documentsPath: documents, exists: (_) => false),
        '$documents/avatars/avatar_1_0.jpg',
      );
    });

    test('without a documents directory the stored path is kept', () {
      expect(AvatarStore.resolvePath(oldPath, documentsPath: null), oldPath);
    });
  });

  group('AvatarStore.resolve (cached documents directory)', () {
    late Directory temp;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('avatar_resolve');
      await AvatarStore.init(documentsDirectory: () async => temp);
    });

    tearDown(() async {
      AvatarStore.resetForTest();
      await temp.delete(recursive: true);
    });

    test('maps a moved container path into this run\'s documents', () {
      expect(AvatarStore.resolve(oldPath),
          '${temp.path}/avatars/avatar_1_0.jpg');
      expect(AvatarStore.resolve(null), isNull);
      expect(AvatarStore.resolve(''), isNull);
    });

    test('FriendAvatar loads the resolved file', () {
      final photo = FriendAvatar.photoAt(oldPath)! as EncryptedFileImage;
      expect(photo.file.path, '${temp.path}/avatars/avatar_1_0.jpg');
    });
  });

  test('without init, resolve keeps the stored path', () {
    AvatarStore.resetForTest();
    expect(AvatarStore.resolve(oldPath), oldPath);
  });
}
