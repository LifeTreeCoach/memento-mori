import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/country_names.dart';

void main() {
  final names = CountryNames.parse(
    File('assets/lifespan/countries.json').readAsStringSync(),
  );

  test('names per language with English fallback', () {
    expect(names.name('DE', 'en'), 'Germany');
    expect(names.name('DE', 'de'), 'Deutschland');
    expect(names.name('DE', 'fr'), 'Allemagne');
    expect(names.name('DE', 'es'), 'Alemania');
    expect(names.name('DE', 'xx'), 'Germany');
    expect(names.name('ZZ', 'en'), 'ZZ');
    expect(names.name('WLD', 'de'), 'Welt');
  });

  test('sortedCodes: WLD first, then accent-insensitive by name', () {
    for (final language in CountryNames.languages) {
      final codes = names.sortedCodes(language);
      expect(codes.first, 'WLD');
      expect(codes, hasLength(238));
      final keys = codes
          .skip(1)
          .map((c) => CountryNames.foldForSort(names.name(c, language)));
      final list = keys.toList();
      for (var i = 1; i < list.length; i++) {
        expect(list[i - 1].compareTo(list[i]), lessThanOrEqualTo(0));
      }
    }
    final german = names.sortedCodes('de');
    // Österreich sorts under O, between Oman and Pakistan.
    expect(german.indexOf('AT'), greaterThan(german.indexOf('OM')));
    expect(german.indexOf('AT'), lessThan(german.indexOf('PK')));
  });

  test('foldForSort strips accents and case', () {
    expect(CountryNames.foldForSort('Émirats'), 'emirats');
    expect(CountryNames.foldForSort('Österreich'), 'osterreich');
  });

  test('deviceCountry only returns codes in the table', () {
    expect(names.deviceCountry(countryCode: 'DE'), 'DE');
    expect(names.deviceCountry(countryCode: 'de'), 'DE');
    expect(names.deviceCountry(countryCode: 'ZZ'), isNull);
    expect(names.deviceCountry(countryCode: 'WLD'), isNull);
  });
}
