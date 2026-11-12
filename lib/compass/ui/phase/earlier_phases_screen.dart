import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/earlier_phases.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/earlier_phase_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/earlier_phase_form.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// "Earlier phases": the phases before the current one with their age
/// range (or years) and closing note, to edit, delete or add. A phase
/// lasts until the next one begins.
class EarlierPhasesScreen extends StatefulWidget {
  const EarlierPhasesScreen({super.key, required this.today, this.birthDate});

  final DateTime today;
  final DateTime? birthDate;

  @override
  State<EarlierPhasesScreen> createState() => _EarlierPhasesScreenState();
}

class _EarlierPhasesScreenState extends State<EarlierPhasesScreen> {
  @override
  void initState() {
    super.initState();
    CompassService.revision.addListener(_onChanged);
  }

  @override
  void dispose() {
    CompassService.revision.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  EarlierPhaseDraft _draft([PhaseSpan? span]) => EarlierPhaseDraft(
      editing: span?.phase, today: widget.today, birthDate: widget.birthDate);

  /// Space the scroll thread keeps free for the "Add" button.
  static const double _fabClearance = 88;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spans = earlierSpans(CompassService.data.phases, widget.today);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('earlier_title'))),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('earlier_add'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.translate('earlier_add')),
        onPressed: () => showEarlierPhaseForm(context, _draft()),
      ),
      body: ScrollThread(
        bottomInset: _fabClearance,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(l10n.translate('earlier_intro'),
                  style: PhaseStyle.muted(context)),
            ),
            if (spans.isEmpty)
              ListTile(title: Text(l10n.translate('earlier_empty'))),
            for (final span in spans.reversed) _tile(context, l10n, span),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, AppLocalizations l10n, PhaseSpan span) {
    final id = span.phase.id;
    final note = span.phase.note;
    return ListTile(
      key: ValueKey('earlier_phase_$id'),
      title: Text(phaseDisplayName(span.phase, l10n)),
      subtitle: Text.rich(TextSpan(text: _range(l10n, span), children: [
        if (note != null)
          TextSpan(
              text: '\n$note',
              style: const TextStyle(fontStyle: FontStyle.italic)),
      ])),
      isThreeLine: note != null,
      onTap: () => showEarlierPhaseForm(context, _draft(span)),
      trailing: IconButton(
        key: ValueKey('earlier_delete_$id'),
        tooltip: l10n.translate('earlier_delete'),
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: () => _confirmDelete(context, l10n, id),
      ),
    );
  }

  /// "6–19 years", or "1996–2009" without a birth date.
  String _range(AppLocalizations l10n, PhaseSpan span) {
    final birth = widget.birthDate;
    final end = span.end ?? widget.today;
    if (birth == null) return '${span.start.year}–${end.year}';
    return l10n.translate('earlier_age_range', replacements: {
      'from': '${ageOn(birth, span.start)}',
      'to': '${ageOn(birth, end)}',
    });
  }

  Future<void> _confirmDelete(
      BuildContext context, AppLocalizations l10n, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('earlier_delete_title')),
        content: Text(l10n.translate('earlier_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('compass_cancel')),
          ),
          TextButton(
            key: const ValueKey('earlier_delete_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('earlier_delete')),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await CompassService.deletePhase(id);
  }
}
