import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/conditions_note.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_page.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/range_bar.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/sources_sheet.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';

/// Part 3: what people with similar answers tend to reach, the range, the
/// optional "what tends to help" and the fine-tune slider.
class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.estimate,
    required this.years,
    required this.currentYears,
    required this.keepLabel,
    required this.onYearsChanged,
    required this.onApply,
    required this.onKeep,
    this.showConditionsNote = false,
    this.subject = const SelfSubject(),
  });

  final LifespanEstimate estimate;

  /// Whose estimate this is ("your" or a named person's texts).
  final LifespanEstimateSubject subject;

  /// Shows [ConditionsNote] (at least one chronic condition was ticked).
  final bool showConditionsNote;

  /// The fine-tuned value shown on the slider.
  final int years;

  /// The life expectancy in use; when [years] equals it, a single
  /// "keep" button replaces "use" + "keep".
  final int currentYears;
  final String keepLabel;
  final ValueChanged<int> onYearsChanged;
  final VoidCallback onApply;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final summary = subject.translate(
      l10n,
      'estimate_result_sentence',
      replacements: {
        'mean': '${estimate.mean.round()}',
        'p25': '${estimate.p25.round()}',
        'p75': '${estimate.p75.round()}',
      },
    );
    // Same value as now: applying still saves the estimate behind it.
    final unchanged = years == currentYears;
    return StepLayout(
      action: FilledButton(
        key: const ValueKey('lifespan_apply'),
        onPressed: onApply,
        child: Text(
          unchanged
              ? keepLabel
              : l10n.translate('estimate_apply', replacements: {'n': '$years'}),
        ),
      ),
      secondaryAction: unchanged
          ? null
          : TextButton(onPressed: onKeep, child: Text(keepLabel)),
      children: [
        SectionLabel(subject.translate(l10n, 'estimate_result_label')),
        const SizedBox(height: 12),
        Text(
          l10n.translate(
            'estimate_result_headline',
            replacements: {'n': '${estimate.mean.round()}'},
          ),
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(summary, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 20),
        RangeBar(p25: estimate.p25, mean: estimate.mean, p75: estimate.p75),
        _Chances(estimate: estimate),
        if (showConditionsNote)
          ConditionsNote(
            key: const ValueKey('lifespan_conditions_note'),
            subject: subject,
          ),
        if (estimate.gains.isNotEmpty) _Gains(gains: estimate.gains),
        const SizedBox(height: 24),
        _FineTune(subject: subject, years: years, onChanged: onYearsChanged),
        const SizedBox(height: 16),
        Text(
          l10n.translate('estimate_footnote'),
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const ValueKey('lifespan_sources'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => showLifespanSourcesSheet(context),
            child: Text(l10n.translate('estimate_sources')),
          ),
        ),
      ],
    );
  }
}

/// Horizontal space between the "chance to reach" columns.
const double _chanceGap = 32;

/// "Chance to reach 80 / 90", only for ages not reached yet.
class _Chances extends StatelessWidget {
  const _Chances({required this.estimate});

  final LifespanEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = NumberFormat.percentPattern(l10n.locale.languageCode);
    final chances = [
      if (estimate.reach80 != null) (80, estimate.reach80!),
      if (estimate.reach90 != null) (90, estimate.reach90!),
    ];
    if (chances.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        // A clear gap: long captions ("probabilidad de llegar a 80") wrap
        // instead of running into the next one.
        spacing: _chanceGap,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (age, chance) in chances)
            Expanded(
              child: _Stat(
                key: ValueKey('estimate_reach_$age'),
                value: percent.format(chance),
                label: l10n.translate(
                  'estimate_reach',
                  replacements: {'age': '$age'},
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Collapsed list of possible gains, phrased as observations.
class _Gains extends StatelessWidget {
  const _Gains({required this.gains});

  final Map<LifestyleFactor, double> gains;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('lifespan_gains'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          maintainState: true,
          title: Text(
            l10n.translate('estimate_gains_title'),
            style: theme.textTheme.titleMedium,
          ),
          children: [
            Text(
              l10n.translate('estimate_gains_intro'),
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 8),
            for (final entry in gains.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translate(LifestyleText.factorName(entry.key)),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      l10n.plural(
                        'estimate_gain',
                        entry.value.round().clamp(1, 99).toInt(),
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Your number": the 50..110 slider, defaulting to the recommended value.
class _FineTune extends StatelessWidget {
  const _FineTune({
    required this.subject,
    required this.years,
    required this.onChanged,
  });

  final LifespanEstimateSubject subject;
  final int years;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: SectionLabel(
                subject.translate(l10n, 'estimate_your_number'),
              ),
            ),
            Text(
              l10n.translate(
                'settings_years_value',
                replacements: {'n': '$years'},
              ),
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        Slider(
          key: const ValueKey('lifespan_slider'),
          value: years.toDouble(),
          min: estimateMinYears.toDouble(),
          max: estimateMaxYears.toDouble(),
          divisions: estimateMaxYears - estimateMinYears,
          label: '$years',
          semanticFormatterCallback: (value) =>
              l10n.plural('friend_years', value.round()),
          onChanged: (value) {
            if (value.round() != years) Haptics.selection();
            onChanged(value.round());
          },
        ),
        Text(
          subject.translate(l10n, 'estimate_fine_tune_note'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
