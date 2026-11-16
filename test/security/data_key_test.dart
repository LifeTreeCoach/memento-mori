import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/security/data_key.dart';

import '../support/in_memory_data_key_store.dart';

/// In-memory platform that records the options and can fail on demand.
class _FakeSecureStorage extends TestFlutterSecureStoragePlatform {
  _FakeSecureStorage() : super({});

  Object? readError;
  Map<String, String>? lastOptions;

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    lastOptions = options;
    if (readError != null) throw readError!;
    return super.read(key: key, options: options);
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    lastOptions = options;
    return super.write(key: key, value: value, options: options);
  }
}

void main() {
  late _FakeSecureStorage platform;
  late SecureStorageDataKeyStore store;
  const keyName = SecureStorageDataKeyStore.keyName;

  setUp(() {
    platform = _FakeSecureStorage();
    FlutterSecureStoragePlatform.instance = platform;
    store = SecureStorageDataKeyStore();
  });

  test('absent entry reads as missing', () async {
    expect(await store.read(), isA<DataKeyMissing>());
  });

  test('written key reads back as found', () async {
    final key = DataKeyStore.newKey();
    await store.write(key);
    expect(platform.data[keyName], base64Encode(key));
    final result = await store.read();
    expect(result, isA<DataKeyFound>());
    expect((result as DataKeyFound).bytes, key);
  });

  test('a platform exception reads as unavailable, never missing', () async {
    platform.readError = PlatformException(code: 'KeychainLocked');
    final result = await store.read();
    expect(result, isA<DataKeyUnavailable>());
    expect((result as DataKeyUnavailable).corrupt, isFalse);
    expect(result.error, isA<PlatformException>());
  });

  test('any other error reads as unavailable too', () async {
    platform.readError = StateError('Keystore hiccup');
    expect(await store.read(), isA<DataKeyUnavailable>());
  });

  test('a stored value of the wrong length is corrupt, not missing', () async {
    platform.data[keyName] = base64Encode(List.filled(16, 7));
    final result = await store.read();
    expect(result, isA<DataKeyUnavailable>());
    expect((result as DataKeyUnavailable).corrupt, isTrue);
  });

  test('a stored value that is not base64 is corrupt', () async {
    platform.data[keyName] = 'not base64!';
    final result = await store.read();
    expect((result as DataKeyUnavailable).corrupt, isTrue);
  });

  test('write rejects keys that are not 32 bytes', () async {
    expect(() => store.write(List.filled(31, 1)), throwsArgumentError);
    expect(platform.data, isEmpty);
  });

  test('delete removes the key', () async {
    await store.write(DataKeyStore.newKey());
    await store.delete();
    expect(await store.read(), isA<DataKeyMissing>());
  });

  test('Android never resets the storage on errors', () async {
    await store.read();
    expect(platform.lastOptions!['resetOnError'], 'false');
  });

  test(
    'iOS keeps the key on this device, readable after first unlock',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await store.write(DataKeyStore.newKey());
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      expect(
        platform.lastOptions,
        containsPair('accessibility', 'first_unlock'),
      );
      expect(platform.lastOptions, containsPair('synchronizable', 'false'));
      expect(
        platform.lastOptions,
        containsPair('accountName', 'memento.vault'),
      );
    },
  );

  group('InMemoryDataKeyStore', () {
    test('starts missing, then finds the written key', () async {
      final memory = InMemoryDataKeyStore();
      expect(await memory.read(), isA<DataKeyMissing>());
      final key = DataKeyStore.newKey();
      await memory.write(key);
      expect((await memory.read() as DataKeyFound).bytes, key);
    });

    test('forcedResult simulates an unavailable key', () async {
      final memory = InMemoryDataKeyStore(DataKeyStore.newKey())
        ..forcedResult = DataKeyUnavailable(StateError('locked'));
      expect(await memory.read(), isA<DataKeyUnavailable>());
    });
  });
}
