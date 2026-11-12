import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/birthdays_together.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/people_sections.dart';

final DateTime _today = DateTime(2026, 11, 2);

Friend _friend(String name, DateTime birthDate,
        {int lifespan = 80, String? group, String? notes}) =>
    Friend(
      id: name,
      name: name,
      birthDate: birthDate,
      customLifespan: lifespan,
      groupName: group,
      notes: notes,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    );

int? _together(Friend friend, {DateTime? user, int expectancy = 80}) =>
    BirthdaysTogether.count(
      friend: friend,
      userBirthDate: user ?? DateTime(1990, 11, 17),
      userLifeExpectancyYears: expectancy,
      today: _today,
    );

void main() {
  group('BirthdaysTogether', () {
    test('a younger friend is limited by the user\'s expectancy', () {
      // User (born 1990-11-17) reaches 80 on 2070-11-17; the friend's
      // birthdays on Dec 1 from 2026 to 2069 fall in that window.
      expect(_together(_friend('Young', DateTime(2000, 12, 1))), 44);
    });

    test('an older friend is limited by their own lifespan', () {
      // Turns 51 on 2026-12-01 ... 80 on 2055-12-01 -> 30 birthdays.
      expect(_together(_friend('Old', DateTime(1975, 12, 1))), 30);
    });

    test('uses the friend\'s custom lifespan', () {
      expect(_together(_friend('Short', DateTime(1975, 12, 1), lifespan: 60)),
          10);
    });

    test('a birthday today still counts, a passed one does not', () {
      final today = _friend('Today', DateTime(1970, 11, 2));
      final yesterday = _friend('Yesterday', DateTime(1970, 11, 1));
      // Today turns 56: 56..80 -> 25; yesterday's 56th is gone: 57..80 -> 24.
      expect(_together(today), 25);
      expect(_together(yesterday), 24);
    });

    test('a friend beyond their expectancy gets 0', () {
      expect(_together(_friend('Elder', DateTime(1930, 5, 5))), 0);
    });

    test('the birthday on which the expectancy is reached counts', () {
      expect(_together(_friend('Eighty', DateTime(1946, 11, 2))), 1);
    });

    test('an elderly user shares few birthdays', () {
      final friend = _friend('Kid', DateTime(2020, 1, 1));
      expect(_together(friend, user: DateTime(1948, 1, 1)), 2); // 2027, 2028
      expect(_together(friend, user: DateTime(1940, 1, 1)), 0);
    });

    test('a leap-day friend celebrates on Feb 28 in common years', () {
      final leap = _friend('Leap', DateTime(2000, 2, 29), lifespan: 30);
      // 2027 .. 2030 (Feb 28 in 2027, 2029, 2030; Feb 29 2028).
      expect(_together(leap), 4);
    });
  });

  group('PeopleSections', () {
    final friends = [
      _friend('Cleo', DateTime(1995, 11, 12)), // in 10 days
      _friend('Anna', DateTime(1990, 11, 2)), // today
      _friend('Bea', DateTime(1985, 12, 2)), // in 30 days
      _friend('Dan', DateTime(1980, 12, 3)), // in 31 days
      _friend('Eve', DateTime(1999, 11, 1)), // yesterday -> next year
    ];
    final sections = PeopleSections.of(friends, _today);

    test('today holds only birthdays today', () {
      expect(sections.today.map((b) => b.friend.name), ['Anna']);
      expect(sections.today.single.age, 36);
    });

    test('next 30 days excludes today, is soonest first and inclusive', () {
      expect(sections.upcoming.map((b) => b.friend.name), ['Cleo', 'Bea']);
      expect(sections.upcoming.map((b) => b.daysUntil), [10, 30]);
    });

    test('everyone keeps the given order and includes all', () {
      expect(sections.everyone.map((b) => b.friend.name),
          friends.map((f) => f.name));
      expect(sections.everyone.last.daysUntil, 364);
      expect(sections.soonCount, 3);
    });
  });

  group('FriendQuery', () {
    group('custom range without both dates', () {
      final friends = [
        _friend('Anna', DateTime(1990, 11, 2)),
        _friend('Ben', DateTime(1990, 5, 1)),
      ];

      test('filters nothing and is not an active filter', () {
        final query = FriendQuery(
            dateFilter: DateFilter.custom, customStart: DateTime(2026, 11, 1));
        expect(query.hasCustomRange, isFalse);
        expect(query.effectiveDateFilter, DateFilter.all);
        expect(query.isFiltered, isFalse);
        expect(query.apply(friends, _today), hasLength(2));
      });

      test('with both dates it is active and filters', () {
        final query = FriendQuery(
          dateFilter: DateFilter.custom,
          customStart: DateTime(2026, 11, 1),
          customEnd: DateTime(2026, 11, 30),
        );
        expect(query.effectiveDateFilter, DateFilter.custom);
        expect(query.isFiltered, isTrue);
        expect(query.apply(friends, _today).map((f) => f.name), ['Anna']);
      });
    });

    final friends = [
      _friend('carl', DateTime(1992, 1, 10), group: 'Family'),
      _friend('Anna', DateTime(1990, 11, 2), notes: 'climbing'),
      _friend('Bea', DateTime(1960, 11, 5), group: 'Work'),
    ];
    List<String> names(FriendQuery q) =>
        q.apply(friends, _today).map((f) => f.name).toList();

    test('sorts by name case-insensitively, and in reverse', () {
      expect(names(const FriendQuery()), ['Anna', 'Bea', 'carl']);
      expect(names(const FriendQuery(ascending: false)), ['carl', 'Bea', 'Anna']);
    });

    test('sorts by next birthday and by age', () {
      expect(names(const FriendQuery(sort: SortOption.birthday)),
          ['Anna', 'Bea', 'carl']);
      expect(names(const FriendQuery(sort: SortOption.age)),
          ['carl', 'Anna', 'Bea']);
    });

    test('searches names, notes and groups', () {
      expect(names(const FriendQuery(search: 'CLIMB')), ['Anna']);
      expect(names(const FriendQuery(search: 'work')), ['Bea']);
    });

    test('filters by group and ungrouped', () {
      expect(names(const FriendQuery(group: 'Family')), ['carl']);
      expect(names(const FriendQuery(group: FriendQuery.ungrouped)), ['Anna']);
    });

    test('filters by date windows', () {
      expect(names(const FriendQuery(dateFilter: DateFilter.today)), ['Anna']);
      expect(names(const FriendQuery(dateFilter: DateFilter.thisWeek)),
          ['Anna', 'Bea']);
      expect(
          names(FriendQuery(
            dateFilter: DateFilter.custom,
            customStart: DateTime(2027, 1, 1),
            customEnd: DateTime(2027, 1, 31),
          )),
          ['carl']);
    });

    test('next 7 / 30 days windows start today and span exactly 7 / 30 days',
        () {
      final edge = [
        _friend('d0', DateTime(1990, 11, 2)),
        _friend('d6', DateTime(1990, 11, 8)),
        _friend('d7', DateTime(1990, 11, 9)),
        _friend('d29', DateTime(1990, 12, 1)),
        _friend('d30', DateTime(1990, 12, 2)),
      ];
      List<String> edgeNames(DateFilter filter) => FriendQuery(dateFilter: filter)
          .apply(edge, _today)
          .map((f) => f.name)
          .toList();
      expect(edgeNames(DateFilter.thisWeek), ['d0', 'd6']);
      expect(edgeNames(DateFilter.thisMonth), ['d0', 'd29', 'd6', 'd7']);
    });
  });

  group('AppLocalizations.plural', () {
    final en = AppLocalizations(const Locale('en'));
    final de = AppLocalizations(const Locale('de'));

    test('picks zero, one and other forms', () {
      expect(en.plural('birthdays_together', 1), '≈ 1 more birthday together');
      expect(en.plural('birthdays_together', 41),
          '≈ 41 more birthdays together');
      expect(en.plural('birthdays_together', 0),
          'Every birthday from here is a gift');
      expect(de.plural('people_count', 1), '1 Person');
      expect(de.plural('people_count', 0), '0 Personen'); // no zero form
    });
  });
}
