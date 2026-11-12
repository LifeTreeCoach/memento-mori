import '../import_matcher.dart';

/// Candidate id -> id of the saved person its update would change, for
/// every "date differs" / "year addable" match.
Map<String, String> updateTargets(List<CandidateMatch> matches) => {
  for (final match in matches)
    if (match.existing != null &&
        (match.status == MatchStatus.dateDiffers ||
            match.status == MatchStatus.yearAddable))
      match.candidate.id: match.existing!.id,
};

/// Unticks updates in [selected] (in place) until each saved person is
/// changed by at most one: a [preferred] candidate wins, else the first in
/// [matches] order.
void keepOneUpdatePerPerson(
  List<CandidateMatch> matches,
  Set<String> selected,
  Map<String, String> targets, {
  Set<String> preferred = const {},
}) {
  final kept = <String, String>{};
  for (final match in matches) {
    final id = match.candidate.id;
    final target = targets[id];
    if (target == null || !selected.contains(id)) continue;
    final current = kept[target];
    if (current == null) {
      kept[target] = id;
    } else if (preferred.contains(id) && !preferred.contains(current)) {
      selected.remove(current);
      kept[target] = id;
    } else {
      selected.remove(id);
    }
  }
}
