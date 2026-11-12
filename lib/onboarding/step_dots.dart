import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Three small dots; the current step is a slightly longer pill.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = AppLocalizations.of(context).translate(
      'onboarding_step',
      replacements: {'n': '${index + 1}', 'total': '$count'},
    );
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < count; i++)
              AnimatedContainer(
                duration: Motion.of(context, Motion.medium),
                curve: Motion.standard,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == index ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == index ? scheme.onSurface : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
