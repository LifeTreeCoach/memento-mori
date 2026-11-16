import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'personal_store.dart';

/// Plaintext [PersonalStore] over `SharedPreferences`.
///
/// **Tests only** (configured in `test/flutter_test_config.dart`): the app
/// keeps personal data in the encrypted `VaultPersonalStore`.
///
/// [reload] re-fetches `SharedPreferences.getInstance()`, because tests call
/// `SharedPreferences.setMockInitialValues` between cases, which replaces
/// the singleton.
@visibleForTesting
class SharedPrefsPersonalStore extends PersonalStore {
  SharedPrefsPersonalStore([this._prefs]);

  SharedPreferences? _prefs;

  SharedPreferences get _loaded {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('SharedPrefsPersonalStore: call reload() first.');
    }
    return prefs;
  }

  Future<SharedPreferences> _ensureLoaded() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<void> reload() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  String? getString(String key) => _loaded.getString(key);

  @override
  int? getInt(String key) => _loaded.getInt(key);

  @override
  bool? getBool(String key) => _loaded.getBool(key);

  @override
  List<String>? getStringList(String key) => _loaded.getStringList(key);

  @override
  bool containsKey(String key) => _loaded.containsKey(key);

  @override
  Future<bool> setString(String key, String value) async =>
      (await _ensureLoaded()).setString(key, value);

  @override
  Future<bool> setInt(String key, int value) async =>
      (await _ensureLoaded()).setInt(key, value);

  @override
  Future<bool> setBool(String key, bool value) async =>
      (await _ensureLoaded()).setBool(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) async =>
      (await _ensureLoaded()).setStringList(key, value);

  @override
  Future<bool> remove(String key) async => (await _ensureLoaded()).remove(key);
}
