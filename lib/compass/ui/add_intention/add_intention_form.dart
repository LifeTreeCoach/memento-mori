import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/due_date_row.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/intention_flow_context.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/intention_more_fields.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/kind_cards.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/time_window_card.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/when_toggle.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/intention_sheet.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';

/// The body of the intention flow: what, which kind, when, an optional
/// date for enjoying, a folded "More" and the time window of the phase.
/// Used by the full-screen flow and by setup step 3.
class AddIntentionForm extends StatefulWidget {
  const AddIntentionForm({
    super.key,
    required this.flow,
    required this.onSubmit,
    this.title,
    this.eyebrow,
    this.initialNote,
    this.initialStatus = IntentionStatus.now,
  });

  final IntentionFlowContext flow;
  final Future<void> Function(IntentionDraft draft) onSubmit;

  /// The question on top; defaults to "What do you want to spend a few
  /// weeks on?".
  final String? title;

  /// Small capitals above the question (none when the screen shows them).
  final String? eyebrow;

  /// Prefilled note (e.g. the week's question); opens "More".
  final String? initialNote;
  final IntentionStatus initialStatus;

  @override
  State<AddIntentionForm> createState() => _AddIntentionFormState();
}

class _AddIntentionFormState extends State<AddIntentionForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  late final _note = TextEditingController(text: widget.initialNote);
  late bool _moreExpanded = widget.initialNote != null;
  late IntentionStatus _when = widget.initialStatus;
  IntentionKind _kind = IntentionKind.doTask;
  DateTime? _dueDate;
  LifeArea? _area;
  Horizon? _horizon;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _hasPhase => widget.flow.phase != null;

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final note = _note.text.trim();
    await widget.onSubmit(IntentionDraft(
      title: _title.text.trim(),
      note: note.isEmpty ? null : note,
      area: _area,
      horizon: _horizon,
      kind: _kind,
      dueDate: _kind == IntentionKind.enjoy ? _dueDate : null,
      status: _when,
    ));
    if (mounted) setState(() => _saving = false);
  }

  String get _saveKey => switch (_when) {
        IntentionStatus.someday => 'intention_save_someday',
        _ => _hasPhase ? 'intention_save_phase' : 'intention_save_now',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: StepLayout(
        topPadding: 8,
        action: FilledButton(
          key: const ValueKey('compass_sheet_save'),
          onPressed: _saving ? null : _submit,
          child: Text(l10n.translate(_saveKey)),
        ),
        children: [
          if (widget.eyebrow case final eyebrow?) PhaseEyebrow(eyebrow),
          Text(widget.title ?? l10n.translate('intention_title'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(l10n.translate('intention_intro'),
              style: PhaseStyle.muted(context)),
          const SizedBox(height: 16),
          _titleField(context, l10n),
          ..._choices(l10n),
          const SizedBox(height: 8),
          _more(),
          if (_when == IntentionStatus.now && widget.flow.phase != null) ...[
            const SizedBox(height: 12),
            TimeWindowCard(flow: widget.flow, phase: widget.flow.phase!,
                kind: _kind, dueDate: _dueDate),
          ],
        ],
      ),
    );
  }

  List<Widget> _choices(AppLocalizations l10n) => [
        PhaseEyebrow(l10n.translate('intention_kind_label'), top: 24),
        KindCards(selected: _kind,
            onChanged: (kind) => setState(() => _kind = kind ?? _kind)),
        PhaseEyebrow(l10n.translate('intention_when_label'), top: 24),
        WhenToggle(selected: _when, hasPhase: _hasPhase,
            onChanged: (when) => setState(() => _when = when)),
        if (_kind == IntentionKind.enjoy)
          DueDateRow(dueDate: _dueDate, today: widget.flow.today,
              onChanged: (day) => setState(() => _dueDate = day)),
      ];

  Widget _titleField(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return TextFormField(
      key: const ValueKey('compass_intention_title'),
      controller: _title,
      textCapitalization: TextCapitalization.sentences,
      maxLength: 120,
      style: theme.textTheme.titleLarge?.copyWith(
          fontFamily: AppTheme.serifFamily, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
          hintText: l10n.translate('intention_hint'), counterText: ''),
      validator: (value) => (value ?? '').trim().isEmpty
          ? l10n.translate('compass_field_title_required')
          : null,
    );
  }

  Widget _more() => IntentionMoreFields(
        expanded: _moreExpanded,
        onToggle: () => setState(() => _moreExpanded = !_moreExpanded),
        note: _note,
        area: _area,
        onArea: (area) => setState(() => _area = area),
        horizon: _horizon,
        onHorizon: (horizon) => setState(() => _horizon = horizon),
        suggestedAge: widget.flow.suggestedAge,
      );
}
