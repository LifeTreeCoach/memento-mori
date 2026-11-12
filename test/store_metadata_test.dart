import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/money_words.dart';

/// Store listing texts (fastlane, used by Google Play and F-Droid).
const _metadataRoot = 'fastlane/metadata/android';
const _locales = ['de-DE', 'en-US', 'fr-FR', 'es-ES'];

/// Google Play limits, in characters.
const _limits = {
  'title.txt': 30,
  'short_description.txt': 80,
  'full_description.txt': 4000,
};
const _changelogLimit = 500;

File _file(String locale, String name) =>
    File('$_metadataRoot/$locale/$name');

String _read(File file) => file.readAsStringSync().trimRight();

List<File> _changelogs(String locale) =>
    Directory('$_metadataRoot/$locale/changelogs')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.txt'))
        .toList();

/// Every text file of [locale]: the listing texts and all changelogs.
Map<String, String> _textsOf(String locale) => {
      for (final name in _limits.keys) name: _read(_file(locale, name)),
      for (final file in _changelogs(locale))
        file.uri.pathSegments.last: _read(file),
    };

void main() {
  for (final locale in _locales) {
    group(locale, () {
      test('has every listing file and at least one changelog', () {
        for (final name in _limits.keys) {
          expect(_file(locale, name).existsSync(), isTrue, reason: name);
        }
        expect(_changelogs(locale), isNotEmpty);
      });

      test('stays within the store length limits', () {
        for (final MapEntry(key: name, value: limit) in _limits.entries) {
          final length = _read(_file(locale, name)).runes.length;
          expect(length, lessThanOrEqualTo(limit), reason: name);
        }
        for (final file in _changelogs(locale)) {
          expect(_read(file).runes.length, lessThanOrEqualTo(_changelogLimit),
              reason: file.path);
        }
      });

      test('has no money or donation wording', () {
        for (final MapEntry(key: name, value: text)
            in _textsOf(locale).entries) {
          expect(moneyWords.firstMatch(text)?.group(0), isNull, reason: name);
        }
      });
    });
  }

  group('French typography', () {
    final texts = _textsOf('fr-FR');

    test('uses the typographic apostrophe, never a straight one', () {
      for (final MapEntry(key: name, value: text) in texts.entries) {
        expect(text.contains("'"), isFalse, reason: name);
      }
    });

    test('puts a no-break space before : ; ? ! and %', () {
      const noBreak = '  ';
      const marks = ':;?!%';
      for (final MapEntry(key: name, value: text) in texts.entries) {
        for (var i = 0; i < text.length; i++) {
          if (!marks.contains(text[i])) continue;
          if (text[i] == ':' && _isTimeOrUrlColon(text, i)) continue;
          final before = i == 0 ? '' : text[i - 1];
          final ok = before.isNotEmpty &&
              (noBreak.contains(before) || marks.contains(before));
          expect(ok, isTrue, reason: '$name (position $i)');
        }
      }
    });

    test('keeps « » together with their content', () {
      for (final MapEntry(key: name, value: text) in texts.entries) {
        expect(RegExp('«[^  ]').hasMatch(text), isFalse,
            reason: name);
        expect(RegExp('[^  ]»').hasMatch(text), isFalse,
            reason: name);
      }
    });
  });

  test('Spanish opens questions and exclamations with ¿ and ¡', () {
    for (final MapEntry(key: name, value: text) in _textsOf('es-ES').entries) {
      for (final (open, close) in [('¿', '?'), ('¡', '!')]) {
        var start = 0;
        for (var i = text.indexOf(close); i >= 0;
            i = text.indexOf(close, i + 1)) {
          expect(text.substring(start, i).contains(open), isTrue,
              reason: '$name (position $i)');
          start = i + 1;
        }
      }
    }
  });
}

/// "19:00" or "https://": colons that take no space in French either.
bool _isTimeOrUrlColon(String text, int index) {
  bool isDigit(int i) =>
      i >= 0 && i < text.length && '0123456789'.contains(text[i]);
  if (isDigit(index - 1) && isDigit(index + 1)) return true;
  return text.startsWith('//', index + 1);
}
