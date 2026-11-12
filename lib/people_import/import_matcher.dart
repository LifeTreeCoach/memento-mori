/// Compares import candidates with the people already saved and merges
/// duplicates within one import. Linear: every lookup goes through a map.
library;

import '../text/fold.dart';
import 'birthday_candidate.dart';
import 'existing_person.dart';

/// How a candidate relates to the saved people.
enum MatchStatus {
  /// Nobody with this name (or source id) is saved yet.
  newPerson,

  /// Saved with the same name and day/month, or from the same source entry.
  alreadyThere,

  /// Same person, but day/month (or a known year) differ; updating is offered.
  dateDiffers,

  /// Same name and day/month; the saved person has no year, the candidate has.
  yearAddable,
}

/// A candidate with its [status] and, unless new, the saved person it
/// matched.
class CandidateMatch {
  const CandidateMatch({
    required this.candidate,
    required this.status,
    this.existing,
  });

  final BirthdayCandidate candidate;
  final MatchStatus status;
  final ExistingPerson? existing;
}

/// Result of [matchCandidates], in the order the candidates came in.
class ImportMatchResult {
  const ImportMatchResult({required this.matches, required this.mergedCount});

  final List<CandidateMatch> matches;

  /// Candidates folded into another one by the in-batch dedupe.
  final int mergedCount;

  List<CandidateMatch> withStatus(MatchStatus status) =>
      matches.where((match) => match.status == status).toList();

  int count(MatchStatus status) =>
      matches.where((match) => match.status == status).length;
}

/// Key under which two names count as the same person: case, accents and
/// spacing are ignored ("Jörg  Müller" == "jorg muller").
String personNameKey(String name) =>
    foldText(name).replaceAll(RegExp(r'\s+'), ' ').trim();

String _nameDateKey(String name, int month, int day) =>
    '${personNameKey(name)}|$month-$day';

/// Dedupes [candidates], then classifies each against [existing].
ImportMatchResult matchCandidates(
  List<BirthdayCandidate> candidates,
  List<ExistingPerson> existing,
) {
  final unique = dedupeCandidates(candidates);
  final index = _ExistingIndex(existing);
  return ImportMatchResult(
    matches: [for (final candidate in unique) index.match(candidate)],
    mergedCount: candidates.length - unique.length,
  );
}

/// Merges candidates with the same source id or the same name and
/// day/month. The more complete one (year, then photo) wins and takes over
/// the year, photo and source id the other one has. Keeps first-seen order.
List<BirthdayCandidate> dedupeCandidates(List<BirthdayCandidate> candidates) {
  final merged = <BirthdayCandidate>[];
  final slotByKey = <String, int>{};
  for (final candidate in candidates) {
    final keys = _dedupeKeys(candidate);
    final slot = keys.map((key) => slotByKey[key]).nonNulls.firstOrNull;
    if (slot == null) {
      merged.add(candidate);
    } else {
      merged[slot] = _mergeCandidates(merged[slot], candidate);
    }
    final target = slot ?? merged.length - 1;
    for (final key in _dedupeKeys(merged[target])) {
      slotByKey[key] = target;
    }
  }
  return merged;
}

List<String> _dedupeKeys(BirthdayCandidate candidate) => [
  if (_hasText(candidate.sourceId)) 'id:${candidate.sourceId}',
  'name:${_nameDateKey(candidate.displayName, candidate.month, candidate.day)}',
];

BirthdayCandidate _mergeCandidates(BirthdayCandidate a, BirthdayCandidate b) {
  final (winner, loser) = _completeness(b) > _completeness(a) ? (b, a) : (a, b);
  return winner.copyWith(
    year: winner.year ?? loser.year,
    photo: winner.photo ?? loser.photo,
    sourceId: _hasText(winner.sourceId) ? winner.sourceId : loser.sourceId,
  );
}

int _completeness(BirthdayCandidate candidate) =>
    (candidate.hasYear ? 2 : 0) + (candidate.hasPhoto ? 1 : 0);

bool _hasText(String? value) => value != null && value.isNotEmpty;

/// The saved people, indexed by source id, name + day/month and name.
class _ExistingIndex {
  _ExistingIndex(List<ExistingPerson> people) {
    for (final person in people) {
      if (_hasText(person.sourceId)) {
        _bySourceId.putIfAbsent(person.sourceId!, () => person);
      }
      _byNameDate.putIfAbsent(
        _nameDateKey(person.name, person.month, person.day),
        () => person,
      );
      _byName.putIfAbsent(personNameKey(person.name), () => person);
    }
  }

  final _bySourceId = <String, ExistingPerson>{};
  final _byNameDate = <String, ExistingPerson>{};
  final _byName = <String, ExistingPerson>{};

  CandidateMatch match(BirthdayCandidate candidate) {
    final person =
        (_hasText(candidate.sourceId)
            ? _bySourceId[candidate.sourceId]
            : null) ??
        _byNameDate[_nameDateKey(
          candidate.displayName,
          candidate.month,
          candidate.day,
        )] ??
        _byName[personNameKey(candidate.displayName)];
    if (person == null) {
      return CandidateMatch(
        candidate: candidate,
        status: MatchStatus.newPerson,
      );
    }
    return CandidateMatch(
      candidate: candidate,
      status: _statusAgainst(candidate, person),
      existing: person,
    );
  }
}

MatchStatus _statusAgainst(BirthdayCandidate candidate, ExistingPerson person) {
  final sameDay =
      candidate.month == person.month && candidate.day == person.day;
  if (!sameDay) return MatchStatus.dateDiffers;
  if (person.year == null) {
    return candidate.hasYear
        ? MatchStatus.yearAddable
        : MatchStatus.alreadyThere;
  }
  final yearsConflict = candidate.hasYear && candidate.year != person.year;
  return yearsConflict ? MatchStatus.dateDiffers : MatchStatus.alreadyThere;
}
