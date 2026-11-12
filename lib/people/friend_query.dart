import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';

enum SortOption { name, age, birthday, remaining, group }

/// Date-based filters; the group filter is separate ([FriendQuery.group]).
enum DateFilter { all, today, thisWeek, thisMonth, custom }

/// Search, filter and sort settings of the People tab, applied as a pure
/// function of a friend list and "today".
class FriendQuery {
  const FriendQuery({
    this.search = '',
    this.sort = SortOption.name,
    this.ascending = true,
    this.dateFilter = DateFilter.all,
    this.customStart,
    this.customEnd,
    this.group,
    this.groupLabel = storedGroupName,
  });

  /// Default [groupLabel]: the stored group value itself.
  static String storedGroupName(String stored) => stored;

  /// Value of [group] that selects friends without a group.
  static const String ungrouped = '\u0000ungrouped';

  final String search;
  final SortOption sort;
  final bool ascending;
  final DateFilter dateFilter;
  final DateTime? customStart;
  final DateTime? customEnd;

  /// Group name to show, [ungrouped], or null for every group.
  final String? group;

  /// The shown label of a stored group value (predefined groups are ids);
  /// search and sort-by-group use it.
  final String Function(String stored) groupLabel;

  bool get isSearching => search.trim().isNotEmpty;

  bool get hasCustomRange => customStart != null && customEnd != null;

  /// [dateFilter], except that a custom range without both dates filters
  /// nothing and counts as [DateFilter.all].
  DateFilter get effectiveDateFilter =>
      dateFilter == DateFilter.custom && !hasCustomRange ? DateFilter.all : dateFilter;

  bool get isFiltered =>
      isSearching || effectiveDateFilter != DateFilter.all || group != null;

  FriendQuery copyWith({
    String? search,
    SortOption? sort,
    bool? ascending,
    DateFilter? dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
    String? group,
    bool clearGroup = false,
    String Function(String stored)? groupLabel,
  }) {
    return FriendQuery(
      search: search ?? this.search,
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
      dateFilter: dateFilter ?? this.dateFilter,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      group: clearGroup ? null : (group ?? this.group),
      groupLabel: groupLabel ?? this.groupLabel,
    );
  }

  /// Friends matching search and filters, in the chosen order. Sorting by
  /// age or remaining time puts people without a birth year last (in either
  /// direction), by name.
  List<Friend> apply(Iterable<Friend> friends, DateTime today) {
    final result = friends
        .where(_matchesSearch)
        .where(_matchesGroup)
        .where((f) => _matchesDate(f, today))
        .toList();
    result.sort((a, b) {
      final unknown = _compareUnknownLast(a, b);
      if (unknown != null) return unknown;
      final comparison = _compare(a, b, today);
      return ascending ? comparison : -comparison;
    });
    return result;
  }

  /// For the year-based sorts: the order when at least one of [a] and [b]
  /// has no birth year (they go last, among themselves by name); null when
  /// the regular comparison applies.
  int? _compareUnknownLast(Friend a, Friend b) {
    if (sort != SortOption.age && sort != SortOption.remaining) return null;
    if (a.hasBirthYear && b.hasBirthYear) return null;
    if (a.hasBirthYear) return -1;
    if (b.hasBirthYear) return 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  bool _matchesSearch(Friend friend) {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return true;
    return friend.name.toLowerCase().contains(query) ||
        (friend.notes?.toLowerCase().contains(query) ?? false) ||
        _groupLabelOf(friend).toLowerCase().contains(query);
  }

  /// The shown group label of [friend]; empty without a group.
  String _groupLabelOf(Friend friend) {
    final name = friend.groupName;
    return name == null || name.isEmpty ? '' : groupLabel(name);
  }

  bool _matchesGroup(Friend friend) {
    if (group == null) return true;
    final name = friend.groupName;
    if (group == ungrouped) return name == null || name.isEmpty;
    return name == group;
  }

  bool _matchesDate(Friend friend, DateTime today) {
    final days = daysUntilBirthday(friend, today);
    switch (effectiveDateFilter) {
      case DateFilter.all:
        return true;
      case DateFilter.today:
        return days == 0;
      // Rolling windows starting today ("Birthdays in the next 7/30 days").
      case DateFilter.thisWeek:
        return days < 7;
      case DateFilter.thisMonth:
        return days < 30;
      case DateFilter.custom:
        return _inCustomRange(today, days);
    }
  }

  bool _inCustomRange(DateTime today, int days) {
    final start = customStart;
    final end = customEnd;
    if (start == null || end == null) return true;
    final next = DateTime.utc(today.year, today.month, today.day + days);
    final from = DateTime.utc(start.year, start.month, start.day);
    final to = DateTime.utc(end.year, end.month, end.day);
    return !next.isBefore(from) && !next.isAfter(to);
  }

  int _compare(Friend a, Friend b, DateTime today) {
    switch (sort) {
      case SortOption.name:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case SortOption.age:
        return ageOf(a, today)!.compareTo(ageOf(b, today)!);
      case SortOption.birthday:
        return daysUntilBirthday(a, today)
            .compareTo(daysUntilBirthday(b, today));
      case SortOption.remaining:
        return remainingYearsOf(a, today)!
            .compareTo(remainingYearsOf(b, today)!);
      case SortOption.group:
        return _groupLabelOf(a)
            .toLowerCase()
            .compareTo(_groupLabelOf(b).toLowerCase());
    }
  }

  static int daysUntilBirthday(Friend friend, DateTime today) =>
      UpcomingBirthday.forFriend(friend, today).daysUntil;

  /// Null without a birth year.
  static int? ageOf(Friend friend, DateTime today) =>
      friend.getCurrentAge(today: today);

  /// Null without a birth year.
  static int? remainingYearsOf(Friend friend, DateTime today) {
    final age = ageOf(friend, today);
    return age == null ? null : friend.customLifespan - age;
  }
}
