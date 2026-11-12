import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_ids.dart';
import 'package:memento_mori_life_in_weeks/reminders/phase_check_in_planner.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

tz.TZDateTime _at(int y, int m, int d, [int h = 0, int min = 0]) =>
    tz.TZDateTime(tz.UTC, y, m, d, h, min);

/// Wednesday; week 0 is Sunday 2026-11-08.
final DateTime _anchor = DateTime(2026, 11, 4);

final LifePhase _phase =
    LifePhase(id: 'p1', name: 'Studium', start: DateTime(2024, 10, 1));

Intention _task(String id, String title,
        {DateTime? created,
        IntentionKind? kind = IntentionKind.doTask,
        IntentionStatus status = IntentionStatus.now,
        String? phaseId = 'p1'}) =>
    Intention(
      id: id,
      title: title,
      createdAt: created ?? DateTime(2026, 1, 1),
      kind: kind,
      status: status,
      phaseId: phaseId,
    );

AppLocalizations _l10n(String lang) => AppLocalizations(Locale(lang));

void main() {
  group('nextCheckInTimes', () {
    test('Sundays 19:00, 4 weeks apart, from the anchor week', () {
      final times =
          PhaseCheckInPlanner.nextCheckInTimes(_at(2026, 11, 5, 10), _anchor);
      expect(times, [
        _at(2026, 11, 8, 19),
        _at(2026, 12, 6, 19),
        _at(2027, 1, 3, 19),
      ]);
      expect(times.every((t) => t.weekday == DateTime.sunday), isTrue);
    });

    test('an anchor on a Sunday is week 0 itself', () {
      expect(PhaseCheckInPlanner.anchorSunday(DateTime(2026, 11, 8)),
          DateTime(2026, 11, 8));
      expect(PhaseCheckInPlanner.anchorSunday(DateTime(2026, 11, 9)),
          DateTime(2026, 11, 15));
    });

    test('dates stay put when rescheduled at different times', () {
      final grid = {
        for (var k = 0; k < 20; k++)
          _at(2026, 11, 8 + 28 * k, 19),
      };
      for (var day = 0; day < 120; day += 3) {
        final now = _at(2026, 11, 5 + day, 13);
        final times = PhaseCheckInPlanner.nextCheckInTimes(now, _anchor);
        expect(grid.containsAll(times), isTrue, reason: '$now: $times');
        // The first one is the next grid date after now: none is skipped.
        final expected = grid.where((t) => t.isAfter(now)).reduce(
            (a, b) => a.isBefore(b) ? a : b);
        expect(times.first, expected, reason: '$now');
      }
    });

    test('strictly after now: at 19:00 on a check-in Sunday the next one',
        () {
      final atTime =
          PhaseCheckInPlanner.nextCheckInTimes(_at(2026, 11, 8, 19), _anchor);
      expect(atTime.first, _at(2026, 12, 6, 19));
      final before = PhaseCheckInPlanner.nextCheckInTimes(
          _at(2026, 11, 8, 18, 59), _anchor);
      expect(before.first, _at(2026, 11, 8, 19));
    });

    test('an anchor in the future starts at its week', () {
      final times = PhaseCheckInPlanner.nextCheckInTimes(
          _at(2026, 11, 5, 10), DateTime(2026, 12, 1));
      expect(times.first, _at(2026, 12, 6, 19));
    });

    test('keeps 19:00 local time across a DST change', () {
      tzdata.initializeTimeZones();
      final berlin = tz.getLocation('Europe/Berlin');
      final now = tz.TZDateTime(berlin, 2026, 2, 1, 12);
      final times =
          PhaseCheckInPlanner.nextCheckInTimes(now, DateTime(2026, 2, 1));
      for (final t in times) {
        expect(t.hour, 19);
        expect(t.weekday, DateTime.sunday);
      }
      expect(times.map((t) => t.day), [1, 1, 29]); // Feb 1, Mar 1, Mar 29
    });
  });

  group('plan', () {
    List<WeeklyReflection> plan({
      String lang = 'en',
      LifePhase? phase,
      List<Intention> tasks = const [],
    }) =>
        PhaseCheckInPlanner.plan(
          now: _at(2026, 11, 5, 10),
          anchor: _anchor,
          l10n: _l10n(lang),
          phase: phase,
          openDoTasks: tasks,
          birthDate: DateTime(1990, 3, 15),
        );

    test('uses ids 10..12 of the weekly range and the Compass payload', () {
      final ids = plan(phase: _phase).map((r) => r.id).toList();
      expect(ids, [10, 11, 12]);
      const end = NotificationIds.weeklyReflectionStart +
          NotificationIds.weeklyReflectionCount;
      expect(ids.every((id) => id >= NotificationIds.weeklyReflectionStart),
          isTrue);
      expect(ids.every((id) => id < end), isTrue);
      expect(PhaseCheckInPlanner.payload, WeeklyReflectionPlanner.payload);
    });

    test('each check-in gets the Compass payload of its own day', () {
      final payloads = plan(phase: _phase)
          .map((r) => WeeklyReflectionPlanner.payloadFor(r.date))
          .toList();
      expect(payloads.length, 3);
      expect(payloads.toSet().length, 3);
      for (final (i, r) in plan(phase: _phase).indexed) {
        final d = r.date;
        expect(payloads[i],
            'compass:${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
        expect(d.weekday, DateTime.sunday);
      }
    });

    test('names the oldest open do-task and the phase', () {
      final body = plan(lang: 'de', phase: _phase, tasks: [
        _task('a', 'Bachelorarbeit'),
        _task('b', 'Auslandssemester'),
      ]).first.body;
      expect(body,
          'Wie geht es mit „Bachelorarbeit“ voran? Und was war in deiner Phase „Studium“ zuletzt gut?');
    });

    test('without open do-tasks asks where you stand', () {
      final reminder = plan(lang: 'de', phase: _phase).first;
      expect(reminder.body,
          'Wo stehst du in deiner Phase „Studium“ – und was war gut?');
      expect(reminder.title, 'Kompass · Check-in');
    });

    test('without a phase falls back to the question of the week', () {
      final reminder = plan().first;
      final question = WeeklyReflectionPlanner.questionFor(
        DateTime(2026, 11, 8),
        birthDate: DateTime(1990, 3, 15),
        gentleOnly: false,
      );
      expect(reminder.body, question.textFor('en'));
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      test('every variant is translated in $lang', () {
        final texts = [
          for (final r in [
            plan(lang: lang).first,
            plan(lang: lang, phase: _phase).first,
            plan(lang: lang, phase: _phase, tasks: [_task('a', 'X')]).first,
          ]) ...[r.title, r.body],
        ];
        for (final text in texts) {
          expect(text, isNotEmpty);
          expect(text.startsWith('phase_'), isFalse, reason: text);
          expect(text.contains('{'), isFalse, reason: text);
        }
      });
    }
  });

  group('openDoTasksIn', () {
    test('keeps open do-tasks of the phase, oldest first', () {
      final tasks = PhaseCheckInPlanner.openDoTasksIn(_phase, [
        _task('new', 'New', created: DateTime(2026, 5, 1)),
        _task('old', 'Old', created: DateTime(2025, 5, 1)),
        _task('same', 'Same day as new', created: DateTime(2026, 5, 1)),
        _task('enjoy', 'Enjoy', kind: IntentionKind.enjoy),
        _task('legacy', 'No kind', kind: null),
        _task('done', 'Done', status: IntentionStatus.done),
        _task('gone', 'Let go', status: IntentionStatus.letGo),
        _task('other', 'Other phase', phaseId: 'p2'),
        _task('someday', 'Someday', status: IntentionStatus.someday,
            created: DateTime(2026, 6, 1)),
      ]);
      expect(tasks.map((t) => t.id), ['old', 'new', 'same', 'someday']);
    });
  });

  group('signature', () {
    test('changes with the phase and the task titles only', () {
      final a = PhaseCheckInPlanner.signature(_phase, [_task('a', 'A')]);
      expect(PhaseCheckInPlanner.signature(_phase, [_task('a', 'A')]), a);
      expect(
          PhaseCheckInPlanner.signature(_phase, [_task('a', 'B')]), isNot(a));
      expect(PhaseCheckInPlanner.signature(_phase.copyWith(name: 'Job'),
          [_task('a', 'A')]), isNot(a));
      expect(PhaseCheckInPlanner.signature(null, const []), '');
    });
  });

  group('phase name', () {
    test('a preset phase is named in the app language', () {
      final preset = LifePhase(
          id: 'p1', preset: PhasePreset.study, start: DateTime(2020));
      for (final lang in AppLocalizations.supportedLanguages) {
        final body = PhaseCheckInPlanner.plan(
          now: _at(2026, 11, 5, 10),
          anchor: _anchor,
          l10n: _l10n(lang),
          phase: preset,
        ).first.body;
        expect(body, contains(_l10n(lang).translate('phase_preset_study')));
        expect(body.contains('phase_preset'), isFalse, reason: body);
      }
    });
  });
}
