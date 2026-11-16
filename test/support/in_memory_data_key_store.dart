import 'dart:typed_data';

import 'package:memento_mori_life_in_weeks/security/data_key.dart';

/// [DataKeyStore] kept in memory, for tests.
///
/// Set [forcedResult] to simulate an unavailable or corrupt key.
class InMemoryDataKeyStore implements DataKeyStore {
  InMemoryDataKeyStore([List<int>? key])
    : _key = key == null ? null : Uint8List.fromList(key);

  Uint8List? _key;

  /// When set, [read] returns it instead of the stored key.
  DataKeyResult? forcedResult;

  /// The stored key, if any.
  Uint8List? get key => _key;

  @override
  Future<DataKeyResult> read() async {
    if (forcedResult != null) return forcedResult!;
    final key = _key;
    return key == null ? const DataKeyMissing() : DataKeyFound(key);
  }

  @override
  Future<void> write(List<int> key) async {
    DataKeyStore.checkLength(key);
    _key = Uint8List.fromList(key);
  }

  @override
  Future<void> delete() async => _key = null;
}
