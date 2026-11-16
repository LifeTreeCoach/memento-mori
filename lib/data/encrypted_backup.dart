/// Password-protected backup files.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Why a protected backup could not be opened; [messageKey] is a
/// localization key.
sealed class EncryptedBackupException implements Exception {
  const EncryptedBackupException(this.message);

  final String message;

  String get messageKey;

  @override
  String toString() => '$runtimeType: $message';
}

/// Authentication failed: the password is wrong, or the file was changed
/// (AES-GCM cannot tell the two apart).
final class WrongBackupPasswordException extends EncryptedBackupException {
  const WrongBackupPasswordException() : super('authentication failed');

  @override
  String get messageKey => 'import_export_password_wrong';
}

/// Written by a newer app: unknown version, key derivation or cipher.
final class UnsupportedEncryptedBackupException
    extends EncryptedBackupException {
  const UnsupportedEncryptedBackupException(super.message);

  @override
  String get messageKey => 'import_export_error_encrypted_unsupported';
}

/// Not a readable protected backup: malformed, truncated, too large or
/// with parameters out of the accepted bounds.
final class InvalidEncryptedBackupException extends EncryptedBackupException {
  const InvalidEncryptedBackupException(super.message);

  @override
  String get messageKey => 'import_export_error_encrypted_invalid';
}

/// Runs [computation] away from the UI isolate ([Isolate.run] by default;
/// tests run it in place).
typedef BackgroundRunner = Future<R> Function<R>(
    FutureOr<R> Function() computation);

/// Encrypts a backup's JSON with a password, file format v1 (UTF-8 JSON):
///
/// ```json
/// {"format":"memento-encrypted-backup","v":1,
///  "kdf":{"name":"pbkdf2-hmac-sha256","iterations":600000,"salt":"<b64 16>"},
///  "cipher":{"name":"aes-256-gcm","nonce":"<b64 12>"},
///  "data":"<b64 ciphertext + 16-byte tag>"}
/// ```
///
/// The AAD is the canonical UTF-8 JSON of the header (`format`, `v`, `kdf`,
/// `cipher`, in this order), so none of it can be changed unnoticed.
/// Pure Dart ([DartPbkdf2], [DartAesGcm]): a file decrypts identically on
/// Android, iOS and every other platform. The password is used as typed
/// (UTF-8, not trimmed or normalized).
class EncryptedBackup {
  const EncryptedBackup({
    this.iterations = defaultIterations,
    this.minIterations = defaultMinIterations,
    this.maxIterations = defaultMaxIterations,
    this.runInBackground = _runInIsolate,
  });

  static const String formatName = 'memento-encrypted-backup';
  static const int version = 1;
  static const String kdfName = 'pbkdf2-hmac-sha256';
  static const String cipherName = 'aes-256-gcm';

  /// OWASP's 2023 recommendation for PBKDF2-HMAC-SHA256.
  static const int defaultIterations = 600000;
  static const int defaultMinIterations = 100000;
  /// Upper bound when reading: about 3x the default, so a crafted file
  /// can't stall the app for minutes on a slow phone.
  static const int defaultMaxIterations = 2000000;
  static const int saltLength = 16;
  static const int nonceLength = 12;
  static const int tagLength = 16;
  static const int keyBits = 256;

  /// Largest backup file read, protected or plain (same cap as vCard
  /// imports); the import checks the picked file's size before reading it.
  static const int maxFileLength = 64 * 1024 * 1024;

  /// Iterations used when writing.
  final int iterations;

  /// Bounds accepted when reading: fewer would be weak, more could stall
  /// the app (a crafted file).
  final int minIterations;
  final int maxIterations;

  final BackgroundRunner runInBackground;

  static final RegExp _formatAtStart =
      RegExp('^\\s*\\{\\s*"format"\\s*:\\s*"$formatName"');

  /// Whether [contents] is a protected backup (its first field names the
  /// format, as [encrypt] writes it). Cheap: looks at the start only.
  static bool isEncryptedBackup(String contents) =>
      _formatAtStart.hasMatch(contents.length > 256
          ? contents.substring(0, 256)
          : contents);

  /// The protected file for [plainJson], keyed by [password].
  Future<String> encrypt(String plainJson, String password) {
    final iterations = this.iterations;
    return runInBackground(() => _encrypt(plainJson, password, iterations));
  }

  /// The backup JSON inside [contents]. Throws [WrongBackupPasswordException],
  /// [UnsupportedEncryptedBackupException] or
  /// [InvalidEncryptedBackupException].
  Future<String> decrypt(String contents, String password) async {
    final header = _Header.parse(contents, minIterations, maxIterations);
    return runInBackground(() => _decrypt(header, password));
  }

  static Future<R> _runInIsolate<R>(FutureOr<R> Function() computation) =>
      Isolate.run(computation, debugName: 'encrypted-backup');

