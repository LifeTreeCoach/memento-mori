import 'package:flutter/material.dart';

/// An inviting line for an empty section (never a "nothing done" nag).
class CompassInvite extends StatelessWidget {
  const CompassInvite(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontFamily: 'Fraunces',
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}
