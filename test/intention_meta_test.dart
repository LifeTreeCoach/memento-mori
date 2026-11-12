import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_meta.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/time_window.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/look_back.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';

final DateTime _today = DateTime(2026, 11, 2);

LifePhase _phase({DateTime? plannedEnd, String id = 'p1'}) => LifePhase(
      id: id,
      preset: PhasePreset.buildUp,
      start: DateTime(2024, 3, 1),
      plannedEnd: plannedEnd,
    );

PhaseSpan _span(LifePhase phase) =>
    PhaseSpan(phase: phase, start: phase.start, isCurrent: true);

Intention _intention({
  IntentionKind? kind,
  String? phaseId = 'p1',
  DateTime? dueDate,
  String id = 'i1',
}) =>
    Intention(
      id: id,
      title: 'Norway',
      status: IntentionStatus.now,
      createdAt: _today,
      kind: kind,
      phaseId: phaseId,
      dueDate: dueDate,
    );

void main() {
  setUpAll(() async {
    for (final code in AppLocalizations.supportedLanguages) {
      await initializeDateFormatting(code);
    }
  });

  group('intentionMetaOf', () {
    final planned = _span(_phase(plannedEnd: DateTime(2028, 1, 15)));

    test('doTask in the current phase gets the planned time left', () {
      final meta = intentionMetaOf(_intention(kind: IntentionKind.doTask),
          current: planned, today: _today);
      expect(meta.kind, IntentionKind.doTask);
      expect(meta.monthsLeft, 14);
      expect(meta.weeksLeft, plannedWeeksLeft(planned, _today));
    });

    test('doTask of another or no phase: no time left', () {
      for (final phaseId in ['other', null]) {
        final meta = intentionMetaOf(
            _intention(kind: IntentionKind.doTask, phaseId: phaseId),
            current: planned, today: _today);
        expect(meta.monthsLeft, isNull);
      }
    });

    test('doTask without a planned end or phase: no time left', () {
      final open = _span(_phase());
      for (final current in [open, null]) {
        final meta = intentionMetaOf(_intention(kind: IntentionKind.doTask),
            current: current, today: _today);
        expect(meta.kind, IntentionKind.doTask);
        expect(meta.monthsLeft, isNull);
      }
    });

    test('enjoy carries its date, never time pressure', () {
      final due = DateTime(2027, 6, 12);
      final meta = intentionMetaOf(
          _intention(kind: IntentionKind.enjoy, dueDate: due),
          current: planned, today: _today);
      expect(meta.kind, IntentionKind.enjoy);
      expect(meta.dueDate, due);
      expect(meta.monthsLeft, isNull);
    });

    test('no kind: nothing to tell', () {
      final meta =
          intentionMetaOf(_intention(), current: planned, today: _today);
      expect(meta.kind, isNull);
    });
  });

  group('phaseYearOf', () {
    final phase = _phase();
    CompassData data(DateTime done) => CompassData(
          phases: [phase],
          intentions: [_intention()],
          moments: [
            Moment(id: 'm', title: 'Norway', date: done, fromIntentionId: 'i1'),
          ],
        );

    test('counts years of the phase from 1', () {
      for (final (date, year) in [
        (DateTime(2024, 3, 1), 1),
        (DateTime(2025, 2, 28), 1),
        (DateTime(2025, 3, 1), 2),
        (DateTime(2026, 11, 2), 3),
      ]) {
        final d = data(date);
        expect(phaseYearOf(d.moments.single, d)?.year, year, reason: '$date');
      }
    });

    test('null without intention, phase, or before the phase', () {
      final free = Moment(id: 'x', title: 'x', date: _today);
      expect(phaseYearOf(free, data(_today)), isNull);
      final early = data(DateTime(2020, 1, 1));
      expect(phaseYearOf(early.moments.single, early), isNull);
      final noPhase = CompassData(
          intentions: [_intention(phaseId: null)],
          moments: data(_today).moments);
      expect(phaseYearOf(noPhase.moments.single, noPhase), isNull);
    });
  });

  group('moment phase: tile and look back agree', () {
    // Phase A (build-up) from 2024-03-01, phase B from 2029-03-01; an
    // intention of A is completed on the day B starts.
    final phaseA = _phase(id: 'a');
    final phaseB = LifePhase(
        id: 'b', preset: PhasePreset.calmer, start: DateTime(2029, 3, 1));
    final bStart = phaseB.start;
    final data = CompassData(
      phases: [phaseA, phaseB],
      intentions: [_intention(phaseId: 'a')],
      moments: [
        Moment(id: 'm', title: 'Norway', date: bStart, fromIntentionId: 'i1'),
        Moment(id: 'f', title: 'Free', date: bStart),
      ],
    );
    final spans = resolvePhases(data.phases, DateTime(2030));
    final fromIntention = data.moments.first;
    final free = data.moments.last;

    test('a moment from an intention belongs to the intention phase', () {
      expect(phaseYearOf(fromIntention, data)?.phase.id, 'a');
      expect(phaseYearOf(fromIntention, data)?.year, 6);
      expect(
          phaseSpanOfMoment(fromIntention,
                  intentions: data.intentions, spans: spans)
              ?.phase
              .id,
          'a');
      final byPhase = LookBack.of(data.moments,
              phases: spans, intentions: data.intentions)
          .byPhase;
      expect([for (final (p, n) in byPhase) (p.id, n)], [('a', 1), ('b', 1)]);
    });

    test('a free moment is grouped by its date', () {
      expect(
          phaseSpanOfMoment(free, intentions: data.intentions, spans: spans)
              ?.phase
              .id,
          'b');
      expect(phaseYearOf(free, data), isNull);
    });

    test('an unknown intention phase falls back to the date', () {
      final orphan = CompassData(
        phases: data.phases,
        intentions: [_intention(phaseId: 'gone')],
        moments: [fromIntention],
      );
      expect(
          phaseSpanOfMoment(fromIntention,
                  intentions: orphan.intentions, spans: spans)
              ?.phase
              .id,
          'b');
    });
  });

  group('time window', () {
    test('phaseWeeks: lived and planned weeks, null when open', () {
      final weeks =
          phaseWeeks(_span(_phase(plannedEnd: DateTime(2027, 11, 1))), _today);
      expect(weeks!.left, 52);
      expect(weeks.lived, 139);
      expect(weeks.total, 191);
      expect(phaseWeeks(_span(_phase()), _today), isNull);
    });

    test('weeksShareOfLifespan', () {
      expect(weeksShareOfLifespan(60, 80), closeTo(0.0144, 0.0001));
      expect(weeksShareOfLifespan(60, 0), isNull);
    });

    test('weeksPerDot keeps the row at 120 dots at most', () {
      expect(weeksPerDot(120), 1);
      expect(weeksPerDot(121), 4);
      expect(weeksPerDot(480), 4);
      expect(weeksPerDot(481), 13);
      expect(weeksPerDot(5000), 52);
      expect(dotsFor(121, 4), 31);
    });
  });

  group('labels', () {
    final en = AppLocalizations(const Locale('en'));
    final de = AppLocalizations(const Locale('de'));
    final fr = AppLocalizations(const Locale('fr'));

    test('meta lines', () {
      expect(
          de.kindMetaText(
              const IntentionMeta(kind: IntentionKind.doTask, monthsLeft: 14),
              today: _today),
          'Vorhaben · noch ~14 Monate in dieser Phase');
      expect(
          de.kindMetaText(
              const IntentionMeta(kind: IntentionKind.doTask, monthsLeft: 0,
                  weeksLeft: 3),
              today: _today),
          'Vorhaben · noch ~3 Wochen in dieser Phase');
      expect(de.kindMetaText(const IntentionMeta(kind: IntentionKind.doTask),
          today: _today), 'Vorhaben');
      expect(de.kindMetaText(const IntentionMeta(kind: IntentionKind.enjoy),
          today: _today), 'Genießen · ohne Eile, aber nicht ohne Termin');
      expect(
          de.kindMetaText(
              IntentionMeta(
                  kind: IntentionKind.enjoy, dueDate: DateTime(2026, 6, 12)),
              today: DateTime(2026, 1, 1)),
          'Genießen · am 12. Juni');
      expect(en.kindMetaText(const IntentionMeta(), today: _today), isNull);
    });

    test('phase year', () {
      final year3 = PhaseYear(_phase(), 3);
      expect(de.phaseYearText(year3), 'Erledigt · Aufbauphase, 3.\u00A0Jahr');
      expect(en.phaseYearText(year3), 'Done · Building up, year\u00A03');
      expect(fr.phaseYearText(PhaseYear(_phase(), 1)), contains('1re\u00A0année'));
    });

    test('percent with one decimal below 10 %', () {
      expect(de.percentText(0.0144), '1,4');
      expect(en.percentText(0.0144), '1.4');
      expect(en.percentText(0.125), '13');
      expect(en.percentText(0.0001), '<0.1');
    });

    test('rhythm sentence follows the rhythm, none when off', () {
      expect(de.rhythmSentence(ReminderRhythm.every4Weeks),
          'Du wirst alle vier Wochen kurz gefragt, ob es vorangeht.');
      expect(de.rhythmSentence(ReminderRhythm.weekly),
          'Sonntags erinnert dich der Kompass an deine Vorhaben.');
      expect(de.rhythmSentence(ReminderRhythm.off), isNull);
    });

    test('Now count', () {
      expect(de.nowCountText(2), '2 von 3 · Rest darf warten');
    });
  });
}
