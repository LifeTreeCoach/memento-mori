import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/completion_story.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Closing lines per tone (`reflection_thanks_<tone>_<i>`).
const Map<GratitudeTone, int> reflectionThanksCount = {
  GratitudeTone.doTask: 3,
  GratitudeTone.enjoy: 3,
  GratitudeTone.long: 2,
};

/// Sentences of the look back after completing an intention, one per
/// level, so each reads as a whole for screen readers too.
extension ReflectionTexts on AppLocalizations {
  /// "Nach 6 Wochen geschafft" (no full stop); "Nach 6 Wochen erlebt" for
  /// an intention of [kind] enjoy.
  String takenText(TakenTime taken, {IntentionKind? kind}) {
    final prefix = kind == IntentionKind.enjoy
        ? 'reflection_taken_enjoy'
        : 'reflection_taken';
    return switch (taken.unit) {
      TakenUnit.sameDay => translate('${prefix}_same_day'),
      TakenUnit.days => plural('${prefix}_days', taken.count),
      TakenUnit.weeks => plural('${prefix}_weeks', taken.count),
      TakenUnit.months => plural('${prefix}_months', taken.count),
    };
  }

  /// Level 1: "Nach 6 Wochen geschafft – in Woche 9 deiner Phase „…“.",
  /// or only "Nach 6 Wochen geschafft." without a phase.
  String phaseLine(CompletionStory story) {
    final taken = takenText(story.taken, kind: story.kind);
    final phase = story.phase;
    if (phase == null) {
      return translate('reflection_taken_line', replacements: {'taken': taken});
    }
    return translate(
      'reflection_phase_line',
      replacements: {
        'taken': taken,
        'week': numberFormat.format(phase.weekInPhase),
        'phase': phaseDisplayName(phase.phase, this),
      },
    );
  }

  /// Level 2: "Ein Moment in Woche 1.913 deines Lebens – …".
  String lifeLine(LifeStory life) => translate(
        'reflection_life_line',
        replacements: {'week': numberFormat.format(life.weekOfLife)},
      );

  /// Level 3: "Vor dir liegen noch etwa 2.247 Wochen. …".
  String aheadLine(LifeStory life) => plural(
        'reflection_ahead',
        life.weeksRemaining,
        replacements: {'n': numberFormat.format(life.weeksRemaining)},
      );

  /// The self-compassion / gratitude line, the same for an intention
  /// every time.
  String thanksLine(CompletionStory story) {
    final count = reflectionThanksCount[story.tone]!;
    return translate(
      'reflection_thanks_${story.tone.name}_${story.gratitudeIndex % count}',
    );
  }

  /// Hint of the gratitude note for an intention of [kind].
  String noteHint(IntentionKind? kind) => translate(
        kind == IntentionKind.enjoy
            ? 'reflection_note_hint_enjoy'
            : 'reflection_note_hint_doTask',
      );
}
