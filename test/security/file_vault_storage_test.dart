import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/security/vault_personal_store.dart';
import 'package:memento_mori_life_in_weeks/security/vault_storage.dart';

import '../support/in_memory_data_key_store.dart';

void main() {
  late Directory dir;
  late FileVaultStorage storage;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vault_storage_test');
    storage = FileVaultStorage(Directory('${dir.path}/vault'));
  });

  tearDown(() => dir.delete(recursive: true));

  File fileIn(String name) => File('${storage.dir.path}/$name');

  test('a missing directory has no records', () async {
    expect(await storage.names(), isEmpty);
    expect(await storage.read('x'), isNull);
  });

  test('writes <name>.bin and reads it back', () async {
    await storage.write('friends_data', [1, 2, 3]);
    expect(fileIn('friends_data.bin').existsSync(), isTrue);
    expect(await storage.read('friends_data'), [1, 2, 3]);
    expect(await storage.names(), ['friends_data']);
  });

  test('a write replaces the record and leaves no temp file', () async {
    await storage.write('a', [1]);
    await storage.write('a', [2, 2]);
    expect(await storage.read('a'), [2, 2]);
    expect(fileIn('a.bin.tmp').existsSync(), isFalse);
  });

  test('stray temp files are ignored and deleted', () async {
    await storage.write('a', [1]);
    fileIn('b.bin.tmp').writeAsBytesSync([9]);
    fileIn('a.bin.tmp').writeAsBytesSync([9, 9]);

    expect(await storage.names(), ['a']);
    expect(fileIn('b.bin.tmp').existsSync(), isFalse);
    expect(fileIn('a.bin.tmp').existsSync(), isFalse);
    expect(await storage.read('a'), [1]);
  });

  test('other files are ignored', () async {
    await storage.write('a', [1]);
    fileIn('notes.txt').writeAsStringSync('x');
    expect(await storage.names(), ['a']);
  });

  test('delete removes one record; missing is fine', () async {
    await storage.write('a', [1]);
    await storage.write('b', [2]);
    await storage.delete('a');
    await storage.delete('never');
    expect(await storage.names(), ['b']);
  });

  test('deleteAll removes records and temp files only', () async {
    await storage.write('a', [1]);
    fileIn('b.bin.tmp').writeAsBytesSync([9]);
    fileIn('notes.txt').writeAsStringSync('x');
    await storage.deleteAll();
    expect(await storage.names(), isEmpty);
    expect(fileIn('b.bin.tmp').existsSync(), isFalse);
    expect(fileIn('notes.txt').existsSync(), isTrue);
  });

  test('a vault on files survives a re-open', () async {
    Cryptography.instance = DartCryptography.defaultInstance;
    final keys = InMemoryDataKeyStore();
    final first = await VaultPersonalStore.open(keys: keys, storage: storage);
    await first.store.setString('birth_date', '1990-03-15');

    final again = await VaultPersonalStore.open(
      keys: keys,
      storage: FileVaultStorage(storage.dir),
    );
    expect(again.state, VaultState.ready);
    expect(again.store.getString('birth_date'), '1990-03-15');
  });
}
