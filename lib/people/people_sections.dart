import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';

/// The People tab's sections: birthdays today, birthdays in the next
/// [upcomingDays] days (soonest first), and everyone in the given order.
///
/// "Everyone" is the full directory, so a friend with a birthday today
/// appears both under "Today" and in "Everyone".
class PeopleSections {
  const PeopleSections._({
    required this.today,
    required this.upcoming,
    required this.everyone,
  });

  static const int upcomingDays = 30;

  /// Splits [friends] (already filtered and sorted) relative to [today].
  factory PeopleSections.of(List<Friend> friends, DateTime today) {
    final birthdays = [
      for (final friend in friends) UpcomingBirthday.forFriend(friend, today),
    ];
    final upcoming = birthdays
        .where((b) => b.daysUntil > 0 && b.daysUntil <= upcomingDays)
        .toList()
      ..sort((a, b) {
        final byDays = a.daysUntil.compareTo(b.daysUntil);
        return byDays != 0 ? byDays : a.friend.name.compareTo(b.friend.name);
      });
    return PeopleSections._(
      today: birthdays.where((b) => b.daysUntil == 0).toList(),
      upcoming: upcoming,
      everyone: birthdays,
    );
  }

  final List<UpcomingBirthday> today;
  final List<UpcomingBirthday> upcoming;

  /// Every friend with their next birthday, in the input order.
  final List<UpcomingBirthday> everyone;

  int get todayCount => today.length;

  /// Birthdays within the window including today.
  int get soonCount => todayCount + upcoming.length;
}
