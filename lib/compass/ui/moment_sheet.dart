import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/area_chips.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_field_label.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_sheet_frame.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// What the moment sheet returns on save.
@immutable
class MomentDraft {
  const MomentDraft({
    required this.title,
    required this.date,
    this.area,
    this.note,
  });

  final String title;
  final DateTime date;
  final LifeArea? area;

  /// Null when left empty.
  final String? note;
}

/// Add ([initial] null) or edit a moment; null when dismissed. The date can
/// be any day from [firstDate] (the birth date, if known) to [today]; a new
/// moment starts on [initialDate] (default [today]).
Future<MomentDraft?> showMomentSheet(
  BuildContext context, {
  Moment? initial,
  required DateTime today,
  DateTime? firstDate,
  DateTime? initialDate,
}) {
  return showCompassSheet<MomentDraft>(
    context,
    (_) => _MomentSheet(
      initial: initial,
      today: compassDate(today),
      firstDate: compassDate(firstDate ?? DateTime(1900)),
      initialDate: initialDate == null ? null : compassDate(initialDate),
    ),
  );
}

class _MomentSheet extends StatefulWidget {
  const _MomentSheet({
    required this.initial,
    required this.today,
    required this.firstDate,
    this.initialDate,
  });

  final Moment? initial;
  final DateTime today;
  final DateTime firstDate;
  final DateTime? initialDate;

  @override
  State<_MomentSheet> createState() => _MomentSheetState();
}

class _MomentSheetState extends State<_MomentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _note = TextEditingController(text: widget.initial?.note);
  late DateTime _date =
      widget.initial?.date ?? widget.initialDate ?? widget.today;
  late LifeArea? _area = widget.initial?.area;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime _clamp(DateTime date) {
    if (date.isAfter(widget.today)) return widget.today;
    if (date.isBefore(widget.firstDate)) return widget.firstDate;
    return date;
  }

  Future<void> _pickDate() async {
    final latest = _date.isAfter(widget.today) ? _date : widget.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(_date),
      firstDate: widget.firstDate,
      lastDate: latest,
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(MomentDraft(
      title: _title.text.trim(),
      date: _date,
      area: _area,
      note: nonEmptyCompassString(_note.text)?.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.initial == null;
    return CompassSheetFrame(
      title: l10n
          .translate(isNew ? 'compass_new_moment' : 'compass_edit_moment'),
      formKey: _formKey,
      onSave: _save,
      children: [
        _titleField(l10n),
        CompassFieldLabel(l10n.translate('compass_field_date')),
        _dateButton(l10n),
        CompassFieldLabel(l10n.translate('compass_field_area')),
        AreaChips(
          selected: _area,
          onChanged: (area) => setState(() => _area = area),
        ),
        CompassFieldLabel(l10n.translate('compass_field_moment_note')),
        _noteField(),
      ],
    );
  }

  Widget _titleField(AppLocalizations l10n) => TextFormField(
        key: const ValueKey('compass_moment_title'),
        controller: _title,
        autofocus: widget.initial == null,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
            labelText: l10n.translate('compass_field_moment_title')),
        validator: (value) => (value ?? '').trim().isEmpty
            ? l10n.translate('compass_field_title_required')
            : null,
      );

  Widget _noteField() => TextFormField(
        key: const ValueKey('compass_moment_note_field'),
        controller: _note,
        maxLength: 140,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(counterText: ''),
      );

  Widget _dateButton(AppLocalizations l10n) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          key: const ValueKey('compass_moment_date'),
          icon: const Icon(Icons.event_outlined),
          label: Text(l10n.shortDateFormat.format(_date)),
          onPressed: _pickDate,
        ),
      );
}
