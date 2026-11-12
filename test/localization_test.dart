import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompts.dart';
import 'package:memento_mori_life_in_weeks/l10n/reflection_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/week_moment_strings.dart';
import 'package:memento_mori_life_in_weeks/life/quotes/quote_data.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

void main() {
  const languages = AppLocalizations.supportedLanguages;
  final placeholder = RegExp(r'\{(\w+)\}');
  Set<String> names(String? s) =>
      placeholder.allMatches(s ?? '').map((m) => m.group(1)!).toSet();

  group('supported languages', () {
    test('English is supported and listed first (fallback language)', () {
      expect(languages.first, 'en');
    });

    test('every supported language has a string table and a name', () {
      for (final code in languages) {
        expect(AppLocalizations.keysByLanguage.keys, contains(code));
        expect(AppLocalizations.languageNames[code], isNotNull, reason: code);
      }
    });

    test('names of the upcoming languages are their endonyms', () {
      expect(AppLocalizations.languageNames['fr'], 'Français');
      expect(AppLocalizations.languageNames['es'], 'Español');
    });

    test('the delegate supports exactly the supported languages', () {
      const delegate = AppLocalizationsDelegate();
      for (final code in languages) {
        expect(delegate.isSupported(Locale(code)), isTrue, reason: code);
      }
      expect(delegate.isSupported(const Locale('it')), isFalse);
    });
  });

  group('parity with English', () {
    final en = AppLocalizations.valuesFor('en');
    for (final code in languages.where((code) => code != 'en')) {
      test('$code has exactly the English keys', () {
        final keys = AppLocalizations.valuesFor(code).keys.toSet();
        expect(en.keys.toSet().difference(keys), isEmpty,
            reason: 'missing in $code');
        expect(keys.difference(en.keys.toSet()), isEmpty,
            reason: 'missing in en');
      });

      test('$code placeholders match English', () {
        final values = AppLocalizations.valuesFor(code);
        for (final key in en.keys) {
          expect(names(values[key]), names(en[key]), reason: '$code: $key');
        }
      });
    }
  });

  group('plural', () {
    String suffix(int count, String code, {bool hasZero = false}) =>
        AppLocalizations.pluralSuffix(count,
            languageCode: code, hasZero: hasZero);

    test('English and German: 1 is "one", 0 and 2+ are "other"', () {
      for (final code in ['en', 'de']) {
        expect(suffix(0, code), 'other', reason: code);
        expect(suffix(1, code), 'one', reason: code);
        expect(suffix(2, code), 'other', reason: code);
        expect(suffix(1000000, code), 'other', reason: code);
      }
    });

    test('French: 0 and 1 are "one"', () {
      expect(suffix(0, 'fr'), 'one');
      expect(suffix(1, 'fr'), 'one');
      expect(suffix(2, 'fr'), 'other');
      // CLDR "many" is not in the tables and falls back to "other".
      expect(suffix(1000000, 'fr'), 'other');
    });

    test('Spanish: only 1 is "one"', () {
      expect(suffix(0, 'es'), 'other');
      expect(suffix(1, 'es'), 'one');
      expect(suffix(5, 'es'), 'other');
    });

    test('a defined zero form wins for 0 in every language', () {
      for (final code in ['en', 'de', 'fr', 'es']) {
        expect(suffix(0, code, hasZero: true), 'zero', reason: code);
        expect(suffix(1, code, hasZero: true), 'one', reason: code);
      }
    });

    test('plural() picks the table entry and fills {n}', () {
      final en = AppLocalizations(const Locale('en'));
      expect(en.plural('rel_weeks_past', 1), '1\u00A0week ago');
      expect(en.plural('rel_weeks_past', 3), '3\u00A0weeks ago');
      expect(en.plural('rel_weeks_past', 0), '0\u00A0weeks ago');
      expect(
        en.plural('rel_weeks_future', 4160, replacements: {'n': '4,160'}),
        'In 4,160\u00A0weeks',
      );
    });

    test('plural() keeps the _zero override', () {
      final en = AppLocalizations(const Locale('en'));
      expect(en.plural('birthdays_together', 0),
          AppLocalizations.valuesFor('en')['birthdays_together_zero']);
    });
  });

  group('shortDateFormat', () {
    setUpAll(() => initializeDateFormatting());
    final date = DateTime(1998, 3, 12);

    test('English and German keep their formats', () {
      expect(AppLocalizations(const Locale('en')).shortDateFormat.format(date),
          '12 Mar 1998');
      expect(AppLocalizations(const Locale('de')).shortDateFormat.format(date),
          '12. März 1998');
    });

    test('French and Spanish use their medium date', () {
      expect(AppLocalizations.shortDateFormatFor('fr').format(date),
          '12 mars 1998');
      expect(AppLocalizations.shortDateFormatFor('es').format(date),
          '12 mar 1998');
    });
  });

  test('German puts a no-break space before "%"', () {
    for (final entry in AppLocalizations.valuesFor('de').entries) {
      expect(entry.value.contains(' %'), isFalse, reason: entry.key);
    }
    expect(AppLocalizations.valuesFor('de')['percent_lived'], '{p} % gelebt');
  });

  group('French typography', () {
    test('app strings use the typographic apostrophe, never a straight one',
        () {
      final french = <String, String>{
        ...AppLocalizations.valuesFor('fr'),
        for (final prompt in [
          ...compassQuestions,
          ...compassNotes,
          ...compassLimitHints,
        ])
          'compass ${prompt.id}': prompt.text['fr']!,
        for (final quote in quoteEntries) ...{
          'quote ${quote.id}': quote.text['fr'] ?? '',
          'quote author ${quote.id}': quote.author?['fr'] ?? '',
        },
      };
      for (final entry in french.entries) {
        expect(entry.value.contains("'"), isFalse, reason: entry.key);
      }
    });

    test('native French strings use it too', () {
      final apostrophe = RegExp(r"\p{L}\\?'\p{L}", unicode: true);
      for (final path in [
        'android/app/src/main/res/values-fr/strings.xml',
        'android/wear/src/main/res/values-fr/strings.xml',
        'ios/Runner/fr.lproj/InfoPlist.strings',
      ]) {
        expect(apostrophe.hasMatch(File(path).readAsStringSync()), isFalse,
            reason: path);
      }
      final swift =
          File('ios/LifeCore/Sources/LifeCore/WidgetText.swift').readAsStringSync();
      final french = swift.substring(swift.indexOf('static let french'),
          swift.indexOf('static let spanish'));
      expect(apostrophe.hasMatch(french), isFalse);
    });
  });

  group('punctuation', () {
    /// Every app string of [code] plus the generated Compass prompts and
    /// the quotes (the texts the other typography checks scan as well).
    Map<String, String> textsOf(String code) => {
          ...AppLocalizations.valuesFor(code),
          for (final prompt in [
            ...compassQuestions,
            ...compassNotes,
            ...compassLimitHints,
          ])
            'compass ${prompt.id}': prompt.text[code]!,
          for (final quote in quoteEntries)
            'quote ${quote.id}': quote.text[code] ?? '',
        };

    test('French puts a no-break space before : ; ? ! and %', () {
      const noBreak = '  ';
      const marks = ':;?!%';
      for (final entry in textsOf('fr').entries) {
        final text = entry.value;
        for (var i = 0; i < text.length; i++) {
          if (!marks.contains(text[i])) continue;
          if (text[i] == ':' && _isTimeOrUrlColon(text, i)) continue;
          final before = i == 0 ? '' : text[i - 1];
          // "?!" or "!!" only needs the space before the first mark.
          final ok = noBreak.contains(before) && before.isNotEmpty ||
              (before.isNotEmpty && marks.contains(before));
          expect(ok, isTrue,
              reason: 'fr ${entry.key}: "$text" (position $i)');
        }
      }
    });

    test('Spanish opens questions and exclamations with ¿ and ¡', () {
      for (final entry in textsOf('es').entries) {
        final text = entry.value;
        for (final (open, close) in [('¿', '?'), ('¡', '!')]) {
          var start = 0;
          for (var i = text.indexOf(close); i >= 0;
              i = text.indexOf(close, i + 1)) {
            final sentence = text.substring(start, i);
            expect(sentence.contains(open), isTrue,
                reason: 'es ${entry.key}: "$text"');
            start = i + 1;
          }
        }
      }
    });
  });

  test('reflection and weekly moment texts keep a no-break space before a dash', () {
    final looseDash = RegExp(r'(^|[^\u00A0])–');
    for (final (code, table) in [
      ('en', reflectionStringsEn),
      ('en', weekMomentStringsEn),
      ('de', reflectionStringsDe),
      ('de', weekMomentStringsDe),
      ('fr', reflectionStringsFr),
      ('fr', weekMomentStringsFr),
      ('es', reflectionStringsEs),
      ('es', weekMomentStringsEs),
    ]) {
      for (final entry in table.entries) {
        expect(looseDash.hasMatch(entry.value), isFalse,
            reason: '$code ${entry.key}: ${entry.value}');
      }
    }
  });

  group('numbers and units', () {
    const units = {
      'en': 'years? weeks? months? days? hours? minutes?',
      'de': 'Jahre Jahren Jahres Jahr Wochen Woche Monate Monaten Monats Monat '
          'Tage Tagen Tag Stunden Stunde Minuten Minute',
      'fr': 'ans an années année semaines semaine mois jours jour heures '
          'heure minutes minute',
      'es': 'años año semanas semana meses mes días día horas hora minutos '
          'minuto',
    };
    for (final code in languages) {
      test('$code keeps "{n} <unit>" together with a no-break space', () {
        final words = units[code]!.split(' ').join('|');
        final split = RegExp(r'(\{\w+\}|\d) (' + words + r')(?![\p{L}\w])',
            unicode: true);
        final texts = <String, String>{
          ...AppLocalizations.valuesFor(code),
          for (final prompt in [
            ...compassQuestions,
            ...compassNotes,
            ...compassLimitHints,
          ])
            'compass ${prompt.id}': prompt.text[code]!,
        };
        for (final entry in texts.entries) {
          expect(split.hasMatch(entry.value), isFalse,
              reason: '$code ${entry.key}: ${entry.value}');
        }
      });
    }

    test('the no-break space is really there', () {
      expect(AppLocalizations.valuesFor('es')['upcoming_in_days_other'],
          '{name} cumple {age} en {n} días');
    });
  });
}

/// A colon inside a time ("19:00") or a URL ("https://") is not
/// punctuation and needs no space.
bool _isTimeOrUrlColon(String text, int index) {
  bool isDigit(int i) =>
      i >= 0 && i < text.length && '0123456789'.contains(text[i]);
  if (isDigit(index - 1) && isDigit(index + 1)) return true;
  return text.startsWith('//', index + 1);
}
