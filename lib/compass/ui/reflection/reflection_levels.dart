import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/completion_story.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/add_intention/phase_week_dots.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/lifespan_bar.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/reflection/breathing_dot.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/reflection/reflection_texts.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Fades and lifts [child] in as [animation] runs from 0 to 1.
class RevealLevel extends StatelessWidget {
  const RevealLevel({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  static final Tween<Offset> _lift = Tween(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: animation.drive(_lift), child: child),
    );
  }
}

/// A level of the look back: optional eyebrow (a heading for screen
/// readers), the visual (hidden from screen readers, the sentence tells
/// the same) and one sentence. Every level starts [gap] below the one
/// before, with or without its eyebrow.
class _Level extends StatelessWidget {
  const _Level({super.key, this.eyebrow, this.visual, required this.sentence});

  final String? eyebrow;
  final Widget? visual;
  final String sentence;

  /// Space between the end of one level and the start of the next.
  static const double gap = 28;

  @override
  Widget build(BuildContext context) {
    final eyebrow = this.eyebrow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (eyebrow != null)
          Semantics(header: true, child: PhaseEyebrow(eyebrow, top: gap))
        else
          const SizedBox(height: gap),
        if (visual case final visual?) ...[
          ExcludeSemantics(child: visual),
          const SizedBox(height: 12),
        ],
        Text(sentence, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

/// Level 1: how long it took and where in the phase (dots with this week
/// breathing); only the time without a phase.
class PhaseLevel extends StatelessWidget {
  const PhaseLevel({super.key, required this.story});

  final CompletionStory story;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = story.phase;
    return _Level(
      key: const ValueKey('reflection_phase_level'),
      eyebrow:
          phase == null ? null : l10n.translate('reflection_phase_eyebrow'),
      visual: phase == null
          ? null
          : PhaseWeekDots(
              weeks: phase.weeks,
              highlightWeek: phase.weekIndex,
              highlight: const BreathingDot(),
            ),
      sentence: l10n.phaseLine(story),
    );
  }
}

/// Level 2: the whole lifespan with today marked.
class LifeLevel extends StatelessWidget {
  const LifeLevel({super.key, required this.life});

  final LifeStory life;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Level(
      key: const ValueKey('reflection_life_level'),
      eyebrow: l10n.translate('reflection_life_eyebrow'),
      visual: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: LifespanBar(fractions: life.bar, marker: life.position),
      ),
      sentence: l10n.lifeLine(life),
    );
  }
}

/// Level 3: the weeks that lie ahead, as room for more.
class AheadLevel extends StatelessWidget {
  const AheadLevel({super.key, required this.life});

  final LifeStory life;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Level(
      key: const ValueKey('reflection_ahead_level'),
      eyebrow: l10n.translate('reflection_ahead_eyebrow'),
      sentence: l10n.aheadLine(life),
    );
  }
}

/// The closing line in the phase gold, and the optional gratitude note.
class ThanksLevel extends StatelessWidget {
  const ThanksLevel({
    super.key,
    required this.story,
    required this.note,
    this.fieldKey,
  });

  final CompletionStory story;
  final TextEditingController note;

  /// Key around the note field, to scroll it into view.
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Text(
          l10n.thanksLine(story),
          key: const ValueKey('reflection_thanks'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Fraunces',
            fontStyle: FontStyle.italic,
            color: PhaseStyle.readableGold(context),
          ),
        ),
        const SizedBox(height: 20),
        KeyedSubtree(
          key: fieldKey,
          child: TextField(
            key: const ValueKey('reflection_note'),
            controller: note,
            maxLength: 140,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.translate('reflection_note_label'),
              hintText: l10n.noteHint(story.kind),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}
