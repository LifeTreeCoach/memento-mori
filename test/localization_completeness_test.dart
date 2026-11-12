import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompts.dart';
import 'package:memento_mori_life_in_weeks/life/quotes/quote_data.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

import 'support/translation_checks.dart';

/// Every app text exists and is non-empty in every language (key parity and
/// typography live in `localization_test.dart`).
void main() {
  const languages = AppLocalizations.supportedLanguages;

  /// Keys that are empty on purpose in some language. None today; add a key
  /// here with a comment saying why before leaving a value blank.
  const intentionallyEmpty = <String>{};

  final prompts = [...compassQuestions, ...compassNotes, ...compassLimitHints];

  for (final code in languages) {
    test('$code: no app string is empty', () {
      expect(
        blankValues(
          AppLocalizations.valuesFor(code),
          allowed: intentionallyEmpty,
        ),
        isEmpty,
      );
    });
  }

  test('every quote has its text (and author) in every language', () {
    expect(quoteEntries, isNotEmpty);
    expect([
      for (final quote in quoteEntries) ...[
        ...missingTranslations(quote.id, quote.text, languages),
        if (quote.author != null)
          ...missingTranslations('${quote.id} author', quote.author, languages),
      ],
    ], isEmpty);
  });

  test(
    'every Compass prompt is in every language with the same placeholders',
    () {
      expect(prompts, isNotEmpty);
      expect([
        for (final prompt in prompts) ...[
          ...missingTranslations(prompt.id, prompt.text, languages),
          ...placeholderMismatches(prompt.id, prompt.text),
        ],
      ], isEmpty);
    },
  );

  group('the checks catch bad input', () {
    test('blank values are found unless allowed', () {
      const table = {'ok': 'Hi', 'empty': '', 'spaces': '  \n'};
      expect(blankValues(table), ['empty', 'spaces']);
      expect(blankValues(table, allowed: {'empty'}), ['spaces']);
    });

    test('missing and blank translations are found', () {
      expect(
        missingTranslations('q', const {'en': 'A', 'de': ' '}, languages),
        [
          'q: de missing or empty',
          'q: fr missing or empty',
          'q: es missing or empty',
        ],
      );
      expect(missingTranslations('q', null, ['en']), [
        'q: en missing or empty',
      ]);
    });

    test('differing placeholders are found', () {
      const texts = {
        'en': 'How is {phase}?',
        'de': 'Wie ist {phase}?',
        'fr': 'Comment va {phase_name} ?',
        'es': '¿Cómo va?',
      };
      final problems = placeholderMismatches('p', texts);
      expect(problems, hasLength(2));
      expect(problems.first, startsWith('p: fr'));
      expect(problems.last, startsWith('p: es'));
    });
  });
}
