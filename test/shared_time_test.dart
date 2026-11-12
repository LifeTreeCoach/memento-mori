import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/encounter_dots.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/shared_time_painter.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/people/birthdays_together.dart';
import 'package:memento_mori_life_in_weeks/people/expected_end.dart';
import 'package:memento_mori_life_in_weeks/people/meeting_frequency.dart';
import 'package:memento_mori_life_in_weeks/people/shared_time.dart';
import 'package:memento_mori_life_in_weeks/theme/app_color_schemes.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

final DateTime _today = DateTime(2026, 11, 2);
final DateTime _userBirth = DateTime(1990, 11, 17); // user ends 2070-11-17

Friend _friend(DateTime birthDate, {int lifespan = 80, MeetingFrequency? f}) =>
    Friend(
      id: 'f',
      name: 'Anna',
      birthDate: birthDate,
      customLifespan: lifespan,
      meetingFrequency: f,
      createdDate: DateTime(2025),
      lastUpdated: DateTime(2025),
    );

SharedTime _time(Friend friend,
        {DateTime? userBirth, int userYears = 80, DateTime? today}) =>
    SharedTime.compute(
      friend: friend,
      userBirthDate: userBirth ?? _userBirth,
      userLifeExpectancyYears: userYears,
      today: today ?? _today,
    )!;

