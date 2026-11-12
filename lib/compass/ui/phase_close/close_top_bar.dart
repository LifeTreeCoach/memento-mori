import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_dots.dart';

/// Top of the phase close flow: back (close on the first step) and the
/// step dots.
class CloseTopBar extends StatelessWidget {
  const CloseTopBar({
    super.key,
    required this.count,
    required this.index,
    required this.onBack,
    required this.onClose,
  });

  final int count;
  final int index;

  /// Goes to the previous step; null on the first step.
  final VoidCallback? onBack;
  final VoidCallback onClose;

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
                  key: const ValueKey('phase_close_cancel'),
                  tooltip: material.closeButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                )
              : IconButton(
                  key: const ValueKey('phase_close_back'),
                  tooltip: material.backButtonTooltip,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: back,
                ),
          Expanded(child: Center(child: StepDots(count: count, index: index))),
          // Balances the leading button so the dots stay centred.
          const SizedBox(width: 52),
        ],
      ),
    );
  }
}
