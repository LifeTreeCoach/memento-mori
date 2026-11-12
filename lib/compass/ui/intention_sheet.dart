import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/due_date_row.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/kind_cards.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/area_chips.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_field_label.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_sheet_frame.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/horizon_picker.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// What the intention sheet returns on save.
@immutable
class IntentionDraft {
  const IntentionDraft({
    required this.title,
    this.note,
    this.area,
    this.horizon,
    this.kind,
    this.dueDate,
    this.status = IntentionStatus.now,
  });

  final String title;
  final String? note;
  final LifeArea? area;
  final Horizon? horizon;
  final IntentionKind? kind;

  /// Appointment of an enjoy intention.
  final DateTime? dueDate;

  /// Where a new intention should go: "Now" or "Someday" (the intention
  /// flow); the edit sheet leaves it at "Now" and the status unchanged.
  final IntentionStatus status;
}

/// Add ([initial] null) or edit an intention; null when dismissed.
/// [initialNote] prefills the note of a new one (e.g. the week's question).
Future<IntentionDraft?> showIntentionSheet(
  BuildContext context, {
  Intention? initial,
  String? initialNote,
  int? currentAge,
  DateTime? today,
}) {
  return showCompassSheet<IntentionDraft>(
    context,
    (_) => _IntentionSheet(
      initial: initial,
      initialNote: initialNote,
      suggestedAge: _suggestedAge(currentAge),
      today: today ?? DateTime.now(),
    ),
  );
}

/// The next round decade above [age] (36 -> 40); 50 when unknown.
int _suggestedAge(int? age) => age == null ? 50 : (age ~/ 10 + 1) * 10;

class _IntentionSheet extends StatefulWidget {
  const _IntentionSheet({
    required this.initial,
    required this.initialNote,
    required this.suggestedAge,
    required this.today,
  });

  final Intention? initial;
  final String? initialNote;
  final int suggestedAge;
  final DateTime today;

  @override
  State<_IntentionSheet> createState() => _IntentionSheetState();
}

class _IntentionSheetState extends State<_IntentionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _note = TextEditingController(
      text: widget.initial?.note ?? widget.initialNote);
  late LifeArea? _area = widget.initial?.area;
  late Horizon? _horizon = widget.initial?.horizon;
  late IntentionKind? _kind = widget.initial?.kind;
  late DateTime? _dueDate = widget.initial?.dueDate;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final note = _note.text.trim();
    Navigator.of(context).pop(IntentionDraft(
      title: _title.text.trim(),
      note: note.isEmpty ? null : note,
      area: _area,
      horizon: _horizon,
      kind: _kind,
      dueDate: _kind == IntentionKind.enjoy ? _dueDate : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.initial == null;
    return CompassSheetFrame(
      title: l10n.translate(
          isNew ? 'compass_new_intention' : 'compass_edit_intention'),
      formKey: _formKey,
      onSave: _save,
      children: [
        _titleField(l10n),
        const SizedBox(height: 12),
        _noteField(l10n),
        CompassFieldLabel(l10n.translate('intention_kind_label')),
        KindCards(
          selected: _kind,
          allowNone: true,
          onChanged: (kind) => setState(() => _kind = kind),
        ),
        if (_kind == IntentionKind.enjoy)
          DueDateRow(
            dueDate: _dueDate,
            today: widget.today,
            onChanged: (day) => setState(() => _dueDate = day),
          ),
        CompassFieldLabel(l10n.translate('compass_field_area')),
        AreaChips(
          selected: _area,
          onChanged: (area) => setState(() => _area = area),
        ),
        CompassFieldLabel(l10n.translate('compass_field_horizon')),
        HorizonPicker(
          selected: _horizon,
          suggestedAge: widget.suggestedAge,
          onChanged: (horizon) => setState(() => _horizon = horizon),
        ),
        const SizedBox(height: 8),
        _horizonHint(context, l10n),
      ],
    );
  }

  Widget _titleField(AppLocalizations l10n) => TextFormField(
        key: const ValueKey('compass_intention_title'),
        controller: _title,
        autofocus: widget.initial == null,
        textCapitalization: TextCapitalization.sentences,
        decoration:
            InputDecoration(labelText: l10n.translate('compass_field_title')),
        validator: (value) => (value ?? '').trim().isEmpty
            ? l10n.translate('compass_field_title_required')
            : null,
      );

  Widget _noteField(AppLocalizations l10n) => TextField(
        key: const ValueKey('compass_intention_note'),
        controller: _note,
        minLines: 1,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration:
            InputDecoration(labelText: l10n.translate('compass_field_note')),
      );

  Widget _horizonHint(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Text(
      l10n.translate('compass_horizon_hint'),
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
