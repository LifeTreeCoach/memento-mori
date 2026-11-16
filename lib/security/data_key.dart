import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Length of the data encryption key (AES-256) in bytes.
const int dataKeyLength = 32;

/// Outcome of reading the data encryption key.
///
/// [DataKeyMissing] means "never created" and is the only case in which a
/// new key may be generated. Errors are always [DataKeyUnavailable], so a
/// transient failure can never lead to a fresh key that orphans the data.
sealed class DataKeyResult {
  const DataKeyResult();
}

/// The key exists and has the expected length.
final class DataKeyFound extends DataKeyResult {
  const DataKeyFound(this.bytes);

  final Uint8List bytes;
}

/// No key has been stored yet.
final class DataKeyMissing extends DataKeyResult {
  const DataKeyMissing();
}

/// The key could not be read right now (e.g. keychain before first unlock,
/// a Keystore hiccup) or the stored value is unusable ([corrupt]).
final class DataKeyUnavailable extends DataKeyResult {
  const DataKeyUnavailable(this.error, {this.corrupt = false});

  final Object error;

  /// True when a value exists but cannot be a valid key (bad base64 or
  /// length); retrying will not help.
  final bool corrupt;
}

/// Persists the data encryption key outside the encrypted data.
abstract class DataKeyStore {
  Future<DataKeyResult> read();

  /// Stores [key]; it must be [dataKeyLength] bytes long.
  Future<void> write(List<int> key);

  Future<void> delete();

  /// A fresh random key of [dataKeyLength] bytes.
  static Uint8List newKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(dataKeyLength, (_) => random.nextInt(256)),
    );
  }

  /// Throws an [ArgumentError] unless [key] has [dataKeyLength] bytes.
  static void checkLength(List<int> key) {
    if (key.length != dataKeyLength) {
      throw ArgumentError.value(
        key.length,
        'key.length',
        'must be $dataKeyLength bytes',
      );
    }
  }
}

/// [DataKeyStore] backed by the Android Keystore / iOS Keychain.
class SecureStorageDataKeyStore implements DataKeyStore {
  SecureStorageDataKeyStore({this._storage = defaultStorage});

  /// Storage entry holding the base64 encoded key.
  static const String keyName = 'vault_dek_v1';

  /// `resetOnError: false` is essential: the plugin's default wipes every
  /// entry on any decryption error, which would lose the key for good.
  /// The key never syncs through iCloud Keychain (on iPhone it still travels
  /// with iCloud and encrypted computer backups, like the data) and is
  /// readable after the first unlock
  /// (background widget refreshes, notifications).
  static const FlutterSecureStorage defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
      accountName: 'memento.vault',
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<DataKeyResult> read() async {
    final String? stored;
    try {
      stored = await _storage.read(key: keyName);
    } catch (error) {
      return DataKeyUnavailable(error);
    }
    return stored == null ? const DataKeyMissing() : _decode(stored);
  }

  @override
  Future<void> write(List<int> key) {
    DataKeyStore.checkLength(key);
    return _storage.write(key: keyName, value: base64Encode(key));
  }

  @override
  Future<void> delete() => _storage.delete(key: keyName);

  static DataKeyResult _decode(String stored) {
    final Uint8List bytes;
    try {
      bytes = base64Decode(stored);
    } on FormatException catch (error) {
      return DataKeyUnavailable(error, corrupt: true);
    }
    if (bytes.length != dataKeyLength) {
      return DataKeyUnavailable(
        StateError('stored key has ${bytes.length} bytes'),
        corrupt: true,
      );
    }
    return DataKeyFound(bytes);
  }
}
