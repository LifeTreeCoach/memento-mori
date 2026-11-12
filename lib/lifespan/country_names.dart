import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';

import '../text/fold.dart';

/// Localised location names from `assets/lifespan/countries.json` (CLDR 48),
/// keyed by the life-table codes (ISO 3166-1 alpha-2 plus `WLD` = World).
class CountryNames {
  CountryNames(Map<String, Map<String, String>> names)
    : _names = Map.unmodifiable(names);

  factory CountryNames.parse(String jsonText) {
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    return CountryNames({
      for (final entry in decoded.entries)
        entry.key: Map<String, String>.from(entry.value as Map),
    });
  }

  static const String assetPath = 'assets/lifespan/countries.json';
  static const String worldCode = 'WLD';
  static const String fallbackLanguage = 'en';
  static const List<String> languages = ['en', 'de', 'fr', 'es'];

  static Future<CountryNames>? _loaded;

  /// Loads and memoises the bundled names (first use only).
  static Future<CountryNames> load({AssetBundle? bundle}) => _loaded ??=
      (bundle ?? rootBundle).loadString(assetPath).then(CountryNames.parse);

  final Map<String, Map<String, String>> _names;

  Iterable<String> get codes => _names.keys;

  bool contains(String? code) => code != null && _names.containsKey(code);

  /// Name of [code] in [language] (fallback English, then the code itself).
  String name(String code, String language) {
    final names = _names[code];
    if (names == null) return code;
    return names[language] ?? names[fallbackLanguage] ?? code;
  }

  /// All codes sorted by their name in [language], ignoring case and accents
  /// (so "Österreich" sorts under O). `WLD` comes first: it is the neutral
  /// "not listed / prefer not to say" choice and the fallback for unknown
  /// countries, so it should be found without scrolling to "W"/"M".
  List<String> sortedCodes(String language) {
    final keyed =
        [
          for (final code in _names.keys)
            if (code != worldCode)
              (code: code, key: foldForSort(name(code, language))),
        ]..sort((a, b) {
          final byKey = a.key.compareTo(b.key);
          return byKey != 0 ? byKey : a.code.compareTo(b.code);
        });
    return [
      if (_names.containsKey(worldCode)) worldCode,
      ...keyed.map((entry) => entry.code),
    ];
  }

  /// The device's region if the table has it (never `WLD`), else null.
  String? deviceCountry({String? countryCode}) {
    final code = (countryCode ?? PlatformDispatcher.instance.locale.countryCode)
        ?.toUpperCase();
    if (code == null || code == worldCode || !_names.containsKey(code)) {
      return null;
    }
    return code;
  }

  /// Lower-cases and strips Latin diacritics for an accent-insensitive sort.
  /// Delegates to the shared [foldText].
  static String foldForSort(String text) => foldText(text);
}
