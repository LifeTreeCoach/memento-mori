import '../friend.dart';

/// The parts of a saved person the import matcher compares against, so the
/// matcher stays independent of [Friend].
class ExistingPerson {
  const ExistingPerson({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    this.year,
    this.sourceId,
  });

  final String id;
  final String name;
  final int month;
  final int day;

  /// Null when the person is saved without a birth year.
  final int? year;

  /// Contact id / vCard UID of an earlier import, if any.
  final String? sourceId;
}

/// Adapter from a saved [Friend]: no year without [Friend.hasBirthYear],
/// the source id of an earlier import ([Friend.importSourceId]).
ExistingPerson existingPersonFromFriend(Friend friend) {
  return ExistingPerson(
    id: friend.id,
    name: friend.name,
    month: friend.birthDate.month,
    day: friend.birthDate.day,
    year: friend.hasBirthYear ? friend.birthDate.year : null,
    sourceId: friend.importSourceId,
  );
}
