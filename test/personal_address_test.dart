import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';

void main() {
  final en = AppLocalizations(const Locale('en'));
  final values = AppLocalizations.valuesFor('en');

  group('without a name', () {
    for (final name in ['', '   ', '\t\n']) {
      test('"$name" keeps the plain key and adds no name', () {
        final address = PersonalAddress(name);
        expect(address.hasName, isFalse);
        expect(address.name, isEmpty);
        expect(
          address.key('onboarding_reveal_tagline'),
          'onboarding_reveal_tagline',
        );
        expect(
          address.translate(en, 'onboarding_reveal_tagline'),
          values['onboarding_reveal_tagline'],
        );
      });
    }

    test('none is the plain address', () {
      expect(PersonalAddress.none.hasName, isFalse);
      expect(
        PersonalAddress.none.key('onboarding_estimate_title'),
        'onboarding_estimate_title',
      );
    });
  });

  group('with a name', () {
    for (final name in ['Daniel', '  Daniel ']) {
      test('"$name" uses the _named key with the trimmed name', () {
        final address = PersonalAddress(name);
        expect(address.hasName, isTrue);
        expect(address.name, 'Daniel');
        expect(
          address.key('onboarding_reveal_tagline'),
          'onboarding_reveal_tagline_named',
        );
        expect(
          address.translate(en, 'onboarding_reveal_tagline'),
          values['onboarding_reveal_tagline_named']!.replaceAll(
            '{name}',
            'Daniel',
          ),
        );
      });
    }

    test('extra replacements are applied on top of the name', () {
      final named = PersonalAddress(
        'Daniel',
      ).translate(en, 'onboarding_estimate_title', replacements: {'n': '80'});
      expect(named, contains('Daniel'));
      expect(
        PersonalAddress.none.translate(
          en,
          'onboarding_estimate_intro',
          replacements: {'n': '80'},
        ),
        en.translate('onboarding_estimate_intro', replacements: {'n': '80'}),
      );
    });
  });

  group('keys', () {
    test('the suffix never looks like a plural or subject form', () {
      expect(PersonalAddress.namedSuffix, '_named');
      for (final other in ['_other', '_one', '_someone']) {
        expect(PersonalAddress.namedSuffix, isNot(other));
      }
    });

    test('every key has a _named twin with {name} in every language', () {
      for (final code in AppLocalizations.supportedLanguages) {
        final strings = AppLocalizations.valuesFor(code);
        for (final key in PersonalAddress.keys) {
          final plain = strings[key];
          final named = strings['$key${PersonalAddress.namedSuffix}'];
          expect(plain, isNotNull, reason: '$code: $key');
          expect(plain, isNot(contains('{name}')), reason: '$code: $key');
          expect(named, isNotNull, reason: '$code: ${key}_named');
          expect(named, contains('{name}'), reason: '$code: ${key}_named');
        }
      }
    });
  });
}
