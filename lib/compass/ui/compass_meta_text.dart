import 'package:flutter/material.dart';

/// A quiet "Health · By 50" line; nothing when [parts] is empty.
class CompassMetaText extends StatelessWidget {
  const CompassMetaText(this.parts, {super.key});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        parts.join(' · '),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
