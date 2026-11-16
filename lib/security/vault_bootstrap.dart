import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:path_provider/path_provider.dart';

import 'data_key.dart';
import 'personal_store.dart';
import 'vault_personal_store.dart';
import 'vault_storage.dart';

/// Opens the encrypted personal data at app start and makes it the
/// [PersonalStore].
///
/// The store is configured even when it is not ready: a locked store reads
/// nothing and refuses every write, so settings can still load (theme,
/// language) while nothing personal can be overwritten.
class VaultBootstrap {
  VaultBootstrap({
    required this.keys,
    required this.storage,
    this.avatarStore = const AvatarStore(),
    this.attempts = defaultAttempts,
    this.retryDelay = defaultRetryDelay,
    Future<void> Function(Duration delay)? wait,
  }) : _wait = wait ?? Future<void>.delayed;

  /// The app's vault: key in the Keystore/Keychain, records in
  /// `<documents>/vault` (Android `app_flutter/vault`, covered by the
  /// backup rules like the avatars).
  factory VaultBootstrap.production() => VaultBootstrap(
    keys: SecureStorageDataKeyStore(),
    storage: () async => FileVaultStorage(await vaultDirectory()),
  );

  /// Opens tried in total while the vault is [VaultState.unavailable].
  static const int defaultAttempts = 3;
  static const Duration defaultRetryDelay = Duration(milliseconds: 400);

  final DataKeyStore keys;
  final Future<VaultStorage> Function() storage;

  /// Friend photos, deleted together with the data by [startFresh].
  final AvatarStore avatarStore;
  final int attempts;
  final Duration retryDelay;
  final Future<void> Function(Duration delay) _wait;

  /// `<documents>/vault`.
  static Future<Directory> vaultDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}${Platform.pathSeparator}vault');
  }

  /// Opens the vault (retrying briefly while it is unavailable, e.g. a
  /// Keystore hiccup) and configures [PersonalStore] with the result.
  Future<VaultOpenResult> open() async {
    var result = await _openOnce();
    for (var attempt = 1; attempt < attempts; attempt++) {
      if (result.state != VaultState.unavailable) break;
      await _wait(retryDelay);
      result = await _openOnce();
    }
    if (!result.isReady) debugPrint('VaultBootstrap: personal data $result');
    _configure(result.store);
    return result;
  }

  Future<VaultOpenResult> _openOnce() async {
    final VaultStorage records;
    try {
      records = await storage();
    } catch (error) {
      // E.g. the documents directory cannot be resolved right now.
      return VaultPersonalStore.unreachable(error);
    }
    return VaultPersonalStore.open(keys: keys, storage: records);
  }

  /// Deletes the (locked) personal data, its key and every friend photo,
  /// then starts an empty vault and configures [PersonalStore] with it.
  Future<VaultPersonalStore> startFresh() async {
    final store = await VaultPersonalStore.startFresh(
      keys: keys,
      storage: await storage(),
    );
    try {
      await avatarStore.deleteAll();
    } catch (error) {
      // Leftover photos are removed by the next orphan cleanup.
      debugPrint('VaultBootstrap: avatars not deleted (${error.runtimeType})');
    }
    _configure(store);
    return store;
  }

  /// Personal data and friend photos use the same vault (and key); photos
  /// get no cipher while it is not ready.
  static void _configure(VaultPersonalStore store) {
    PersonalStore.configure(store);
    AvatarStore.configureCipher(store.cipher);
  }
}
