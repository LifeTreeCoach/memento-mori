import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompts.dart';
import 'package:memento_mori_life_in_weeks/compass/weekly_question.dart';
import 'package:memento_mori_life_in_weeks/life/life_stage.dart';

const _languages = ['en', 'de', 'fr', 'es'];

/// A Wednesday in week [index] since the epoch Monday.
DateTime _week(int index) => DateTime(2024, 1, 3 + 7 * index);

void main() {
  group('prompt data', () {
    test('has 34 questions per kind (3 of them phase questions), 13 notes and '
        '8 limit hints', () {
      for (final kind in [
        CompassPromptKind.courage,
        ...CompassPromptKind.gentle,
      ]) {
        expect(compassQuestions.where((p) => p.kind == kind), hasLength(34));
        expect(compassQuestions.where((p) => p.kind == kind && p.phase),
            hasLength(3));
      }
      expect(compassQuestions, hasLength(136));
      expect(compassNotes, hasLength(13));
      expect(compassLimitHints, hasLength(8));
      expect(compassNotes.every((p) => p.kind == CompassPromptKind.note), isTrue);
      expect(compassLimitHints.every((p) => p.kind == CompassPromptKind.limit), isTrue);
    });

    test('every prompt has non-empty text in all four languages, unique ids', () {
      final all = [...compassQuestions, ...compassNotes, ...compassLimitHints];
      expect(all.map((p) => p.id).toSet(), hasLength(all.length));
      for (final prompt in all) {
        for (final language in _languages) {
          expect(prompt.text[language]?.trim(), isNotEmpty,
              reason: '${prompt.id} $language');
        }
      }
    });

    test('limit hints fit adding and moving (no "the new one")', () {
      final newOne = RegExp(r'\bnew one\b|\bdie neue\b|\bla nouvelle\b|\bla nueva\b',
          caseSensitive: false);
      for (final hint in compassLimitHints) {
        for (final language in _languages) {
          expect(hint.text[language], isNot(contains(newOne)),
              reason: '${hint.id} $language');
        }
      }
    });

    test('German says "Vorhaben", never "Absicht"', () {
      final all = [...compassQuestions, ...compassNotes, ...compassLimitHints];
      for (final prompt in all) {
        expect(prompt.text['de'], isNot(contains('Absicht')), reason: prompt.id);
      }
    });

    test('textFor fills placeholders and falls back to English', () {
      final note = compassNotes.firstWhere((p) => p.text['en']!.contains('{weeks}'));
      expect(note.textFor('de', replacements: {'weeks': '1912'}), contains('1912'));
      expect(note.textFor('xx'), note.text['en']);
    });
  });

  group('week index', () {
    test('counts weeks from the epoch Monday without yearly reset', () {
      expect(compassWeekIndex(DateTime(2024, 1, 1)), 0);
      expect(compassWeekIndex(DateTime(2024, 1, 7, 23, 59)), 0);
      expect(compassWeekIndex(DateTime(2024, 1, 8)), 1);
      expect(compassWeekIndex(DateTime(2023, 12, 31)), -1);
      expect(compassWeekIndex(DateTime(2025, 1, 6)), 53);
    });

    test('ISO week keys', () {
      expect(isoWeekKey(DateTime(2026, 11, 5)), '2026-W45');
      expect(isoWeekKey(DateTime(2021, 1, 3)), '2020-W53');
      expect(isoWeekKey(DateTime(2024, 12, 30)), '2025-W01');
    });

    test('ISO week year and number', () {
      expect(isoWeekOf(DateTime(2026, 11, 8)), (year: 2026, week: 45));
      expect(isoWeekOf(DateTime(2026, 11, 9)), (year: 2026, week: 46));
      expect(isoWeekOf(DateTime(2021, 1, 3)), (year: 2020, week: 53));
      expect(isoWeekOf(DateTime(2024, 12, 30)), (year: 2025, week: 1));
    });
  });

  group('questionForWeek', () {
    test('is the same on every day of a week', () {
      final ids = {
        for (var d = 0; d < 7; d++)
          questionForWeek(DateTime(2026, 11, 2 + d), ageYears: 36.5, gentleOnly: false).id,
      };
      expect(ids, hasLength(1));
    });

    test('asks courage on even weeks only, cycling all gentle kinds', () {
      final oddKinds = <CompassPromptKind>{};
      for (var w = -12; w < 60; w++) {
        final kind = questionForWeek(_week(w), ageYears: 30, gentleOnly: false).kind;
        if (w.isEven) {
          expect(kind, CompassPromptKind.courage, reason: 'week $w');
        } else {
          expect(kind, isNot(CompassPromptKind.courage), reason: 'week $w');
          oddKinds.add(kind);
        }
      }
      expect(oddKinds, CompassPromptKind.gentle.toSet());
    });

    test('gentleOnly never asks courage', () {
      final kinds = {
        for (var w = 0; w < 30; w++)
          questionForWeek(_week(w), ageYears: 50, gentleOnly: true).kind,
      };
      expect(kinds, CompassPromptKind.gentle.toSet());
    });

    test('rotates through different prompts of a kind', () {
      final ids = {
        for (var w = 0; w < 40; w += 2)
          questionForWeek(_week(w), ageYears: 40, gentleOnly: false).id,
      };
      expect(ids, hasLength(20));
    });

    test('only picks prompts for the life stage of the age', () {
      for (final age in [10.0, 22.4, 37.9, 50.0, 66.0, 81.0]) {
        final stage = LifeStage.fromAge(age.floor());
        for (var w = 0; w < 120; w++) {
          for (final gentleOnly in [false, true]) {
            final prompt = questionForWeek(_week(w), ageYears: age, gentleOnly: gentleOnly);
            expect(prompt.fitsStage(stage), isTrue, reason: '${prompt.id} $age');
          }
        }
      }
    });

    test('swap gives a different, gentle prompt', () {
      for (var w = 0; w < 24; w++) {
        for (final gentleOnly in [false, true]) {
          final original = questionForWeek(_week(w), ageYears: 45, gentleOnly: gentleOnly);
          final swapped =
              questionForWeek(_week(w), ageYears: 45, gentleOnly: gentleOnly, swap: 1);
          expect(swapped.id, isNot(original.id));
          expect(swapped.kind, isNot(CompassPromptKind.courage));
        }
      }
    });
  });

  group('swapped question', () {
    const ages = [10.0, 22.4, 37.9, 45.0, 50.0, 66.0, 81.0];

    test('never repeats a question of the weeks around it', () {
      for (final age in ages) {
        final stage = LifeStage.fromAge(age.floor());
        for (final gentleOnly in [false, true]) {
          for (var w = -30; w < 160; w++) {
            final swapped = questionForWeek(_week(w),
                ageYears: age, gentleOnly: gentleOnly, swap: 1);
            expect(swapped.kind, isNot(CompassPromptKind.courage));
            expect(swapped.fitsStage(stage), isTrue, reason: swapped.id);
            for (var other = w - compassSwapDistinctWeeks;
                other <= w + compassSwapDistinctWeeks;
                other++) {
              final unswapped = questionForWeek(_week(other),
                  ageYears: age, gentleOnly: gentleOnly);
              expect(swapped.id, isNot(unswapped.id),
                  reason: 'age $age gentle $gentleOnly week $w vs $other');
            }
          }
        }
      }
    });

    test('is deterministic per week', () {
      for (var w = 0; w < 20; w++) {
        expect(
          questionForWeek(_week(w), ageYears: 30, gentleOnly: false, swap: 1).id,
          questionForWeek(_week(w).add(const Duration(days: 3)),
                  ageYears: 30, gentleOnly: false, swap: 1)
              .id,
        );
      }
    });

    test('consecutive weeks never share a question', () {
      for (final age in ages) {
        for (final gentleOnly in [false, true]) {
          for (var w = -30; w < 160; w++) {
            final a = questionForWeek(_week(w), ageYears: age, gentleOnly: gentleOnly);
            final b =
                questionForWeek(_week(w + 1), ageYears: age, gentleOnly: gentleOnly);
            expect(a.id, isNot(b.id), reason: 'age $age gentle $gentleOnly week $w');
          }
        }
      }
    });
  });

  group('phase questions', () {
    const ages = [10.0, 22.4, 37.9, 45.0, 50.0, 66.0, 81.0];

    test('contain {phase} in every language; no other prompt does', () {
      for (final prompt in [
        ...compassQuestions,
        ...compassNotes,
        ...compassLimitHints,
      ]) {
        for (final language in _languages) {
          expect(prompt.text[language]!.contains('{phase}'), prompt.phase,
              reason: '${prompt.id} $language');
        }
      }
    });

    test('fits only with a phase', () {
      final phaseQuestion = compassQuestions.firstWhere((p) => p.phase);
      final other = compassQuestions.firstWhere((p) => !p.phase);
      expect(phaseQuestion.fits(LifeStage.midlife, hasPhase: false), isFalse);
      expect(phaseQuestion.fits(LifeStage.midlife, hasPhase: true), isTrue);
      expect(other.fits(LifeStage.midlife, hasPhase: false),
          other.fitsStage(LifeStage.midlife));
    });

    test('are never asked without a phase (also swapped)', () {
      for (final age in ages) {
        for (final gentleOnly in [false, true]) {
          for (var w = 0; w < 200; w++) {
            for (final swap in [0, 1]) {
              final prompt = questionForWeek(_week(w),
                  ageYears: age, gentleOnly: gentleOnly, swap: swap);
              expect(prompt.phase, isFalse,
                  reason: '${prompt.id} age $age week $w swap $swap');
            }
          }
        }
      }
    });

    test('with a phase, every other turn of each kind asks one', () {
      for (final gentleOnly in [false, true]) {
        final asked = <CompassPromptKind, Set<String>>{};
        var phaseWeeks = 0;
        for (var w = 0; w < 200; w++) {
          final prompt = questionForWeek(_week(w),
              ageYears: 40, gentleOnly: gentleOnly, hasPhase: true);
          if (!prompt.phase) continue;
          phaseWeeks++;
          asked.putIfAbsent(prompt.kind, () => {}).add(prompt.id);
        }
        final kinds = gentleOnly
            ? CompassPromptKind.gentle
            : [CompassPromptKind.courage, ...CompassPromptKind.gentle];
        for (final kind in kinds) {
          // All three phase questions of every kind come up.
          expect(asked[kind], hasLength(3), reason: '$kind gentle $gentleOnly');
        }
        expect(phaseWeeks, inInclusiveRange(95, 105),
            reason: 'gentle $gentleOnly');
      }
    });

    test('with a phase, other turns keep the rotation without a phase', () {
      for (final gentleOnly in [false, true]) {
        for (var w = -30; w < 160; w++) {
          final withPhase = questionForWeek(_week(w),
              ageYears: 40, gentleOnly: gentleOnly, hasPhase: true);
          if (withPhase.phase) continue;
          expect(
              withPhase.id,
              questionForWeek(_week(w), ageYears: 40, gentleOnly: gentleOnly)
                  .id,
              reason: 'week $w');
        }
      }
    });

    test('with a phase, kinds and life stages still hold', () {
      for (final age in ages) {
        final stage = LifeStage.fromAge(age.floor());
        for (var w = -12; w < 120; w++) {
          final prompt = questionForWeek(_week(w),
              ageYears: age, gentleOnly: false, hasPhase: true);
          expect(prompt.kind == CompassPromptKind.courage, w.isEven,
              reason: 'week $w');
          expect(prompt.fits(stage, hasPhase: true), isTrue, reason: prompt.id);
          final gentle = questionForWeek(_week(w),
              ageYears: age, gentleOnly: true, hasPhase: true);
          expect(gentle.kind, isNot(CompassPromptKind.courage));
        }
      }
    });

    test('swap with a phase stays gentle and distinct from the weeks around',
        () {
      for (final age in ages) {
        for (final gentleOnly in [false, true]) {
          for (var w = -30; w < 160; w++) {
            final swapped = questionForWeek(_week(w),
                ageYears: age, gentleOnly: gentleOnly, swap: 1, hasPhase: true);
            expect(swapped.kind, isNot(CompassPromptKind.courage));
            for (var other = w - compassSwapDistinctWeeks;
                other <= w + compassSwapDistinctWeeks;
                other++) {
              final unswapped = questionForWeek(_week(other),
                  ageYears: age, gentleOnly: gentleOnly, hasPhase: true);
              expect(swapped.id, isNot(unswapped.id),
                  reason: 'age $age gentle $gentleOnly week $w vs $other');
            }
          }
        }
      }
    });

    test('consecutive weeks never share a question with a phase', () {
      for (final gentleOnly in [false, true]) {
        for (var w = -30; w < 160; w++) {
          final a = questionForWeek(_week(w),
              ageYears: 40, gentleOnly: gentleOnly, hasPhase: true);
          final b = questionForWeek(_week(w + 1),
              ageYears: 40, gentleOnly: gentleOnly, hasPhase: true);
          expect(a.id, isNot(b.id), reason: 'gentle $gentleOnly week $w');
        }
      }
    });
  });

  test('noteForWeek and limitHint are deterministic', () {
    expect(noteForWeek(DateTime(2026, 11, 2)).id, noteForWeek(DateTime(2026, 11, 8)).id);
    expect(noteForWeek(DateTime(2026, 11, 2)).id, isNot(noteForWeek(DateTime(2026, 11, 9)).id));
    expect(limitHint(3).id, limitHint(3 + compassLimitHints.length).id);
    expect(limitHint(-1).kind, CompassPromptKind.limit);
  });
}
