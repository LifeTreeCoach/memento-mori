import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';

/// Calm, illustration-free text shown before anyone has been added.
class PeopleEmptyState extends StatelessWidget {
  const PeopleEmptyState({
    super.key,
    required this.onAdd,
    required this.onImport,
  });

  final VoidCallback onAdd;

  /// Opens the birthday import (contacts / vCard).
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _CenteredMessage(
      title: l10n.translate('people_empty_title'),
      body: l10n.translate('people_empty_body'),
      titleStyle: theme.textTheme.headlineSmall,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TourAnchor(
            id: PeopleTour.addAnchor,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.translate('people_add_person')),
            ),
          ),
          const SizedBox(height: 8),
          TourAnchor(
            id: PeopleTour.importAnchor,
            child: OutlinedButton.icon(
              key: const ValueKey('people-empty-import'),
              onPressed: onImport,
              icon: const Icon(Icons.cake_outlined),
              label: Text(l10n.translate('import_birthdays')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when search or filters hide everyone.
class PeopleNoMatchState extends StatelessWidget {
  const PeopleNoMatchState({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CenteredMessage(
      title: l10n.translate('people_no_match_title'),
      body: l10n.translate('people_no_match_body'),
      titleStyle: Theme.of(context).textTheme.titleLarge,
      action: TextButton(
        onPressed: onClear,
        child: Text(l10n.translate('people_clear_filters')),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.title,
    required this.body,
    required this.action,
    this.titleStyle,
  });

  final String title;
  final String body;
  final Widget action;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: titleStyle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            action,
          ],
        ),
      ),
    );
  }
}
