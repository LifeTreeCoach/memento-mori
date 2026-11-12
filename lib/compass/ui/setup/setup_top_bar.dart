import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_dots.dart';

/// Top of the Compass setup: back (or close on the first shown step), the
/// step dots and "Later".
class SetupTopBar extends StatelessWidget {
  const SetupTopBar({
    super.key,
    required this.step,
    required this.onBack,
    required this.onClose,
    required this.onLater,
  });

  final SetupStep step;

  /// Goes to the previous step; null on the first shown step.
  final VoidCallback? onBack;
  final VoidCallback onClose;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final back = onBack;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 4),
          back == null
              ? IconButton(
                  key: const ValueKey('compass_setup_close'),
                  tooltip: material.closeButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                )
              : IconButton(
                  key: const ValueKey('compass_setup_back'),
                  tooltip: material.backButtonTooltip,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: back,
                ),
          Expanded(
            child: Center(
              child: StepDots(
                  count: SetupStep.values.length, index: step.index),
            ),
          ),
          TextButton(
            key: const ValueKey('compass_setup_later'),
            onPressed: onLater,
            child: Text(AppLocalizations.of(context).translate('setup_later')),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
