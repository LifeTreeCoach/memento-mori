import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/completion_story.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/reflection/reflection_texts.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:flutter/widgets.dart' show Locale;

final DateTime _today = DateTime(2026, 11, 2);
final DateTime _birth = DateTime(1990, 11, 17);

Intention _intention({
  DateTime? createdAt,
  String? phaseId,
  IntentionKind? kind,
  String id = 'i1',
}) =>
    Intention(
      id: id,
      title: 'Call Mum',
      status: IntentionStatus.now,
      createdAt: createdAt ?? _today,
      phaseId: phaseId,
      kind: kind,
    );

Moment _moment(Intention intention, [DateTime? date]) => Moment(
      id: 'm1',
      title: intention.title,
      date: date ?? _today,
      fromIntentionId: intention.id,
    );

CompletionStory _story(
  Intention intention, {
  List<LifePhase> phases = const [],
  DateTime? birthDate,
  DateTime? doneOn,
}) =>
    CompletionStory.of(
      intention: intention,
      moment: _moment(intention, doneOn),
      phases: phases,
      birthDate: birthDate,
      lifeExpectancyYears: 80,
      today: _today,
    );

void main() {
  group('TakenTime', () {
    TakenTime taken(int days) =>
        TakenTime.between(_today.subtract(Duration(days: days)), _today);

    test('same day, days under a week, then weeks', () {
      expect(taken(0), const TakenTime(TakenUnit.sameDay, 0));
      expect(taken(1), const TakenTime(TakenUnit.days, 1));
      expect(taken(6), const TakenTime(TakenUnit.days, 6));
      expect(taken(7), const TakenTime(TakenUnit.weeks, 1));
      expect(taken(44), const TakenTime(TakenUnit.weeks, 6));
      expect(taken(16 * 7 + 6), const TakenTime(TakenUnit.weeks, 16));
    });

    test('months after about four months, and only those are long', () {
      final months = TakenTime.between(DateTime(2026, 5, 2), _today);
      expect(months, const TakenTime(TakenUnit.months, 6));
      expect(months.isLong, isTrue);
      expect(taken(16 * 7).isLong, isFalse);
      expect(TakenTime.between(DateTime(2026, 7, 5), _today),
          const TakenTime(TakenUnit.months, 3));
    });
  });

  group('phase level', () {
    final phase = LifePhase(
      id: 'p',
      preset: PhasePreset.buildUp,
      start: DateTime(2026, 9, 1),
      plannedEnd: DateTime(2027, 9, 1),
    );

    test('week in the phase (1 = first week) and the dots', () {
      final story = _story(_intention(phaseId: 'p'), phases: [phase]);
      // 2026-09-01 .. 2026-11-02 = 62 days = 8 full weeks -> week 9.
      expect(story.phase!.weekInPhase, 9);
      expect(story.phase!.weekIndex, 8);
      expect(story.phase!.weeks.lived, 9);
      expect(story.phase!.weeks.left,
          LifeCalculator(birthDate: _today, now: phase.plannedEnd).weeksLived);
      expect(story.phase!.phase.id, 'p');
    });

    test('the first day of a phase is its week 1', () {
      final story =
          _story(_intention(), phases: [phase], doneOn: phase.start);
      expect(story.phase!.weekInPhase, 1);
    });

    test('without a planned end there is no planned rest', () {
      final open = LifePhase(id: 'o', start: DateTime(2026, 10, 1), name: 'X');
      final story = _story(_intention(phaseId: 'o'), phases: [open]);
      expect(story.phase!.weeks.left, 0);
      expect(story.phase!.weeks.lived, story.phase!.weekInPhase);
    });

    test('without a phase the level drops out', () {
      expect(_story(_intention()).phase, isNull);
      final later = LifePhase(id: 'l', name: 'Later', start: DateTime(2027));
      expect(_story(_intention(), phases: [later]).phase, isNull);
    });

    test('the intention\'s phase wins over the date', () {
      final older = LifePhase(id: 'a', name: 'A', start: DateTime(2026, 1, 1));
      final newer = LifePhase(id: 'b', name: 'B', start: DateTime(2026, 6, 1));
      // Without a phase on the intention, the date decides.
      expect(_story(_intention(), phases: [older, newer]).phase!.phase.id, 'b');
      // Done after its own phase ended: no week position to tell.
      expect(
          _story(_intention(phaseId: 'a'), phases: [older, newer]).phase,
          isNull);
      // Done in the intention's phase: that phase.
      final done = _story(_intention(phaseId: 'a'),
          phases: [older, newer], doneOn: DateTime(2026, 3, 1));
      expect(done.phase!.phase.id, 'a');
      expect(done.phase!.weekInPhase, 9);
    });
  });

  group('life levels', () {
    test('week of life, weeks ahead and the position', () {
      final story = _story(_intention(), birthDate: _birth);
      final calc = LifeCalculator(birthDate: _birth, now: _today);
      final life = story.life!;
      expect(life.weekOfLife, calc.weeksLived + 1);
      expect(life.totalWeeks, 80 * 52);
      expect(life.weeksRemaining, calc.weeksRemaining);
      expect(life.position, lifeFraction(_today, _birth, 80));
      // No phase: no gold band, the bar ends at today.
      expect(life.bar.phaseStart, life.bar.today);
    });

    test('the bar shows the current phase and its planned rest', () {
      final phase = LifePhase(
          id: 'p',
          name: 'P',
          start: DateTime(2026, 1, 1),
          plannedEnd: DateTime(2028, 1, 1));
      final bar =
          _story(_intention(phaseId: 'p'), phases: [phase], birthDate: _birth)
              .life!
              .bar;
      expect(bar.phaseStart, lessThan(bar.today));
      expect(bar.plannedEnd, greaterThan(bar.today));
    });

    test('without a birth date both life levels drop out', () {
      expect(_story(_intention()).life, isNull);
    });

    test('beyond the life expectancy no weeks remain', () {
      final story = _story(_intention(), birthDate: DateTime(1930));
      expect(story.life!.weeksRemaining, 0);
    });
  });

  group('tone and closing line', () {
    test('by kind, a long wait first', () {
      expect(_story(_intention()).tone, GratitudeTone.doTask);
      expect(_story(_intention(kind: IntentionKind.doTask)).tone,
          GratitudeTone.doTask);
      expect(_story(_intention(kind: IntentionKind.enjoy)).tone,
          GratitudeTone.enjoy);
      expect(
          _story(_intention(
                  kind: IntentionKind.enjoy, createdAt: DateTime(2026)))
              .tone,
          GratitudeTone.long);
    });

    test('the index is stable per id and varies between ids', () {
      expect(CompletionStory.stableIndex('abc'),
          CompletionStory.stableIndex('abc'));
      final indexes = {
        for (var i = 0; i < 20; i++) CompletionStory.stableIndex('id$i') % 3,
      };
      expect(indexes, hasLength(3));
      expect(_story(_intention(id: 'x')).gratitudeIndex,
          CompletionStory.stableIndex('x'));
    });
  });

  group('texts', () {
    final de = AppLocalizations(const Locale('de'));
    final en = AppLocalizations(const Locale('en'));

    test('German level sentences', () {
      final phase = LifePhase(
          id: 'p', preset: PhasePreset.buildUp, start: DateTime(2026, 9, 1));
      final story = _story(_intention(phaseId: 'p', createdAt: DateTime(2026, 9, 21)),
          phases: [phase], birthDate: DateTime(1990, 1, 1));
      expect(de.phaseLine(story),
          'Nach 6\u00A0Wochen geschafft\u00A0– in Woche\u00A09 deiner Phase „Aufbauphase“.');
      expect(de.lifeLine(story.life!),
          startsWith('Ein Moment in Woche\u00A01.923 deines Lebens'));
      expect(de.aheadLine(story.life!),
          'Vor dir liegen noch etwa 2.238\u00A0Wochen. Raum für viele weitere solcher Momente.');
    });

    test('without a phase only the time; same day and days', () {
      expect(de.phaseLine(_story(_intention())),
          'Noch am selben Tag geschafft.');
      final days = _story(_intention(createdAt: DateTime(2026, 10, 30)));
      expect(en.phaseLine(days), 'Done after 3\u00A0days.');
    });

    test('something enjoyed is told as lived, not as done', () {
      final fr = AppLocalizations(const Locale('fr'));
      final es = AppLocalizations(const Locale('es'));
      final sameDay = _story(_intention(kind: IntentionKind.enjoy));
      expect(de.phaseLine(sameDay), 'Noch am selben Tag erlebt.');
      expect(en.phaseLine(sameDay), 'Enjoyed the very same day.');
      expect(fr.phaseLine(sameDay), 'Vécu le jour même.');
      expect(es.phaseLine(sameDay), 'Disfrutado el mismo día.');
      final weeks = _story(_intention(
          kind: IntentionKind.enjoy, createdAt: DateTime(2026, 9, 21)));
      expect(de.phaseLine(weeks), 'Nach 6\u00A0Wochen erlebt.');
      expect(fr.phaseLine(weeks), 'Vécu après 6\u00A0semaines.');
      final oneDay = _story(_intention(
          kind: IntentionKind.enjoy, createdAt: DateTime(2026, 11, 1)));
      expect(en.phaseLine(oneDay), 'Enjoyed after 1\u00A0day.');
      expect(es.phaseLine(oneDay), 'Disfrutado tras 1\u00A0día.');
      // A task keeps "done".
      expect(de.phaseLine(_story(_intention(kind: IntentionKind.doTask))),
          'Noch am selben Tag geschafft.');
    });

    test('every tone has its closing lines in every language', () {
      for (final code in AppLocalizations.supportedLanguages) {
        final values = AppLocalizations.valuesFor(code);
        for (final entry in reflectionThanksCount.entries) {
          for (var i = 0; i < entry.value; i++) {
            expect(values['reflection_thanks_${entry.key.name}_$i'], isNotNull,
                reason: '$code ${entry.key.name} $i');
          }
        }
      }
    });

    test('nothing ahead reads as a gift, not as zero', () {
      final story = _story(_intention(), birthDate: DateTime(1930));
      expect(de.aheadLine(story.life!), startsWith('Jede Woche ab jetzt'));
    });
  });
}
