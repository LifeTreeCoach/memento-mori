import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/planned_duration.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/planned_duration_form.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_close/close_next_phase_step.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_close/close_note_step.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_close/close_open_items_step.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_close/close_top_bar.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_close/phase_close_draft.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Opens the close flow full screen; the new phase once it began, null
/// when left.
Future<LifePhase?> showPhaseClose(BuildContext context, PhaseCloseScreen screen) =>
    Navigator.of(context).push<LifePhase>(
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => screen));

/// Closing the current phase: open intentions (take along / let go), "what
/// was good", the next phase and its planned duration. Going back keeps
/// every entry; the last step saves everything in one go.
class PhaseCloseScreen extends StatefulWidget {
  const PhaseCloseScreen({
    super.key,
    required this.draft,
    required this.birthDate,
    required this.lifeExpectancyYears,
  });

  final PhaseCloseDraft draft;
  final DateTime? birthDate;
  final int lifeExpectancyYears;

  @override
  State<PhaseCloseScreen> createState() => _PhaseCloseScreenState();
}

class _PhaseCloseScreenState extends State<PhaseCloseScreen> {
  late final _note = TextEditingController(text: _draft.note);
  late final _name = TextEditingController(text: _draft.name);
  int _index = 0;
  String? _error;

  PhaseCloseDraft get _draft => widget.draft;
  List<PhaseCloseStep> get _steps => _draft.steps;

  @override
  void dispose() {
    _note.dispose();
    _name.dispose();
    super.dispose();
  }

  void _go(int delta) => setState(() {
        _index = (_index + delta).clamp(0, _steps.length - 1);
        _error = null;
      });

  void _afterNote({bool skip = false}) {
    if (skip) _note.clear();
    _draft.note = _note.text;
    _go(1);
  }

  void _afterNextPhase() {
    final error = _draft.validateNext();
    if (error == null) return _go(1);
    setState(() => _error = AppLocalizations.of(context).startErrorText(error));
  }

  Future<void> _finish(PlannedDuration duration) async {
    _draft.duration = duration;
    await _draft.save();
    if (mounted) Navigator.of(context).pop(_draft.next);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(-1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CloseTopBar(
                count: _steps.length,
                index: _index,
                onBack: _index == 0 ? null : () => _go(-1),
                onClose: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(_steps[_index]),
                  child: _stepView(AppLocalizations.of(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepView(AppLocalizations l10n) {
    final eyebrow = phaseDisplayName(_draft.closing, l10n);
    return switch (_steps[_index]) {
      PhaseCloseStep.openItems => CloseOpenItemsStep(
          eyebrow: eyebrow,
          items: _draft.openItems,
          takeAlong: _draft.takeAlong,
          onChanged: (id, take) => setState(() => _draft.takeAlong[id] = take),
          onNext: () => _go(1),
        ),
      PhaseCloseStep.note => CloseNoteStep(
          eyebrow: eyebrow,
          controller: _note,
          onNext: _afterNote,
          onSkip: () => _afterNote(skip: true),
        ),
      PhaseCloseStep.next => _nextPhaseStep(eyebrow),
      PhaseCloseStep.duration => PlannedDurationForm(
          phase: _draft.next,
          today: _draft.today,
          birthDate: widget.birthDate,
          lifeExpectancyYears: widget.lifeExpectancyYears,
          initial: _draft.duration,
          persist: false,
          onChanged: (d) => _draft.duration = d,
          actionLabel: l10n.translate('phase_close_finish'),
          onSaved: _finish,
        ),
    };
  }

  Widget _nextPhaseStep(String eyebrow) => CloseNextPhaseStep(
        eyebrow: eyebrow,
        preset: _draft.preset,
        nameController: _name,
        error: _error,
        onPresetChanged: (preset) => setState(() {
          _draft.preset = preset;
          if (preset == null) return;
          _name.clear();
          _draft.name = '';
        }),
        onNameChanged: (name) => setState(() {
          _draft.name = name;
          _draft.preset = null;
        }),
        onNext: _draft.hasNextName ? _afterNextPhase : null,
      );
}
