import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_week.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';

/// Small Life-tab card with this week's Compass question and "Open
/// Compass"; tapping anywhere opens the Compass tab.
class CompassWeekCard extends StatelessWidget {
  const CompassWeekCard({super.key, required this.week, required this.onOpen});

  final CompassWeek week;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('life_compass_card'),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(l10n.translate('compass_question_label')),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  week.questionText(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Fraunces',
                    fontWeight: FontWeight.w400,
                    color: LifePalette.of(context).quoteText,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: Text(l10n.translate('compass_open')),
                  onPressed: onOpen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
