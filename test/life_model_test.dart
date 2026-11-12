import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/life/life_stage.dart';
import 'package:memento_mori_life_in_weeks/life/quote_service.dart';
import 'package:memento_mori_life_in_weeks/life/quote_share.dart';
import 'package:memento_mori_life_in_weeks/life/quotes/quote_data.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

Friend _friend(String name, DateTime birthDate) => Friend(
      id: name,
      name: name,
      birthDate: birthDate,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    );

void main() {
  group('LifeGridGeometry', () {
    final weeks = LifeGridGeometry(
      mode: LifeMode.weeks,
      totalCells: 80 * 52,
      maxWidth: 22 + 52 * 6.0,
      gutterWidth: 22,
    );

    test('fits 52 square cells per row into the width', () {
      expect(weeks.pitch, 6.0);
      expect(weeks.rows, 80);
      expect(weeks.cellRect(0), Rect.fromLTWH(22, 0, weeks.cellSize, weeks.cellSize));
    });

    test('indexAt is the inverse of cellRect', () {
      for (final index in [0, 51, 52, 100, 2047, 4159]) {
        expect(weeks.indexAt(weeks.cellRect(index).center), index);
      }
    });

    test('indexAt rejects the gutter and points outside the grid', () {
      expect(weeks.indexAt(const Offset(10, 3)), isNull);
      expect(weeks.indexAt(const Offset(30, -1)), isNull);
      expect(weeks.indexAt(Offset(30, weeks.rows * weeks.pitch + 1)), isNull);
      expect(weeks.indexAt(Offset(22 + 52 * 6.0 + 1, 3)), isNull);
    });

    test('years mode has 10 columns and labels every row by decade', () {
      final years = LifeGridGeometry(
          mode: LifeMode.years, totalCells: 85, maxWidth: 400, gutterWidth: 24);
      expect(years.rows, 9);
      expect(years.indexAt(years.cellRect(84).center), 84);
      expect(years.indexAt(years.cellRect(84).center.translate(years.pitch, 0)),
          isNull);
      expect(years.ageAtRow(3), 30);
      expect(years.isLabelledRow(1), isTrue);
    });

    test('months mode puts two years per row, labelled every decade', () {
      final months = LifeGridGeometry(
          mode: LifeMode.months, totalCells: 80 * 12, maxWidth: 24 + 24 * 10.0);
      expect(months.columns, 24);
      expect(months.rows, 40);
      expect(months.rowsPerDecade, 5);
      expect(months.ageAtRow(5), 10);
      expect(months.isLabelledRow(5), isTrue);
      expect(months.isLabelledRow(4), isFalse);
      // Cell 12 (first month of year 2) sits in row 0, column 12.
      expect(months.cellRect(12).left, 24 + 12 * 10.0);
      expect(months.cellRect(24).top, 10.0);
      for (final index in [0, 11, 12, 23, 24, 500, 959]) {
        expect(months.indexAt(months.cellRect(index).center), index);
      }
      expect(months.indexAt(Offset(30, months.rows * months.pitch + 1)), isNull);
    });

    test('caps the cell size for coarse modes', () {
      final months = LifeGridGeometry(
          mode: LifeMode.months, totalCells: 960, maxWidth: 1000);
      expect(months.pitch, 18);
    });
  });

  group('LifePeriod', () {
    final calc = LifeCalculator(
        birthDate: DateTime(1990, 11, 17), now: DateTime(2026, 11, 2));

    test('week periods start every 7 days from birth', () {
      final p = LifePeriod.of(LifeMode.weeks, 100, calc);
      expect(p.start, DateTime.utc(1992, 10, 17));
      expect(p.end, DateTime.utc(1992, 10, 24));
      expect(p.relation, PeriodRelation.past);
      expect(p.distance, 1776);
      expect(p.ageAtStart, 1);
    });

    test('month periods follow the calendar regardless of the 2-year rows', () {
      final p = LifePeriod.of(LifeMode.months, 12, calc);
      expect(p.start, DateTime.utc(1991, 11, 17));
      expect(p.end, DateTime.utc(1991, 12, 17));
      expect(p.ageAtStart, 1);
      final second = LifePeriod.of(LifeMode.months, 25, calc);
      expect(second.start, DateTime.utc(1992, 12, 17));
      expect(second.ageAtStart, 2);
    });

    group('the cell holding a day is the lived count on that day', () {
      int cellOf(LifeMode mode, DateTime birth, DateTime day) {
        // The first cell that ends after [day]; it must also start by then.
        for (var i = 0; i < 2000; i++) {
          if (day.isBefore(LifePeriod.periodStart(mode, i + 1, birth))) {
            expect(day.isBefore(LifePeriod.periodStart(mode, i, birth)), isFalse);
            return i;
          }
        }
        fail('no cell for $day');
      }

      final births = {
        'Jan 31': DateTime.utc(1990, 1, 31),
        'Feb 29': DateTime.utc(1992, 2, 29),
        'Mar 31': DateTime.utc(1991, 3, 31),
        'Aug 30': DateTime.utc(1993, 8, 30),
        'Dec 31': DateTime.utc(1990, 12, 31),
      };
      for (final entry in births.entries) {
        test(entry.key, () {
          final birth = entry.value;
          // ~2.5 years of consecutive days, covering leap and non-leap Febs.
          for (var offset = 0; offset < 920; offset++) {
            final day = DateTime.utc(birth.year, birth.month, birth.day + offset);
            final c = LifeCalculator(birthDate: birth, now: day);
            for (final mode in LifeMode.values) {
              expect(cellOf(mode, birth, day), mode.livedCells(c),
                  reason: '$mode on $day');
            }
          }
          // Around a Feb 29 anniversary in a non-leap year.
          final later = DateTime.utc(birth.year + 7, 2, 25);
          for (var offset = 0; offset < 10; offset++) {
            final day = DateTime.utc(later.year, later.month, later.day + offset);
            final c = LifeCalculator(birthDate: birth, now: day);
            for (final mode in LifeMode.values) {
              expect(cellOf(mode, birth, day), mode.livedCells(c),
                  reason: '$mode on $day');
            }
          }
        });
      }

      test('Jan 31 + 1 month starts on Mar 1, not Mar 3', () {
        expect(LifePeriod.periodStart(LifeMode.months, 1, DateTime.utc(1990, 1, 31)),
            DateTime.utc(1990, 3, 1));
        expect(LifePeriod.periodStart(LifeMode.months, 2, DateTime.utc(1990, 1, 31)),
            DateTime.utc(1990, 3, 31));
      });
    });

    test('the lived count is the current period', () {
      expect(LifePeriod.of(LifeMode.years, 35, calc).relation,
          PeriodRelation.current);
      expect(LifePeriod.of(LifeMode.months, 500, calc).relation,
          PeriodRelation.future);
    });

    test('collects friend birthdays inside the period', () {
      final anna = _friend('Anna', DateTime(1978, 10, 20));
      final baby = _friend('Baby', DateTime(1992, 10, 18));
      final other = _friend('Other', DateTime(1980, 1, 1));
      final p = LifePeriod.of(LifeMode.weeks, 100, calc);
      final birthdays = p.birthdaysOf([anna, baby, other]);
      expect(birthdays.map((b) => b.friend.name), ['Baby', 'Anna']);
      expect(birthdays.last.age, 14);
      expect(birthdays.first.age, 0);
      expect(birthdays.every((b) => b.isPast && !b.isToday), isTrue);
    });
  });

  group('UpcomingBirthday', () {
    final today = DateTime(2026, 11, 2);

    test('finds the soonest birthday within 30 days', () {
      final next = UpcomingBirthday.next([
        _friend('Late', DateTime(1990, 11, 30)),
        _friend('Soon', DateTime(1996, 11, 5)),
        _friend('Past', DateTime(1990, 11, 1)),
      ], today);
      expect(next?.friend.name, 'Soon');
      expect(next?.daysUntil, 3);
      expect(next?.age, 30);
    });

    test('counts today and ignores birthdays beyond the window', () {
      expect(UpcomingBirthday.next([_friend('A', DateTime(2000, 11, 2))], today)
          ?.daysUntil, 0);
      expect(UpcomingBirthday.next([_friend('B', DateTime(2000, 12, 31))], today),
          isNull);
    });

    test('card header says Today only when every birthday is today', () {
      final todayOnly = UpcomingBirthday.soonest([
        _friend('A', DateTime(2000, 11, 2)),
        _friend('B', DateTime(1990, 11, 2)),
      ], today);
      final later = UpcomingBirthday.soonest([_friend('C', DateTime(1996, 11, 5))], today);
      expect(UpcomingBirthdayCard.headerKey(todayOnly), 'upcoming_header_today');
      expect(UpcomingBirthdayCard.headerKey(later), 'upcoming');
    });
  });

  group('QuoteService.quoteOfTheDay', () {
    const languages = ['en', 'de', 'fr', 'es'];

    test('is stable within a day and picks the language', () {
      final morning = QuoteService.quoteOfTheDay('en', date: DateTime(2026, 3, 1, 8));
      final evening = QuoteService.quoteOfTheDay('en', date: DateTime(2026, 3, 1, 22));
      expect(morning.id, evening.id);
      expect(morning.text, evening.text);
      expect(QuoteService.lifeQuotes('de').map((q) => q.text),
          contains(QuoteService.quoteOfTheDay('de', date: DateTime(2026, 3, 1)).text));
    });

    test('shows the same quote in every language on the same day', () {
      for (var day = 0; day < 60; day++) {
        final date = DateTime(2026, 1, 1).add(Duration(days: day));
        final ids = {
          for (final language in languages)
            QuoteService.quoteOfTheDay(language, date: date, ageYears: 40).id,
        };
        expect(ids, hasLength(1), reason: '$date');
      }
    });

    test('does not reset on Jan 1', () {
      final dec31 = QuoteService.quoteOfTheDay('en', date: DateTime(2025, 12, 31));
      final jan1 = QuoteService.quoteOfTheDay('en', date: DateTime(2026, 1, 1));
      final jan1Before = QuoteService.quoteOfTheDay('en', date: DateTime(2025, 1, 1));
      expect(jan1.id, isNot(dec31.id));
      expect(jan1.id, isNot(jan1Before.id));
      expect(QuoteService.daysSinceEpoch(DateTime(2026, 1, 1)) -
          QuoteService.daysSinceEpoch(DateTime(2025, 12, 31)), 1);
    });

    test('changes from one day to the next', () {
      for (var day = 0; day < 400; day++) {
        final date = DateTime(2026, 1, 1).add(Duration(days: day));
        final next = date.add(const Duration(days: 1));
        expect(QuoteService.quoteOfTheDay('en', date: date, ageYears: 70).id,
            isNot(QuoteService.quoteOfTheDay('en', date: next, ageYears: 70).id),
            reason: '$date');
      }
    });

    test('every quote has text in all languages, authored ones a source', () {
      expect(quoteEntries, hasLength(greaterThanOrEqualTo(150)));
      expect(quoteEntries.map((e) => e.id).toSet(), hasLength(quoteEntries.length));
      for (final language in languages) {
        final quotes = QuoteService.lifeQuotes(language);
        expect(quotes.map((q) => q.id), quoteEntries.map((e) => e.id));
        for (final quote in quotes) {
          expect(quote.text.trim(), isNotEmpty, reason: '${quote.id} $language');
          if (quote.author != null) {
            expect(quote.author!.trim(), isNotEmpty, reason: quote.id);
            expect(quote.source?.trim(), isNotEmpty, reason: quote.id);
          }
        }
      }
      expect(quoteEntries.where((e) => e.author != null), isNotEmpty);
    });

    test('stage weighting is deterministic and complete', () {
      final all = List.generate(quoteEntries.length, (i) => i);
      final base = QuoteService.cycleFor(null);
      expect(base.toList()..sort(), all);
      for (final stage in LifeStage.values) {
        final cycle = QuoteService.cycleFor(stage);
        expect(cycle.toSet(), all.toSet(), reason: '$stage');
        final matching = [
          for (var i = 0; i < quoteEntries.length; i++)
            if (quoteEntries[i].stages.contains(stage)) i,
        ];
        expect(cycle.length, quoteEntries.length + matching.length);
        for (final index in all) {
          final count = cycle.where((i) => i == index).length;
          expect(count, matching.contains(index) ? 2 : 1, reason: '$stage $index');
        }
        for (var i = 0; i < cycle.length; i++) {
          expect(cycle[i], isNot(cycle[(i + 1) % cycle.length]));
        }
      }
      expect(QuoteService.quoteOfTheDay('en', date: DateTime(2026, 5, 5), ageYears: 80).id,
          QuoteService.quoteOfTheDay('en', date: DateTime(2026, 5, 5), ageYears: 80).id);
    });

    test('life stages follow age', () {
      expect(LifeStage.fromAge(15), LifeStage.young);
      expect(LifeStage.fromAge(18), LifeStage.exploring);
      expect(LifeStage.fromAge(30), LifeStage.building);
      expect(LifeStage.fromAge(45), LifeStage.midlife);
      expect(LifeStage.fromAge(60), LifeStage.harvest);
      expect(LifeStage.fromAge(74), LifeStage.harvest);
      expect(LifeStage.fromAge(75), LifeStage.wisdom);
    });
  });

  group('quoteShareText', () {
    const seneca = Quote(
      id: 'x',
      text: 'Life is long.',
      author: 'Seneca',
      source: 'De Brevitate Vitae 2.1',
    );

    test('quotes the text and credits author, source and app', () {
      expect(quoteShareText(AppLocalizations(const Locale('en')), seneca),
          '“Life is long.”\n— Seneca · De Brevitate Vitae 2.1\n\n'
          'Memento Mori · Life in Weeks');
      expect(quoteShareText(AppLocalizations(const Locale('fr')), seneca),
          startsWith('« Life is long. »\n— Seneca'));
      expect(quoteShareText(AppLocalizations(const Locale('de')), seneca),
          startsWith('„Life is long.“'));
    });

    test('omits the attribution for anonymous quotes', () {
      const anonymous = Quote(id: 'a', text: 'Hope.');
      expect(quoteShareText(AppLocalizations(const Locale('es')), anonymous),
          '«Hope.»\n\nMemento Mori · La vida en semanas');
      expect(quoteAttribution(anonymous), isNull);
      expect(quoteAttribution(const Quote(id: 'b', text: 't', author: 'Pascal')),
          'Pascal');
    });
  });
}
