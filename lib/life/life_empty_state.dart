import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Shown instead of the grid until a birth date is set.
class LifeEmptyState extends StatelessWidget {
  const LifeEmptyState({super.key, required this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty_rounded,
              size: 48, color: LifePalette.of(context).accent),
          const SizedBox(height: 20),
          Text(
            l10n.translate('empty_birthdate_title'),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('empty_birthdate_body'),
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (onOpenSettings != null)
            FilledButton.tonal(
              onPressed: onOpenSettings,
              child: Text(l10n.translate('open_settings')),
            ),
        ],
      ),
    );
  }
}
