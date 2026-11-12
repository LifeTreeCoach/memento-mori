import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/completion_story.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/add_intention_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/intention_flow_context.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_item_menu.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/intention_sheet.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/moment_sheet.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/reflection/completion_reflection_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/weekly_question.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/widgets/action_snack_bar.dart';

/// The Compass flows behind the tab's buttons: sheets, service calls and
/// gentle snackbars (with undo after a delete). The screen redraws through
/// [CompassService.revision].
class CompassActions {
  CompassActions({
    required this.contextOf,
    required this.today,
    required this.birthDate,
    required this.onSavedToSomeday,
    int Function()? lifeExpectancyYears,
  }) : lifeExpectancyYears =
            lifeExpectancyYears ?? SettingsService.getLifeExpectancyYears;

  /// A context below the tab's [ScaffoldMessenger].
  final BuildContext Function() contextOf;
  final DateTime Function() today;
  final DateTime? Function() birthDate;

  /// The lifespan the intention flow measures the phase against.
  final int Function() lifeExpectancyYears;

  /// Called when an intention landed in "Someday" because "Now" was full.
  final VoidCallback onSavedToSomeday;

  /// How long the undo action stays on screen (as for people).
  static const Duration undoDuration = actionSnackBarDuration;

  AppLocalizations get _l10n => AppLocalizations.of(contextOf());

  int? get _age {
    final birth = birthDate();
    return birth == null
        ? null
        : LifeCalculator(birthDate: birth, now: today()).ageYears;
  }

  /// The text shown when "Now" is full (one hint per week).
  String limitHintText() => limitHint(compassWeekIndex(today()))
      .textFor(_l10n.locale.languageCode);

