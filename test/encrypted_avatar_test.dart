import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/data/backup_avatar.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people/encrypted_file_image.dart';
import 'package:memento_mori_life_in_weeks/people/friend_avatar.dart';
import 'package:memento_mori_life_in_weeks/security/vault_cipher.dart';

/// A valid 1x1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// A tiny "JPEG": only its signature matters for the store.
final Uint8List _jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

VaultCipher _cipher(int fill) => VaultCipher(List<int>.filled(32, fill));

bool _containsJpegHeader(List<int> bytes) {
  for (var i = 0; i + 2 < bytes.length; i++) {
    if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8 && bytes[i + 2] == 0xFF) {
      return true;
    }
  }
  return false;
}

/// Resolves [provider] outside the fake async zone (real file IO).
Future<ImageInfo?> _load(WidgetTester tester, ImageProvider provider) =>
    tester.runAsync(() => _resolve(provider));

Future<ImageInfo> _resolve(ImageProvider provider) async {
  final completer = Completer<ImageInfo>();
  final stream = provider.resolve(ImageConfiguration.empty);
  final listener = ImageStreamListener(
    (info, _) => completer.complete(info),
    onError: completer.completeError,
  );
  stream.addListener(listener);
  try {
    return await completer.future;
  } finally {
    stream.removeListener(listener);
  }
}

