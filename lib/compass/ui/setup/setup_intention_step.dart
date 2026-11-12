import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/add_intention_form.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/intention_flow_context.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/intention_sheet.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Setup step 3: "What do you really want to have lived in this phase?" –
/// the intention flow (kind, when, time window) with "in this phase"
/// chosen.
class SetupIntentionStep extends StatelessWidget {
  const SetupIntentionStep({
    super.key,
    required this.eyebrow,
    required this.flow,
    required this.onSubmit,
  });

  /// Small capitals above the question (the phase name).
  final String eyebrow;
  final IntentionFlowContext flow;

  /// Saves the intention.
  final Future<void> Function(IntentionDraft draft) onSubmit;

  @override
  Widget build(BuildContext context) {
    return AddIntentionForm(
      key: const ValueKey('setup_intention_form'),
      flow: flow,
      eyebrow: eyebrow,
      title: AppLocalizations.of(context).translate('setup_intention_question'),
      onSubmit: onSubmit,
    );
  }
}
