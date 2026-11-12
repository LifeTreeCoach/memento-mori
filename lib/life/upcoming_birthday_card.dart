import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// The next friend birthday within a window of days.
class UpcomingBirthday {
  const UpcomingBirthday({
    required this.friend,
    required this.daysUntil,
    required this.age,
  });

  final Friend friend;
  final int daysUntil;

  /// Age the friend turns on that birthday; null without a birth year.
  final int? age;

  /// Soonest birthday among [friends] within [withinDays] of [today].
  static UpcomingBirthday? next(
    Iterable<Friend> friends,
    DateTime today, {
    int withinDays = 30,
  }) {
    final day = DateTime.utc(today.year, today.month, today.day);
    UpcomingBirthday? best;
    for (final friend in friends) {
      final candidate = forFriend(friend, day);
      if (candidate.daysUntil > withinDays) continue;
      if (best == null || candidate.daysUntil < best.daysUntil) best = candidate;
    }
    return best;
  }

  /// Every birthday on the soonest day among [friends] within [withinDays]
  /// of [today] (several friends may share it), sorted by name.
  static List<UpcomingBirthday> soonest(
    Iterable<Friend> friends,
    DateTime today, {
    int withinDays = 30,
  }) {
    final first = next(friends, today, withinDays: withinDays);
    if (first == null) return const [];
    final day = DateTime.utc(today.year, today.month, today.day);
    return [
      for (final friend in friends)
        if (forFriend(friend, day) case final b when b.daysUntil == first.daysUntil) b,
    ]..sort((a, b) => a.friend.name.toLowerCase().compareTo(b.friend.name.toLowerCase()));
  }

  /// [friend]'s next birthday on or after [today].
  static UpcomingBirthday forFriend(Friend friend, DateTime today) {
    final next = friend.getNextBirthday(today: today);
    return UpcomingBirthday(
      friend: friend,
      daysUntil: friend.getDaysUntilNextBirthday(today: today),
      age: friend.ageTurningIn(next.year),
    );
  }

  String describe(AppLocalizations l10n) {
    final age = this.age;
    final values = {
      'name': friend.name,
      'age': '$age',
      'n': '$daysUntil',
    };
    final key = switch (daysUntil) {
      0 => 'upcoming_today',
      1 => 'upcoming_tomorrow',
      _ => 'upcoming_in_days',
    };
    if (age == null) {
      return l10n.translate('${key}_noage', replacements: values);
    }
    return l10n.plural(key, age, replacements: values);
  }
}

/// "Anna turns 30 in 3 days", one line per friend when several share the
/// soonest day; tapping a line calls [onOpen] with that friend.
class UpcomingBirthdayCard extends StatelessWidget {
  const UpcomingBirthdayCard({
    super.key,
    required this.upcoming,
    required this.onOpen,
  });

  /// Non-empty; usually from [UpcomingBirthday.soonest].
  final List<UpcomingBirthday> upcoming;
  final ValueChanged<Friend> onOpen;

  /// "Today" when every birthday in [upcoming] is today, else "Upcoming".
  static String headerKey(List<UpcomingBirthday> upcoming) =>
      upcoming.every((b) => b.daysUntil == 0) ? 'upcoming_header_today' : 'upcoming';

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, birthday) in upcoming.indexed)
            _BirthdayLine(
              birthday: birthday,
              header: index == 0 ? headerKey(upcoming) : null,
              onTap: () => onOpen(birthday.friend),
            ),
        ],
      ),
    );
  }
}

/// One tappable line; the first carries the cake icon and the [header].
class _BirthdayLine extends StatelessWidget {
  const _BirthdayLine({
    required this.birthday,
    required this.header,
    required this.onTap,
  });

  final UpcomingBirthday birthday;

  /// Localization key of the card header; null for all but the first line.
  final String? header;
  final VoidCallback onTap;

  bool get isFirst => header != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final description = Text(
      birthday.describe(l10n),
      style: theme.textTheme.bodyLarge,
    );
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(20, isFirst ? 8 : 0, 12, 8),
      leading: isFirst
          ? Icon(Icons.cake_outlined, color: LifePalette.of(context).accent)
          : const SizedBox(width: 24),
      title: isFirst
          ? Text(
              l10n.translate(header!).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.8,
              ),
            )
          : description,
      subtitle: isFirst
          ? Padding(padding: const EdgeInsets.only(top: 4), child: description)
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