void main() {
  setUpAll(() => Cryptography.instance = DartCryptography.defaultInstance);

  late Directory documents;
  late AvatarStore store;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('encrypted_avatar');
    store = AvatarStore(
      baseDirectory: () async => documents,
      cipher: _cipher(7),
    );
    imageCache.clear();
  });

  tearDown(() async {
    AvatarStore.configureCipher(null);
    imageCache.clear();
    await documents.delete(recursive: true);
  });

  group('AvatarStore with a cipher', () {
    test('seals saved photos: no JPEG header on disk', () async {
      final path = await store.save(_jpeg);
      final onDisk = await File(path).readAsBytes();

      expect(path, endsWith('.jpg'));
      expect(VaultCipher.looksSealed(onDisk), isTrue);
      expect(_containsJpegHeader(onDisk), isFalse);
      expect(
        await _cipher(7).open(AvatarStore.recordName(path), onDisk),
        _jpeg,
      );
    });

    test('record name is the file name only', () {
      expect(
        AvatarStore.recordName('/old/container/avatars/avatar_1_0.jpg'),
        'avatar/avatar_1_0.jpg',
      );
    });

    test('readForBackup returns the plain photo (round trip)', () async {
      final path = await store.save(_png, extension: 'png');

      final avatar = await store.readForBackup(path);

      expect(avatar!.mime, 'image/png');
      expect(avatar.bytes, _png);
      final restored = await store.restore(avatar);
      expect((await store.readForBackup(restored))!.bytes, _png);
    });

    test('readForBackup still reads a legacy plain photo', () async {
      final legacy = File('${documents.path}/avatars/avatar_1_0.jpg');
      await legacy.create(recursive: true);
      await legacy.writeAsBytes(_jpeg);

      expect((await store.readForBackup(legacy.path))!.bytes, _jpeg);
    });

    test('readForBackup skips a photo sealed with another key', () async {
      final path = await store.save(_jpeg);
      final other = AvatarStore(
        baseDirectory: () async => documents,
        cipher: _cipher(9),
      );

      expect(await other.readForBackup(path), isNull);
    });

    test('uses the configured cipher when none is passed', () async {
      AvatarStore.configureCipher(_cipher(7));
      final path = await AvatarStore(baseDirectory: () async => documents)
          .save(_jpeg);

      expect(VaultCipher.looksSealed(await File(path).readAsBytes()), isTrue);
    });

    test('measures sealing and opening 50 KB (informational)', () async {
      final random = Random(1);
      final photo = Uint8List.fromList(
        List<int>.generate(50 * 1024, (_) => random.nextInt(256)),
      );
      final cipher = _cipher(7);
      await cipher.open('avatar/warm', await cipher.seal('avatar/warm', photo));

      final watch = Stopwatch()..start();
      final sealed = await cipher.seal('avatar/a.jpg', photo);
      final sealMs = watch.elapsedMilliseconds;
      final opened = await cipher.open('avatar/a.jpg', sealed);
      final totalMs = watch.elapsedMilliseconds;

      expect(opened, photo);
      // ignore: avoid_print
      print('50 KB avatar: seal ${sealMs}ms, open ${totalMs - sealMs}ms');
    });
  });

  group('AvatarStore without a cipher', () {
    test('release builds refuse to write a plain photo', () async {
      final releaseStore = AvatarStore(
        baseDirectory: () async => documents,
        allowPlainPhotos: false,
      );

      await expectLater(releaseStore.save(_jpeg), throwsStateError);
      expect(Directory('${documents.path}/avatars').existsSync(), isFalse);
      expect(await releaseStore.restore(BackupAvatar.fromBytes(_png)), isNull);
    });

    test('release builds still read plain photos of older versions', () async {
      final plain = File('${documents.path}/avatars/avatar_old.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(_png);
      final releaseStore = AvatarStore(
        baseDirectory: () async => documents,
        allowPlainPhotos: false,
      );

      expect((await releaseStore.readForBackup(plain.path))!.bytes, _png);
    });

    test('debug builds and tests keep the plain fallback', () async {
      final debugStore = AvatarStore(baseDirectory: () async => documents);
      expect(debugStore.allowPlainPhotos, isTrue);

      final path = await debugStore.save(_jpeg);
      expect(File(path).readAsBytesSync(), _jpeg);
    });
  });

  group('EncryptedFileImage', () {
    testWidgets('decodes a sealed PNG', (tester) async {
      final path = (await tester.runAsync(
        () => store.save(_png, extension: 'png'),
      ))!;

      final info = await _load(
        tester,
        EncryptedFileImage(File(path), cipher: _cipher(7)),
      );

      expect(info!.image.width, 1);
      expect(info.image.height, 1);
    });

    testWidgets('decodes a legacy plain file', (tester) async {
      final file = File('${documents.path}/legacy.png');
      await tester.runAsync(() => file.writeAsBytes(_png));

      final info = await _load(tester, EncryptedFileImage(file));

      expect(info!.image.width, 1);
    });

    testWidgets('uses the configured cipher by default', (tester) async {
      AvatarStore.configureCipher(_cipher(7));
      final path = (await tester.runAsync(
        () => store.save(_png, extension: 'png'),
      ))!;

      final info = await _load(tester, EncryptedFileImage(File(path)));

      expect(info!.image.width, 1);
    });

    testWidgets('fails to load with the wrong key', (tester) async {
      final path = (await tester.runAsync(
        () => store.save(_png, extension: 'png'),
      ))!;

      final error = await tester.runAsync(() async {
        try {
          await _resolve(EncryptedFileImage(File(path), cipher: _cipher(9)));
          return null;
        } catch (error) {
          return error;
        }
      });

      expect(error, isA<VaultWrongKeyException>());
    });

    test('equal by path, scale and cipher (image cache key)', () {
      final cipher = _cipher(7);
      expect(
        EncryptedFileImage(File('/a/avatar_1.jpg'), cipher: cipher),
        EncryptedFileImage(File('/a/avatar_1.jpg'), cipher: cipher),
      );
      expect(
        EncryptedFileImage(File('/a/avatar_1.jpg')).hashCode,
        EncryptedFileImage(File('/a/avatar_1.jpg')).hashCode,
      );
      expect(
        EncryptedFileImage(File('/a/avatar_1.jpg')),
        isNot(EncryptedFileImage(File('/a/avatar_2.jpg'))),
      );
      expect(
        EncryptedFileImage(File('/a/avatar_1.jpg')),
        isNot(EncryptedFileImage(File('/a/avatar_1.jpg'), scale: 2)),
      );
    });
  });

  testWidgets('FriendAvatar keeps the initials when the key is wrong', (
    tester,
  ) async {
    final path = (await tester.runAsync(
      () => store.save(_png, extension: 'png'),
    ))!;
    AvatarStore.configureCipher(_cipher(9));
    final friend = Friend(
      id: 'a',
      name: 'Anna Lopez',
      birthDate: DateTime(1990),
      avatarPath: path,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FriendAvatar(friend: friend)),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('AL'), findsOneWidget);
  });
}
