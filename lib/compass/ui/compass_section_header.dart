import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';

/// Section label with a short muted line below (wraps), and an optional
/// trailing widget (e.g. an expand button) kept 12 px away from it.
class CompassSectionHeader extends StatelessWidget {
  const CompassSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: SectionLabel(title)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            // Keeps a count ("…c’est 1") from touching a wrapped subtitle.
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
