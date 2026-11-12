import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// The Life tab's occasional prompt card: an accent [icon], a [text], the
/// [primary] button across the full width and the [secondary] (text)
/// buttons together on one row below it (they only wrap with very large
/// fonts). Three buttons in one row don't fit a phone in every language,
/// so the layout is two rows on purpose. Shared by `SupportCard` and
/// `RecommendCard`.
class PromptCardFrame extends StatelessWidget {
  const PromptCardFrame({
    super.key,
    required this.icon,
    required this.text,
    required this.primary,
    required this.secondary,
  });

  final IconData icon;
  final String text;

  /// The card's main action, usually a [FilledButton]; stretched to the
  /// card's width.
  final Widget primary;

  /// The quieter actions (e.g. "Not now"), usually [TextButton]s.
  final List<Widget> secondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('life_support_card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: Icon(
                    icon,
                    size: 20,
                    color: LifePalette.of(context).accent,
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: primary),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
