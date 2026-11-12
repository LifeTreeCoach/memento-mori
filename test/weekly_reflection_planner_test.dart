import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/compass/weekly_question.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';
import 'package:timezone/timezone.dart' as tz;

tz.TZDateTime _at(int y, int m, int d, [int h = 0]) =>
    tz.TZDateTime(tz.UTC, y, m, d, h);

final DateTime _birth = DateTime(1990, 3, 15);

List<WeeklyReflection> _plan({
  DateTime? birthDate,
  bool gentleOnly = false,
  String lang = 'en',
  bool Function(DateTime)? isSwapped,
  tz.TZDateTime? now,
}) =>
    WeeklyReflectionPlanner.plan(
      now: now ?? _at(2026, 11, 5, 10), // Thursday
      birthDate: birthDate,
      gentleOnly: gentleOnly,
      l10n: AppLocalizations(Locale(lang)),
      isSwapped: isSwapped,
    );

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  group('WeeklyReflectionPlanner.plan', () {
    test('schedules the next 4 Sundays at 19:00', () {
      final dates = _plan(birthDate: _birth).map((r) => r.date).toList();
      expect(dates, [
        _at(2026, 11, 8, 19),
        _at(2026, 11, 15, 19),
        _at(2026, 11, 22, 19),
        _at(2026, 11, 29, 19),
      ]);
      expect(dates.every((d) => d.weekday == DateTime.sunday), isTrue);
    });

    test('Sunday after 19:00 starts with the next Sunday', () {
      final dates = _plan(now: _at(2026, 11, 8, 20)).map((r) => r.date);
      expect(dates.first, _at(2026, 11, 15, 19));
      expect(dates, hasLength(4));
    });

    test('uses the weekly reflection id range', () {
      final ids = _plan().map((r) => r.id).toList();
      expect(ids, [
        for (var i = 0; i < NotificationIds.weeklyReflectionCount; i++)
          NotificationIds.weeklyReflectionStart + i,
      ]);
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      test('carries each week\'s question in $lang', () {
        final l10n = AppLocalizations(Locale(lang));
        for (final reflection in _plan(birthDate: _birth, lang: lang)) {
          final date = _day(reflection.date);
          // Born 1990-03-15: 36 on every Sunday of November 2026.
          final expected =
              questionForWeek(date, ageYears: 36, gentleOnly: false);
          expect(reflection.body, expected.textFor(lang));
          expect(reflection.title, l10n.translate('weekly_reflection_title'));
        }
      });
    }

    test('consecutive weeks get different questions', () {
      final bodies = _plan(birthDate: _birth).map((r) => r.body).toSet();
      expect(bodies, hasLength(4));
    });

    test('gentle only never asks courage questions', () {
      final reflections = _plan(birthDate: _birth, gentleOnly: true);
      for (final reflection in reflections) {
        final prompt = WeeklyReflectionPlanner.questionFor(
            _day(reflection.date),
            birthDate: _birth,
            gentleOnly: true);
        expect(prompt.kind, isNot(CompassPromptKind.courage));
        expect(reflection.body, prompt.textFor('en'));
      }
      // Without it, every other week asks for courage.
      final kinds = _plan(birthDate: _birth).map((r) => WeeklyReflectionPlanner
          .questionFor(_day(r.date), birthDate: _birth, gentleOnly: false)
          .kind);
      expect(kinds, contains(CompassPromptKind.courage));
    });

    test('without a birth date the Compass tab\'s neutral age is used', () {
      for (final reflection in _plan()) {
        final date = _day(reflection.date);
        final expected = questionForWeek(date,
            ageYears: compassDefaultAgeYears, gentleOnly: false);
        expect(reflection.body, expected.textFor('en'));
      }
    });

    test('a swapped week carries the swapped question', () {
      final firstSunday = DateTime(2026, 11, 8);
      final reflections = _plan(
          birthDate: _birth, isSwapped: (date) => date == firstSunday);
      final swapped = WeeklyReflectionPlanner.questionFor(firstSunday,
          birthDate: _birth, gentleOnly: false, swapped: true);
      expect(reflections.first.body, swapped.textFor('en'));
      final unswapped = WeeklyReflectionPlanner.questionFor(
          DateTime(2026, 11, 15),
          birthDate: _birth,
          gentleOnly: false);
      expect(reflections[1].body, unswapped.textFor('en'));
    });

    test('a swapped week never carries a neighbouring week\'s question', () {
      for (final gentleOnly in [false, true]) {
        for (var i = 0; i < WeeklyReflectionPlanner.count; i++) {
          final swappedSunday = DateTime(2026, 11, 8 + 7 * i);
          final reflections = _plan(
              birthDate: _birth,
              gentleOnly: gentleOnly,
              isSwapped: (date) => date == swappedSunday);
          final bodies = reflections.map((r) => r.body).toList();
          expect(bodies.toSet(), hasLength(bodies.length),
              reason: 'gentle $gentleOnly swapped $i');
        }
      }
    });
  });

  group('WeeklyReflectionPlanner.payloadFor', () {
    test('carries the local date of the reminder', () {
      expect(WeeklyReflectionPlanner.payloadFor(_at(2026, 11, 15, 19)),
          'compass:2026-11-15');
      expect(WeeklyReflectionPlanner.payloadFor(DateTime(2027, 1, 3, 23, 59)),
          'compass:2027-01-03');
    });

    test('starts with the prefix and keeps the bare payload', () {
      expect(WeeklyReflectionPlanner.payload, 'compass');
      expect(WeeklyReflectionPlanner.payloadPrefix, 'compass:');
      expect(
          WeeklyReflectionPlanner.payloadFor(DateTime(2026, 5, 3))
              .startsWith(WeeklyReflectionPlanner.payloadPrefix),
          isTrue);
    });

    test('one dated payload per planned Sunday', () {
      final payloads = _plan(now: _at(2026, 11, 12, 10))
          .map((r) => WeeklyReflectionPlanner.payloadFor(r.date))
          .toList();
      expect(payloads, [
        'compass:2026-11-15',
        'compass:2026-11-22',
        'compass:2026-11-29',
        'compass:2026-12-06',
      ]);
    });
  });
}
