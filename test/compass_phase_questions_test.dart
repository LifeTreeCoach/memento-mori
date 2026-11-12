import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_week.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/phase_check_in_planner.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/compass_test_app.dart';

AppLocalizations _l10n(String lang) => AppLocalizations(Locale(lang));

/// The [CompassWeek]s of the 60 weeks from [compassToday].
List<CompassWeek> _weeks() => [
      for (var w = 0; w < 60; w++)
        CompassWeek.of(compassToday.add(Duration(days: 7 * w)),
            birthDate: compassBirthDate),
    ];

void main() {
  setUp(() => initCompassTest());

  group('CompassWeek', () {
    test('never asks a phase question before the first phase', () async {
      await CompassService.startPhase(
          name: 'Later', start: DateTime(2030), today: compassToday);
      for (final week in _weeks()) {
        expect(week.phase, isNull);
        expect(week.question.phase, isFalse, reason: week.question.id);
      }
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      test('fills {phase} with the translated preset name in $lang', () async {
        await CompassService.startPhase(
            preset: PhasePreset.study,
            start: DateTime(2024, 10, 1),
            today: compassToday);
        final l10n = _l10n(lang);
        final presetName = l10n.translate('phase_preset_study');
        final phaseWeeks = _weeks().where((w) => w.question.phase).toList();
        expect(phaseWeeks, isNotEmpty);
        for (final week in _weeks()) {
          expect(week.questionText(l10n), isNot(contains('{')),
              reason: week.question.id);
        }
        for (final week in phaseWeeks) {
          expect(week.questionText(l10n), contains(presetName),
              reason: week.question.id);
        }
      });
    }

    test('fills {phase} with the user\'s own phase name', () async {
      await CompassService.startPhase(
          name: 'Umbruch', start: DateTime(2026, 1, 1), today: compassToday);
      final week = _weeks().firstWhere((w) => w.question.phase);
      expect(week.questionText(_l10n('de')), contains('„Umbruch“'));
    });
  });

  group('WeeklyReflectionPlanner with phases', () {
    final phase = LifePhase(
        id: 'p1', preset: PhasePreset.study, start: DateTime(2026, 12, 1));
    LifePhase? phaseAt(DateTime date) =>
        date.isBefore(phase.start) ? null : phase;

    for (final lang in AppLocalizations.supportedLanguages) {
      test('fills {phase} on Sundays in the phase only ($lang)', () {
        final l10n = _l10n(lang);
        final presetName = l10n.translate('phase_preset_study');
        var phaseBodies = 0;
        for (var w = 0; w < 30; w++) {
          final now = tz.TZDateTime(tz.UTC, 2026, 11, 5 + 7 * w, 10);
          final plan = WeeklyReflectionPlanner.plan(
            now: now,
            birthDate: compassBirthDate,
            gentleOnly: false,
            l10n: l10n,
            phaseAt: phaseAt,
          );
          for (final reflection in plan) {
            expect(reflection.body, isNot(contains('{')));
            if (reflection.body.contains(presetName)) {
              phaseBodies++;
              expect(reflection.date.isBefore(phase.start), isFalse);
            }
          }
        }
        expect(phaseBodies, greaterThan(0));
      });
    }

    test('asks the same question as the Compass tab in that week', () async {
      await CompassService.startPhase(
          preset: PhasePreset.study,
          start: DateTime(2024, 10, 1),
          today: compassToday);
      final l10n = _l10n('fr');
      for (var w = 0; w < 12; w++) {
        final sunday = DateTime(2026, 11, 8 + 7 * w);
        final reflection = WeeklyReflectionPlanner.reflectionAt(
          tz.TZDateTime(tz.UTC, sunday.year, sunday.month, sunday.day, 19),
          id: 10,
          birthDate: compassBirthDate,
          gentleOnly: false,
          l10n: l10n,
          phase: CompassService.currentPhase(today: sunday),
        );
        final week = CompassWeek.of(sunday, birthDate: compassBirthDate);
        expect(reflection.body, week.questionText(l10n));
      }
    });

    test('the phase check-in fallback never shows a raw placeholder', () {
      for (final lang in AppLocalizations.supportedLanguages) {
        for (var w = 0; w < 30; w++) {
          final plan = PhaseCheckInPlanner.plan(
            now: tz.TZDateTime(tz.UTC, 2026, 11, 5 + 7 * w, 10),
            anchor: DateTime(2026, 11, 1),
            l10n: _l10n(lang),
            birthDate: compassBirthDate,
          );
          for (final reflection in plan) {
            expect(reflection.body, isNot(contains('{')));
          }
        }
      }
    });
  });
}
