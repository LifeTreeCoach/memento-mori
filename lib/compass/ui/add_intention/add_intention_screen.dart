import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/add_intention_form.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/intention_flow_context.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/intention_sheet.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Opens the intention flow full screen; the draft on save, null when left.
Future<IntentionDraft?> showAddIntention(
  BuildContext context, {
  required IntentionFlowContext flow,
  String? initialNote,
  IntentionStatus initialStatus = IntentionStatus.now,
}) {
  return Navigator.of(context).push<IntentionDraft>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => AddIntentionScreen(
      flow: flow,
      initialNote: initialNote,
      initialStatus: initialStatus,
    ),
  ));
}

/// The intention flow: back arrow, the phase name (or "Compass") centred
/// on top, and [AddIntentionForm]; saving pops with the draft.
class AddIntentionScreen extends StatelessWidget {
  const AddIntentionScreen({
    super.key,
    required this.flow,
    this.initialNote,
    this.initialStatus = IntentionStatus.now,
  });

  final IntentionFlowContext flow;
  final String? initialNote;
  final IntentionStatus initialStatus;

  String _eyebrow(AppLocalizations l10n) {
    final phase = flow.phase;
    return phase == null
        ? l10n.translate('nav_compass')
        : phaseDisplayName(phase.phase, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('add_intention_screen'),
      appBar: AppBar(
        leading: const BackButton(key: ValueKey('add_intention_back')),
        centerTitle: true,
        title: Text(_eyebrow(l10n).toUpperCase(),
            key: const ValueKey('add_intention_eyebrow'),
            style: PhaseStyle.eyebrow(context)),
      ),
      body: SafeArea(
        top: false,
        child: AddIntentionForm(
          flow: flow,
          initialNote: initialNote,
          initialStatus: initialStatus,
          onSubmit: (draft) async => Navigator.of(context).pop(draft),
        ),
      ),
    );
  }
}
