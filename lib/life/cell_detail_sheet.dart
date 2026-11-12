import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// Localized sentences describing a [LifePeriod].
class LifePeriodText {
  LifePeriodText(this.l10n);

  final AppLocalizations l10n;

  String date(DateTime d) => l10n.shortDateFormat.format(d);

  /// "Week of 12 Mar 1998".
  String title(LifePeriod period) {
    return l10n.translate('period_title_${period.mode.id}',
        replacements: {'date': date(period.start)});
  }

  /// "You were 12" / "You are 35" / "You will be 50".
  String age(LifePeriod period) {
    final key = switch (period.relation) {
      PeriodRelation.past => 'age_past',
      PeriodRelation.current => 'age_current',
      PeriodRelation.future => 'age_future',
    };
    return l10n.plural(key, period.ageAtStart);
  }

  /// "1,203 weeks ago" / "In 410 weeks" / "This week".
  String relative(LifePeriod period) {
    final unit = period.mode.id;
    if (period.relation == PeriodRelation.current) {
      return l10n.translate('rel_${unit}_current');
    }
    final direction = period.relation == PeriodRelation.past ? 'past' : 'future';
    final n = l10n.numberFormat.format(period.distance);
    return l10n.plural('rel_${unit}_$direction', period.distance,
        replacements: {'n': n});
  }

  /// "Anna turned 14" / "Anna turns 14" / "Anna was born"; without a
  /// birth year "Anna had a birthday" / "Anna has a birthday".
  String birthday(FriendBirthday b) {
    final age = b.age;
    final replacements = {'name': b.friend.name, 'age': '$age'};
    if (age == null) {
      final when = b.isToday ? 'today' : (b.isPast ? 'past' : 'future');
      return l10n.translate('friend_birthday_${when}_noage',
          replacements: replacements);
    }
    if (age == 0) {
      final key = b.isPast ? 'friend_born_past' : 'friend_born_future';
      return l10n.translate(key, replacements: replacements);
    }
    final key = b.isToday
        ? 'friend_turns_today'
        : (b.isPast ? 'friend_turned' : 'friend_turns');
    return l10n.plural(key, age, replacements: replacements);
  }
}

/// The life phase a tapped cell belongs to.
@immutable
class CellPhase {
  const CellPhase({required this.name, this.planned = false});

  /// Display name of the phase.
  final String name;

  /// The cell lies in the planned rest of the current phase.
  final bool planned;
}

/// Opens the bottom sheet describing [period], with its [moments]. With
/// [onAddMoment] a past or current period offers "Add a moment"; the sheet
/// closes and [onAddMoment] gets the day to start the new moment on. With
/// [phase] it names the life phase of the cell.
Future<void> showCellDetailSheet(
  BuildContext context, {
  required LifePeriod period,
  required List<Friend> friends,
  List<Moment> moments = const [],
  ValueChanged<DateTime>? onAddMoment,
  CellPhase? phase,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => CellDetailSheet(
      period: period,
      friends: friends,
      moments: moments,
      onAddMoment: onAddMoment,
      phase: phase,
    ),
  );
}

class CellDetailSheet extends StatelessWidget {
  const CellDetailSheet({
    super.key,
    required this.period,
    required this.friends,
    this.moments = const [],
    this.onAddMoment,
    this.phase,
  });

  final LifePeriod period;
  final List<Friend> friends;

  /// Compass moments inside [period], oldest first.
  final List<Moment> moments;

  /// Called (after the sheet closed) with the day a new moment starts on.
  final ValueChanged<DateTime>? onAddMoment;

  /// The life phase of the cell, if any.
  final CellPhase? phase;

  bool get _canAddMoment => onAddMoment != null && period.canHoldMoments;

  @override
  Widget build(BuildContext context) {
    final text = LifePeriodText(AppLocalizations.of(context));
    final theme = Theme.of(context);
    final birthdays = period.birthdaysOf(friends);
    // Full width even when the texts are short (bottom sheets are loose).
    return SafeArea(
      child: ScrollThread(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _RelationLabel(period: period, text: text.relative(period)),
                const SizedBox(height: 8),
                Text(text.title(period), style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  text.age(period),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                ?_phaseLine(text.l10n, theme),
                if (birthdays.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  for (final b in birthdays)
                    _BirthdayLine(text: text.birthday(b)),
                ],
                if (moments.isNotEmpty || _canAddMoment)
                  ..._momentSection(context, text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "In deiner Phase: Aufbauphase" below the age.
  Widget? _phaseLine(AppLocalizations l10n, ThemeData theme) {
    final phase = this.phase;
    if (phase == null) return null;
    final key = phase.planned ? 'phase_cell_planned' : 'phase_cell_in';
    return Padding(
      key: const ValueKey('cell_phase'),
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        l10n.translate(key, replacements: {'name': phase.name}),
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  /// The period's moments and, for a past or current period, the action
  /// to add one.
  List<Widget> _momentSection(BuildContext context, LifePeriodText text) {
    final addMoment = onAddMoment;
    return [
      const SizedBox(height: 20),
      const Divider(height: 1),
      const SizedBox(height: 16),
      for (final moment in moments)
        _MomentLine(moment: moment, date: text.date(moment.date)),
      if (addMoment != null && period.canHoldMoments)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            key: const ValueKey('cell_add_moment'),
            icon: const Icon(Icons.add_rounded),
            label: Text(text.l10n.translate('cell_add_moment_${period.mode.id}')),
            onPressed: () {
              Navigator.of(context).pop();
              addMoment(period.suggestedMomentDate);
            },
          ),
        ),
    ];
  }
}

class _RelationLabel extends StatelessWidget {
  const _RelationLabel({required this.period, required this.text});

  final LifePeriod period;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNow = period.relation == PeriodRelation.current;
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
        color: isNow
            ? LifePalette.of(context).accent
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _BirthdayLine extends StatelessWidget {
  const _BirthdayLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.cake_outlined, size: 20, color: LifePalette.of(context).accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _MomentLine extends StatelessWidget {
  const _MomentLine({required this.moment, required this.date});

  final Moment moment;
  final String date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(momentIcon(moment), size: 20, color: LifePalette.of(context).moment),
          const SizedBox(width: 12),
          Expanded(
            child: Text(moment.title, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(width: 12),
          Text(
            date,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
