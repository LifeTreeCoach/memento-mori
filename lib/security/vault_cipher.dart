import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'data_key.dart';

/// Encrypts and decrypts named records (e.g. "friends", "compass").
///
/// The record name is bound to the ciphertext, so a record sealed under one
/// name cannot be opened under another.
abstract interface class RecordCipher {
  Future<Uint8List> seal(String record, List<int> plain);

  /// Throws a [VaultException] if [envelope] cannot be opened.
  Future<Uint8List> open(String record, List<int> envelope);
}

/// Why an envelope could not be opened.
sealed class VaultException implements Exception {
  const VaultException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The envelope was sealed with a different data key.
final class VaultWrongKeyException extends VaultException {
  const VaultWrongKeyException(super.message);
}

/// The envelope is damaged, truncated, not an envelope at all, or belongs to
/// another record.
final class VaultCorruptException extends VaultException {
  const VaultCorruptException(super.message);
}

/// AES-256-GCM [RecordCipher] writing envelope v1:
///
/// `'M' 'M' 'V'` | version 0x01 | key id (8) | nonce (12) | ciphertext |
/// GCM tag (16).
///
/// The key id is the first 8 bytes of HMAC-SHA256(key, "memento-vault-key-id")
/// and tells a wrong key apart from damaged data. The AAD is
/// "memento-vault/v1/" + record name.
class VaultCipher implements RecordCipher {
  VaultCipher(List<int> key) : _key = SecretKey(_checkedCopy(key));

  static const List<int> _magic = [0x4D, 0x4D, 0x56]; // "MMV"
  static const int _version = 0x01;
  static const int _keyIdLength = 8;
  static const int _nonceLength = 12;
  static const int _tagLength = 16;
  static const int _keyIdOffset = 4;
  static const int _nonceOffset = _keyIdOffset + _keyIdLength;
  static const int _cipherTextOffset = _nonceOffset + _nonceLength;
  static const int _minLength = _cipherTextOffset + _tagLength;
  static const String _keyIdLabel = 'memento-vault-key-id';
  static const String _aadPrefix = 'memento-vault/v1/';

  final SecretKey _key;
  final AesGcm _aes = AesGcm.with256bits();
  Future<List<int>>? _keyId;

  /// Whether [bytes] start like an envelope v1 (magic, version, minimum
  /// length). Cheap check to tell sealed data from plain files.
  static bool looksSealed(List<int> bytes) {
    if (bytes.length < _minLength) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return bytes[_magic.length] == _version;
  }

  @override
  Future<Uint8List> seal(String record, List<int> plain) async {
    final box = await _aes.encrypt(plain, secretKey: _key, aad: _aad(record));
    return (BytesBuilder(copy: false)
          ..add(_magic)
          ..addByte(_version)
          ..add(await _keyIdBytes())
          ..add(box.nonce)
          ..add(box.cipherText)
          ..add(box.mac.bytes))
        .takeBytes();
  }

  @override
  Future<Uint8List> open(String record, List<int> envelope) async {
    if (!looksSealed(envelope)) {
      throw const VaultCorruptException('not a vault envelope (v1)');
    }
    await _checkKeyId(envelope);
    try {
      final plain = await _aes.decrypt(
        _secretBoxOf(envelope),
        secretKey: _key,
        aad: _aad(record),
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const VaultCorruptException('authentication failed');
    }
  }

  Future<void> _checkKeyId(List<int> envelope) async {
    final expected = await _keyIdBytes();
    for (var i = 0; i < _keyIdLength; i++) {
      if (envelope[_keyIdOffset + i] != expected[i]) {
        throw const VaultWrongKeyException('sealed with another key');
      }
    }
  }

  static SecretBox _secretBoxOf(List<int> envelope) {
    final tagOffset = envelope.length - _tagLength;
    return SecretBox(
      envelope.sublist(_cipherTextOffset, tagOffset),
      nonce: envelope.sublist(_nonceOffset, _cipherTextOffset),
      mac: Mac(envelope.sublist(tagOffset)),
    );
  }

  Future<List<int>> _keyIdBytes() => _keyId ??= _computeKeyId();

  Future<List<int>> _computeKeyId() async {
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode(_keyIdLabel),
      secretKey: _key,
    );
    return mac.bytes.sublist(0, _keyIdLength);
  }

  static List<int> _aad(String record) => utf8.encode('$_aadPrefix$record');

  static List<int> _checkedCopy(List<int> key) {
    DataKeyStore.checkLength(key);
    return List<int>.unmodifiable(key);
  }
}
