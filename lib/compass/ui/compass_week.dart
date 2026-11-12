import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/weekly_question.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// This week's question with everything needed to show it: the prompt
/// (swapped if the user asked for another one), the week's state and the
/// weeks lived for `{weeks}` and the current life phase for `{phase}`.
class CompassWeek {
  const CompassWeek({
    required this.question,
    required this.note,
    required this.state,
    required this.weeksLived,
    this.phase,
  });

  /// The week of [today] for someone born on [birthDate] (if known).
  factory CompassWeek.of(DateTime today, {DateTime? birthDate}) {
    final calc = birthDate == null
        ? null
        : LifeCalculator(birthDate: birthDate, now: today);
    final state = CompassService.weekState(today);
    final phase = currentSpan(CompassService.data.phases, today)?.phase;
    return CompassWeek(
      question: questionForWeek(
        today,
        ageYears: calc?.ageYears.toDouble() ?? compassDefaultAgeYears,
        gentleOnly: CompassService.gentleOnly,
        swap: state.swapped ? 1 : 0,
        hasPhase: phase != null,
      ),
      note: noteForWeek(today),
      state: state,
      weeksLived: calc?.weeksLived,
      phase: phase,
    );
  }

  final CompassPrompt question;

  /// The compassionate note of this week.
  final CompassPrompt note;
  final CompassWeekState state;

  /// Full weeks lived; null without a birth date.
  final int? weeksLived;

  /// The life phase lived this week; null before the first phase. Phase
  /// questions are only chosen when it is set.
  final LifePhase? phase;

  /// The note is shown on quieter weeks (rest and pride questions) only,
  /// and only when `{weeks}` can be filled in.
  bool get showsNote =>
      weeksLived != null &&
      (question.kind == CompassPromptKind.rest ||
          question.kind == CompassPromptKind.pride);

  /// The question in the language of [l10n].
  String questionText(AppLocalizations l10n) => _text(question, l10n);

  /// The note in the language of [l10n].
  String noteText(AppLocalizations l10n) => _text(note, l10n);

  String _text(CompassPrompt prompt, AppLocalizations l10n) {
    final weeks = weeksLived;
    final phase = this.phase;
    return prompt.textFor(
      l10n.locale.languageCode,
      replacements: {
        if (weeks != null) 'weeks': l10n.numberFormat.format(weeks),
        if (phase != null) 'phase': phaseDisplayName(phase, l10n),
      },
    );
  }
}
