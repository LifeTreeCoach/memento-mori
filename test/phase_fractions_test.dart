import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_ribbon.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/since_stepper.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_actions.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

LifePhase _phase(String id, DateTime start, {DateTime? plannedEnd}) =>
    LifePhase(id: id, start: start, plannedEnd: plannedEnd);

void main() {
  final birth = DateTime(2000, 1, 1);
  final today = DateTime(2040, 1, 1);
  double at(DateTime d) => lifeFraction(d, birth, 80);

  group('lifeFraction', () {
    test('birth is 0, half the lifespan 0.5, the expected end 1', () {
      expect(at(birth), 0);
      expect(at(today), closeTo(0.5, 0.001));
      expect(at(DateTime(2080, 1, 1)), 1);
    });

    test('clamped outside the lifespan, 0 without a life expectancy', () {
      expect(at(DateTime(1990)), 0);
      expect(at(DateTime(2100)), 1);
      expect(lifeFraction(today, birth, 0), 0);
    });

    test('ignores the time of day', () {
      expect(at(DateTime(2040, 1, 1, 23, 59)), at(today));
    });
  });

  group('LifespanBarFractions', () {
    test('lived before the phase, the phase until today, its plan', () {
      final bar = LifespanBarFractions.of(
        birthDate: birth,
        lifeExpectancyYears: 80,
        start: DateTime(2032, 1, 1),
        today: today,
        plannedEnd: DateTime(2048, 1, 1),
      );
      expect(bar.phaseStart, closeTo(0.4, 0.001));
      expect(bar.today, closeTo(0.5, 0.001));
      expect(bar.plannedEnd, closeTo(0.6, 0.001));
    });

    test('no plan, or a past plan, ends at today', () {
      final open = LifespanBarFractions.of(birthDate: birth,
          lifeExpectancyYears: 80, start: birth, today: today);
      expect(open.phaseStart, 0);
      expect(open.plannedEnd, open.today);
      final past = LifespanBarFractions.of(birthDate: birth,
          lifeExpectancyYears: 80, start: birth, today: today,
          plannedEnd: DateTime(2030));
      expect(past.plannedEnd, past.today);
    });

    test('lerp interpolates every edge', () {
      const a = LifespanBarFractions(phaseStart: 0, today: 0.2, plannedEnd: 0.4);
      const b = LifespanBarFractions(phaseStart: 0.2, today: 0.4, plannedEnd: 0.8);
      final mid = LifespanBarFractions.lerp(a, b, 0.5);
      expect(mid.phaseStart, closeTo(0.1, 1e-9));
      expect(mid.today, closeTo(0.3, 1e-9));
      expect(mid.plannedEnd, closeTo(0.6, 1e-9));
    });
  });

  group('ribbonSegments', () {
    List<RibbonSegment> segments(List<LifePhase> phases) => ribbonSegments(
        resolvePhases(phases, today),
        birthDate: birth, lifeExpectancyYears: 80, today: today);

    test('without phases everything lived is "before"', () {
      final only = segments([]).single;
      expect(only.tone, RibbonTone.before);
      expect(only.to, closeTo(0.5, 0.001));
    });

    test('before, earlier phases, current and planned in order', () {
      final result = segments([
        _phase('study', DateTime(2020, 1, 1)),
        _phase('job', DateTime(2024, 1, 1)),
        _phase('now', DateTime(2032, 1, 1), plannedEnd: DateTime(2048, 1, 1)),
      ]);
      expect(result.map((s) => s.tone), [
        RibbonTone.before,
        RibbonTone.earlier,
        RibbonTone.earlier,
        RibbonTone.current,
        RibbonTone.planned,
      ]);
      expect(result.map((s) => s.earlierIndex).take(3), [0, 0, 1]);
      expect(result[1].from, closeTo(0.25, 0.001));
      expect(result[2].from, closeTo(0.3, 0.001));
      expect(result[3].from, closeTo(0.4, 0.001));
      expect(result[3].to, closeTo(0.5, 0.001));
      expect(result[4].to, closeTo(0.6, 0.001));
      for (var i = 1; i < result.length; i++) {
        expect(result[i].from, result[i - 1].to);
      }
    });

    test('empty stretches are dropped (phase from birth, started today)', () {
      final result = segments([_phase('a', birth), _phase('b', today)]);
      expect(result.map((s) => s.tone), [RibbonTone.earlier]);
    });

    test('the painter colours each tone from PhaseColors', () {
      final colors = PhaseColors.stoicLight;
      final painter = PhaseRibbonPainter(
          segments: const [], phaseColors: colors, remaining: Colors.white);
      expect(painter.colorOf(const RibbonSegment(0, 1, RibbonTone.before)),
          colors.before);
      expect(
          painter.colorOf(
              const RibbonSegment(0, 1, RibbonTone.earlier, earlierIndex: 5)),
          colors.earlierAt(5));
      expect(painter.colorOf(const RibbonSegment(0, 1, RibbonTone.current)),
          colors.current);
      expect(painter.colorOf(const RibbonSegment(0, 1, RibbonTone.planned)),
          colors.planned);
    });
  });

  group('SinceSteps', () {
    test('years keep the months and stop at the bound', () {
      expect(SinceSteps.addYears(50, 1, 100), 62);
      expect(SinceSteps.addYears(50, -1, 100), 38);
      expect(SinceSteps.addYears(5, -1, 100), isNull);
      expect(SinceSteps.addYears(87, 1, 100), 99);
      expect(SinceSteps.addYears(91, 1, 100), 100);
      expect(SinceSteps.addYears(100, 1, 100), isNull);
      expect(SinceSteps.addYears(95, 0, 100), 95);
    });

    test('months stay within 0..11 and the bound', () {
      expect(SinceSteps.addMonths(0, 1, 100), 1);
      expect(SinceSteps.addMonths(0, -1, 100), isNull);
      expect(SinceSteps.addMonths(11, 1, 100), isNull);
      expect(SinceSteps.addMonths(100, 1, 100), isNull);
    });

    test('years up clamps the months to the bound', () {
      expect(SinceSteps.addYears(11, 1, 20), 20);
    });
  });

  test('monthsAfter adds calendar months (day clamped)', () {
    expect(monthsAfter(DateTime(2026, 11, 6), 6), DateTime(2027, 5, 6));
    expect(monthsAfter(DateTime(2026, 8, 31), 6), DateTime(2027, 2, 28));
  });
}
