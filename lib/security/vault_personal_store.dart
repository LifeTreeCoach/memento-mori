import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'data_key.dart';
import 'personal_store.dart';
import 'vault_cipher.dart';
import 'vault_storage.dart';

/// Whether the vault can be used.
enum VaultState {
  /// Decrypted and writable.
  ready,

  /// Data exists but cannot be opened (wrong/missing key, damaged file).
  /// Nothing is written, so the data stays as it is.
  locked,

  /// The key or the storage cannot be read right now; retrying may help.
  unavailable,
}

/// Why the vault is not [VaultState.ready].
enum VaultIssue {
  none,

  /// A record was sealed with another key.
  wrongKey,

  /// A record is damaged or holds no valid value.
  corrupt,

  /// Records exist but no key is stored.
  missingKey,

  /// The key store could not be read (e.g. before the first unlock).
  keyUnavailable,

  /// The stored key is unusable (bad encoding or length).
  keyCorrupt,

  /// A new key could not be stored and read back identically.
  keyNotSaved,

  /// The record storage could not be read.
  storageError,
}

/// Result of [VaultPersonalStore.open].
class VaultOpenResult {
  const VaultOpenResult._(this.state, this.issue, this.store, [this.error]);

  final VaultState state;
  final VaultIssue issue;

  /// The store; reads return nothing and writes are refused unless
  /// [isReady].
  final VaultPersonalStore store;

  /// The underlying error, if any (for logs; never shown with data).
  final Object? error;

  bool get isReady => state == VaultState.ready;

  /// Whether deleting the data can be the way out: only when it can't be
  /// opened with the key this device holds (wrong, missing or unusable key,
  /// damaged record). Transient issues (key store or storage not readable
  /// right now, e.g. before the first unlock) never offer it.
  bool get mayStartFresh => switch (issue) {
        VaultIssue.wrongKey ||
        VaultIssue.missingKey ||
        VaultIssue.corrupt ||
        VaultIssue.keyCorrupt =>
          true,
        VaultIssue.none ||
        VaultIssue.keyUnavailable ||
        VaultIssue.keyNotSaved ||
        VaultIssue.storageError =>
          false,
      };

  @override
  String toString() => 'VaultOpenResult(${state.name}, ${issue.name})';
}

/// Encrypted [PersonalStore]: one sealed record per key in a [VaultStorage].
///
/// Each record's plaintext is UTF-8 JSON `{"t":"s|i|b|l","v":value}`
/// (string, int, bool, string list), sealed by [VaultCipher] with the key as
/// record name. All values are decrypted by [open] and served from memory;
/// setters update memory at once and persist through a serial write queue
/// per key, so the last call always wins on disk. Keys whose latest write
/// failed are tracked ([hasUnsavedChanges], [retryUnsaved]).
class VaultPersonalStore extends PersonalStore {
  VaultPersonalStore._(this._state, this._cipher, this._storage, this._values);

  VaultPersonalStore._closed(VaultState state)
    : this._(state, null, null, <String, Object>{});

  final VaultState _state;
  final VaultCipher? _cipher;
  final VaultStorage? _storage;
  final Map<String, Object> _values;
  final Map<String, Future<bool>> _writes = {};

  /// Keys whose latest write failed; memory still holds their newest value.
  final Set<String> _unsavedKeys = {};
  final ValueNotifier<bool> _hasUnsavedChanges = ValueNotifier(false);

  /// Record names double as file names, so they are kept simple.
  static final RegExp _validKey = RegExp(r'^[A-Za-z0-9_\-]+$');

  VaultState get state => _state;
  bool get isReady => _state == VaultState.ready;

  /// The cipher with the vault's data key (null unless [isReady]), e.g. to
  /// seal other files such as avatars with the same key.
  VaultCipher? get cipher => _cipher;

  /// Opens the vault, following the safety rules:
  ///
  /// - key found: every record must open with it, else [VaultState.locked]
  ///   ([VaultIssue.wrongKey] / [VaultIssue.corrupt]); nothing is changed.
  /// - key missing: with records on disk -> locked ([VaultIssue.missingKey]);
  ///   with none, a new key is created, stored and verified by reading it
  ///   back (failure -> [VaultState.unavailable]).
  /// - key unavailable: [VaultState.unavailable]; a key is never created.
  static Future<VaultOpenResult> open({
    required DataKeyStore keys,
    required VaultStorage storage,
  }) async {
    final DataKeyResult keyResult;
    try {
      keyResult = await keys.read();
    } catch (error) {
      return _notReady(
        VaultState.unavailable,
        VaultIssue.keyUnavailable,
        error,
      );
    }
    return switch (keyResult) {
      DataKeyFound(:final bytes) => _openWithKey(bytes, storage),
      DataKeyMissing() => _openWithoutKey(keys, storage),
      DataKeyUnavailable(:final error, :final corrupt) => _notReady(
        VaultState.unavailable,
        corrupt ? VaultIssue.keyCorrupt : VaultIssue.keyUnavailable,
        error,
      ),
    };
  }

