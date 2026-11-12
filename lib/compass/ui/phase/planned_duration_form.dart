import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/planned_duration.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/lifespan_preview_card.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/planned_duration_picker.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';

/// Opens "About how much longer?" for [phase] full screen; the chosen
/// duration once saved, null when left.
Future<PlannedDuration?> showPlannedDurationEditor(
  BuildContext context, {
  required LifePhase phase,
  required DateTime today,
  required DateTime? birthDate,
  required int lifeExpectancyYears,
  PlannedDuration initial = const PlannedDuration.months(12),
}) {
  return Navigator.of(context).push<PlannedDuration>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: PlannedDurationForm(
          phase: phase,
          today: today,
          birthDate: birthDate,
          lifeExpectancyYears: lifeExpectancyYears,
          initial: initial,
          onSaved: (duration) => Navigator.of(context).pop(duration),
        ),
      ),
    ),
  ));
}

/// "About how much longer should this phase last?": quick choices, a fine
/// stepper and the lifespan bar with the planned rest. Saves the planned
/// end of [phase] ("Open" removes it).
class PlannedDurationForm extends StatefulWidget {
  const PlannedDurationForm({
    super.key,
    required this.phase,
    required this.today,
    required this.birthDate,
    required this.lifeExpectancyYears,
    required this.onSaved,
    this.initial = const PlannedDuration.months(12),
    this.persist = true,
    this.onChanged,
    this.actionLabel,
  });

  final LifePhase phase;
  final DateTime today;
  final DateTime? birthDate;
  final int lifeExpectancyYears;
  final PlannedDuration initial;

  /// Called with the chosen duration once it was saved.
  final ValueChanged<PlannedDuration> onSaved;

  /// Saves the planned end of [phase]; false only reports the choice (the
  /// phase close flow saves everything in one go).
  final bool persist;

  /// Called on every change of the choice (keeps it across steps).
  final ValueChanged<PlannedDuration>? onChanged;

  /// Text of the main button; defaults to "Save".
  final String? actionLabel;

  @override
  State<PlannedDurationForm> createState() => _PlannedDurationFormState();
}

class _PlannedDurationFormState extends State<PlannedDurationForm> {
  late PlannedDuration _duration = widget.initial;

  LifePhase get _phase => widget.phase;

  Future<void> _save() async {
    if (widget.persist) {
      final end = _duration.endFrom(widget.today);
      await CompassService.editPhase(end == null
          ? _phase.copyWith(clearPlannedEnd: true)
          : _phase.copyWith(plannedEnd: end));
    }
    if (mounted) widget.onSaved(_duration);
  }

  void _onChanged(PlannedDuration duration) {
    setState(() => _duration = duration);
    widget.onChanged?.call(duration);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepLayout(
      topPadding: 0,
      action: FilledButton(
        key: const ValueKey('duration_apply'),
        onPressed: _save,
        child: Text(widget.actionLabel ?? l10n.translate('duration_apply')),
      ),
      children: [
        PhaseEyebrow(phaseDisplayName(_phase, l10n)),
        Text(l10n.translate('duration_question'),
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(l10n.translate('duration_intro'), style: PhaseStyle.muted(context)),
        const SizedBox(height: 24),
        PlannedDurationPicker(
          value: _duration,
          maxMonths: PlannedDuration.maxMonths(
              birthDate: widget.birthDate,
              lifeExpectancyYears: widget.lifeExpectancyYears,
              today: widget.today),
          onChanged: _onChanged,
        ),
        const SizedBox(height: 16),
        _preview(l10n),
      ],
    );
  }

  Widget _preview(AppLocalizations l10n) {
    final months = monthsIn(
        PhaseSpan(phase: _phase, start: _phase.start, isCurrent: true),
        widget.today);
    final end = _duration.endFrom(widget.today);
    final birth = widget.birthDate;
    final total =
        _duration.totalShare(_phase.start, widget.today, widget.lifeExpectancyYears);
    return LifespanPreviewCard(
      name: phaseDisplayName(_phase, l10n),
      months: months,
      fractions: birth == null
          ? null
          : LifespanBarFractions.of(
              birthDate: birth,
              lifeExpectancyYears: widget.lifeExpectancyYears,
              start: _phase.start,
              today: widget.today,
              plannedEnd: end),
      share: birth == null ? null : shareOfLifespan(months, widget.lifeExpectancyYears),
      shareText: birth == null || total == null ? null : l10n.totalShareText(total),
      detail: end == null
          ? l10n.translate('duration_open_hint')
          : l10n.plannedUntilText(end),
      lifeExpectancyYears: widget.lifeExpectancyYears,
    );
  }
}
