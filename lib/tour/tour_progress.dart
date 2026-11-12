import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which product tours were seen, stored as `{"seen":[...],"v":1}` under
/// [key]. Reading is tolerant: anything unreadable counts as "none seen".
class TourProgressStore {
  TourProgressStore._();

  static const String key = 'product_tours';
  static const int version = 1;

  static Set<String> _seen = <String>{};
  static bool _isInitialized = false;

  /// Bumped after every change, so screens can react.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Loads the stored ids once.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _seen = decode(prefs.getString(key));
    _isInitialized = true;
  }

  /// Drops the in-memory cache so the next [initialize] re-reads storage.
  @visibleForTesting
  static void clearCacheForTesting() {
    _seen = <String>{};
    _isInitialized = false;
  }

  /// Whether tour [id] was seen (after [initialize]).
  static bool isSeen(String id) => _seen.contains(id);

  static Future<void> markSeen(String id) async {
    await initialize();
    if (!_seen.add(id)) return;
    await _persist();
  }

  /// Forgets every tour (diagnostics).
  static Future<void> reset() async {
    _seen = <String>{};
    _isInitialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    revision.value++;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, encode(_seen));
    revision.value++;
  }

  /// `{"seen":[...sorted],"v":1}`.
  static String encode(Set<String> seen) =>
      jsonEncode({'seen': seen.toList()..sort(), 'v': version});

  /// The seen ids in [source]; empty for null, bad JSON or a bad shape.
  static Set<String> decode(String? source) {
    if (source == null) return <String>{};
    try {
      final json = jsonDecode(source);
      final seen = json is Map ? json['seen'] : null;
      if (seen is! List) return <String>{};
      return seen.whereType<String>().toSet();
    } on FormatException catch (e) {
      debugPrint('Error loading product tours: $e');
      return <String>{};
    }
  }
}
