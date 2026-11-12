import 'package:memento_mori_life_in_weeks/people/people_sections.dart';

/// The one row the People tour points at: the topmost person of the list
/// (Today, else Next 30 days, else Everyone). A friend can show in two
/// sections, so the section is part of it.
typedef TourPersonRow = ({String section, String friendId});

/// The [TourPersonRow] of [sections]; null without anyone.
TourPersonRow? tourPersonRowOf(PeopleSections sections) {
  for (final (section, birthdays) in [
    ('today', sections.today),
    ('upcoming', sections.upcoming),
    ('everyone', sections.everyone),
  ]) {
    if (birthdays.isNotEmpty) {
      return (section: section, friendId: birthdays.first.friend.id);
    }
  }
  return null;
}
