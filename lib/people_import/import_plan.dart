/// Turns the user's choice in the import review into new people and updates
/// of saved ones. Plain values: converting them to friends happens when the
/// batch is saved.
library;

import 'birthday_candidate.dart';
import 'birthday_text_parser.dart';
import '../people/group_names.dart';
import 'import_matcher.dart';

/// What the user picked in the review list.
class ImportSelection {
  const ImportSelection({
    required this.candidateIds,
    this.yearOverrides = const {},
    this.groupName,
    this.importPhotos = true,
  });

  final Set<String> candidateIds;

  /// Years typed in for candidates (by candidate id), mostly for those
  /// without one.
  final Map<String, int> yearOverrides;

  /// Group given to every new person (blank = none).
  final String? groupName;
  final bool importPhotos;
}

/// A person to add.
class PlannedFriend {
  const PlannedFriend({
    required this.candidateId,
    required this.name,
    required this.month,
    required this.day,
    this.year,
    required this.source,
    this.sourceId,
    this.photo,
    this.groupName,
  });

  final String candidateId;
  final String name;
  final int month;
  final int day;
  final int? year;
  final ImportSource source;
  final String? sourceId;
  final CandidatePhoto? photo;
  final String? groupName;
}

/// A new birthday for a saved person, with the old one for undo.
class PlannedUpdate {
  const PlannedUpdate({
    required this.candidateId,
    required this.friendId,
    required this.month,
    required this.day,
    this.year,
    required this.previous,
  });

  final String candidateId;
  final String friendId;
  final int month;
  final int day;
  final int? year;
  final BirthdayDate previous;
}

/// Everything one import will save, in a single batch.
class ImportPlan {
  const ImportPlan({required this.newFriends, required this.updates});

  final List<PlannedFriend> newFriends;
  final List<PlannedUpdate> updates;

  int get changeCount => newFriends.length + updates.length;

  bool get isEmpty => changeCount == 0;
}

/// Builds the plan for the selected [matches]: new people are added, a
/// differing date or a missing year is updated, "already there" is skipped.
/// A year override that makes no valid date (e.g. 29 Feb in a common year)
/// is ignored. Each saved person gets at most one update (the first).
ImportPlan buildImportPlan(
  List<CandidateMatch> matches,
  ImportSelection selection, {
  DateTime? today,
}) {
  final newFriends = <PlannedFriend>[];
  final updates = <PlannedUpdate>[];
  final group = _groupOrNull(selection.groupName);
  for (final match in matches) {
    if (!selection.candidateIds.contains(match.candidate.id)) continue;
    final year = _chosenYear(match.candidate, selection, today);
    switch (match.status) {
      case MatchStatus.newPerson:
        newFriends.add(
          _plannedFriend(match.candidate, year, group, selection.importPhotos),
        );
      case MatchStatus.dateDiffers || MatchStatus.yearAddable:
        final update = _plannedUpdate(match, year, today);
        if (update != null && !_updatesFriend(updates, update.friendId)) {
          updates.add(update);
        }
      case MatchStatus.alreadyThere:
        break;
    }
  }
  return ImportPlan(newFriends: newFriends, updates: updates);
}

bool _updatesFriend(List<PlannedUpdate> updates, String friendId) =>
    updates.any((update) => update.friendId == friendId);

/// The group to store: trimmed, null when empty, a predefined group's
/// label (any language) as its id.
String? _groupOrNull(String? group) => GroupNames.normalize(group);

/// The override when it gives a valid birthday, else the candidate's year.
int? _chosenYear(
  BirthdayCandidate candidate,
  ImportSelection selection,
  DateTime? today,
) {
  final override = selection.yearOverrides[candidate.id];
  if (override == null) return candidate.year;
  final valid = birthdayFromParts(
    year: override,
    month: candidate.month,
    day: candidate.day,
    today: today,
  );
  return valid?.year ?? candidate.year;
}

PlannedFriend _plannedFriend(
  BirthdayCandidate candidate,
  int? year,
  String? group,
  bool importPhotos,
) {
  return PlannedFriend(
    candidateId: candidate.id,
    name: candidate.displayName,
    month: candidate.month,
    day: candidate.day,
    year: year,
    source: candidate.source,
    sourceId: candidate.sourceId,
    photo: importPhotos ? candidate.photo : null,
    groupName: group,
  );
}

/// The candidate's day/month with its year, or the saved year when the
/// candidate has none and that year still gives a valid date.
PlannedUpdate? _plannedUpdate(
  CandidateMatch match,
  int? year,
  DateTime? today,
) {
  final person = match.existing;
  if (person == null) return null;
  final candidate = match.candidate;
  final keptYear = birthdayFromParts(
    year: year ?? person.year,
    month: candidate.month,
    day: candidate.day,
    today: today,
  )?.year;
  return PlannedUpdate(
    candidateId: candidate.id,
    friendId: person.id,
    month: candidate.month,
    day: candidate.day,
    year: year ?? keptYear,
    previous: BirthdayDate(
      month: person.month,
      day: person.day,
      year: person.year,
    ),
  );
}
