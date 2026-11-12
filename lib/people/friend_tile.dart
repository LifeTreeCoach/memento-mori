import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_avatar.dart';
import 'package:memento_mori_life_in_weeks/people/group_badge.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';
import 'package:memento_mori_life_in_weeks/people/lifespan_ring.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// "turns 31 · in 12 days" / "turns 31 today 🎂"; without a birth year
/// "birthday · in 12 days" / "birthday today 🎂".
String describeNextBirthday(AppLocalizations l10n, UpcomingBirthday next) {
  final age = next.age;
  final when = switch (next.daysUntil) {
    0 => 'today',
    1 => 'tomorrow',
    _ => 'in_days',
  };
  if (age == null) {
    return l10n.translate('people_birthday_${when}_noage',
        replacements: {'n': '${next.daysUntil}'});
  }
  return l10n.plural('people_turns_$when', age,
      replacements: {'age': '$age', 'n': '${next.daysUntil}'});
}

/// One person in the People list: avatar, name and group, the next
/// birthday, the birthdays still shared, and a small lifespan ring (only
/// with a known birth year).
class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.birthday,
    required this.currentAge,
    this.birthdaysTogether,
    this.showLifespan = true,
    this.onTap,
    this.onLongPress,
    this.horizontalPadding = 20,
  });

  final UpcomingBirthday birthday;

  /// Null without a birth year: no lifespan ring then.
  final int? currentAge;

  /// Null when the user's own birth date is unknown.
  final int? birthdaysTogether;
  final bool showLifespan;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Smaller inside an inset group so content stays on the 20px gutter.
  final double horizontalPadding;

  Friend get friend => birthday.friend;

  bool get _isToday => birthday.daysUntil == 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
        child: Row(
          children: [
            FriendAvatar(friend: friend, highlight: _isToday),
            const SizedBox(width: 16),
            Expanded(child: _FriendLines(tile: this)),
            if (currentAge case final age? when showLifespan) ...[
              const SizedBox(width: 12),
              LifespanRing.ofAge(
                age: age,
                lifespanYears: friend.customLifespan,
                highlight: _isToday,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FriendLines extends StatelessWidget {
  const _FriendLines({required this.tile});

  final FriendTile tile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final together = tile.birthdaysTogether;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NameRow(friend: tile.friend),
        const SizedBox(height: 2),
        Text(
          describeNextBirthday(l10n, tile.birthday),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tile._isToday ? LifePalette.of(context).accent : muted,
            fontWeight: tile._isToday ? FontWeight.w600 : null,
          ),
        ),
        if (together != null) ...[
          const SizedBox(height: 2),
          Text(
            l10n.plural('birthdays_together', together),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: muted.withValues(alpha: 0.75)),
          ),
        ],
      ],
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final group = friend.groupName;
    return Row(
      children: [
        Flexible(
          child: Text(
            friend.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (group != null && group.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: GroupBadge(
              name: GroupNames.label(group, AppLocalizations.of(context)),
            ),
          ),
        ],
      ],
    );
  }
}
