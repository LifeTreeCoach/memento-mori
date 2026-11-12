import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/planned_duration.dart';
import 'package:memento_mori_life_in_weeks/compass/setup_flow.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/intention_flow_context.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/intention_sheet.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_edit_form.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/planned_duration_form.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/setup_intention_step.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/setup_rhythm_step.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/setup_top_bar.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_permission.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Opens the Compass setup full screen at [start].
Future<void> showCompassSetup(BuildContext context, CompassSetupScreen screen) =>
    Navigator.of(context).push<void>(
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => screen));

/// The resumable Compass setup: phase → planned duration → first
/// intention → reminder rhythm. Every confirmed step is saved at once and
/// steps already done are passed over; "Later" puts the step off and
/// closes, the checklist on the Compass resumes there.
class CompassSetupScreen extends StatefulWidget {
  const CompassSetupScreen({
    super.key,
    required this.start,
    required this.today,
    required this.birthDate,
    required this.lifeExpectancyYears,
    this.permission = const SystemNotificationPermission(),
  });

  final SetupStep start;
  final DateTime today;
  final DateTime? birthDate;
  final int lifeExpectancyYears;
  final NotificationPermission permission;

  @override
  State<CompassSetupScreen> createState() => _CompassSetupScreenState();
}

class _CompassSetupScreenState extends State<CompassSetupScreen> {
  late SetupStep _step = _shown(widget.start);
  final List<SetupStep> _history = [];

  /// The phase being chosen; kept across rebuilds (e.g. the keyboard).
  PhaseDraft? _draft;

  LifePhase? get _phase => CompassService.currentPhase(today: widget.today);

  SetupFacts get _facts => SetupFacts.of(CompassService.data, widget.today);

  /// The duration needs a phase; without one the phase step comes first.
  SetupStep _shown(SetupStep step) =>
      step == SetupStep.duration && _phase == null ? SetupStep.phase : step;

  @override
  void initState() {
    super.initState();
    _saveLastStep(_step);
  }

  Future<void> _saveLastStep(SetupStep step) =>
      CompassSetupStore.save(CompassSetupStore.progress.copyWith(lastStep: step));

  /// Saves [step] as done and shows the next open step, or closes.
  Future<void> _complete(SetupStep step) async {
    final progress = CompassSetupStore.progress.markCompleted(step);
    final next = stepAfter(step, _facts, progress);
    await CompassSetupStore.save(next == null
        ? progress.copyWith(clearLastStep: true)
        : progress.copyWith(lastStep: next));
    if (!mounted) return;
    if (next == null) return Navigator.of(context).pop();
    setState(() {
      _history.add(_step);
      _step = _shown(next);
      _draft = null;
    });
  }

  Future<void> _later() async {
    await CompassSetupStore.save(CompassSetupStore.progress.markSkipped(_step));
    if (mounted) Navigator.of(context).pop();
  }

  void _back() {
    if (_history.isEmpty) return;
    setState(() {
      _step = _history.removeLast();
      _draft = null;
    });
    _saveLastStep(_step);
  }

  Future<void> _addIntention(IntentionDraft draft) async {
    await CompassService.addIntention(
      title: draft.title,
      note: draft.note,
      area: draft.area,
      horizon: draft.horizon,
      kind: draft.kind,
      dueDate: draft.dueDate,
      status: draft.status,
      today: widget.today,
    );
    await _complete(SetupStep.intention);
  }

  Future<void> _applyRhythm(ReminderRhythm rhythm) async {
    if (rhythm.isOn) {
      try {
        await widget.permission.request();
      } catch (e) {
        debugPrint('Compass setup: permission request failed: $e');
      }
    }
    await ReminderService.setRhythm(rhythm);
    await _complete(SetupStep.rhythm);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _history.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SetupTopBar(
                step: _step,
                onBack: _history.isEmpty ? null : _back,
                onClose: () => Navigator.of(context).maybePop(),
                onLater: _later,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.medium),
                  switchInCurve: Motion.standard,
                  switchOutCurve: Motion.standard,
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _stepView(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = _phase;
    return switch (_step) {
      SetupStep.phase => PhaseEditForm(
          draft: _draft ??= PhaseDraft(
            editing: phase,
            today: widget.today,
            birthDate: widget.birthDate,
            lifeExpectancyYears: widget.lifeExpectancyYears,
          ),
          firstTime: CompassService.data.phases.isEmpty,
          onSaved: () => _complete(SetupStep.phase),
        ),
      SetupStep.duration => PlannedDurationForm(
          phase: phase!,
          today: widget.today,
          birthDate: widget.birthDate,
          lifeExpectancyYears: widget.lifeExpectancyYears,
          initial: phase.plannedEnd == null
              ? const PlannedDuration.months(12)
              : PlannedDuration.until(phase.plannedEnd, widget.today),
          onSaved: (_) => _complete(SetupStep.duration),
        ),
      SetupStep.intention => SetupIntentionStep(
          eyebrow: phase == null
              ? l10n.translate('nav_compass')
              : phaseDisplayName(phase, l10n),
          flow: IntentionFlowContext.current(
            today: widget.today,
            birthDate: widget.birthDate,
            lifeExpectancyYears: widget.lifeExpectancyYears,
          ),
          onSubmit: _addIntention,
        ),
      SetupStep.rhythm => SetupRhythmStep(
          initial: ReminderService.rhythm(),
          onConfirm: _applyRhythm,
        ),
    };
  }
}
