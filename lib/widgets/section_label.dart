import 'package:flutter/material.dart';

/// Small uppercase, letter-spaced section header in the muted text colour.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color})
      : _compact = false;

  /// Smaller variant with spacing below, used above form and friend-detail
  /// sections ("BIRTHDAY").
  const SectionLabel.compact(this.text, {super.key})
      : color = null,
        _compact = true;

  final String text;

  /// Overrides the default `onSurfaceVariant` colour (e.g. `error`).
  final Color? color;

  final bool _compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle =
        _compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium;
    final label = Text(
      text.toUpperCase(),
      style: baseStyle?.copyWith(
        color: color ?? theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.8,
      ),
    );
    if (!_compact) return label;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: label);
  }
}