  /// The result for a vault that cannot be reached at all (e.g. its
  /// directory cannot be resolved): [VaultState.unavailable].
  static VaultOpenResult unreachable(Object error) =>
      _notReady(VaultState.unavailable, VaultIssue.storageError, error);

  /// Deletes every record and the key, then starts an empty vault with a new
  /// key. Throws a [StateError] if the new key cannot be stored.
  static Future<VaultPersonalStore> startFresh({
    required DataKeyStore keys,
    required VaultStorage storage,
  }) async {
    await storage.deleteAll();
    await keys.delete();
    final key = await _createVerifiedKey(keys);
    if (key == null) {
      throw StateError('VaultPersonalStore: the new key could not be saved');
    }
    return _ready(key, storage, {});
  }

  static Future<VaultOpenResult> _openWithKey(
    List<int> key,
    VaultStorage storage,
  ) async {
    final cipher = VaultCipher(key);
    final values = <String, Object>{};
    var issue = VaultIssue.none;
    try {
      for (final name in await storage.names()) {
        final recordIssue = await _loadRecord(cipher, storage, name, values);
        issue = _worse(issue, recordIssue);
      }
    } catch (error) {
      return _notReady(VaultState.unavailable, VaultIssue.storageError, error);
    }
    if (issue != VaultIssue.none) return _notReady(VaultState.locked, issue);
    final store = VaultPersonalStore._(
      VaultState.ready,
      cipher,
      storage,
      values,
    );
    return VaultOpenResult._(VaultState.ready, VaultIssue.none, store);
  }

  /// Decrypts record [name] into [values]; returns what went wrong, if
  /// anything. Storage errors are thrown.
  static Future<VaultIssue> _loadRecord(
    VaultCipher cipher,
    VaultStorage storage,
    String name,
    Map<String, Object> values,
  ) async {
    final bytes = await storage.read(name);
    if (bytes == null) return VaultIssue.none;
    try {
      values[name] = _VaultValue.decode(await cipher.open(name, bytes));
      return VaultIssue.none;
    } on VaultWrongKeyException {
      return VaultIssue.wrongKey;
    } on VaultCorruptException {
      return VaultIssue.corrupt;
    }
  }

  /// A wrong key explains everything else, so it is reported first.
  static VaultIssue _worse(VaultIssue a, VaultIssue b) {
    if (a == VaultIssue.wrongKey || b == VaultIssue.wrongKey) {
      return VaultIssue.wrongKey;
    }
    return a == VaultIssue.none ? b : a;
  }

  static Future<VaultOpenResult> _openWithoutKey(
    DataKeyStore keys,
    VaultStorage storage,
  ) async {
    final List<String> names;
    try {
      names = await storage.names();
    } catch (error) {
      return _notReady(VaultState.unavailable, VaultIssue.storageError, error);
    }
    if (names.isNotEmpty) {
      return _notReady(VaultState.locked, VaultIssue.missingKey);
    }
    final key = await _createVerifiedKey(keys);
    if (key == null) {
      return _notReady(VaultState.unavailable, VaultIssue.keyNotSaved);
    }
    return VaultOpenResult._(
      VaultState.ready,
      VaultIssue.none,
      _ready(key, storage, {}),
    );
  }

  /// Stores a new key and reads it back; null unless both match.
  static Future<Uint8List?> _createVerifiedKey(DataKeyStore keys) async {
    final key = DataKeyStore.newKey();
    try {
      await keys.write(key);
      final stored = await keys.read();
      if (stored is DataKeyFound && listEquals(stored.bytes, key)) return key;
    } catch (error) {
      debugPrint('VaultPersonalStore: saving the key failed: $error');
    }
    return null;
  }

  static VaultPersonalStore _ready(
    List<int> key,
    VaultStorage storage,
    Map<String, Object> values,
  ) =>
      VaultPersonalStore._(VaultState.ready, VaultCipher(key), storage, values);

