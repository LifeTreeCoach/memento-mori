import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_bilanz.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/earlier_phases_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_edit_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/planned_duration_form.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_close/phase_close_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_close/phase_close_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_sheet/phase_sheet.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_permission.dart';

/// The phase flows behind the Compass header (and Settings): the phase
/// sheet, set, edit, extend and close the current phase, earlier phases.
/// The screen redraws through [CompassService.revision].
class PhaseActions {
  PhaseActions({
    required this.contextOf,
    required this.today,
    required this.birthDate,
    required this.lifeExpectancyYears,
    this.permission = const SystemNotificationPermission(),
  });

  /// A context below a [ScaffoldMessenger] (for the closing snackbar).
  final BuildContext Function() contextOf;
  final DateTime Function() today;
  final DateTime? Function() birthDate;
  final int Function() lifeExpectancyYears;
  final NotificationPermission permission;

  PhaseDraft _draft({LifePhase? editing}) => PhaseDraft(
        editing: editing,
        today: today(),
        birthDate: birthDate(),
        lifeExpectancyYears: lifeExpectancyYears(),
      );

  LifePhase? get _current => CompassService.currentPhase(today: today());

  /// Chooses a new current phase ("first time" when there is none at all).
  Future<void> setPhase() => showPhaseEditor(contextOf(), _draft(),
      firstTime: CompassService.data.phases.isEmpty);

  /// Edits the current phase (sets one when there is none).
  Future<void> editCurrent() async {
    final phase = _current;
    if (phase == null) return setPhase();
    await showPhaseEditor(contextOf(), _draft(editing: phase));
  }

  /// Asks how much longer the current phase lasts (the shared planned
  /// duration picker) and moves its planned end.
  Future<void> extendCurrent() async {
    final phase = _current;
    if (phase == null) return;
    await showPlannedDurationEditor(
      contextOf(),
      phase: phase,
      today: today(),
      birthDate: birthDate(),
      lifeExpectancyYears: lifeExpectancyYears(),
    );
  }

  /// Opens the phase sheet of the current phase (sets one when there is
  /// none); "Close phase" there starts [closeCurrent].
  Future<void> openSheet() async {
    if (_current == null) return setPhase();
    final result = await showPhaseSheet(
      contextOf(),
      PhaseSheet(
        today: today(),
        birthDate: birthDate(),
        permission: permission,
        onEarlier: editEarlier,
        onDuration: extendCurrent,
      ),
    );
    if (result == PhaseSheetResult.closePhase) await closeCurrent();
  }

  /// The close flow of the current phase; afterwards "New phase begun".
  Future<void> closeCurrent() async {
    final span = currentSpan(CompassService.data.phases, today());
    if (span == null) return;
    final draft = PhaseCloseDraft(
      closing: span.phase,
      openItems: PhaseBilanz.of(CompassService.data, span, today()).open,
      today: today(),
    );
    final next = await showPhaseClose(
      contextOf(),
      PhaseCloseScreen(
          draft: draft,
          birthDate: birthDate(),
          lifeExpectancyYears: lifeExpectancyYears()),
    );
    if (next != null) _showBegun(next);
  }

  void _showBegun(LifePhase next) {
    final context = contextOf();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(l10n.translate('phase_close_done',
              replacements: {'name': phaseDisplayName(next, l10n)}))));
  }

  /// "Earlier phases": add, edit or delete the phases before this one.
  Future<void> editEarlier() => Navigator.of(contextOf()).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              EarlierPhasesScreen(today: today(), birthDate: birthDate()),
        ),
      );
}

/// The day [months] calendar months after [day] (day clamped to short
/// months).
DateTime monthsAfter(DateTime day, int months) =>
    startFromAgo(day, 0, -months);
