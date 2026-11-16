import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/data/encrypted_backup.dart';

Future<R> _inPlace<R>(FutureOr<R> Function() computation) async =>
    computation();

/// Low iterations keep the tests fast; the bounds allow them.
const _fast = EncryptedBackup(
  iterations: 1000,
  minIterations: 1000,
  runInBackground: _inPlace,
);

const _plain = '{"version":"2.0","friends":[{"name":"Anna"}]}';

Map<String, dynamic> _fields(String contents) =>
    jsonDecode(contents) as Map<String, dynamic>;

void main() {
  test('round trip returns the same JSON', () async {
    final sealed = await _fast.encrypt(_plain, 'correct horse');
    expect(sealed, isNot(contains('Anna')));
    expect(await _fast.decrypt(sealed, 'correct horse'), _plain);
  });

  test('round trip with non-ASCII text and password', () async {
    const text = '{"name":"Zoë – 🎂 Ünal"}';
    final sealed = await _fast.encrypt(text, 'pässwört ✓');
    expect(await _fast.decrypt(sealed, 'pässwört ✓'), text);
  });

  test('runs in a background isolate by default', () async {
    const isolated = EncryptedBackup(iterations: 1000, minIterations: 1000);
    final sealed = await isolated.encrypt(_plain, 'password');
    expect(await isolated.decrypt(sealed, 'password'), _plain);
    await expectLater(isolated.decrypt(sealed, 'nope'),
        throwsA(isA<WrongBackupPasswordException>()));
  });

  test('writes the documented format', () async {
    final fields = _fields(await _fast.encrypt(_plain, 'password'));
    expect(fields.keys, ['format', 'v', 'kdf', 'cipher', 'data']);
    expect(fields['format'], 'memento-encrypted-backup');
    expect(fields['v'], 1);
    expect(fields['kdf']['name'], 'pbkdf2-hmac-sha256');
    expect(fields['kdf']['iterations'], 1000);
    expect(base64.decode(fields['kdf']['salt'] as String), hasLength(16));
    expect(fields['cipher']['name'], 'aes-256-gcm');
    expect(base64.decode(fields['cipher']['nonce'] as String), hasLength(12));
    expect(base64.decode(fields['data'] as String).length,
        utf8.encode(_plain).length + 16);
  });

  test('defaults to 600000 iterations', () {
    expect(const EncryptedBackup().iterations, 600000);
  });

  test('salt and nonce are fresh every time', () async {
    final a = _fields(await _fast.encrypt(_plain, 'password'));
    final b = _fields(await _fast.encrypt(_plain, 'password'));
    expect(a['kdf']['salt'], isNot(b['kdf']['salt']));
    expect(a['cipher']['nonce'], isNot(b['cipher']['nonce']));
    expect(a['data'], isNot(b['data']));
  });

  test('a wrong password fails authentication', () async {
    final sealed = await _fast.encrypt(_plain, 'password');
    await expectLater(_fast.decrypt(sealed, 'Password'),
        throwsA(isA<WrongBackupPasswordException>()));
  });

  group('tampering', () {
    Future<String> tampered(void Function(Map<String, dynamic>) change) async {
      final fields = _fields(await _fast.encrypt(_plain, 'password'));
      change(fields);
      return jsonEncode(fields);
    }

    test('changed iterations fail', () async {
      final sealed = await tampered((f) => f['kdf']['iterations'] = 1001);
      await expectLater(_fast.decrypt(sealed, 'password'),
          throwsA(isA<WrongBackupPasswordException>()));
    });

    test('a changed nonce fails', () async {
      final sealed = await tampered((f) => f['cipher']['nonce'] =
          base64.encode(List.filled(12, 7)));
      await expectLater(_fast.decrypt(sealed, 'password'),
          throwsA(isA<WrongBackupPasswordException>()));
    });

    test('a flipped data byte fails', () async {
      final sealed = await tampered((f) {
        final data = base64.decode(f['data'] as String);
        data[0] ^= 1;
        f['data'] = base64.encode(data);
      });
      await expectLater(_fast.decrypt(sealed, 'password'),
          throwsA(isA<WrongBackupPasswordException>()));
    });

    test('a newer version is unsupported', () async {
      final sealed = await tampered((f) => f['v'] = 2);
      await expectLater(_fast.decrypt(sealed, 'password'),
          throwsA(isA<UnsupportedEncryptedBackupException>()));
    });

    test('an unknown cipher is unsupported', () async {
      final sealed =
          await tampered((f) => f['cipher']['name'] = 'chacha20-poly1305');
      await expectLater(_fast.decrypt(sealed, 'password'),
          throwsA(isA<UnsupportedEncryptedBackupException>()));
    });

    test('a short salt is invalid', () async {
      final sealed = await tampered(
          (f) => f['kdf']['salt'] = base64.encode(List.filled(8, 1)));
      await expectLater(_fast.decrypt(sealed, 'password'),
          throwsA(isA<InvalidEncryptedBackupException>()));
    });

    test('truncated data is invalid', () async {
      final sealed =
          await tampered((f) => f['data'] = base64.encode(List.filled(4, 1)));
      await expectLater(_fast.decrypt(sealed, 'password'),
          throwsA(isA<InvalidEncryptedBackupException>()));
    });
  });

  group('iteration bounds', () {
    test('the default reader rejects too few iterations', () async {
      final sealed = await _fast.encrypt(_plain, 'password');
      await expectLater(const EncryptedBackup().decrypt(sealed, 'password'),
          throwsA(isA<InvalidEncryptedBackupException>()));
    });

    test('the default reader rejects too many iterations', () async {
      final fields = _fields(await _fast.encrypt(_plain, 'password'));
      fields['kdf']['iterations'] = 2000001;
      await expectLater(
          const EncryptedBackup().decrypt(jsonEncode(fields), 'password'),
          throwsA(isA<InvalidEncryptedBackupException>()));
    });

    test('the default reader caps iterations at 2,000,000', () {
      expect(EncryptedBackup.defaultMaxIterations, 2000000);
    });

    test('non-integer iterations are rejected', () async {
      final fields = _fields(await _fast.encrypt(_plain, 'password'));
      fields['kdf']['iterations'] = '1000';
      await expectLater(_fast.decrypt(jsonEncode(fields), 'password'),
          throwsA(isA<InvalidEncryptedBackupException>()));
    });
  });

  test('garbage and oversized files are invalid', () async {
    await expectLater(_fast.decrypt('{"format":"memento-encrypted-backup"',
            'password'),
        throwsA(isA<InvalidEncryptedBackupException>()));
    final huge = '{"format":"memento-encrypted-backup","data":"'
        '${'A' * EncryptedBackup.maxFileLength}"}';
    await expectLater(_fast.decrypt(huge, 'password'),
        throwsA(isA<InvalidEncryptedBackupException>()));
  });

  group('isEncryptedBackup', () {
    test('recognises a protected file', () async {
      final sealed = await _fast.encrypt(_plain, 'password');
      expect(EncryptedBackup.isEncryptedBackup(sealed), isTrue);
      expect(
          EncryptedBackup.isEncryptedBackup(
              const JsonEncoder.withIndent('  ').convert(_fields(sealed))),
          isTrue);
    });

    test('a plain backup or other text is not protected', () {
      expect(EncryptedBackup.isEncryptedBackup(_plain), isFalse);
      expect(EncryptedBackup.isEncryptedBackup(''), isFalse);
      expect(EncryptedBackup.isEncryptedBackup('memento-encrypted-backup'),
          isFalse);
      expect(
          EncryptedBackup.isEncryptedBackup(
              '{"version":"2.0","format":"memento-encrypted-backup"}'),
          isFalse);
    });
  });
}