  static VaultOpenResult _notReady(
    VaultState state,
    VaultIssue issue, [
    Object? error,
  ]) =>
      VaultOpenResult._(state, issue, VaultPersonalStore._closed(state), error);

  // Reads.

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  List<String>? getStringList(String key) =>
      (_values[key] as List<String>?)?.toList();

  @override
  bool containsKey(String key) => _values.containsKey(key);

  // Writes.

  @override
  Future<bool> setString(String key, String value) => _set(key, value);

  @override
  Future<bool> setInt(String key, int value) => _set(key, value);

  @override
  Future<bool> setBool(String key, bool value) => _set(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _set(key, List<String>.unmodifiable(value));

  @override
  Future<bool> remove(String key) async {
    if (!isReady) return false;
    _checkKey(key);
    _values.remove(key);
    return _enqueue(key, null);
  }

  /// Memory is the source of truth (only this store writes the records), so
  /// reloading just waits for pending writes.
  @override
  Future<void> reload() => flush();

  @override
  ValueListenable<bool> get hasUnsavedChanges => _hasUnsavedChanges;

  /// Persists the in-memory value (or absence) of every key whose latest
  /// write failed; true when no key is left unsaved.
  @override
  Future<bool> retryUnsaved() async {
    if (!isReady) return false;
    final keys = _unsavedKeys.toList();
    await Future.wait([for (final key in keys) _enqueue(key, _values[key])]);
    return _unsavedKeys.isEmpty;
  }

  /// Completes when every queued write has reached the storage.
  Future<void> flush() async {
    while (_writes.isNotEmpty) {
      await Future.wait(_writes.values.toList());
    }
  }

  Future<bool> _set(String key, Object value) async {
    if (!isReady) return false;
    _checkKey(key);
    _values[key] = value;
    return _enqueue(key, value);
  }

  /// Persists [value] (null = delete) after the key's previous write.
  Future<bool> _enqueue(String key, Object? value) {
    final previous = _writes[key] ?? Future<bool>.value(true);
    late final Future<bool> next;
    next = previous.then((_) => _persist(key, value)).whenComplete(() {
      if (identical(_writes[key], next)) _writes.remove(key);
    });
    _writes[key] = next;
    return next;
  }

  Future<bool> _persist(String key, Object? value) async {
    try {
      if (value == null) {
        await _storage!.delete(key);
      } else {
        final sealed = await _cipher!.seal(key, _VaultValue.encode(value));
        await _storage!.write(key, sealed);
      }
      _markSaved(key, saved: true);
      return true;
    } catch (error) {
      debugPrint(
        'VaultPersonalStore: writing "$key" failed (${error.runtimeType})',
      );
      _markSaved(key, saved: false);
      return false;
    }
  }

  /// Records the outcome of [key]'s latest write (writes per key are serial).
  void _markSaved(String key, {required bool saved}) {
    final changed = saved ? _unsavedKeys.remove(key) : _unsavedKeys.add(key);
    if (changed) _hasUnsavedChanges.value = _unsavedKeys.isNotEmpty;
  }

  static void _checkKey(String key) {
    if (!_validKey.hasMatch(key)) {
      throw ArgumentError.value(key, 'key', 'only letters, digits, _ and -');
    }
  }
}

/// Typed JSON encoding of one value: `{"t":"s|i|b|l","v":value}`.
abstract final class _VaultValue {
  static const String _string = 's';
  static const String _int = 'i';
  static const String _bool = 'b';
  static const String _list = 'l';

  static List<int> encode(Object value) =>
      utf8.encode(jsonEncode({'t': _typeOf(value), 'v': value}));

  static String _typeOf(Object value) => switch (value) {
    String() => _string,
    int() => _int,
    bool() => _bool,
    List<String>() => _list,
    _ => throw ArgumentError.value(value, 'value', 'unsupported type'),
  };

  /// Throws a [VaultCorruptException] for anything but a valid value.
  static Object decode(List<int> plain) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(plain));
    } on FormatException {
      throw const VaultCorruptException('record is not valid JSON');
    }
    final value = switch (json) {
      {'t': _string, 'v': final String v} => v,
      {'t': _int, 'v': final int v} => v,
      {'t': _bool, 'v': final bool v} => v,
      {'t': _list, 'v': final List<dynamic> v} => _stringList(v),
      _ => null,
    };
    if (value == null) {
      throw const VaultCorruptException('record holds no valid value');
    }
    return value;
  }

  static List<String>? _stringList(List<dynamic> list) =>
      list.every((item) => item is String)
      ? List<String>.unmodifiable(list.cast<String>())
      : null;
}
