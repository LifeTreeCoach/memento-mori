import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/security/data_key.dart';

/// The Android backup agent reads and writes the data key without Flutter
/// (VaultKeyStorage.kt). Its hard-coded option map must equal what Dart sends
/// for [SecureStorageDataKeyStore.defaultStorage], or the plugin would use
/// other prefs or a key prefix, or migrate the entry.
const _kotlinSource = 'android/app/src/main/kotlin/lifetree/coach/'
    'memento_mori_life_in_weeks/backup/VaultKeyStorage.kt';

/// The `"key" to "value"` pairs of the `OPTIONS` map literal.
Map<String, String> _kotlinOptions() {
  final source = File(_kotlinSource).readAsStringSync();
  final literal = RegExp(
    r'val OPTIONS: Map<String, Any> = mapOf\((.*?)\n\s*\)',
    dotAll: true,
  ).firstMatch(source);
  expect(literal, isNotNull, reason: 'OPTIONS = mapOf(...) in $_kotlinSource');
  return {
    for (final m in RegExp(r'"([^"]*)"\s+to\s+"([^"]*)"')
        .allMatches(literal!.group(1)!))
      m.group(1)!: m.group(2)!,
  };
}

void main() {
  test('VaultKeyStorage.OPTIONS equals the Dart AndroidOptions map', () {
    final dart = SecureStorageDataKeyStore.defaultStorage.aOptions.toMap();
    expect(_kotlinOptions(), dart);
  });

  test('the Kotlin key name is the Dart one', () {
    final source = File(_kotlinSource).readAsStringSync();
    expect(
      source,
      contains('KEY_NAME = "${SecureStorageDataKeyStore.keyName}"'),
    );
  });

  test('flutter_secure_storage is pinned to the version both sides assume',
      () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final pinned = RegExp(r'^  flutter_secure_storage: (\S+)$', multiLine: true)
        .firstMatch(pubspec)
        ?.group(1);
    expect(pinned, '11.2.0', reason: 'exact pin, no caret');

    final lock = File('pubspec.lock').readAsStringSync();
    final locked = RegExp(
      r'^  flutter_secure_storage:\n(?:    .*\n)*?    version: "([^"]+)"',
      multiLine: true,
    ).firstMatch(lock)?.group(1);
    expect(locked, pinned);
    expect(File(_kotlinSource).readAsStringSync(), contains('of flutter_secure_storage $pinned'));
  });
}
