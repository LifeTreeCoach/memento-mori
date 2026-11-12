import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/compass/setup_flow.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/compass_setup_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/setup_checklist_card.dart';

/// The ways into the Compass setup from the Compass tab: opening by itself
/// once for an empty Compass, and the checklist card.
class CompassSetupEntry {
  CompassSetupEntry({
    required this.contextOf,
    required this.today,
    required this.birthDate,
    required this.lifeExpectancyYears,
  });

  final BuildContext Function() contextOf;
  final DateTime Function() today;
  final DateTime? Function() birthDate;
  final int Function() lifeExpectancyYears;

  bool _opening = false;

  SetupFacts get facts => SetupFacts.of(CompassService.data, today());

  CompassSetupProgress get progress => CompassSetupStore.progress;

  /// Whether the setup would still open by itself (it goes first).
  bool get autoOpenDue => shouldAutoOpen(facts, progress);

  /// Opens the setup at [start].
  Future<void> open(SetupStep start) async {
    if (_opening) return;
    _opening = true;
    try {
      await showCompassSetup(
        contextOf(),
        CompassSetupScreen(
          start: start,
          today: today(),
          birthDate: birthDate(),
          lifeExpectancyYears: lifeExpectancyYears(),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  /// Opens the setup once by itself, for a Compass without any data whose
  /// setup nobody touched yet. [stillVisible] is checked after loading.
  Future<void> autoOpenIfDue(bool Function() stillVisible) async {
    await CompassService.load();
    await CompassSetupStore.load();
    if (!stillVisible() || !autoOpenDue) return;
    await CompassSetupStore.save(progress.copyWith(autoOpened: true));
    await open(nextStep(facts, progress) ?? SetupStep.phase);
  }

  /// Continues where the setup was left (skipped steps included).
  Future<void> resume() => open(resumeStep(facts, progress) ?? SetupStep.phase);

  /// Hides the checklist card for good.
  Future<void> dismissCard() =>
      CompassSetupStore.save(progress.copyWith(cardDismissed: true));

  /// The checklist card while a step is open, else null.
  Widget? checklist() {
    if (!showChecklist(facts, progress)) return null;
    return SetupChecklistCard(
      facts: facts,
      progress: progress,
      onContinue: resume,
      onDismiss: dismissCard,
    );
  }
}
