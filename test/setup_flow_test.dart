import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/setup_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fresh = SetupFacts();
const _withPhase = SetupFacts(hasPhase: true, compassEmpty: false);
const _allData = SetupFacts(
  hasPhase: true,
  hasPlannedEndOrOpenChoice: true,
  hasPhaseIntention: true,
  compassEmpty: false,
);

void main() {
  group('CompassSetupProgress JSON', () {
    test('round-trip', () {
      const progress = CompassSetupProgress(
        completed: {SetupStep.duration, SetupStep.rhythm},
        skipped: {SetupStep.intention},
        lastStep: SetupStep.intention,
        cardDismissed: true,
        autoOpened: true,
      );
      expect(CompassSetupProgress.fromJson(progress.toJson()), progress);
    });

    test('tolerates junk', () {
      expect(CompassSetupProgress.fromJson(null), CompassSetupProgress.empty);
      expect(CompassSetupProgress.fromJson('x'), CompassSetupProgress.empty);
      final progress = CompassSetupProgress.fromJson({
        'completed': ['phase', 'nope', 3],
        'skipped': 'rhythm',
        'lastStep': 'later',
        'cardDismissed': 'yes',
      });
      expect(progress.completed, {SetupStep.phase});
      expect(progress.skipped, isEmpty);
      expect(progress.lastStep, isNull);
      expect(progress.cardDismissed, isFalse);
    });

    test('copyWith can clear lastStep', () {
      const progress = CompassSetupProgress(lastStep: SetupStep.rhythm);
      expect(progress.copyWith(autoOpened: true).lastStep, SetupStep.rhythm);
      expect(progress.copyWith(clearLastStep: true).lastStep, isNull);
    });
  });

  group('CompassSetupStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CompassSetupStore.clearCacheForTesting();
    });

    test('save, reload and reset', () async {
      expect(await CompassSetupStore.load(), CompassSetupProgress.empty);
      const progress = CompassSetupProgress(lastStep: SetupStep.duration);
      final before = CompassSetupStore.revision.value;
      await CompassSetupStore.save(progress);
      expect(CompassSetupStore.revision.value, before + 1);

      CompassSetupStore.clearCacheForTesting();
      expect(await CompassSetupStore.load(), progress);

      await CompassSetupStore.reset();
      CompassSetupStore.clearCacheForTesting();
      expect(await CompassSetupStore.load(), CompassSetupProgress.empty);
    });

    test('unreadable storage loads as empty', () async {
      SharedPreferences.setMockInitialValues({'compass_setup': '{broken'});
      expect(await CompassSetupStore.load(), CompassSetupProgress.empty);
    });
  });

  group('steps', () {
    test('phase and intention follow the data', () {
      const progress = CompassSetupProgress(
          completed: {SetupStep.phase, SetupStep.intention});
      expect(isStepDone(SetupStep.phase, _fresh, progress), isFalse);
      expect(isStepDone(SetupStep.intention, _fresh, progress), isFalse);
      expect(isStepDone(SetupStep.phase, _withPhase, progress), isTrue);
    });

    test('duration and rhythm follow the choices', () {
      const progress = CompassSetupProgress(
          completed: {SetupStep.duration, SetupStep.rhythm});
      expect(isStepDone(SetupStep.duration, _fresh, progress), isTrue);
      expect(isStepDone(SetupStep.rhythm, _fresh, progress), isTrue);
      expect(isStepDone(SetupStep.rhythm, _allData, CompassSetupProgress.empty),
          isFalse);
      expect(
          isStepDone(SetupStep.duration, _allData, CompassSetupProgress.empty),
          isTrue);
    });

    test('nextStep skips skipped steps unless asked', () {
      const progress = CompassSetupProgress(
        completed: {SetupStep.duration},
        skipped: {SetupStep.intention},
      );
      expect(nextStep(_fresh, CompassSetupProgress.empty), SetupStep.phase);
      expect(nextStep(_withPhase, progress), SetupStep.rhythm);
      expect(nextStep(_withPhase, progress, includeSkipped: true),
          SetupStep.intention);
    });

    test('cancel at step 2, restart, resume at step 2', () async {
      SharedPreferences.setMockInitialValues({});
      CompassSetupStore.clearCacheForTesting();
      // Step 1 saved a phase; the user left on the duration step.
      await CompassSetupStore.save(
        const CompassSetupProgress(autoOpened: true, lastStep: SetupStep.duration),
      );
      CompassSetupStore.clearCacheForTesting();

      final progress = await CompassSetupStore.load();
      expect(resumeStep(_withPhase, progress), SetupStep.duration);
      expect(shouldAutoOpen(_withPhase, progress), isFalse);
      expect(showChecklist(_withPhase, progress), isTrue);
      expect(doneCount(_withPhase, progress), 1);
    });

    test('resume ignores a finished lastStep and includes skipped steps', () {
      const progress = CompassSetupProgress(
        completed: {SetupStep.duration},
        skipped: {SetupStep.intention},
        lastStep: SetupStep.duration,
      );
      expect(resumeStep(_withPhase, progress), SetupStep.intention);
      expect(resumeStep(_allData,
              const CompassSetupProgress(completed: {SetupStep.rhythm})),
          isNull);
    });
  });

  group('auto open and checklist', () {
    test('auto opens a fresh, empty Compass once', () {
      expect(shouldAutoOpen(_fresh, CompassSetupProgress.empty), isTrue);
      expect(
          shouldAutoOpen(_fresh, const CompassSetupProgress(autoOpened: true)),
          isFalse);
      expect(
          shouldAutoOpen(
              _fresh, const CompassSetupProgress(skipped: {SetupStep.phase})),
          isFalse);
    });

    test('existing user with data: no auto open, checklist shown', () {
      const facts = SetupFacts(compassEmpty: false);
      expect(shouldAutoOpen(facts, CompassSetupProgress.empty), isFalse);
      expect(showChecklist(facts, CompassSetupProgress.empty), isTrue);
    });

    test('all done: no checklist', () {
      const progress = CompassSetupProgress(completed: {SetupStep.rhythm});
      expect(doneCount(_allData, progress), 4);
      expect(showChecklist(_allData, progress), isFalse);
      expect(nextStep(_allData, progress, includeSkipped: true), isNull);
    });

    test('dismissed card hides the checklist', () {
      expect(
          showChecklist(_fresh, const CompassSetupProgress(cardDismissed: true)),
          isFalse);
    });
  });

  group('progress steps', () {
    test('markCompleted un-skips, markSkipped remembers the step', () {
      final skipped = CompassSetupProgress.empty.markSkipped(SetupStep.duration);
      expect(skipped.skipped, {SetupStep.duration});
      expect(skipped.lastStep, SetupStep.duration);
      final done = skipped.markCompleted(SetupStep.duration);
      expect(done.completed, {SetupStep.duration});
      expect(done.skipped, isEmpty);
    });

    test('stepAfter passes over done steps, skipped ones included', () {
      const progress = CompassSetupProgress(skipped: {SetupStep.intention});
      expect(stepAfter(SetupStep.phase, _withPhase, progress),
          SetupStep.duration);
      const withIntention = SetupFacts(
          hasPhase: true, hasPhaseIntention: true, compassEmpty: false);
      expect(stepAfter(SetupStep.duration, withIntention, progress),
          SetupStep.rhythm);
      expect(stepAfter(SetupStep.rhythm, _fresh, progress), isNull);
    });
  });

  group('SetupFacts.of', () {
    final today = DateTime(2026, 11, 2);
    final phase = LifePhase(id: 'p', start: DateTime(2024, 1, 1));

    Intention intention(String id, {String? phaseId,
            IntentionStatus status = IntentionStatus.now}) =>
        Intention(id: id, title: id, status: status, createdAt: today,
            phaseId: phaseId);

    test('empty data', () {
      final facts = SetupFacts.of(CompassData.empty, today);
      expect(facts.compassEmpty, isTrue);
      expect(facts.hasPhase, isFalse);
      expect(facts.hasPhaseIntention, isFalse);
    });

    test('a phase with a plan and a "Now" intention in it', () {
      final planned = phase.copyWith(plannedEnd: DateTime(2027, 1, 1));
      final facts = SetupFacts.of(
          CompassData(phases: [planned], intentions: [intention('a', phaseId: 'p')]),
          today);
      expect(facts.hasPhase, isTrue);
      expect(facts.hasPlannedEndOrOpenChoice, isTrue);
      expect(facts.hasPhaseIntention, isTrue);
      expect(facts.compassEmpty, isFalse);
    });

    test('intentions outside the current phase or not "Now" do not count', () {
      final facts = SetupFacts.of(
          CompassData(phases: [phase], intentions: [
            intention('a'),
            intention('b', phaseId: 'p', status: IntentionStatus.someday),
          ]),
          today);
      expect(facts.hasPhaseIntention, isFalse);
      expect(facts.hasPlannedEndOrOpenChoice, isFalse);
    });

    test('without a phase any "Now" intention counts', () {
      final facts =
          SetupFacts.of(CompassData(intentions: [intention('a')]), today);
      expect(facts.hasPhaseIntention, isTrue);
    });

    test('a phase starting later is not current yet', () {
      final later = LifePhase(id: 'l', start: DateTime(2027, 1, 1));
      expect(SetupFacts.of(CompassData(phases: [later]), today).hasPhase,
          isFalse);
    });
  });
}
