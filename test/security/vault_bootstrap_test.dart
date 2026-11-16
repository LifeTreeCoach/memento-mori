import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/security/data_key.dart';
import 'package:memento_mori_life_in_weeks/security/personal_store.dart';
import 'package:memento_mori_life_in_weeks/security/shared_prefs_personal_store.dart';
import 'package:memento_mori_life_in_weeks/security/vault_bootstrap.dart';
import 'package:memento_mori_life_in_weeks/security/vault_personal_store.dart';
import 'package:memento_mori_life_in_weeks/security/vault_storage.dart';

import '../support/in_memory_data_key_store.dart';
import '../support/in_memory_vault_storage.dart';

/// Key store whose first [failingReads] reads are unavailable.
class _FlakyKeyStore extends InMemoryDataKeyStore {
  _FlakyKeyStore({required this.failingReads});

  int failingReads;
  int reads = 0;

  @override
  Future<DataKeyResult> read() {
    reads++;
    if (failingReads > 0) {
      failingReads--;
      return Future.value(DataKeyUnavailable(StateError('keystore busy')));
    }
    return super.read();
  }
}

void main() {
  setUpAll(() => Cryptography.instance = DartCryptography.defaultInstance);

  late InMemoryVaultStorage storage;
  late Directory documents;
  late List<Duration> waits;

  setUp(() async {
    storage = InMemoryVaultStorage();
    documents = await Directory.systemTemp.createTemp('vault_bootstrap');
    waits = [];
  });

  tearDown(() async {
    PersonalStore.configure(SharedPrefsPersonalStore());
    AvatarStore.configureCipher(null);
    await documents.delete(recursive: true);
  });

  VaultBootstrap bootstrap(DataKeyStore keys, {VaultStorage? records}) =>
      VaultBootstrap(
        keys: keys,
        storage: () async => records ?? storage,
        avatarStore: AvatarStore(baseDirectory: () async => documents),
        wait: (delay) async => waits.add(delay),
      );

  /// A vault holding a birth date, sealed with the key in [keys].
  Future<void> seedVault(InMemoryDataKeyStore keys) async {
    final result = await VaultPersonalStore.open(keys: keys, storage: storage);
    await result.store.setString(PersonalKeys.birthDate, '1990-03-15');
  }

  test('ready: friend photos are sealed with the vault\'s cipher', () async {
    final keys = InMemoryDataKeyStore();
    await seedVault(keys);

    final result = await bootstrap(keys).open();

    expect(result.store.cipher, isNotNull);
    expect(AvatarStore.configuredCipher, same(result.store.cipher));
  });

  test('ready: configures the opened vault as the personal store', () async {
    final keys = InMemoryDataKeyStore();
    await seedVault(keys);

    final result = await bootstrap(keys).open();

    expect(result.state, VaultState.ready);
    expect(PersonalStore.instance, same(result.store));
    expect(
      PersonalStore.instance.getString(PersonalKeys.birthDate),
      '1990-03-15',
    );
    expect(waits, isEmpty);
  });

  test('first start: creates a key and an empty, writable vault', () async {
    final keys = InMemoryDataKeyStore();

    final result = await bootstrap(keys).open();

    expect(result.isReady, isTrue);
    expect(keys.key, isNotNull);
    expect(await PersonalStore.instance.setString('user_name', 'Ada'), isTrue);
  });

  test('locked: configures a store that reads nothing and writes nothing',
      () async {
    await seedVault(InMemoryDataKeyStore());
    final before = Map.of(storage.records);

    final result = await bootstrap(InMemoryDataKeyStore()).open();

    expect(result.state, VaultState.locked);
    expect(result.issue, VaultIssue.missingKey);
    expect(PersonalStore.instance, same(result.store));
    expect(AvatarStore.configuredCipher, isNull);
    expect(PersonalStore.instance.getString(PersonalKeys.birthDate), isNull);
    expect(
      await PersonalStore.instance.setString(PersonalKeys.birthDate, 'x'),
      isFalse,
    );
    expect(storage.records, before);
    expect(waits, isEmpty, reason: 'a locked vault is not retried');
  });

  test('unavailable: retried briefly, then opens', () async {
    final keys = _FlakyKeyStore(failingReads: 2);

    final result = await bootstrap(keys).open();

    expect(result.isReady, isTrue);
    expect(keys.reads, greaterThanOrEqualTo(3));
    expect(waits, hasLength(2));
  });

  test('unavailable: gives up after the attempts, never creates a key',
      () async {
    final keys = InMemoryDataKeyStore()
      ..forcedResult = DataKeyUnavailable(StateError('keystore busy'));

    final result = await bootstrap(keys).open();

    expect(result.state, VaultState.unavailable);
    expect(result.issue, VaultIssue.keyUnavailable);
    expect(waits, hasLength(VaultBootstrap.defaultAttempts - 1));
    expect(keys.key, isNull);
    expect(PersonalStore.instance.getString(PersonalKeys.birthDate), isNull);
  });

  test('unavailable when the storage cannot be resolved', () async {
    final failing = VaultBootstrap(
      keys: InMemoryDataKeyStore(),
      storage: () async => throw const FileSystemException('no documents'),
      wait: (delay) async => waits.add(delay),
    );

    final result = await failing.open();

    expect(result.state, VaultState.unavailable);
    expect(result.issue, VaultIssue.storageError);
    expect(result.mayStartFresh, isFalse, reason: 'transient');
  });

  test('start fresh deletes the locked data and the photos', () async {
    await seedVault(InMemoryDataKeyStore());
    final avatars = Directory('${documents.path}/avatars')..createSync();
    File('${avatars.path}/avatar_1.jpg').writeAsBytesSync([1, 2, 3]);
    final keys = InMemoryDataKeyStore();
    final vault = bootstrap(keys);
    expect((await vault.open()).state, VaultState.locked);

    final store = await vault.startFresh();

    expect(store.isReady, isTrue);
    expect(PersonalStore.instance, same(store));
    expect(AvatarStore.configuredCipher, same(store.cipher));
    expect(storage.records, isEmpty);
    expect(avatars.existsSync(), isFalse);
    expect(keys.key, isNotNull);
    expect(await store.setString('user_name', 'Ada'), isTrue);
    expect((await vault.open()).isReady, isTrue, reason: 'reopens with key');
  });
}
