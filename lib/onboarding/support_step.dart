import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Last step: an honest note that the app is free and how to support it.
/// "Let's start" always finishes; the coffee link keeps the user here.
class SupportStep extends StatelessWidget {
  const SupportStep({
    super.key,
    required this.busy,
    required this.onStart,
    required this.onSupport,
  });

  /// True while finishing; both buttons are disabled.
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepLayout(
      action: FilledButton(
        onPressed: busy ? null : onStart,
        child: Text(l10n.translate('onboarding_support_start')),
      ),
      secondaryAction: TextButton.icon(
        onPressed: busy ? null : onSupport,
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(l10n.translate('support_coffee')),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.favorite_outline,
            size: 32,
            color: LifePalette.of(context).accent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.translate('onboarding_support_title'),
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.translate('onboarding_support_body'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
