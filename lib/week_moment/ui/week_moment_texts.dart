import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ordinal.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_turn.dart';

/// The texts of one act: a [main] line in serif and an optional quieter
/// [detail] beneath it.
class WeekMomentLines {
  const WeekMomentLines(this.main, [this.detail]);

  final String main;
  final String? detail;

  /// Both lines as one sentence for screen readers.
  String get spoken => detail == null ? main : '$main $detail';
}

/// The texts of the weekly moment, built from a [WeekMomentStory] in the
/// app language. [address] greets the user by name once in the whole
/// moment: in the title of the closing step ("Daniel, the week is over.").
class WeekMomentTexts {
  const WeekMomentTexts(this.l10n, {this.address = PersonalAddress.none});

  final AppLocalizations l10n;
  final PersonalAddress address;

  String get _language => l10n.locale.languageCode;

  String _number(int n) => l10n.numberFormat.format(n);

  /// The small capitals above [act] ("This week", "Your phase", ...); null
  /// for the final act, whose steps carry their own eyebrows.
  String? eyebrow(WeekMomentAct act) => act == WeekMomentAct.next
      ? null
      : l10n.translate('week_moment_eyebrow_${act.name}');

  /// The lines of [act] in [story].
  WeekMomentLines linesFor(WeekMomentAct act, WeekMomentStory story) =>
      switch (act) {
        WeekMomentAct.week => WeekMomentLines(
          passedLine(story.passedWeeks),
          yearLine(story.year),
        ),
        WeekMomentAct.phase => _phaseLines(story.phase),
        WeekMomentAct.life => WeekMomentLines(lifeLine(story.life)),
        WeekMomentAct.next => closingLines(ClosingStep.close),
      };

  /// "Another week has passed." (never with the name, see [address]).
  String passedLine(int passedWeeks) => l10n.plural(
    'week_moment_passed',
    passedWeeks,
    replacements: {'n': _number(passedWeeks)},
  );

  /// Where the week stands in the year of life: just begun, a few days
  /// until the next one, or the weeks that remain.
  String yearLine(YearMoment year) {
    if (year.justBegan) {
      return l10n.translate(
        'week_moment_year_begun',
        replacements: {'ordinal': _ordinal(year.yearNumber)},
      );
    }
    if (year.weeksUntilBirthday == 0) return _daysLine(year);
    return l10n.plural(
      'week_moment_year_left',
      year.weeksUntilBirthday,
      replacements: {
        'ordinal': _ordinal(year.yearNumber),
        'n': _number(year.weeksUntilBirthday),
      },
    );
  }

  /// "Your 38th year of life begins in 3 days." (the coming year).
  String _daysLine(YearMoment year) => l10n.plural(
    'week_moment_year_days',
    year.daysUntilBirthday,
    replacements: {
      'ordinal': _ordinal(year.yearNumber + 1),
      'n': _number(year.daysUntilBirthday),
    },
  );

  String _ordinal(int n) => yearOrdinal(n, _language);

  WeekMomentLines _phaseLines(PhaseMoment? phase) {
    if (phase == null) return const WeekMomentLines('');
    return WeekMomentLines(phaseWeekLine(phase), phaseRestLine(phase));
  }

  /// "Week 9 of your phase “Building up”."
  String phaseWeekLine(PhaseMoment phase) => l10n.translate(
    'week_moment_phase_week',
    replacements: {
      'week': _number(phase.weekInPhase),
      'phase': phaseDisplayName(phase.phase, l10n),
    },
  );

  /// The planned weeks still ahead, or room for as long as it needs.
  String phaseRestLine(PhaseMoment phase) {
    final left = phase.plannedLeft;
    if (left == null) return l10n.translate('week_moment_phase_open');
    return l10n.plural(
      'week_moment_phase_left',
      left,
      replacements: {'n': _number(left)},
    );
  }

  /// What the whole life means: the weeks still ahead, or a gift beyond
  /// the life expectancy.
  String lifeLine(LifeMoment life) {
    if (life.beyond) return l10n.translate('week_moment_life_beyond');
    return l10n.plural(
      'week_moment_life',
      life.weeksRemaining,
      replacements: {
        'total': _number(life.totalWeeks),
        'n': _number(life.weeksRemaining),
      },
    );
  }

  // The closing steps

  String _stepKey(ClosingStep step, String part) =>
      'week_moment_${step.name}_$part';

  /// Title and question of [step]; only the closing title greets by name.
  WeekMomentLines closingLines(ClosingStep step) => WeekMomentLines(
    step == ClosingStep.close
        ? address.translate(l10n, _stepKey(step, 'title'))
        : l10n.translate(_stepKey(step, 'title')),
    l10n.translate(_stepKey(step, 'body')),
  );

  /// The label above [step]'s optional text field.
  String fieldLabel(ClosingStep step) =>
      l10n.translate(_stepKey(step, 'label'));

  /// The example inside [step]'s empty text field.
  String fieldHint(ClosingStep step) => l10n.translate(_stepKey(step, 'hint'));

  /// The main button of [step] ("Close the week", "Plan the week").
  String primaryAction(ClosingStep step) =>
      l10n.translate(_stepKey(step, 'primary'));

  /// The quiet button of [step] ("Kept in my thoughts", "Enjoy life").
  String secondaryAction(ClosingStep step) =>
      l10n.translate(_stepKey(step, 'secondary'));

  /// "1 of 2".
  String stepCounter(ClosingStep step) => l10n.translate(
    'week_moment_step_counter',
    replacements: {
      'step': _number(step.number),
      'total': _number(ClosingStep.count),
    },
  );

  /// The eyebrow of [step] at [turn]: the week that ended, or the next week
  /// with what is left of the phase or the year of life.
  String stepEyebrow(ClosingStep step, WeekTurn turn, WeekMomentStory story) =>
      switch (step) {
        ClosingStep.close => l10n.translate(
          'week_moment_close_eyebrow',
          replacements: {'week': _number(turn.endedWeek)},
        ),
        ClosingStep.plan => planEyebrow(turn.nextWeek, story),
      };

  /// "Week 46 · 6 more in this phase", else the weeks left in the year of
  /// life, else just "Week 46" (a birthday within days).
  String planEyebrow(int week, WeekMomentStory story) {
    final weekText = _number(week);
    final phaseLeft = story.phase?.plannedLeft;
    final yearLeft = story.year.weeksUntilBirthday;
    final (base, left) = phaseLeft != null
        ? ('week_moment_plan_eyebrow_phase', phaseLeft)
        : ('week_moment_plan_eyebrow_year', yearLeft);
    if (left <= 0) {
      return l10n.translate(
        'week_moment_plan_eyebrow',
        replacements: {'week': weekText},
      );
    }
    return l10n.plural(
      base,
      left,
      replacements: {'week': weekText, 'n': _number(left)},
    );
  }
}
