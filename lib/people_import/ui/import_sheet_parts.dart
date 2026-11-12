import 'package:flutter/material.dart';

import '../../localization.dart';

/// "Recommended" label under a source option.
class RecommendedBadge extends StatelessWidget {
  const RecommendedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        AppLocalizations.of(context).translate('import_recommended'),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Lock icon with the "stays on your device" line.
class PrivacyLine extends StatelessWidget {
  const PrivacyLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
