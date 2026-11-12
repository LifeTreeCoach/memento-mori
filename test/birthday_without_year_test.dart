import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_service.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/birth_year_hint.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/friend_detail_screen.dart';
import 'package:memento_mori_life_in_weeks/friend_form/day_month_picker.dart';
import 'package:memento_mori_life_in_weeks/friend_form/lifespan_slider.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/life/cell_detail_sheet.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/birthdays_together.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/friend_tile.dart';
import 'package:memento_mori_life_in_weeks/people/lifespan_ring.dart';
import 'package:memento_mori_life_in_weeks/people/shared_time.dart';
import 'package:memento_mori_life_in_weeks/people_import/existing_person.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_budget.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _today = DateTime(2026, 11, 2);

/// Ben: birthday on 20 May, year unknown.
Friend _noYear({
  String name = 'Ben',
  int month = 5,
  int day = 20,
  String id = 'b',
}) =>
    Friend(
      id: id,
      name: name,
      birthDate: DateTime(Friend.noYearStorageYear, month, day),
      hasBirthYear: false,
      createdDate: DateTime(2025),
      lastUpdated: DateTime(2025),
    );

Friend _withYear(String name, DateTime birthDate, {String? id}) => Friend(
      id: id ?? name,
      name: name,
      birthDate: birthDate,
      createdDate: DateTime(2025),
      lastUpdated: DateTime(2025),
    );

AppLocalizations _l10n(String lang) => AppLocalizations(Locale(lang));

