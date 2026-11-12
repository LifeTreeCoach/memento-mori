import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Step 3: birthday reminders and the weekly reflection, opt-in.
class RemindersStep extends StatelessWidget {
  const RemindersStep({
    super.key,
    required this.busy,
    required this.onEnable,
    required this.onSkip,
  });

  /// True while finishing; both buttons are disabled.
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepLayout(
      action: FilledButton(
        onPressed: busy ? null : onEnable,
        child: Text(l10n.translate('onboarding_reminders_on')),
      ),
      secondaryAction: TextButton(
        onPressed: busy ? null : onSkip,
        child: Text(l10n.translate('onboarding_not_now')),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.cake_outlined,
            size: 32,
            color: LifePalette.of(context).accent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.translate('onboarding_people_title'),
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.translate('onboarding_people_body'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
