import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/birthdays_together.dart';
import 'package:memento_mori_life_in_weeks/people/friend_avatar.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Top of the friend detail screen: avatar, name, age, next birthday and
/// the birthdays you may still share (age and shared birthdays only with a
/// known birth year).
class FriendHero extends StatelessWidget {
  const FriendHero({
    super.key,
    required this.friend,
    required this.today,
    this.userBirthDate,
    required this.userLifeExpectancyYears,
  });

  final Friend friend;
  final DateTime today;

  /// The user's birth date; null hides the "birthdays together" line.
  final DateTime? userBirthDate;
  final int userLifeExpectancyYears;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = FriendText(l10n);
    final next = UpcomingBirthday.forFriend(friend, today);
    final isToday = next.daysUntil == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FriendAvatar(friend: friend, radius: 38, highlight: isToday),
        const SizedBox(height: 16),
        Text(friend.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        if (friend.getCurrentAge(today: today) case final age?)
          _line(context, text.age(age)),
        _line(context, text.turns(next), accent: isToday),
        if (_together(l10n) case final together?) _line(context, together),
        if (_hasGroup) ...[
          const SizedBox(height: 12),
          Chip(label: Text(GroupNames.label(friend.groupName!, l10n))),
        ],
      ],
    );
  }

  bool get _hasGroup => friend.groupName?.isNotEmpty ?? false;

  String? _together(AppLocalizations l10n) {
    final birthDate = userBirthDate;
    if (birthDate == null) return null;
    final count = BirthdaysTogether.count(
      friend: friend,
      userBirthDate: birthDate,
      userLifeExpectancyYears: userLifeExpectancyYears,
      today: today,
    );
    if (count == null) return null;
    return l10n.plural('birthdays_together', count);
  }

  Widget _line(BuildContext context, String value, {bool accent = false}) {
    final theme = Theme.of(context);
    final color = accent
        ? LifePalette.of(context).accent
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: accent ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}
