import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';

/// What the Compass data already holds, as far as the setup cares. Derived
/// from the data, so existing users and imported backups count as done.
@immutable
class SetupFacts {
  const SetupFacts({
    this.hasPhase = false,
    this.hasPlannedEndOrOpenChoice = false,
    this.hasPhaseIntention = false,
    this.compassEmpty = true,
  });

  /// The facts of [data] on [today]. Without a phase any open "Now"
  /// intention counts as the first intention.
  factory SetupFacts.of(CompassData data, DateTime today) {
    final current = currentSpan(data.phases, today)?.phase;
    return SetupFacts(
      hasPhase: current != null,
      hasPlannedEndOrOpenChoice: current?.plannedEnd != null,
      hasPhaseIntention: data.withStatus(IntentionStatus.now)
          .any((i) => current == null || i.phaseId == current.id),
      compassEmpty: data.isEmpty,
    );
  }

  /// A current life phase exists.
  final bool hasPhase;

  /// The current phase has a planned end (or "open" was chosen).
  final bool hasPlannedEndOrOpenChoice;

  /// An intention belongs to the current phase.
  final bool hasPhaseIntention;

  /// No intentions, moments or phases at all.
  final bool compassEmpty;
}

/// Whether [step] is done: phase and intention follow the data, duration
/// and rhythm the user's choices in [progress].
bool isStepDone(SetupStep step, SetupFacts facts, CompassSetupProgress progress) {
  switch (step) {
    case SetupStep.phase:
      return facts.hasPhase;
    case SetupStep.duration:
      return facts.hasPlannedEndOrOpenChoice ||
          progress.completed.contains(SetupStep.duration);
    case SetupStep.intention:
      return facts.hasPhaseIntention;
    case SetupStep.rhythm:
      return progress.completed.contains(SetupStep.rhythm);
  }
}

/// The first step that is not done; skipped steps only if [includeSkipped].
SetupStep? nextStep(
  SetupFacts facts,
  CompassSetupProgress progress, {
  bool includeSkipped = false,
}) {
  for (final step in SetupStep.values) {
    if (isStepDone(step, facts, progress)) continue;
    if (includeSkipped || !progress.skipped.contains(step)) return step;
  }
  return null;
}

/// Where to continue the setup: the step it was left at if still open,
/// otherwise the first open step (skipped ones included).
SetupStep? resumeStep(SetupFacts facts, CompassSetupProgress progress) {
  final last = progress.lastStep;
  if (last != null && !isStepDone(last, facts, progress)) return last;
  return nextStep(facts, progress, includeSkipped: true);
}

/// Open the setup by itself only once, for a Compass without any data and
/// a setup nobody touched yet.
bool shouldAutoOpen(SetupFacts facts, CompassSetupProgress progress) {
  return facts.compassEmpty &&
      !progress.autoOpened &&
      progress.completed.isEmpty &&
      progress.skipped.isEmpty;
}

/// Show the setup checklist while a step is open and it was not hidden.
bool showChecklist(SetupFacts facts, CompassSetupProgress progress) {
  return !progress.cardDismissed && doneCount(facts, progress) < SetupStep.values.length;
}

/// Number of steps that are done.
int doneCount(SetupFacts facts, CompassSetupProgress progress) {
  return SetupStep.values.where((s) => isStepDone(s, facts, progress)).length;
}

/// The step to show after [step] was confirmed: the next one in order that
/// is not done (skipped ones included); null when the setup is finished.
SetupStep? stepAfter(
    SetupStep step, SetupFacts facts, CompassSetupProgress progress) {
  for (final next in SetupStep.values.skip(step.index + 1)) {
    if (!isStepDone(next, facts, progress)) return next;
  }
  return null;
}
