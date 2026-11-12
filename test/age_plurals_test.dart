import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/life/cell_detail_sheet.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_tile.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';

/// Age texts put a number before "years" in some languages (French "ans"),
/// so they are plural keys: French needs "1 an", not "1 ans".
void main() {
  AppLocalizations l10n(String code) => AppLocalizations(Locale(code));
  final anna = Friend(
    id: 'a',
    name: 'Anna',
    birthDate: DateTime(2025, 6, 15),
    createdDate: DateTime(2026, 1, 1),
    lastUpdated: DateTime(2026, 1, 1),
  );

  UpcomingBirthday upcoming(int age, int daysUntil) =>
      UpcomingBirthday(friend: anna, daysUntil: daysUntil, age: age);

  FriendBirthday birthday(
    int age, {
    bool isPast = false,
    bool isToday = false,
  }) => FriendBirthday(
    friend: anna,
    age: age,
    date: DateTime(2025 + age, 6, 15),
    isPast: isPast,
    isToday: isToday,
  );

  // language -> age -> expected text
  void expectForms(
    String Function(AppLocalizations l10n, int age) build,
    Map<String, Map<int, String>> expected,
  ) {
    expected.forEach((code, byAge) {
      byAge.forEach((age, text) {
        expect(build(l10n(code), age), text, reason: '$code, age $age');
      });
    });
  }

  group('birthday notification body', () {
    test('day of the birthday', () {
      expectForms(
        (l, age) => BirthdayReminderScheduler.buildContent(anna, age, l).body,
        {
          'en': {1: 'Anna turns 1 today 🎂', 2: 'Anna turns 2 today 🎂'},
          'de': {1: 'Anna wird heute 1 🎂', 2: 'Anna wird heute 2 🎂'},
          'es': {1: 'Anna cumple 1 hoy 🎂', 2: 'Anna cumple 2 hoy 🎂'},
          'fr': {
            1: 'Anna a 1\u00A0an aujourd’hui 🎂',
            2: 'Anna fête ses 2\u00A0ans aujourd’hui 🎂',
          },
        },
      );
    });

    test('day before', () {
      expectForms(
        (l, age) => BirthdayReminderScheduler.buildContent(
          anna,
          age,
          l,
          dayBefore: true,
        ).body,
        {
          'en': {1: 'Anna turns 1 tomorrow.', 2: 'Anna turns 2 tomorrow.'},
          'de': {1: 'Anna wird morgen 1.', 2: 'Anna wird morgen 2.'},
          'es': {1: 'Anna cumple 1 mañana.', 2: 'Anna cumple 2 mañana.'},
          'fr': {1: 'Anna aura 1\u00A0an demain.', 2: 'Anna fête ses 2\u00A0ans demain.'},
        },
      );
    });
  });

  group('upcoming birthday card', () {
    test('today, tomorrow and in 3 days', () {
      expectForms((l, age) => upcoming(age, 0).describe(l), {
        'en': {1: 'Anna turns 1 today 🎂', 2: 'Anna turns 2 today 🎂'},
        'fr': {
          1: 'Anna a 1\u00A0an aujourd’hui 🎂',
          2: 'Anna fête ses 2\u00A0ans aujourd’hui 🎂',
        },
        'es': {1: 'Anna cumple 1 hoy 🎂', 2: 'Anna cumple 2 hoy 🎂'},
        'de': {1: 'Anna wird heute 1 🎂', 2: 'Anna wird heute 2 🎂'},
      });
      expectForms((l, age) => upcoming(age, 1).describe(l), {
        'en': {1: 'Anna turns 1 tomorrow', 2: 'Anna turns 2 tomorrow'},
        'fr': {1: 'Anna aura 1\u00A0an demain', 2: 'Anna aura 2\u00A0ans demain'},
        'es': {1: 'Anna cumple 1 mañana', 2: 'Anna cumple 2 mañana'},
        'de': {1: 'Anna wird morgen 1', 2: 'Anna wird morgen 2'},
      });
      expectForms((l, age) => upcoming(age, 3).describe(l), {
        'en': {1: 'Anna turns 1 in 3\u00A0days', 2: 'Anna turns 2 in 3\u00A0days'},
        'fr': {
          1: 'Anna aura 1\u00A0an dans 3\u00A0jours',
          2: 'Anna aura 2\u00A0ans dans 3\u00A0jours',
        },
        'es': {1: 'Anna cumple 1 en 3\u00A0días', 2: 'Anna cumple 2 en 3\u00A0días'},
        'de': {1: 'Anna wird in 3\u00A0Tagen 1', 2: 'Anna wird in 3\u00A0Tagen 2'},
      });
    });
  });

  group('people list and friend detail', () {
    final cases = <int, Map<String, Map<int, String>>>{
      0: {
        'en': {1: 'turns 1 today 🎂', 2: 'turns 2 today 🎂'},
        'de': {1: 'wird heute 1 🎂', 2: 'wird heute 2 🎂'},
        'es': {1: 'cumple 1 hoy 🎂', 2: 'cumple 2 hoy 🎂'},
        'fr': {1: 'a 1\u00A0an aujourd’hui 🎂', 2: 'fête ses 2\u00A0ans aujourd’hui 🎂'},
      },
      1: {
        'en': {1: 'turns 1 · tomorrow', 2: 'turns 2 · tomorrow'},
        'de': {1: 'wird 1 · morgen', 2: 'wird 2 · morgen'},
        'es': {1: 'cumple 1 · mañana', 2: 'cumple 2 · mañana'},
        'fr': {1: 'aura 1\u00A0an · demain', 2: 'aura 2\u00A0ans · demain'},
      },
      12: {
        'en': {1: 'turns 1 · in 12\u00A0days', 2: 'turns 2 · in 12\u00A0days'},
        'de': {1: 'wird 1 · in 12\u00A0Tagen', 2: 'wird 2 · in 12\u00A0Tagen'},
        'es': {1: 'cumple 1 · en 12\u00A0días', 2: 'cumple 2 · en 12\u00A0días'},
        'fr': {1: 'aura 1\u00A0an · dans 12\u00A0jours', 2: 'aura 2\u00A0ans · dans 12\u00A0jours'},
      },
    };
    cases.forEach((daysUntil, expected) {
      test('in $daysUntil days (tile and detail agree)', () {
        expectForms(
          (l, age) => describeNextBirthday(l, upcoming(age, daysUntil)),
          expected,
        );
        expectForms(
          (l, age) => FriendText(l).turns(upcoming(age, daysUntil)),
          expected,
        );
      });
    });
  });

  group('cell detail sheet birthdays', () {
    test('turned, turns and turns today', () {
      expectForms(
        (l, age) => LifePeriodText(l).birthday(birthday(age, isPast: true)),
        {
          'en': {1: 'Anna turned 1', 2: 'Anna turned 2'},
          'de': {1: 'Anna wurde 1', 2: 'Anna wurde 2'},
          'es': {1: 'Anna cumplió 1', 2: 'Anna cumplió 2'},
          'fr': {1: 'Anna a eu 1\u00A0an', 2: 'Anna a eu 2\u00A0ans'},
        },
      );
      expectForms((l, age) => LifePeriodText(l).birthday(birthday(age)), {
        'en': {1: 'Anna turns 1', 2: 'Anna turns 2'},
        'de': {1: 'Anna wird 1', 2: 'Anna wird 2'},
        'es': {1: 'Anna cumple 1', 2: 'Anna cumple 2'},
        'fr': {1: 'Anna aura 1\u00A0an', 2: 'Anna aura 2\u00A0ans'},
      });
      expectForms(
        (l, age) => LifePeriodText(l).birthday(birthday(age, isToday: true)),
        {
          'en': {1: 'Anna turns 1 today 🎂', 2: 'Anna turns 2 today 🎂'},
          'de': {1: 'Anna wird heute 1 🎂', 2: 'Anna wird heute 2 🎂'},
          'es': {1: 'Anna cumple 1 hoy 🎂', 2: 'Anna cumple 2 hoy 🎂'},
          'fr': {
            1: 'Anna a 1\u00A0an aujourd’hui 🎂',
            2: 'Anna fête ses 2\u00A0ans aujourd’hui 🎂',
          },
        },
      );
    });

    test('age 0 is the birth, not a plural age text', () {
      for (final code in AppLocalizations.supportedLanguages) {
        final l = l10n(code);
        expect(
          LifePeriodText(l).birthday(birthday(0, isPast: true)),
          l.translate('friend_born_past', replacements: {'name': 'Anna'}),
        );
        expect(
          LifePeriodText(l).birthday(birthday(0)),
          l.translate('friend_born_future', replacements: {'name': 'Anna'}),
        );
      }
    });
  });

  group('cell detail sheet age line', () {
    // Born 1 Mar 2025, today 2 Nov 2026: year cells 0 (age 0) past,
    // 1 (age 1) current, 2 (age 2) future.
    final calc = LifeCalculator(
      birthDate: DateTime(2025, 3, 1),
      now: DateTime(2026, 11, 2),
    );
    String ageAt(AppLocalizations l, int index) =>
        LifePeriodText(l).age(LifePeriod.of(LifeMode.years, index, calc));

    test('past (age 0), current (age 1), future (age 2)', () {
      expect(ageAt(l10n('en'), 0), 'You were 0');
      expect(ageAt(l10n('en'), 1), 'You are 1');
      expect(ageAt(l10n('en'), 2), 'You will be 2');
      expect(ageAt(l10n('de'), 1), 'Du bist 1');
      expect(ageAt(l10n('de'), 2), 'Du wirst 2 sein');
      expect(ageAt(l10n('es'), 1), 'Tienes 1');
      expect(ageAt(l10n('es'), 2), 'Tendrás 2');
      expect(ageAt(l10n('fr'), 0), 'Âge alors : 0');
      expect(ageAt(l10n('fr'), 1), 'Tu as 1\u00A0an');
      expect(ageAt(l10n('fr'), 2), 'Tu auras 2\u00A0ans');
    });

    test('French: 0 is singular, 2 and up plural', () {
      final fr = l10n('fr');
      expect(fr.plural('age_current', 0), 'Tu as 0\u00A0an');
      expect(fr.plural('age_current', 2), 'Tu as 2\u00A0ans');
      expect(fr.plural('age_future', 1), 'Tu auras 1\u00A0an');
      expect(fr.plural('age_future', 80), 'Tu auras 80\u00A0ans');
    });
  });

  test('the replaced single age keys are gone', () {
    const replaced = [
      'birthday_notification_body_today',
      'birthday_notification_body_tomorrow',
      'age_past',
      'age_current',
      'age_future',
      'friend_turned',
      'friend_turns',
      'friend_turns_today',
      'upcoming_today',
      'upcoming_tomorrow',
      'upcoming_in_days',
      'people_turns_today',
      'people_turns_tomorrow',
      'people_turns_in_days',
    ];
    for (final code in AppLocalizations.supportedLanguages) {
      final values = AppLocalizations.valuesFor(code);
      for (final key in replaced) {
        expect(values.containsKey(key), isFalse, reason: '$code $key');
        expect(values.containsKey('${key}_one'), isTrue, reason: '$code $key');
        expect(
          values.containsKey('${key}_other'),
          isTrue,
          reason: '$code $key',
        );
      }
    }
  });
}
