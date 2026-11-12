import 'package:flutter/services.dart';

import 'life_table_set.dart';

/// Loads the bundled life tables once, on first use (memoised).
class LifeTableRepository {
  LifeTableRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String assetPath = 'assets/lifespan/wpp2024_lt.bin';

  /// Shared app-wide instance.
  static final LifeTableRepository instance = LifeTableRepository();

  final AssetBundle _bundle;
  Future<LifeTableSet>? _tables;

  Future<LifeTableSet> load() => _tables ??= _loadOnce();

  Future<LifeTableSet> _loadOnce() async {
    try {
      return LifeTableSet.parse(await _bundle.load(assetPath));
    } catch (_) {
      _tables = null; // allow a retry after a failed load
      rethrow;
    }
  }
}
