import 'package:flutter/foundation.dart';

import '../birthday_candidate.dart';
import '../contacts_source.dart';
import '../import_matcher.dart';
import '../import_plan.dart';
import '../vcard_parser.dart';
import 'update_targets.dart';

/// What a source delivered: the candidates plus what the review header
/// reports about the source (limited contacts access, skipped vCards,
/// picked contacts without birthday).
class ImportFound {
  const ImportFound({
    required this.candidates,
    this.access,
    this.vcard,
    this.sourceWithoutBirthday = 0,
  });

  final List<BirthdayCandidate> candidates;
  final ContactsAccess? access;
  final VCardParseResult? vcard;

  /// Entries a non-vCard source left out for lack of a usable birthday
  /// (e.g. picked contacts).
  final int sourceWithoutBirthday;

  /// Entries left out for lack of a usable birthday: vCards without `BDAY`,
  /// else [sourceWithoutBirthday].
  int get withoutBirthday => vcard?.withoutBirthday ?? sourceWithoutBirthday;
}

/// The review list's choices: which candidates are ticked, typed years,
/// photos, group and search. New people and added years start ticked; a
/// differing date is opt-in; "already there" cannot be ticked. Updates of
/// the same saved person exclude each other: at most one is ticked.
class ImportReviewModel extends ChangeNotifier {
  ImportReviewModel(this.result)
    : _selected = {
        for (final match in result.matches)
          if (match.status == MatchStatus.newPerson ||
              match.status == MatchStatus.yearAddable)
            match.candidate.id,
      } {
    _keepOnePerTarget();
  }

  final ImportMatchResult result;
  final Set<String> _selected;
  final Map<String, int> _years = {};
  late final Map<String, String> _nameKeys = {
    for (final match in result.matches)
      match.candidate.id: personNameKey(match.candidate.displayName),
  };
  late final Map<String, String> _targets = updateTargets(result.matches);
  String _search = '';
  bool importPhotos = true;
  String groupName = '';
  bool showAlreadyThere = false;

  int get foundCount => result.matches.length;

  int get alreadyCount => result.count(MatchStatus.alreadyThere);

  int get selectedCount => _selected.length;

  bool get hasSelectable => foundCount > alreadyCount;

  /// Whether a candidate that can be imported (not "already there") has a
  /// photo: only then is "Import photos" worth offering.
  bool get hasPhotos => result.matches.any(
    (m) => m.status != MatchStatus.alreadyThere && m.candidate.hasPhoto,
  );

  bool isSelected(String candidateId) => _selected.contains(candidateId);

  int? yearFor(String candidateId) => _years[candidateId];

  /// Matches of [status] whose name contains the search text. Without
  /// anything selectable the search field is hidden, so it filters nothing.
  List<CandidateMatch> visible(MatchStatus status) {
    final query = hasSelectable ? personNameKey(_search) : '';
    return [
      for (final match in result.matches)
        if (match.status == status &&
            (query.isEmpty || _nameKeys[match.candidate.id]!.contains(query)))
          match,
    ];
  }

  set search(String value) {
    if (value == _search) return;
    _search = value;
    notifyListeners();
  }

  void toggle(CandidateMatch match) {
    if (match.status == MatchStatus.alreadyThere) return;
    final id = match.candidate.id;
    if (!_selected.remove(id)) _select(id);
    notifyListeners();
  }

  /// Ticks (or unticks) every selectable match the search shows; per saved
  /// person it keeps the update already ticked, else the first one.
  void selectAllVisible(bool selected) {
    final before = Set.of(_selected);
    for (final status in _selectableStatuses) {
      for (final match in visible(status)) {
        selected
            ? _selected.add(match.candidate.id)
            : _selected.remove(match.candidate.id);
      }
    }
    if (selected) _keepOnePerTarget(preferred: before);
    notifyListeners();
  }

  /// Ticks [candidateId] and unticks other updates of the same saved person.
  void _select(String candidateId) {
    _selected.add(candidateId);
    final target = _targets[candidateId];
    if (target == null) return;
    _selected.removeWhere((id) => id != candidateId && _targets[id] == target);
  }

  void _keepOnePerTarget({Set<String> preferred = const {}}) =>
      keepOneUpdatePerPerson(
        result.matches,
        _selected,
        _targets,
        preferred: preferred,
      );

  /// Stores a typed year (null clears it); ticks the row when set.
  void setYear(String candidateId, int? year) {
    year == null ? _years.remove(candidateId) : _years[candidateId] = year;
    if (year != null) _select(candidateId);
    notifyListeners();
  }

  void setImportPhotos(bool value) {
    importPhotos = value;
    notifyListeners();
  }

  void setGroupName(String value) {
    groupName = value;
    notifyListeners();
  }

  void toggleAlreadyThere() {
    showAlreadyThere = !showAlreadyThere;
    notifyListeners();
  }

  /// Takes over the choices of [previous] (the same source read again):
  /// ticks and typed years of the candidates still there, photos, group
  /// and search. New candidates keep their defaults.
  void carryOver(ImportReviewModel? previous) {
    if (previous == null) return;
    final known = previous._nameKeys.keys.toSet();
    for (final match in result.matches) {
      final id = match.candidate.id;
      if (!known.contains(id) || match.status == MatchStatus.alreadyThere) {
        continue;
      }
      previous.isSelected(id) ? _selected.add(id) : _selected.remove(id);
      final year = previous.yearFor(id);
      if (year != null) _years[id] = year;
    }
    _keepOnePerTarget(preferred: previous._selected);
    importPhotos = previous.importPhotos;
    groupName = previous.groupName;
    showAlreadyThere = previous.showAlreadyThere;
    _search = previous._search;
  }

  ImportSelection get selection => ImportSelection(
    candidateIds: Set.of(_selected),
    yearOverrides: Map.of(_years),
    groupName: groupName,
    importPhotos: importPhotos,
  );

  static const _selectableStatuses = [
    MatchStatus.newPerson,
    MatchStatus.dateDiffers,
    MatchStatus.yearAddable,
  ];
}
