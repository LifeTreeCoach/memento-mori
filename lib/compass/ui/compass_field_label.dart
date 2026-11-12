import 'package:flutter/material.dart';

/// Small muted label above a group of sheet fields.
class CompassFieldLabel extends StatelessWidget {
  const CompassFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
