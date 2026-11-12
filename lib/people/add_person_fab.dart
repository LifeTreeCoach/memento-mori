import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// "Add" button: extended at the top of the list, an icon once scrolled.
class AddPersonFab extends StatelessWidget {
  const AddPersonFab({
    super.key,
    required this.extended,
    required this.onPressed,
  });

  final bool extended;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FloatingActionButton.extended(
      onPressed: onPressed,
      tooltip: l10n.translate('people_add_person'),
      extendedPadding: EdgeInsets.symmetric(horizontal: extended ? 20 : 16),
      extendedIconLabelSpacing: extended ? 8 : 0,
      icon: const Icon(Icons.person_add_alt_1_outlined),
      label: _label(context, l10n),
    );
  }

  /// The label grows/shrinks with the motion setting. Without motion the
  /// label switches directly: a zero-duration [AnimatedSize] finishes
  /// inside its own layout and trips a framework assertion.
  Widget _label(BuildContext context, AppLocalizations l10n) {
    final label = extended
        ? Text(l10n.translate('people_add'))
        : const SizedBox.shrink();
    final duration = Motion.of(context, Motion.medium);
    if (duration == Duration.zero) return label;
    return AnimatedSize(
      duration: duration,
      curve: Motion.standard,
      child: label,
    );
  }
}
