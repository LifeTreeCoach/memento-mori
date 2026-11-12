import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Bottom of the phase sheet: "Close phase · begin a new one", "Carry on
/// in this phase" and the quieter "Add earlier phases" (or "Edit earlier
/// phases" once there are some) / "Change planned duration".
class PhaseSheetActions extends StatelessWidget {
  const PhaseSheetActions({
    super.key,
    required this.onClose,
    required this.onContinue,
    required this.onEarlier,
    required this.onDuration,
    this.hasEarlierPhases = false,
  });

  final VoidCallback onClose;
  final VoidCallback onContinue;
  final VoidCallback onEarlier;
  final VoidCallback onDuration;

  /// Whether phases before the current one exist: the earlier phases
  /// button then edits instead of adds.
  final bool hasEarlierPhases;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const ValueKey('phase_sheet_close'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: onClose,
          child: Text(l10n.translate('phase_sheet_close'),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 4),
        TextButton(
          key: const ValueKey('phase_sheet_continue'),
          onPressed: onContinue,
          child: Text(l10n.translate('phase_sheet_continue')),
        ),
        const Divider(height: 24),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          children: [
            _secondary(
              'phase_sheet_earlier',
              hasEarlierPhases
                  ? 'phase_sheet_earlier_edit'
                  : 'phase_sheet_earlier',
              Icons.history_rounded,
              l10n,
              onEarlier,
            ),
            _secondary('phase_sheet_duration', 'phase_sheet_duration',
                Icons.schedule_rounded, l10n, onDuration),
          ],
        ),
      ],
    );
  }

  Widget _secondary(String key, String labelKey, IconData icon,
      AppLocalizations l10n, VoidCallback onPressed) {
    return TextButton.icon(
      key: ValueKey(key),
      icon: Icon(icon, size: 18),
      label: Text(l10n.translate(labelKey)),
      onPressed: onPressed,
    );
  }
}
