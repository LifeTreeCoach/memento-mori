import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/security/data_key.dart';
import 'package:memento_mori_life_in_weeks/security/vault_cipher.dart';

void main() {
  setUpAll(() => Cryptography.instance = DartCryptography.defaultInstance);

  final key = List<int>.generate(32, (i) => i);
  final otherKey = List<int>.generate(32, (i) => 255 - i);
  final plain = utf8.encode('{"friends":[{"name":"Ada"}]}');
  const headerLength = 3 + 1 + 8 + 12;

  Future<Uint8List> sealFriends() => VaultCipher(key).seal('friends', plain);

  Matcher throwsCorrupt() => throwsA(isA<VaultCorruptException>());

  test('round trip returns the plain bytes', () async {
    final envelope = await sealFriends();
    expect(await VaultCipher(key).open('friends', envelope), plain);
  });

  test('round trip works for empty input', () async {
    final cipher = VaultCipher(key);
    final envelope = await cipher.seal('friends', const []);
    expect(await cipher.open('friends', envelope), isEmpty);
  });

  test('envelope layout: magic, version, key id, nonce, ct, tag', () async {
    final envelope = await sealFriends();
    expect(envelope.sublist(0, 4), [0x4D, 0x4D, 0x56, 0x01]);
    expect(envelope.length, headerLength + plain.length + 16);
    final hmac = await Hmac.sha256().calculateMac(
      utf8.encode('memento-vault-key-id'),
      secretKey: SecretKey(key),
    );
    expect(envelope.sublist(4, 12), hmac.bytes.sublist(0, 8));
  });

  test('sealing the same input twice uses different nonces', () async {
    final cipher = VaultCipher(key);
    final a = await cipher.seal('friends', plain);
    final b = await cipher.seal('friends', plain);
    expect(a.sublist(12, 24), isNot(b.sublist(12, 24)));
    expect(a, isNot(b));
  });

  test('a different key throws VaultWrongKeyException', () async {
    final envelope = await sealFriends();
    expect(
      VaultCipher(otherKey).open('friends', envelope),
      throwsA(isA<VaultWrongKeyException>()),
    );
  });

  test('a flipped ciphertext byte throws VaultCorruptException', () async {
    final envelope = await sealFriends();
    envelope[headerLength] ^= 0x01;
    expect(VaultCipher(key).open('friends', envelope), throwsCorrupt());
  });

  test('a flipped tag byte throws VaultCorruptException', () async {
    final envelope = await sealFriends();
    envelope[envelope.length - 1] ^= 0x80;
    expect(VaultCipher(key).open('friends', envelope), throwsCorrupt());
  });

  test('a truncated envelope throws VaultCorruptException', () async {
    final envelope = await sealFriends();
    final cipher = VaultCipher(key);
    final cut = envelope.sublist(0, envelope.length - 1);
    expect(cipher.open('friends', cut), throwsCorrupt());
    expect(cipher.open('friends', envelope.sublist(0, 20)), throwsCorrupt());
  });

  test('bad magic or version throws VaultCorruptException', () async {
    final badMagic = await sealFriends();
    badMagic[0] = 0x58;
    final badVersion = await sealFriends();
    badVersion[3] = 0x02;
    final cipher = VaultCipher(key);
    expect(cipher.open('friends', badMagic), throwsCorrupt());
    expect(cipher.open('friends', badVersion), throwsCorrupt());
  });

  test('a record sealed as "friends" cannot be opened as "compass"', () async {
    final envelope = await sealFriends();
    expect(VaultCipher(key).open('compass', envelope), throwsCorrupt());
  });

  group('looksSealed', () {
    test('is true for envelopes', () async {
      expect(VaultCipher.looksSealed(await sealFriends()), isTrue);
    });

    test('is false for a JPEG header', () {
      final jpeg = [0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(60, 0)];
      expect(VaultCipher.looksSealed(jpeg), isFalse);
    });

    test('is false for plain JSON', () {
      expect(VaultCipher.looksSealed(utf8.encode(_plainJson)), isFalse);
    });

    test('is false for short input', () {
      expect(VaultCipher.looksSealed([0x4D, 0x4D, 0x56, 0x01]), isFalse);
    });
  });

  test('rejects keys that are not 32 bytes', () {
    expect(() => VaultCipher(List.filled(16, 1)), throwsArgumentError);
  });

  test('a new key is 32 random bytes', () {
    final a = DataKeyStore.newKey();
    expect(a, hasLength(32));
    expect(a, isNot(DataKeyStore.newKey()));
  });
}

const _plainJson =
    '[{"name":"Ada","birthDate":"1990-03-15","groups":["family"]}]';