  void _show(String text, {SnackBarAction? action}) {
    final messenger = ScaffoldMessenger.of(contextOf());
    if (action != null) {
      showActionSnackBar(messenger, text: text, action: action);
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // Intentions

  /// Opens the intention flow ([status] preselects "when", [initialNote]
  /// prefills its note) and saves the result; "Now" overflows into
  /// "Someday" with a friendly explanation.
  Future<void> addIntention({
    IntentionStatus status = IntentionStatus.now,
    String? initialNote,
  }) async {
    final draft = await showAddIntention(
      contextOf(),
      flow: IntentionFlowContext.current(
        today: today(),
        birthDate: birthDate(),
        lifeExpectancyYears: lifeExpectancyYears(),
      ),
      initialNote: initialNote,
      initialStatus: status,
    );
    if (draft == null) return;
    final result = await saveDraft(draft);
    if (!result.nowLimitReached) return;
    _reportSavedToSomeday();
  }

  /// Saves a new intention from the flow's [draft] on [today].
  Future<AddIntentionResult> saveDraft(IntentionDraft draft) =>
      CompassService.addIntention(
        title: draft.title,
        note: draft.note,
        area: draft.area,
        horizon: draft.horizon,
        kind: draft.kind,
        dueDate: draft.dueDate,
        status: draft.status,
        today: today(),
      );

  /// Saves [title] straight away (no sheet) as a "Now" intention and shows
  /// [savedText]; when "Now" is full it goes to "Someday" with the same
  /// friendly explanation as [addIntention]. Either snackbar carries
  /// [action] (e.g. "Open" the Compass).
  Future<AddIntentionResult> addIntentionDirectly({
    required String title,
    required String savedText,
    LifeArea? area,
    SnackBarAction? action,
    String? friendId,
  }) async {
    final result = await CompassService.addIntention(
      title: title,
      area: area,
      today: today(),
      friendId: friendId,
    );
    if (result.nowLimitReached) {
      _reportSavedToSomeday(action: action);
    } else {
      _show(savedText, action: action);
    }
    return result;
  }

  void _reportSavedToSomeday({SnackBarAction? action}) {
    onSavedToSomeday();
    _show(_l10n.translate('compass_now_full_saved'), action: action);
  }

  Future<void> editIntention(Intention intention) async {
    final draft = await showIntentionSheet(contextOf(),
        initial: intention, currentAge: _age, today: today());
    if (draft == null) return;
    await CompassService.editIntention(intention.copyWith(
      title: draft.title,
      note: draft.note,
      clearNote: draft.note == null,
      area: draft.area,
      clearArea: draft.area == null,
      horizon: draft.horizon,
      clearHorizon: draft.horizon == null,
      kind: draft.kind,
      clearKind: draft.kind == null,
      dueDate: draft.dueDate,
      clearDueDate: draft.dueDate == null,
    ));
  }

  /// Marks [intention] done; it becomes a moment in "Lived". With the look
  /// back on ([CompassService.showReflection]) it opens full screen,
  /// otherwise a snackbar thanks. Undo (in either) restores its status and
  /// removes that moment.
  Future<void> complete(Intention intention) async {
    final moment = await CompassService.complete(intention.id, today: today());
    if (CompassService.showReflection) return _reflect(intention, moment);
    _show(
      _l10n.translate('compass_well_done'),
      action: SnackBarAction(
        label: _l10n.translate('compass_undo'),
        onPressed: () => CompassService.undoComplete(intention, moment.id),
      ),
    );
  }

  Future<void> _reflect(Intention intention, Moment moment) async {
    final context = contextOf();
    if (!context.mounted) return;
    final story = CompletionStory.of(
      intention: intention,
      moment: moment,
      phases: CompassService.data.phases,
      birthDate: birthDate(),
      lifeExpectancyYears: lifeExpectancyYears(),
      today: today(),
    );
    await showCompletionReflection(
      context,
      CompletionReflectionScreen(
          intention: intention, moment: moment, story: story),
    );
  }

  /// Runs the menu [action] chosen for [intention].
  void onIntentionMenu(Intention intention, CompassMenuAction action) {
    switch (action) {
      case CompassMenuAction.edit:
        editIntention(intention);
      case CompassMenuAction.moveToNow:
        moveToNow(intention);
      case CompassMenuAction.moveToSomeday:
        moveToSomeday(intention);
      case CompassMenuAction.letGo:
        letGo(intention);
      case CompassMenuAction.delete:
        deleteIntention(intention);
    }
  }

  Future<void> moveToSomeday(Intention intention) =>
      CompassService.moveToSomeday(intention.id);

  /// Moves [intention] to "Now"; when full, shows the limit hint instead.
  Future<void> moveToNow(Intention intention) async {
    final moved = await CompassService.moveToNow(intention.id);
    if (!moved) _show(limitHintText());
  }

  /// Lets [intention] go (kept, no longer open); undo restores it as it was.
  Future<void> letGo(Intention intention) async {
    await CompassService.letGoIntention(intention.id, today: today());
    _show(
      _l10n.translate('compass_let_go_done'),
      action: SnackBarAction(
        label: _l10n.translate('compass_undo'),
        onPressed: () => CompassService.restoreIntention(intention),
      ),
    );
  }

  Future<void> deleteIntention(Intention intention) async {
    await CompassService.deleteIntention(intention.id);
    _show(
      _l10n.translate('compass_intention_removed'),
      action: _undo(CompassData(intentions: [intention])),
    );
  }

  // Moments

  /// Asks for a moment (any day up to today, starting on [initialDate])
  /// and saves it.
  Future<void> addMoment({DateTime? initialDate}) async {
    final draft = await showMomentSheet(contextOf(),
        today: today(), firstDate: birthDate(), initialDate: initialDate);
    if (draft == null) return;
    await CompassService.addMoment(
        title: draft.title,
        date: draft.date,
        area: draft.area,
        note: draft.note);
  }

  Future<void> editMoment(Moment moment) async {
    final draft = await showMomentSheet(contextOf(),
        initial: moment, today: today(), firstDate: birthDate());
    if (draft == null) return;
    await CompassService.editMoment(
      moment.copyWith(
        title: draft.title,
        date: draft.date,
        area: draft.area,
        clearArea: draft.area == null,
        note: draft.note,
        clearNote: draft.note == null,
      ),
    );
  }

  Future<void> deleteMoment(Moment moment) async {
    await CompassService.deleteMoment(moment.id);
    _show(
      _l10n.translate('compass_moment_removed'),
      action: _undo(CompassData(moments: [moment])),
    );
  }

  /// Restores [deleted] with its ids (import keeps "Now" within the limit).
  SnackBarAction _undo(CompassData deleted) => SnackBarAction(
        label: _l10n.translate('compass_undo'),
        onPressed: () => CompassService.importData(deleted),
      );
}
