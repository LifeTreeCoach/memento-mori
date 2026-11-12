import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/people_sections.dart';

/// What the People tab shows for one friend list, query and day: the
/// filtered people, their sections and the group chips.
///
/// Computing it is linear in the number of friends (plus sorting), so the
/// tab keeps one and only recomputes it via [PeopleView.reuseOrCompute]
/// when an input changes, not on every rebuild (scrolling, FAB, ...).
@immutable
class PeopleView {
  const PeopleView._({
    required this.friends,
    required this.query,
    required this.day,
    required this.visible,
    required this.sections,
    required this.groups,
    required this.hasUngrouped,
  });

  /// Computes the view of [friends] for [query] on the day of [today].
  factory PeopleView.compute(
      List<Friend> friends, FriendQuery query, DateTime today) {
    final visible = query.apply(friends, today);
    return PeopleView._(
      friends: friends,
      query: query,
      day: _dayOf(today),
      visible: visible,
      sections: PeopleSections.of(visible, today),
      groups: groupsOf(friends, query.groupLabel),
      hasUngrouped: friends.any((f) => !_hasGroup(f)),
    );
  }

  /// [previous] when it was computed from the same list instance, query
  /// instance and day; otherwise a fresh view.
  static PeopleView reuseOrCompute(PeopleView? previous, List<Friend> friends,
      FriendQuery query, DateTime today) {
    if (previous != null && previous._matches(friends, query, today)) {
      return previous;
    }
    return PeopleView.compute(friends, query, today);
  }

  final List<Friend> friends;
  final FriendQuery query;
  final DateTime day;
  final List<Friend> visible;
  final PeopleSections sections;

  /// Stored group values, sorted case-insensitively by label.
  final List<String> groups;

  /// Whether anyone has no group.
  final bool hasUngrouped;

  /// Distinct non-empty stored group values of [friends], sorted
  /// case-insensitively by their [labelOf] (default: the value itself).
  static List<String> groupsOf(Iterable<Friend> friends,
          [String Function(String) labelOf = FriendQuery.storedGroupName]) =>
      {
        for (final f in friends)
          if (_hasGroup(f)) f.groupName!,
      }.toList()
        ..sort((a, b) =>
            labelOf(a).toLowerCase().compareTo(labelOf(b).toLowerCase()));

  bool _matches(List<Friend> friends, FriendQuery query, DateTime today) =>
      identical(this.friends, friends) &&
      identical(this.query, query) &&
      day == _dayOf(today);

  static bool _hasGroup(Friend f) =>
      f.groupName != null && f.groupName!.isNotEmpty;

  static DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);
}
