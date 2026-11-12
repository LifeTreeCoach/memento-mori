import 'package:flutter/material.dart';

/// Small uppercase section label ("TODAY", "EVERYONE") with an optional
/// trailing action.
class PeopleSectionHeader extends StatelessWidget {
  const PeopleSectionHeader({
    super.key,
    required this.label,
    this.color,
    this.trailing,
  });

  final String label;

  /// Label colour; muted by default.
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, trailing == null ? 20 : 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color ?? theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
