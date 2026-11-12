import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_steps.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';

/// Localisation keys of the lifestyle questions.
abstract final class LifestyleText {
  static String question(LifestyleFactor factor) =>
      'estimate_question_${factor.name}';
  static String hint(LifestyleFactor factor) => 'estimate_hint_${factor.name}';
  static String factorName(LifestyleFactor factor) =>
      'estimate_factor_${factor.name}';
  static String option(LifestyleFactor factor, LifestyleOption option) =>
      'estimate_option_${factor.name}_${option.name}';
}

/// Frame of one optional question: progress label, title, hint, [body] and
/// next / skip-the-rest actions.
class QuestionFrame extends StatelessWidget {
  /// The frame of the lifestyle question about [factor].
  QuestionFrame({
    super.key,
    required LifestyleFactor factor,
    required this.isLast,
    required this.onNext,
    required this.onSkipRest,
    required this.body,
    this.subject = const SelfSubject(),
  }) : number = factor.index + QuestionSteps.firstQuestion,
       questionKey = LifestyleText.question(factor),
       hintKey = LifestyleText.hint(factor),
       onSkip = null;

  /// A frame for a question that is not a lifestyle factor; [onSkip] adds
  /// a "Skip" action on the last question.
  const QuestionFrame.custom({
    super.key,
    required this.number,
    required this.questionKey,
    required this.hintKey,
    required this.isLast,
    required this.onNext,
    required this.onSkipRest,
    required this.body,
    this.onSkip,
    this.subject = const SelfSubject(),
  });

  /// 1-based position among the [QuestionSteps.questionCount] questions.
  final int number;
  final String questionKey;
  final String hintKey;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkipRest;
  final VoidCallback? onSkip;
  final List<Widget> body;

  /// Whose estimate this is; picks the question, hint and button texts.
  final LifespanEstimateSubject subject;

  Widget? _secondaryAction(AppLocalizations l10n) {
    if (!isLast) {
      return TextButton(
        key: const ValueKey('lifespan_skip_rest'),
        onPressed: onSkipRest,
        child: Text(l10n.translate('estimate_skip_rest')),
      );
    }
    final skip = onSkip;
    if (skip == null) return null;
    return TextButton(
      key: const ValueKey('lifespan_skip_question'),
      onPressed: skip,
      child: Text(l10n.translate('estimate_skip')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepLayout(
      action: FilledButton(
        key: const ValueKey('lifespan_next'),
        onPressed: onNext,
        child: Text(
          isLast
              ? subject.translate(l10n, 'estimate_show_estimate')
              : l10n.translate('estimate_next'),
        ),
      ),
      secondaryAction: _secondaryAction(l10n),
      children: [
        SectionLabel(
          l10n.translate(
            'estimate_question_progress',
            replacements: {
              'n': '$number',
              'total': '${QuestionSteps.questionCount}',
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subject.translate(l10n, questionKey),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          subject.translate(l10n, hintKey),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        ...body,
      ],
    );
  }
}

/// One question answered by picking a category (or "Prefer not to say").
class QuestionPage extends StatelessWidget {
  const QuestionPage({
    super.key,
    required this.factor,
    required this.answer,
    required this.isLast,
    required this.onAnswer,
    required this.onNext,
    required this.onSkipRest,
    this.subject = const SelfSubject(),
  });

  final LifestyleFactor factor;
  final LifestyleOption? answer;
  final LifespanEstimateSubject subject;
  final bool isLast;
  final ValueChanged<LifestyleOption?> onAnswer;
  final VoidCallback onNext;
  final VoidCallback onSkipRest;

  @override
  Widget build(BuildContext context) {
    return QuestionFrame(
      factor: factor,
      isLast: isLast,
      onNext: onNext,
      onSkipRest: onSkipRest,
      subject: subject,
      body: [
        OptionList(
          factor: factor,
          answer: answer,
          onAnswer: onAnswer,
          subject: subject,
        ),
      ],
    );
  }
}

/// Calm list of the options of [factor] plus "Prefer not to say" (= null).
class OptionList extends StatelessWidget {
  const OptionList({
    super.key,
    required this.factor,
    required this.answer,
    required this.onAnswer,
    this.subject = const SelfSubject(),
  });

  final LifestyleFactor factor;
  final LifestyleOption? answer;
  final ValueChanged<LifestyleOption?> onAnswer;

  /// Picks the "Prefer not to say" / "Don't know" label.
  final LifespanEstimateSubject subject;

  /// Radio value of "Prefer not to say".
  static const int _preferNot = -1;

  void _pick(int index) {
    Haptics.selection();
    onAnswer(index == _preferNot ? null : factor.options[index]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = answer == null
        ? _preferNot
        : factor.options.indexOf(answer!);
    final rows = [
      for (var i = 0; i < factor.options.length; i++)
        (i, l10n.translate(LifestyleText.option(factor, factor.options[i]))),
      (_preferNot, subject.translate(l10n, 'estimate_prefer_not')),
    ];
    return Material(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: RadioGroup<int>(
        groupValue: selected,
        onChanged: (value) => _pick(value ?? _preferNot),
        child: Column(
          children: [
            for (final (index, label) in rows)
              ListTile(
                key: ValueKey('lifespan_option_${factor.name}_$index'),
                contentPadding: const EdgeInsetsDirectional.only(
                  start: 8,
                  end: 16,
                ),
                leading: Radio<int>(value: index),
                title: Text(label),
                onTap: () => _pick(index),
              ),
          ],
        ),
      ),
    );
  }
}