  static Future<String> _encrypt(
      String plainJson, String password, int iterations) async {
    final header = _Header(
      iterations: iterations,
      salt: _randomBytes(saltLength),
      nonce: _randomBytes(nonceLength),
    );
    final key = await _deriveKey(password, header);
    final box = await DartAesGcm.with256bits().encrypt(
      utf8.encode(plainJson),
      secretKey: key,
      nonce: header.nonce,
      aad: header.aad,
    );
    return jsonEncode({
      ...header.toJson(),
      'data': base64.encode([...box.cipherText, ...box.mac.bytes]),
    });
  }

  static Future<String> _decrypt(_Header header, String password) async {
    final key = await _deriveKey(password, header);
    final data = header.data;
    final tagStart = data.length - tagLength;
    try {
      final plain = await DartAesGcm.with256bits().decrypt(
        SecretBox(
          data.sublist(0, tagStart),
          nonce: header.nonce,
          mac: Mac(data.sublist(tagStart)),
        ),
        secretKey: key,
        aad: header.aad,
      );
      return utf8.decode(plain);
    } on SecretBoxAuthenticationError {
      throw const WrongBackupPasswordException();
    } on FormatException {
      throw const InvalidEncryptedBackupException('payload is not UTF-8');
    }
  }

  static Future<SecretKey> _deriveKey(String password, _Header header) =>
      DartPbkdf2(
        macAlgorithm: DartHmac.sha256(),
        iterations: header.iterations,
        bits: keyBits,
        // Runs off the UI isolate: no pauses needed.
        pausePeriod: Duration.zero,
      ).deriveKeyFromPassword(password: password, nonce: header.salt);

  static List<int> _randomBytes(int length) =>
      SecretKeyData.random(length: length).bytes;
}

/// The authenticated header of a protected file (and its data when read).
class _Header {
  _Header({
    required this.iterations,
    required this.salt,
    required this.nonce,
    this.data = const [],
  });

  final int iterations;
  final List<int> salt;
  final List<int> nonce;
  final List<int> data;

  Map<String, Object> toJson() => {
        'format': EncryptedBackup.formatName,
        'v': EncryptedBackup.version,
        'kdf': {
          'name': EncryptedBackup.kdfName,
          'iterations': iterations,
          'salt': base64.encode(salt),
        },
        'cipher': {
          'name': EncryptedBackup.cipherName,
          'nonce': base64.encode(nonce),
        },
      };

  /// Canonical UTF-8 JSON of [toJson] (fixed key order, no whitespace).
  List<int> get aad => utf8.encode(jsonEncode(toJson()));

  /// Validates every field of [contents] before any key is derived.
  static _Header parse(String contents, int minIterations, int maxIterations) {
    if (contents.length > EncryptedBackup.maxFileLength) {
      throw const InvalidEncryptedBackupException('file too large');
    }
    final json = _decodeObject(contents);
    if (json['format'] != EncryptedBackup.formatName) {
      throw const InvalidEncryptedBackupException('not a protected backup');
    }
    final version = json['v'];
    if (version is! int) {
      throw const InvalidEncryptedBackupException('missing version');
    }
    if (version != EncryptedBackup.version) {
      throw UnsupportedEncryptedBackupException('version $version');
    }
    final kdf = _object(json['kdf'], 'kdf');
    final cipher = _object(json['cipher'], 'cipher');
    _expectName(kdf, EncryptedBackup.kdfName);
    _expectName(cipher, EncryptedBackup.cipherName);
    return _Header(
      iterations: _iterations(kdf['iterations'], minIterations, maxIterations),
      salt: _bytes(kdf['salt'], 'salt', exactLength: EncryptedBackup.saltLength),
      nonce: _bytes(cipher['nonce'], 'nonce',
          exactLength: EncryptedBackup.nonceLength),
      data: _bytes(json['data'], 'data'),
    );
  }

  static Map<String, dynamic> _decodeObject(String contents) {
    try {
      return _object(jsonDecode(contents), 'file');
    } on FormatException {
      throw const InvalidEncryptedBackupException('not JSON');
    }
  }

  static Map<String, dynamic> _object(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    throw InvalidEncryptedBackupException('$field is not an object');
  }

  static void _expectName(Map<String, dynamic> section, String expected) {
    final name = section['name'];
    if (name is! String) {
      throw const InvalidEncryptedBackupException('missing algorithm name');
    }
    if (name != expected) {
      throw UnsupportedEncryptedBackupException('algorithm $name');
    }
  }

  static int _iterations(Object? value, int min, int max) {
    if (value is int && value >= min && value <= max) return value;
    throw InvalidEncryptedBackupException('iterations out of bounds: $value');
  }

  static List<int> _bytes(Object? value, String field, {int? exactLength}) {
    if (value is! String) {
      throw InvalidEncryptedBackupException('$field missing');
    }
    final List<int> bytes;
    try {
      bytes = base64.decode(value);
    } on FormatException {
      throw InvalidEncryptedBackupException('$field is not base64');
    }
    final valid = exactLength == null
        ? bytes.length >= EncryptedBackup.tagLength
        : bytes.length == exactLength;
    if (!valid) {
      throw InvalidEncryptedBackupException('$field has a wrong length');
    }
    return bytes;
  }
}
