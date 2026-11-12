import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/baseline_bar.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_intro.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_steps.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Part 1 of the estimate: country and sex, plus the optional questions.
class BasicsPage extends StatelessWidget {
  const BasicsPage({
    super.key,
    required this.countryName,
    required this.sex,
    required this.baselineYears,
    required this.answeredCount,
    required this.showQuestions,
    required this.loading,
    required this.failed,
    required this.keepLabel,
    required this.onPickCountry,
    required this.onSexChanged,
    required this.onQuestions,
    required this.onShowEstimate,
    required this.onKeep,
    this.subject = const SelfSubject(),
    this.intro,
  });

  /// Whose estimate this is ("your" or a named person's texts).
  final LifespanEstimateSubject subject;

  /// The caller's own title and intro; null uses the [subject]'s texts.
  final EstimateIntro? intro;

  /// Null while the names are loading.
  final String? countryName;
  final Sex sex;

  /// Population estimate for [sex] and the country, drawn as a bar without
  /// a number; null while the data is loading.
  final int? baselineYears;
  final int answeredCount;

  /// False under 18: no lifestyle questions.
  final bool showQuestions;
  final bool loading;

  /// The data could not be loaded; only "keep" is offered.
  final bool failed;
  final String keepLabel;
  final VoidCallback onPickCountry;
  final ValueChanged<Sex> onSexChanged;
  final VoidCallback onQuestions;
  final VoidCallback onShowEstimate;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    if (failed) {
      return _FailedPage(
        subject: subject,
        title: _title(l10n),
        keepLabel: keepLabel,
        onKeep: onKeep,
      );
    }
    // Compact spacing keeps the "more personal" card above the pinned
    // buttons on a 393x851 screen in every language.
    return StepLayout(
      topPadding: 24,
      action: FilledButton(
        key: const ValueKey('lifespan_show_estimate'),
        onPressed: loading ? null : onShowEstimate,
        child: Text(subject.translate(l10n, 'estimate_show_estimate')),
      ),
      secondaryAction: TextButton(onPressed: onKeep, child: Text(keepLabel)),
      children: [
        Text(_title(l10n), style: theme.textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          intro?.text ?? subject.translate(l10n, 'estimate_intro'),
          style: theme.textTheme.bodyLarge?.copyWith(color: muted),
        ),
        if (!subject.isSelf) ...[
          const SizedBox(height: 8),
          Text(
            l10n.translate('estimate_other_privacy'),
            key: const ValueKey('lifespan_other_privacy'),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
        const SizedBox(height: 24),
        _CountryField(name: countryName, onTap: loading ? null : onPickCountry),
        const SizedBox(height: 24),
        Text(
          l10n.translate('estimate_sex'),
          style: theme.textTheme.labelLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: 10),
        _SexChoice(subject: subject, sex: sex, onChanged: onSexChanged),
        const SizedBox(height: 8),
        Text(
          l10n.translate('estimate_sex_note'),
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        BaselineBar(years: baselineYears),
        if (showQuestions) ...[
          const SizedBox(height: 16),
          _PersonalCard(
            answeredCount: answeredCount,
            onTap: loading ? null : onQuestions,
          ),
        ],
      ],
    );
  }

  String _title(AppLocalizations l10n) =>
      intro?.title ?? subject.translate(l10n, 'estimate_title');
}

/// Large tappable field: label above, the country name (or a spinner).
class _CountryField extends StatelessWidget {
  const _CountryField({required this.name, required this.onTap});

  final String? name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = name;
    return Material(
      color:
          theme.inputDecorationTheme.fillColor ?? scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const ValueKey('lifespan_country'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('estimate_country'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (value == null)
                      const _QuietProgress()
                    else
                      Text(value, style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietProgress extends StatelessWidget {
  const _QuietProgress();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).translate('estimate_loading'),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _SexChoice extends StatelessWidget {
  const _SexChoice({
    required this.subject,
    required this.sex,
    required this.onChanged,
  });

  final LifespanEstimateSubject subject;
  final Sex sex;
  final ValueChanged<Sex> onChanged;

  String _label(AppLocalizations l10n, Sex option) => switch (option) {
    Sex.female => l10n.translate('estimate_sex_female'),
    Sex.male => l10n.translate('estimate_sex_male'),
    Sex.unspecified => subject.translate(l10n, 'estimate_prefer_not'),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in Sex.values)
          ChoiceChip(
            key: ValueKey('lifespan_sex_${option.name}'),
            label: Text(_label(l10n, option)),
            // The fill marks the choice; no checkmark keeps the row short.
            showCheckmark: false,
            selected: option == sex,
            onSelected: (_) {
              Haptics.selection();
              onChanged(option);
            },
          ),
      ],
    );
  }
}

/// "Make it more personal": entry to the optional questions.
class _PersonalCard extends StatelessWidget {
  const _PersonalCard({required this.answeredCount, required this.onTap});

  final int answeredCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = QuestionSteps.questionCount;
    final subtitle = answeredCount == 0
        ? l10n.translate('estimate_personal_sub', replacements: {'n': '$total'})
        : l10n.translate(
            'estimate_personal_answered',
            replacements: {'n': '$answeredCount', 'total': '$total'},
          );
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        key: const ValueKey('lifespan_personal'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('estimate_personal'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the bundled data cannot be read: the current value stays.
class _FailedPage extends StatelessWidget {
  const _FailedPage({
    required this.subject,
    required this.title,
    required this.keepLabel,
    required this.onKeep,
  });

  final LifespanEstimateSubject subject;
  final String title;
  final String keepLabel;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepLayout(
      action: FilledButton(onPressed: onKeep, child: Text(keepLabel)),
      children: [
        Text(title, style: theme.textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          subject.translate(l10n, 'estimate_load_failed'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
