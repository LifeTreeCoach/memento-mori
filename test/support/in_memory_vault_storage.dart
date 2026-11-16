import 'dart:typed_data';

import 'package:memento_mori_life_in_weeks/security/vault_storage.dart';

/// [VaultStorage] kept in memory, for tests.
///
/// Set [failWrites] to simulate a full or read-only disk.
class InMemoryVaultStorage implements VaultStorage {
  final Map<String, Uint8List> records = {};

  /// When true, [write] and [delete] throw.
  bool failWrites = false;

  /// Number of [write] calls that reached the storage.
  int writeCount = 0;

  @override
  Future<List<String>> names() async => records.keys.toList()..sort();

  @override
  Future<Uint8List?> read(String name) async {
    final bytes = records[name];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    if (failWrites) throw StateError('write failed');
    writeCount++;
    records[name] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> delete(String name) async {
    if (failWrites) throw StateError('delete failed');
    records.remove(name);
  }

  @override
  Future<void> deleteAll() async => records.clear();
}
