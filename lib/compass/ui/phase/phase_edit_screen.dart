import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_edit_form.dart';

/// Opens the phase editor full screen; true when a phase was saved.
Future<bool> showPhaseEditor(BuildContext context, PhaseDraft draft,
    {bool firstTime = false}) async {
  final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => PhaseEditScreen(draft: draft, firstTime: firstTime),
  ));
  return saved ?? false;
}

/// The phase editor as a full screen (see [PhaseEditForm]); pops true
/// once the phase was saved.
class PhaseEditScreen extends StatelessWidget {
  const PhaseEditScreen({super.key, required this.draft, this.firstTime = false});

  final PhaseDraft draft;

  /// The very first phase (eyebrow "Compass · first time").
  final bool firstTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: PhaseEditForm(
          draft: draft,
          firstTime: firstTime,
          onSaved: () => Navigator.of(context).pop(true),
        ),
      ),
    );
  }
}
