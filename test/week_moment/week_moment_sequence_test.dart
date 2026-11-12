import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';

void main() {
  const week = WeekMomentAct.week;
  const phase = WeekMomentAct.phase;
  const life = WeekMomentAct.life;
  const next = WeekMomentAct.next;
  final withPhase = actsFor(hasPhase: true);
  final withoutPhase = actsFor(hasPhase: false);

  MomentState entering(WeekMomentAct act, List<WeekMomentAct> acts) =>
      MomentState(act, MomentPhase.entering, isFinal: act == acts.last);
  MomentState holding(WeekMomentAct act, List<WeekMomentAct> acts) =>
      MomentState(act, MomentPhase.holding, isFinal: act == acts.last);

  group('actsFor', () {
    test('with a phase shows all four acts', () {
      expect(withPhase, [week, phase, life, next]);
    });

    test('without a phase skips the phase act', () {
      expect(withoutPhase, [week, life, next]);
    });
  });

  group('WeekMomentTiming', () {
    const timing = WeekMomentTiming();

    test('enter and hold per act', () {
      expect(timing.enter(week), const Duration(milliseconds: 900));
      expect(timing.hold(week), const Duration(milliseconds: 3600));
      expect(timing.enter(phase), const Duration(milliseconds: 2000));
      expect(timing.hold(phase), const Duration(milliseconds: 3000));
      expect(timing.enter(life), const Duration(milliseconds: 1800));
      expect(timing.hold(life), const Duration(milliseconds: 3400));
      expect(timing.enter(next), const Duration(milliseconds: 1400));
      expect(timing.hold(next), isNull);
    });

    test('the final act closes the week, then plans the next one', () {
      expect(ClosingStep.values, [ClosingStep.close, ClosingStep.plan]);
      expect(ClosingStep.close.number, 1);
      expect(ClosingStep.plan.number, 2);
      expect(ClosingStep.count, 2);
    });

    test('run time ends when the final act has entered', () {
      expect(timing.runTime(withPhase), const Duration(milliseconds: 16100));
      expect(timing.runTime(withoutPhase), const Duration(milliseconds: 11100));
    });

    test('both act lists take roughly 10 to 16 seconds', () {
      for (final acts in [withPhase, withoutPhase]) {
        final seconds = timing.runTime(acts).inMilliseconds / 1000;
        expect(seconds, inInclusiveRange(10, 16.5), reason: '$acts');
      }
    });
  });

  group('MomentState', () {
    test('initial is the first act, entering', () {
      expect(MomentState.initial(withPhase), entering(week, withPhase));
      expect(MomentState.initial(withPhase).isFinal, isFalse);
    });

    test('isFinal only on the last act', () {
      expect(holding(next, withPhase).isFinal, isTrue);
      expect(holding(life, withPhase).isFinal, isFalse);
    });
  });

  group('reduce', () {
    for (final acts in [withPhase, withoutPhase]) {
      group('${acts.length} acts', () {
        MomentState run(MomentState s, MomentEvent e) => reduce(s, e, acts);

        test('entered -> holding the same act', () {
          for (final act in acts) {
            expect(
              run(entering(act, acts), MomentEvent.entered),
              holding(act, acts),
            );
          }
        });

        test('tap while entering -> holding the same act', () {
          for (final act in acts) {
            expect(
              run(entering(act, acts), MomentEvent.tap),
              holding(act, acts),
            );
          }
        });

        test('tap or hold elapsed while holding -> next act entering', () {
          for (var i = 0; i < acts.length - 1; i++) {
            final expected = entering(acts[i + 1], acts);
            expect(run(holding(acts[i], acts), MomentEvent.tap), expected);
            expect(
              run(holding(acts[i], acts), MomentEvent.holdElapsed),
              expected,
            );
          }
        });

        test('tap or hold elapsed on the final act holding -> unchanged', () {
          final last = holding(next, acts);
          expect(run(last, MomentEvent.tap), last);
          expect(run(last, MomentEvent.holdElapsed), last);
        });

        test('skip -> final act holding', () {
          for (final act in acts.take(acts.length - 1)) {
            expect(
              run(entering(act, acts), MomentEvent.skip),
              holding(next, acts),
            );
            expect(
              run(holding(act, acts), MomentEvent.skip),
              holding(next, acts),
            );
          }
        });

        test('skip on the final act is a no-op', () {
          expect(
            run(entering(next, acts), MomentEvent.skip),
            entering(next, acts),
          );
          expect(
            run(holding(next, acts), MomentEvent.skip),
            holding(next, acts),
          );
        });

        test('stray events are ignored', () {
          expect(
            run(holding(week, acts), MomentEvent.entered),
            holding(week, acts),
          );
          expect(
            run(entering(week, acts), MomentEvent.holdElapsed),
            entering(week, acts),
          );
        });

        test('taps walk through every act and stop at the end', () {
          var state = MomentState.initial(acts);
          final seen = <WeekMomentAct>{state.act};
          for (var i = 0; i < acts.length * 3; i++) {
            state = run(state, MomentEvent.tap);
            seen.add(state.act);
          }
          expect(seen.toList(), acts);
          expect(state, holding(next, acts));
        });
      });
    }
  });
}