void main() {
  setUpAll(() => initializeDateFormatting());

  group('model and JSON', () {
    test('a birthday without a year round-trips as --MM-dd', () {
      final ben = _noYear();
      final map = ben.toMap();
      expect(map['birthDate'], '--05-20');
      final back = Friend.fromMap(jsonDecode(jsonEncode(map)));
      expect(back, ben);
      expect(back.hasBirthYear, isFalse);
      expect(back.birthDate, DateTime(2000, 5, 20));
    });

    test('a birthday with a year keeps yyyy-MM-dd and the flag', () {
      final anna = _withYear('Anna', DateTime(1990, 3, 15));
      expect(anna.toMap()['birthDate'], '1990-03-15');
      final back = Friend.fromMap(anna.toMap());
      expect(back.hasBirthYear, isTrue);
      expect(back, anna);
    });

    test('legacy epoch millis still read, with a year', () {
      final map = _withYear('Anna', DateTime(1985, 12, 31)).toMap()
        ..['birthDate'] = DateTime(1985, 12, 31).millisecondsSinceEpoch;
      final back = Friend.fromMap(map);
      expect(back.birthDate, DateTime(1985, 12, 31));
      expect(back.hasBirthYear, isTrue);
    });

    test('--02-29 is kept in the leap storage year', () {
      expect(Friend.decodeBirthDate('--02-29'), DateTime(2000, 2, 29));
      expect(Friend.encodedHasBirthYear('--02-29'), isFalse);
      final leap = _noYear(month: 2, day: 29);
      expect(leap.birthdayInYear(2027), DateTime(2027, 2, 28));
      expect(leap.birthdayInYear(2028), DateTime(2028, 2, 29));
    });

    test('invalid month-day strings throw FormatException', () {
      expect(() => Friend.decodeBirthDate('--02-30'), throwsFormatException);
      expect(() => Friend.decodeBirthDate('--13-01'), throwsFormatException);
      expect(() => Friend.decodeBirthDate('--5-1'), throwsFormatException);
    });

    test('import source fields round-trip and are omitted when null', () {
      final imported = _noYear().copyWith(
          importSource: Friend.importSourceVcard, importSourceId: 'uid-1');
      final back = Friend.fromMap(imported.toMap());
      expect(back.importSource, 'vcard');
      expect(back.importSourceId, 'uid-1');
      expect(_noYear().toMap().containsKey('importSource'), isFalse);
    });

    test('identityKey uses --MM-dd without a year', () {
      expect(_noYear(name: ' Ben ').identityKey, 'ben|--05-20');
      expect(_withYear('Anna', DateTime(1990, 3, 5)).identityKey,
          'anna|1990-03-05');
    });

    test('age helpers are null or neutral without a year', () {
      final ben = _noYear();
      expect(ben.getCurrentAge(today: _today), isNull);
      expect(ben.getRemainingYears(today: _today), isNull);
      expect(ben.isBeyondExpectedLifespan(today: _today), isFalse);
      expect(ben.ageTurningIn(2027), isNull);
      expect(ben.getDaysUntilNextBirthday(today: DateTime(2027, 5, 18)), 2);
      expect(ben.isBirthdayToday(today: DateTime(2031, 5, 20)), isTrue);
    });

    test('import adapter: no year, and the source id', () {
      final person = existingPersonFromFriend(
          _noYear().copyWith(importSourceId: 'c-7'));
      expect(person.year, isNull);
      expect((person.month, person.day), (5, 20));
      expect(person.sourceId, 'c-7');
      expect(
          existingPersonFromFriend(_withYear('A', DateTime(1990, 1, 2))).year,
          1990);
    });
  });

  group('backup 1.4', () {
    test('writes 1.4 and round-trips a friend without a year', () {
      final backup = FriendsService.encodeBackup([_noYear()]);
      expect(jsonDecode(backup)['version'], '1.5');
      final friend = FriendsService.decodeBackup(backup).single;
      expect(friend.hasBirthYear, isFalse);
      expect(friend.birthDate, DateTime(2000, 5, 20));
    });

    test('a 1.3 backup still imports, every friend with a year', () {
      final backup = jsonEncode({
        'version': '1.3',
        'friends': [
          {
            'id': 'a',
            'name': 'Anna',
            'birthDate': '1990-05-01',
            'createdDate': 0,
            'lastUpdated': 0,
          },
        ],
      });
      final friend = FriendsService.decodeBackup(backup).single;
      expect(friend.hasBirthYear, isTrue);
      expect(friend.birthDate, DateTime(1990, 5, 1));
    });

    test('import keeps the missing year and the import source', () async {
      SharedPreferences.setMockInitialValues({});
      await FriendsService.clearCacheForTesting();
      final (added, skipped) = await FriendsService.importFriends([
        _noYear().copyWith(
            importSource: Friend.importSourceContacts, importSourceId: '42'),
      ]);
      expect((added, skipped), (1, 0));
      final saved = (await FriendsService.getAllFriends()).single;
      expect(saved.hasBirthYear, isFalse);
      expect(saved.importSourceId, '42');
      // The same person again is recognised by --MM-dd.
      expect(await FriendsService.importFriends([_noYear()]), (0, 1));
    });
  });

  group('reminder texts', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      test('no age in the notification ($lang)', () {
        final l10n = _l10n(lang);
        final today = BirthdayReminderScheduler.buildContent(
            _noYear(), null, l10n);
        final tomorrow = BirthdayReminderScheduler.buildContent(
            _noYear(), null, l10n,
            dayBefore: true);
        for (final body in [today.body, tomorrow.body]) {
          expect(body, contains('Ben'));
          expect(body, isNot(contains('{')));
          expect(body, isNot(matches(RegExp(r'\d'))));
        }
        expect(tomorrow.body, isNot(today.body));
      });
    }

    test('the age of a budget occurrence is null without a year', () {
      final ben = _noYear().copyWith(notificationId: 3);
      final all = ReminderBudget.occurrences(
        friends: [ben],
        now: DateTime(2026, 5, 1),
        reminderMinutes: 9 * 60,
        dayBeforeEnabled: false,
      );
      expect(all.first.at, DateTime(2026, 5, 20, 9));
      expect(all.every((o) => o.age == null), isTrue);
      expect(
          BirthdayReminderScheduler.friendAgeOnBirthdayFor(
              ben, DateTime(2026, 5, 20), 0),
          isNull);
    });
  });

  group('upcoming card and People texts', () {
    test('upcoming birthday without an age', () {
      final next = UpcomingBirthday.forFriend(_noYear(), DateTime(2027, 5, 17));
      expect(next.age, isNull);
      expect(next.daysUntil, 3);
      expect(next.describe(_l10n('en')), 'Ben has a birthday in 3 days');
      expect(next.describe(_l10n('de')), 'Ben hat in 3 Tagen Geburtstag');
      final today = UpcomingBirthday.forFriend(_noYear(), DateTime(2027, 5, 20));
      expect(today.describe(_l10n('en')), 'Ben has a birthday today 🎂');
    });

    test('People line and detail texts without an age', () {
      final next = UpcomingBirthday.forFriend(_noYear(), DateTime(2027, 5, 19));
      expect(describeNextBirthday(_l10n('en'), next), 'birthday · tomorrow');
      expect(describeNextBirthday(_l10n('de'), next), 'Geburtstag · morgen');
      final text = FriendText(_l10n('de'));
      expect(text.birthDate(_noYear()), '20. Mai');
      expect(text.remaining(_noYear()), isNull);
      expect(FriendText.percentLived(_noYear()), isNull);
      expect(text.shareText(_noYear()), isNot(contains('%')));
    });
  });

  group('sorting', () {
    final friends = [
      _noYear(name: 'Zoe', id: 'z'),
      _withYear('Old', DateTime(1950, 1, 1)),
      _noYear(name: 'Ben', id: 'b'),
      _withYear('Young', DateTime(2000, 1, 1)),
    ];
    List<String> names(FriendQuery query) =>
        query.apply(friends, _today).map((f) => f.name).toList();

    for (final ascending in [true, false]) {
      test('age and remaining put people without a year last ($ascending)',
          () {
        final byAge =
            names(FriendQuery(sort: SortOption.age, ascending: ascending));
        expect(byAge.sublist(2), ['Ben', 'Zoe']);
        expect(byAge.first, ascending ? 'Young' : 'Old');
        final byRemaining = names(
            FriendQuery(sort: SortOption.remaining, ascending: ascending));
        expect(byRemaining.sublist(2), ['Ben', 'Zoe']);
      });
    }

    test('filters still include people without a year', () {
      expect(names(const FriendQuery(sort: SortOption.name)),
          ['Ben', 'Old', 'Young', 'Zoe']);
    });
  });

  group('time together', () {
    test('no birthdays together and no shared time without a year', () {
      expect(
          BirthdaysTogether.count(
            friend: _noYear(),
            userBirthDate: DateTime(1990, 11, 17),
            userLifeExpectancyYears: 80,
            today: _today,
          ),
          isNull);
      expect(
          SharedTime.compute(
            friend: _noYear(),
            userBirthDate: DateTime(1990, 11, 17),
            userLifeExpectancyYears: 80,
            today: _today,
          ),
          isNull);
    });
  });

  group('calendar', () {
    test('description has no birth year line', () {
      for (final lang in AppLocalizations.supportedLanguages) {
        final l10n = _l10n(lang);
        final description =
            CalendarService.formatEventDescription(_noYear(), l10n);
        expect(description, l10n.translate('calendar_event_description_noyear'));
        expect(description, isNot(contains('2000')));
      }
      final details = CalendarService.birthdayEventDetails(
          _noYear(), _l10n('en'),
          today: _today);
      expect(details.start, DateTime(2027, 5, 20));
    });
  });

  group('life grid birthdays', () {
    final calc = LifeCalculator(
      birthDate: DateTime(1990, 11, 17),
      lifeExpectancyYears: 80,
      now: _today,
    );

    test('a friend without a year has a birthday in every year, no age', () {
      // The year cell 1990-11-17 .. 1991-11-17 holds 20 May 1991.
      final first = LifePeriod.of(LifeMode.years, 0, calc).birthdaysOf([_noYear()]);
      expect(first.single.date, DateTime.utc(1991, 5, 20));
      expect(first.single.age, isNull);
      final future = LifePeriod.of(LifeMode.years, 60, calc).birthdaysOf([_noYear()]);
      expect(future.single.isPast, isFalse);
    });

    test('cell sheet texts without an age', () {
      final period = LifePeriod.of(LifeMode.years, 0, calc);
      final b = period.birthdaysOf([_noYear()]).single;
      expect(LifePeriodText(_l10n('en')).birthday(b), 'Ben had a birthday');
      expect(LifePeriodText(_l10n('de')).birthday(b), 'Ben hatte Geburtstag');
      final future = LifePeriod.of(LifeMode.years, 60, calc)
          .birthdaysOf([_noYear()]).single;
      expect(LifePeriodText(_l10n('en')).birthday(future), 'Ben has a birthday');
    });
  });

  group('widgets', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'birth_date': DateTime(1990, 11, 17).toIso8601String(),
        'lifespan_visualization_enabled': true,
      });
      await SettingsService.initialize();
      await FriendsService.clearCacheForTesting();
    });

    testWidgets('tile shows no age and no lifespan ring', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: FriendTile(
            birthday: UpcomingBirthday.forFriend(_noYear(), DateTime(2027, 5, 10)),
            currentAge: null,
          ),
        ),
      );
      expect(find.text('Ben'), findsOneWidget);
      expect(find.text('birthday · in 10 days'), findsOneWidget);
      expect(find.byType(LifespanRing), findsNothing);
    });

    testWidgets('detail shows the hint card; its button opens the form',
        (tester) async {
      await FriendsService.addFriend(_noYear());
      await _pump(tester, FriendDetailScreen(friend: _noYear()));
      expect(find.byType(BirthYearHint), findsOneWidget);
      expect(find.text('Add the birth year to see your time together.'),
          findsOneWidget);
      expect(find.textContaining('years old'), findsNothing);
      expect(find.text('20 May'), findsOneWidget);
      expect(find.text('Turning'), findsNothing);
      expect(find.text('Expected lifespan'), findsNothing);

      await tester.tap(find.text('Add birth year'));
      await tester.pumpAndSettle();
      expect(find.byType(AddFriendScreen), findsOneWidget);
      expect(_yearUnknownSwitch(tester).value, isTrue);
    });

    testWidgets('form: year unknown hides the lifespan and saves --MM-dd',
        (tester) async {
      final saved = await _openForm(tester, _withYear('Anna', DateTime(1990, 5, 20)));
      expect(find.byType(LifespanSlider), findsOneWidget);
      expect(find.textContaining('20 May 1990'), findsOneWidget);

      await tester.tap(find.text('Year unknown'));
      await tester.pumpAndSettle();
      expect(find.byType(LifespanSlider), findsNothing);
      expect(find.text('20 May'), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      final friend = saved();
      expect(friend!.hasBirthYear, isFalse);
      expect(friend.birthDate, DateTime(2000, 5, 20));
      expect(friend.toMap()['birthDate'], '--05-20');
      final stored = (await FriendsService.getAllFriends()).single;
      expect(stored.hasBirthYear, isFalse);
    });

    testWidgets('form: editing a friend without a year keeps it',
        (tester) async {
      final saved = await _openForm(tester, _noYear());
      expect(_yearUnknownSwitch(tester).value, isTrue);
      expect(find.byType(LifespanSlider), findsNothing);
      await tester.enterText(find.widgetWithText(TextFormField, 'Ben'), 'Benno');
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(saved()!.hasBirthYear, isFalse);
      expect(saved()!.name, 'Benno');
      expect(saved()!.birthDate, DateTime(2000, 5, 20));
    });

    testWidgets('form: day and month picker for a new friend without a year',
        (tester) async {
      await _pump(tester, const AddFriendScreen());
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Cleo');
      await tester.tap(find.text('Year unknown'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap to choose a date'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      // Choose February, then 29.
      await tester.tap(find.text('January'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('February').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('29'), 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('29').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('29 Feb'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final stored = (await FriendsService.getAllFriends()).single;
      expect(stored.name, 'Cleo');
      expect(stored.hasBirthYear, isFalse);
      expect(stored.toMap()['birthDate'], '--02-29');
    });

    testWidgets('form: switching the year back on asks for the full date',
        (tester) async {
      final saved = await _openForm(tester, _noYear());
      await tester.tap(find.text('Year unknown'));
      await tester.pumpAndSettle();
      // The date picker opens at day and month; cancelling keeps "unknown".
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_yearUnknownSwitch(tester).value, isTrue);

      await tester.tap(find.text('Year unknown'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(_yearUnknownSwitch(tester).value, isFalse);
      expect(find.byType(LifespanSlider), findsOneWidget);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(saved()!.hasBirthYear, isTrue);
      expect(saved()!.birthDate, DateTime(2000, 5, 20));
    });

    test('day counts of the storage year allow Feb 29', () {
      expect(daysInStorageMonth(2), 29);
      expect(daysInStorageMonth(4), 30);
      expect(daysInStorageMonth(12), 31);
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('detail and form fit 393x851 ($lang)', (tester) async {
        await FriendsService.addFriend(_noYear());
        await _pump(tester, FriendDetailScreen(friend: _noYear()),
            lang: lang, pixel5: true);
        expect(tester.takeException(), isNull);
        final l10n = _l10n(lang);
        expect(find.text(l10n.translate('friend_no_year_hint')), findsOneWidget);
        await tester.scrollUntilVisible(
            find.text(l10n.translate('friend_detail_section_reminder')
                .toUpperCase()),
            300,
            scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull);

        await _pump(tester, AddFriendScreen(friend: _noYear()),
            lang: lang, pixel5: true);
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.translate('form_birthday_year_unknown')),
            findsOneWidget);
        await tester.tap(find.byIcon(Icons.cake_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

SwitchListTile _yearUnknownSwitch(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byType(SwitchListTile));

/// Opens the form for [friend] (saved first) from a page and returns a
/// getter for the friend the form popped with.
Future<Friend? Function()> _openForm(WidgetTester tester, Friend friend) async {
  await FriendsService.addFriend(friend);
  Friend? result;
  await _pump(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<Friend>(
                MaterialPageRoute(
                    builder: (_) => AddFriendScreen(friend: friend)));
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

Future<void> _pump(WidgetTester tester, Widget home,
    {String lang = 'en', bool pixel5 = false}) async {
  // 1080x2340 at 2.75 = 393x851 (Pixel 5).
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = pixel5 ? 2.75 : 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    locale: Locale(lang),
    supportedLocales: [
      for (final code in AppLocalizations.supportedLanguages) Locale(code),
    ],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  ));
  await tester.pump();
}