int _days(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

void main() {
  group('ExpectedEnd', () {
    test('user end is birth date + expectancy', () {
      expect(
        ExpectedEnd.ofUser(
            birthDate: _userBirth, lifeExpectancyYears: 80, today: _today),
        DateTime.utc(2070, 11, 17),
      );
    });

    test('friend end is the birthday at their lifespan (Feb 29 -> 28)', () {
      expect(ExpectedEnd.ofFriend(_friend(DateTime(2000, 2, 29))),
          DateTime.utc(2080, 2, 29));
      expect(ExpectedEnd.ofFriend(_friend(DateTime(2000, 2, 29), lifespan: 81)),
          DateTime.utc(2081, 2, 28));
    });

    test('shared end is the earlier one', () {
      final older = _friend(DateTime(1950, 1, 1));
      expect(
        ExpectedEnd.shared(
            friend: older,
            userBirthDate: _userBirth,
            userLifeExpectancyYears: 80,
            today: _today),
        DateTime.utc(2030, 1, 1),
      );
    });
  });

  group('SharedTime', () {
    test('is null without the user birth date', () {
      expect(
        SharedTime.compute(
          friend: _friend(DateTime(1995, 11, 14)),
          userBirthDate: null,
          userLifeExpectancyYears: 80,
          today: _today,
        ),
        isNull,
      );
    });

    test('younger friend: window ends with the user expectancy', () {
      final time = _time(_friend(DateTime(1995, 11, 14)));
      final days = _days(_today, DateTime(2070, 11, 17));
      expect(time.remainingDays, days);
      expect(time.remainingWeeks, days ~/ 7);
      expect(time.remainingYears, closeTo(44.04, 0.01));
      expect(time.isBeyondExpectancy, isFalse);
      // From the friend's birth (the later one) to today.
      expect(time.livedAlongsideYears.floor(), 30);
    });

    test('older friend: window ends with the friend expectancy', () {
      final time = _time(_friend(DateTime(1950, 1, 1)));
      expect(time.remainingDays, _days(_today, DateTime(2030, 1, 1)));
      // From the user's birth (the later one) to today.
      expect(time.livedAlongsideYears.floor(), 35);
    });

    test('birthdays together match BirthdaysTogether', () {
      final friend = _friend(DateTime(1995, 11, 14));
      expect(
        _time(friend).birthdaysTogether,
        BirthdaysTogether.count(
          friend: friend,
          userBirthDate: _userBirth,
          userLifeExpectancyYears: 80,
          today: _today,
        ),
      );
    });

    test('friend beyond their expectancy: no time ahead', () {
      final time = _time(_friend(DateTime(1940, 3, 1)));
      expect(time.isBeyondExpectancy, isTrue);
      expect(time.remainingDays, 0);
      expect(time.remainingWeeks, 0);
      expect(time.meetingsLeft(MeetingFrequency.weekly), 0);
      expect(time.birthdaysTogether, 0);
    });

    test('user beyond their own expectancy: also no time ahead', () {
      final time = _time(_friend(DateTime(1995, 1, 1)),
          userBirth: DateTime(1930, 1, 1));
      expect(time.isBeyondExpectancy, isTrue);
    });

    test('friend not yet born: window starts at their birth', () {
      final time = _time(_friend(DateTime(2027, 3, 1)));
      expect(time.livedAlongsideYears, 0);
      expect(time.remainingDays, _days(DateTime(2027, 3, 1), DateTime(2070, 11, 17)));
      expect(time.isBeyondExpectancy, isFalse);
    });

    test('same birthday: lived alongside = age', () {
      final time = _time(_friend(_userBirth));
      expect(time.livedAlongsideYears.floor(), 35);
    });

    group('meetings left', () {
      final time = _time(_friend(DateTime(1995, 11, 14)));

      test('null without a frequency', () {
        expect(time.meetingsLeft(null), isNull);
      });

      test('daily counts the days ahead', () {
        expect(time.meetingsLeft(MeetingFrequency.daily), time.remainingDays);
      });

      test('other frequencies scale the years ahead', () {
        final years = time.remainingYears;
        expect(time.meetingsLeft(MeetingFrequency.weekly), (years * 52).round());
        expect(time.meetingsLeft(MeetingFrequency.monthly), (years * 12).round());
        expect(time.meetingsLeft(MeetingFrequency.fewTimesYear), (years * 4).round());
        expect(time.meetingsLeft(MeetingFrequency.yearly), years.round());
        expect(time.meetingsLeft(MeetingFrequency.rarely), (years / 2).round());
      });

      test('fewer meetings for rarer frequencies', () {
        final counts = [
          for (final f in MeetingFrequency.values) time.meetingsLeft(f)!,
        ];
        for (var i = 1; i < counts.length; i++) {
          expect(counts[i], lessThan(counts[i - 1]));
        }
      });
    });
  });

  group('dots', () {
    test('one dot per encounter up to 400, then 10, 100, ...', () {
      expect(encountersPerDot(0), 1);
      expect(encountersPerDot(400), 1);
      expect(encountersPerDot(401), 10);
      expect(encountersPerDot(4000), 10);
      expect(encountersPerDot(4001), 100);
      expect(EncounterDots.dotCount(0), 0);
      expect(EncounterDots.dotCount(37), 37);
      expect(EncounterDots.dotCount(401), 41);
      expect(EncounterDots.dotCount(16000), 160);
    });
  });

  group('MeetingFrequency on Friend', () {
    test('stored by name and read back', () {
      final friend = _friend(DateTime(1990, 5, 1), f: MeetingFrequency.fewTimesYear);
      expect(friend.toMap()['meetingFrequency'], 'fewTimesYear');
      expect(Friend.fromJson(friend.toJson()).meetingFrequency,
          MeetingFrequency.fewTimesYear);
    });

    test('old JSON without the field (and unknown values) read as null', () {
      final map = _friend(DateTime(1990, 5, 1)).toMap();
      expect(map.containsKey('meetingFrequency'), isFalse);
      expect(Friend.fromMap(map).meetingFrequency, isNull);
      expect(Friend.fromMap({...map, 'meetingFrequency': 'hourly'}).meetingFrequency,
          isNull);
    });

    test('copyWith keeps, sets and clears it', () {
      final friend = _friend(DateTime(1990, 5, 1), f: MeetingFrequency.weekly);
      expect(friend.copyWith(name: 'B').meetingFrequency, MeetingFrequency.weekly);
      expect(friend.copyWith(meetingFrequency: MeetingFrequency.daily).meetingFrequency,
          MeetingFrequency.daily);
      expect(friend.copyWith(clearMeetingFrequency: true).meetingFrequency, isNull);
      expect(friend == friend.copyWith(clearMeetingFrequency: true), isFalse);
    });

    test('backup round trip keeps it; old backups stay valid', () {
      final friend = _friend(DateTime(1990, 5, 1), f: MeetingFrequency.monthly);
      final backup = FriendsService.encodeBackup([friend, _friend(DateTime(1991))]);
      final friends = FriendsService.decodeBackup(backup);
      expect(friends[0].meetingFrequency, MeetingFrequency.monthly);
      expect(friends[1].meetingFrequency, isNull);

      final old = jsonEncode({
        'version': '1.1',
        'friends': [
          {
            'id': '1',
            'name': 'Old',
            'birthDate': '1980-01-02',
            'customLifespan': 80,
            'createdDate': 0,
            'lastUpdated': 0,
          },
        ],
      });
      expect(FriendsService.decodeBackup(old).single.meetingFrequency, isNull);
    });
  });

  group('SharedTimePainter', () {
    test('fractionOf clamps to the axis and survives an empty axis', () {
      final start = DateTime.utc(2000);
      final end = DateTime.utc(2100);
      expect(SharedTimePainter.fractionOf(DateTime.utc(2050), start, end),
          closeTo(0.5, 0.01));
      expect(SharedTimePainter.fractionOf(DateTime.utc(1900), start, end), 0);
      expect(SharedTimePainter.fractionOf(DateTime.utc(2200), start, end), 1);
      expect(SharedTimePainter.fractionOf(start, start, start), 0);
    });

    final cases = <String, SharedTime>{
      'younger': _time(_friend(DateTime(1995, 11, 14))),
      'older': _time(_friend(DateTime(1950, 1, 1))),
      'beyond expectancy': _time(_friend(DateTime(1930, 1, 1))),
      'not yet born': _time(_friend(DateTime(2027, 3, 1))),
      'lifespan 0': _time(_friend(DateTime(2000, 1, 1), lifespan: 0)),
      'same day, expectancy 0':
          _time(_friend(_today, lifespan: 0), userBirth: _today, userYears: 0),
      'very long lives': _time(_friend(DateTime(1900, 1, 1), lifespan: 150),
          userBirth: DateTime(1901, 1, 1), userYears: 150),
    };
    const sizes = [
      Size.zero,
      Size(1, 1),
      Size(2, 200),
      Size(305, SharedTimePainter.preferredHeight),
      Size(1000, 40),
    ];
    for (final entry in cases.entries) {
      test('paints without errors: ${entry.key}', () {
        for (final palette in [LifePalette.stoicLight, LifePalette.warmDark]) {
          final colors = SharedTimeColors.resolve(
              palette, AppColorSchemes.of(ThemeStyle.stoic, Brightness.light));
          for (final size in sizes) {
            final painter = SharedTimePainter(
              time: entry.value,
              youLabel: 'You',
              themLabel: 'A very long name that will never fit ' * 3,
              todayLabel: 'Aujourd’hui',
              colors: colors,
              outline: Colors.grey,
              labelColor: Colors.black,
              todayColor: Colors.black,
            );
            final recorder = ui.PictureRecorder();
            painter.paint(Canvas(recorder), size);
            recorder.endRecording().dispose();
            expect(painter.shouldRepaint(painter), isFalse);
          }
        }
      });
    }
  });

  group('SharedTimeColors', () {
    double distance(Color a, Color b) {
      final dr = a.r - b.r, dg = a.g - b.g, db = a.b - b.b;
      return dr * dr + dg * dg + db * db;
    }

    for (final style in ThemeStyle.values) {
      for (final brightness in Brightness.values) {
        test('every segment is visible: ${style.name} ${brightness.name}', () {
          final scheme = AppColorSchemes.of(style, brightness);
          final card = style == ThemeStyle.stoic
              ? scheme.surfaceContainerLow
              : scheme.surfaceContainer;
          final colors = SharedTimeColors.resolve(
              LifePalette.resolve(style, brightness), scheme);
          for (final color in [colors.together, colors.ahead, colors.own]) {
            expect(contrastRatio(color, card), greaterThanOrEqualTo(1.5),
                reason: '$color on card $card');
          }
          // Own time differs from both other segments (by lightness or hue).
          for (final other in [colors.together, colors.ahead]) {
            expect(distance(colors.own, other), greaterThan(0.04),
                reason: '${colors.own} vs $other');
          }
        });
      }
    }
  });
}
