import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/people_view.dart';

Friend _friend(String name, {String? group, int month = 3}) => Friend(
      id: name,
      name: name,
      birthDate: DateTime(1980, month, 1),
      groupName: group,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    );

void main() {
  final today = DateTime(2026, 11, 2, 9);
  final friends = [
    _friend('Cleo', group: 'family'),
    _friend('Anna', group: 'Work'),
    _friend('Ben', month: 11),
  ];
  const query = FriendQuery();

  test('computes visible people, sections and groups', () {
    final view = PeopleView.compute(friends, query, today);
    expect(view.visible, hasLength(3));
    expect(view.sections.everyone, hasLength(3));
    expect(view.groups, ['family', 'Work']);
    expect(view.hasUngrouped, isTrue);
  });

  test('reuses the view for the same friends, query and day', () {
    final view = PeopleView.compute(friends, query, today);
    final later = today.add(const Duration(hours: 5));
    expect(PeopleView.reuseOrCompute(view, friends, query, later),
        same(view));
  });

  test('recomputes when friends, query or day change', () {
    final view = PeopleView.compute(friends, query, today);
    expect(PeopleView.reuseOrCompute(view, [...friends], query, today),
        isNot(same(view)));
    expect(
        PeopleView.reuseOrCompute(
            view, friends, query.copyWith(search: 'an'), today),
        isNot(same(view)));
    final tomorrow = today.add(const Duration(days: 1));
    expect(PeopleView.reuseOrCompute(view, friends, query, tomorrow),
        isNot(same(view)));
    expect(PeopleView.reuseOrCompute(null, friends, query, today).visible,
        hasLength(3));
  });

  test('groupsOf ignores empty names and sorts case-insensitively', () {
    expect(
        PeopleView.groupsOf([
          _friend('A', group: 'b'),
          _friend('B', group: ''),
          _friend('C', group: 'A'),
          _friend('D', group: 'b'),
        ]),
        ['A', 'b']);
  });
}
