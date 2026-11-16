import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/security/data_key.dart';
import 'package:memento_mori_life_in_weeks/security/vault_cipher.dart';
import 'package:memento_mori_life_in_weeks/security/vault_personal_store.dart';

import '../support/in_memory_data_key_store.dart';
import '../support/in_memory_vault_storage.dart';

void main() {
  setUpAll(() => Cryptography.instance = DartCryptography.defaultInstance);

  late InMemoryDataKeyStore keys;
  late InMemoryVaultStorage storage;

  setUp(() {
    keys = InMemoryDataKeyStore();
    storage = InMemoryVaultStorage();
  });

  Future<VaultOpenResult> openVault() =>
      VaultPersonalStore.open(keys: keys, storage: storage);

  Future<VaultPersonalStore> openReady() async {
    final result = await openVault();
    expect(result.state, VaultState.ready, reason: '$result');
    return result.store;
  }

  Map<String, Uint8List> snapshot() => {
    for (final entry in storage.records.entries)
      entry.key: Uint8List.fromList(entry.value),
  };

  group('round trip', () {
    test('every type survives a re-open with the same key', () async {
      final store = await openReady();
      await store.setString('user_name', 'Ada');
      await store.setInt('life_expectancy_years', 87);
      await store.setBool('flag', false);
      await store.setStringList('list', ['a', 'b', '']);
      await store.setString('empty', '');

      final reopened = await openReady();
      expect(reopened.getString('user_name'), 'Ada');
      expect(reopened.getInt('life_expectancy_years'), 87);
      expect(reopened.getBool('flag'), isFalse);
      expect(reopened.getStringList('list'), ['a', 'b', '']);
      expect(reopened.getString('empty'), '');
      expect(reopened.containsKey('flag'), isTrue);
      expect(reopened.containsKey('nothing'), isFalse);
    });

    test('remove deletes the record', () async {
      final store = await openReady();
      await store.setString('birth_date', '1990-03-15');
      expect(await store.remove('birth_date'), isTrue);

      expect(store.containsKey('birth_date'), isFalse);
      expect(storage.records, isEmpty);
      expect((await openReady()).getString('birth_date'), isNull);
    });

    test('setters update memory before the write completes', () async {
      final store = await openReady();
      final write = store.setString('user_name', 'Ada');
      expect(store.getString('user_name'), 'Ada');
      expect(await write, isTrue);
    });

    test('returned lists are copies', () async {
      final store = await openReady();
      final input = ['a'];
      await store.setStringList('list', input);
      input.add('b');
      store.getStringList('list')!.add('c');
      expect(store.getStringList('list'), ['a']);
    });

    test('serial writes keep the last value', () async {
      final store = await openReady();
      final writes = [
        for (var i = 0; i < 20; i++) store.setInt('counter', i),
        store.remove('counter'),
        store.setInt('counter', 99),
      ];
      await store.flush();
      expect(await Future.wait(writes), everyElement(isTrue));
      expect((await openReady()).getInt('counter'), 99);
    });

    test('a failed write returns false', () async {
      final store = await openReady();
      storage.failWrites = true;
      expect(await store.setString('user_name', 'Ada'), isFalse);
    });

    test('a failed write keeps the value in memory and flags it', () async {
      final store = await openReady();
      storage.failWrites = true;
      await store.setString('user_name', 'Ada');

      expect(store.getString('user_name'), 'Ada');
      expect(store.hasUnsavedChanges.value, isTrue);
    });

    test('retryUnsaved persists the latest value and clears the flag',
        () async {
      final store = await openReady();
      storage.failWrites = true;
      await store.setString('user_name', 'Ada');
      await store.setString('user_name', 'Grace');
      await store.setString('birth_date', '1990-03-15');
      await store.remove('birth_date');

      expect(await store.retryUnsaved(), isFalse, reason: 'still failing');
      expect(store.hasUnsavedChanges.value, isTrue);

      storage.failWrites = false;
      expect(await store.retryUnsaved(), isTrue);
      expect(store.hasUnsavedChanges.value, isFalse);
      final reopened = await openReady();
      expect(reopened.getString('user_name'), 'Grace');
      expect(reopened.containsKey('birth_date'), isFalse);
    });

    test('a later successful write of the key clears the flag', () async {
      final store = await openReady();
      storage.failWrites = true;
      await store.setString('user_name', 'Ada');
      await store.setString('birth_date', '1990-03-15');
      storage.failWrites = false;

      await store.setString('user_name', 'Grace');
      expect(store.hasUnsavedChanges.value, isTrue, reason: 'birth_date');
      await store.setString('birth_date', '1990-03-16');
      expect(store.hasUnsavedChanges.value, isFalse);
    });

    test('notifies only when the flag changes', () async {
      final store = await openReady();
      var notified = 0;
      store.hasUnsavedChanges.addListener(() => notified++);
      storage.failWrites = true;
      await store.setString('user_name', 'Ada');
      await store.setString('user_name', 'Grace');
      expect(notified, 1);
      storage.failWrites = false;
      await store.retryUnsaved();
      expect(notified, 2);
    });

    test('rejects keys that are no simple file names', () async {
      final store = await openReady();
      expect(() => store.setString('../x', 'y'), throwsArgumentError);
    });
  });

  group('plaintext never reaches the storage', () {
    test('a marker string is absent from the stored bytes', () async {
      const marker = 'SECRET-MARKER-4711';
      final store = await openReady();
      await store.setString('friends_data', '{"name":"$marker"}');
      await store.setStringList('list', [marker]);

      final markerBytes = utf8.encode(marker);
      for (final bytes in storage.records.values) {
        expect(VaultCipher.looksSealed(bytes), isTrue);
        expect(_contains(bytes, markerBytes), isFalse);
        expect(_contains(bytes, utf8.encode('"t"')), isFalse);
      }
    });
  });

  group('open: safety rules', () {
    test('no key and no records creates and stores a key', () async {
      final result = await openVault();
      expect(result.state, VaultState.ready);
      expect(keys.key, hasLength(dataKeyLength));
      expect(result.store.cipher, isNotNull);
      expect(result.store.getString('birth_date'), isNull);
    });

    test('records without a key are locked and nothing changes', () async {
      final store = await openReady();
      await store.setString('birth_date', '1990-03-15');
      await keys.delete();
      final before = snapshot();

      final result = await openVault();
      expect(result.state, VaultState.locked);
      expect(result.issue, VaultIssue.missingKey);
      expect(result.mayStartFresh, isTrue);
      expect(keys.key, isNull);
      expect(storage.records, before);
    });

    test('an unavailable key never creates a key', () async {
      keys.forcedResult = DataKeyUnavailable(StateError('locked keychain'));

      final result = await openVault();
      expect(result.state, VaultState.unavailable);
      expect(result.issue, VaultIssue.keyUnavailable);
      expect(result.mayStartFresh, isFalse, reason: 'transient');
      expect(keys.key, isNull);
      expect(storage.writeCount, 0);
    });

    test('a corrupt stored key is unavailable, not replaced', () async {
      final original = DataKeyStore.newKey();
      await keys.write(original);
      keys.forcedResult = DataKeyUnavailable(
        const FormatException('bad'),
        corrupt: true,
      );

      final result = await openVault();
      expect(result.state, VaultState.unavailable);
      expect(result.issue, VaultIssue.keyCorrupt);
      expect(result.mayStartFresh, isTrue);
      expect(keys.key, original);
    });

    test('a wrong key is locked and leaves the records untouched', () async {
      final store = await openReady();
      await store.setString('birth_date', '1990-03-15');
      await store.setInt('life_expectancy_years', 80);
      final before = snapshot();
      await keys.write(DataKeyStore.newKey());

      final result = await openVault();
      expect(result.state, VaultState.locked);
      expect(result.issue, VaultIssue.wrongKey);
      expect(result.mayStartFresh, isTrue);
      expect(storage.records, before);
    });

    test('a damaged record is locked and not overwritten', () async {
      final store = await openReady();
      await store.setString('birth_date', '1990-03-15');
      final damaged = storage.records['birth_date']!..last ^= 0x01;
      final before = snapshot();

      final result = await openVault();
      expect(result.state, VaultState.locked);
      expect(result.issue, VaultIssue.corrupt);
      expect(storage.records, before);
      expect(result.mayStartFresh, isTrue);
      expect(storage.records['birth_date'], damaged);
    });

    test('a record holding no valid value is corrupt', () async {
      final store = await openReady();
      final cipher = store.cipher!;
      storage.records['x'] = await cipher.seal('x', utf8.encode('{"t":"q"}'));

      final result = await openVault();
      expect(result.state, VaultState.locked);
      expect(result.issue, VaultIssue.corrupt);
    });

    test('a record renamed to another key is corrupt', () async {
      final store = await openReady();
      await store.setString('user_name', 'Ada');
      storage.records['birth_date'] = storage.records.remove('user_name')!;

      expect((await openVault()).issue, VaultIssue.corrupt);
    });

    test('a key that does not read back is unavailable', () async {
      final flaky = _ForgetfulKeyStore();
      final result = await VaultPersonalStore.open(
        keys: flaky,
        storage: storage,
      );
      expect(result.state, VaultState.unavailable);
      expect(result.issue, VaultIssue.keyNotSaved);
      expect(result.mayStartFresh, isFalse, reason: 'transient');
    });
  });

  group('not ready', () {
    test('a locked store refuses writes without any I/O', () async {
      final store = await openReady();
      await store.setString('birth_date', '1990-03-15');
      await keys.write(DataKeyStore.newKey());
      final writesBefore = storage.writeCount;
      final before = snapshot();

      final locked = (await openVault()).store;
      expect(locked.isReady, isFalse);
      expect(locked.cipher, isNull);
      expect(await locked.setString('birth_date', '2000-01-01'), isFalse);
      expect(await locked.setInt('x', 1), isFalse);
      expect(await locked.setBool('x', true), isFalse);
      expect(await locked.setStringList('x', const []), isFalse);
      expect(await locked.remove('birth_date'), isFalse);
      expect(locked.getString('birth_date'), isNull);
      expect(storage.writeCount, writesBefore);
      expect(storage.records, before);
    });
  });

  group('startFresh', () {
    test('wipes records and key and starts empty with a new key', () async {
      final store = await openReady();
      await store.setString('birth_date', '1990-03-15');
      final oldKey = keys.key;
      await keys.write(DataKeyStore.newKey()); // now locked (wrong key)
      expect((await openVault()).state, VaultState.locked);

      final fresh = await VaultPersonalStore.startFresh(
        keys: keys,
        storage: storage,
      );
      expect(fresh.isReady, isTrue);
      expect(fresh.containsKey('birth_date'), isFalse);
      expect(storage.records, isEmpty);
      expect(keys.key, isNot(oldKey));

      await fresh.setString('user_name', 'Ada');
      expect((await openReady()).getString('user_name'), 'Ada');
    });
  });
}

/// Accepts a key but reads back a different one.
class _ForgetfulKeyStore implements DataKeyStore {
  @override
  Future<DataKeyResult> read() async => _stored == null
      ? const DataKeyMissing()
      : DataKeyFound(DataKeyStore.newKey());

  Uint8List? _stored;

  @override
  Future<void> write(List<int> key) async => _stored = Uint8List.fromList(key);

  @override
  Future<void> delete() async => _stored = null;
}

bool _contains(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length && match; j++) {
      match = haystack[i + j] == needle[j];
    }
    if (match) return true;
  }
  return false;
}
