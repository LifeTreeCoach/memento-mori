import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_week.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// The question of the week in serif type, with what answering it could
/// become (intention or moment), "Another question" (once a week) and
/// "Not now".
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.week,
    required this.onMakeIntention,
    required this.onNoteMoment,
    required this.onSwap,
    required this.onDismiss,
  });

  final CompassWeek week;
  final VoidCallback onMakeIntention;
  final VoidCallback onNoteMoment;

  /// Null once the question was swapped this week (the action is hidden).
  final VoidCallback? onSwap;
  final VoidCallback onDismiss;

  CompassPrompt get _question => week.question;

  bool get _suggestsMoment =>
      _question.suggestion == CompassSuggestion.moment ||
      _question.kind == CompassPromptKind.pride;

  bool get _suggestsIntention =>
      _question.suggestion == CompassSuggestion.intention ||
      (_question.suggestion == null && !_suggestsMoment);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const ValueKey('compass_question_card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(context, l10n),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _questionText(context, l10n),
            ),
            const SizedBox(height: 8),
            _actions(l10n),
          ],
        ),
      ),
    );
  }

  /// "QUESTION OF THE WEEK · REST": the topic (or kind) shown subtly after
  /// the label.
  Widget _label(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final topic = l10n.questionTopicLabel(_question);
    final label = [l10n.translate('compass_question_label'), ?topic].join(' · ');
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _questionText(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Text(
      week.questionText(l10n),
      key: const ValueKey('compass_question_text'),
      style: theme.textTheme.titleLarge?.copyWith(
        fontFamily: 'Fraunces',
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: LifePalette.of(context).quoteText,
      ),
    );
  }

  Widget _actions(AppLocalizations l10n) {
    return Wrap(
      spacing: 4,
      children: [
        if (_suggestsIntention)
          TextButton.icon(
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: Text(l10n.translate('compass_make_intention')),
            onPressed: onMakeIntention,
          ),
        if (_suggestsMoment)
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: Text(l10n.translate('compass_note_moment')),
            onPressed: onNoteMoment,
          ),
        if (onSwap != null)
          TextButton(
            onPressed: onSwap,
            child: Text(l10n.translate('compass_another_question')),
          ),
        TextButton(
          onPressed: onDismiss,
          child: Text(l10n.translate('compass_not_now')),
        ),
      ],
    );
  }
}
