import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Calm note on the result page when chronic conditions were ticked:
/// treatment changes a lot, this is not medical advice.
class ConditionsNote extends StatelessWidget {
  const ConditionsNote({super.key, this.subject = const SelfSubject()});

  final LifespanEstimateSubject subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            subject.translate(
              AppLocalizations.of(context),
              'estimate_conditions_note',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
