import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_page.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_steps.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Localisation key of a condition's plain-language label.
String conditionLabelKey(ChronicCondition condition) =>
    'estimate_condition_${condition.name}';

/// Ticking [condition] (or unticking it) in [current]: a condition clears
/// "none of these"; nothing ticked any more means not answered (null).
Set<ChronicCondition>? toggleCondition(
  Set<ChronicCondition>? current,
  ChronicCondition condition,
) {
  final next = {...?current};
  if (!next.remove(condition)) next.add(condition);
  return next.isEmpty ? null : next;
}

/// Ticking "none of these": the empty set (clears every condition);
/// unticking it means not answered (null).
Set<ChronicCondition>? toggleNoCondition(Set<ChronicCondition>? current) =>
    current != null && current.isEmpty ? null : const {};

/// The last, optional question: diagnosed chronic conditions as checkboxes
/// plus an exclusive "None of these". Skip = not answered (null).
class ConditionsPage extends StatelessWidget {
  const ConditionsPage({
    super.key,
    required this.answer,
    required this.onAnswer,
    required this.onNext,
    required this.onSkip,
    this.subject = const SelfSubject(),
  });

  final LifespanEstimateSubject subject;

  /// Null = not answered, empty = "none of these".
  final Set<ChronicCondition>? answer;
  final ValueChanged<Set<ChronicCondition>?> onAnswer;
  final VoidCallback onNext;

  /// Clears the answer and shows the estimate.
  final VoidCallback onSkip;

  void _set(Set<ChronicCondition>? value) {
    Haptics.selection();
    onAnswer(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final none = answer != null && answer!.isEmpty;
    return QuestionFrame.custom(
      number: QuestionSteps.questionCount,
      questionKey: 'estimate_question_conditions',
      hintKey: 'estimate_hint_conditions',
      isLast: true,
      onNext: onNext,
      onSkipRest: onSkip,
      onSkip: onSkip,
      subject: subject,
      body: [
        Material(
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (final condition in ChronicCondition.values)
                _checkRow(
                  key: ValueKey('lifespan_condition_${condition.name}'),
                  label: l10n.translate(conditionLabelKey(condition)),
                  checked: answer?.contains(condition) ?? false,
                  onTap: () => _set(toggleCondition(answer, condition)),
                ),
              Divider(height: 1, color: scheme.outlineVariant),
              _checkRow(
                key: const ValueKey('lifespan_condition_none'),
                label: l10n.translate('estimate_condition_none'),
                checked: none,
                onTap: () => _set(toggleNoCondition(answer)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subject.translate(l10n, 'estimate_conditions_privacy'),
          key: const ValueKey('lifespan_conditions_privacy'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// One checkbox row; [key] sits on the tile itself.
  static Widget _checkRow({
    required Key key,
    required String label,
    required bool checked,
    required VoidCallback onTap,
  }) => CheckboxListTile(
    key: key,
    contentPadding: const EdgeInsetsDirectional.only(start: 8, end: 16),
    controlAffinity: ListTileControlAffinity.leading,
    value: checked,
    title: Text(label),
    onChanged: (_) => onTap(),
  );
}
