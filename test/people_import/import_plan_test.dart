import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_text_parser.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_matcher.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_plan.dart';

import 'import_test_helpers.dart';

void main() {
  final today = DateTime(2026, 11, 7);
  final matches = matchCandidates(
    [
      candidate('new', 'Clara', 3, 4, year: 1980, sourceId: 's1', photo: true),
      candidate('new-no-year', 'Dora', 2, 29, source: ImportSource.vcard),
      candidate('there', 'Anna', 5, 13, year: 1988),
      candidate('moved', 'Jörg', 8, 1),
      candidate('year', 'Ben', 1, 2, year: 1990),
    ],
    [
      person('f-anna', 'Anna', 5, 13, year: 1988),
      person('f-jorg', 'Jorg', 7, 21, year: 1985),
      person('f-ben', 'Ben', 1, 2),
    ],
  ).matches;
  final everything = {'new', 'new-no-year', 'there', 'moved', 'year'};
  ImportPlan plan(ImportSelection selection) =>
      buildImportPlan(matches, selection, today: today);

  test('selected new people become PlannedFriends, others updates', () {
    final result = plan(ImportSelection(candidateIds: everything));
    expect(result.newFriends.map((f) => f.candidateId), ['new', 'new-no-year']);
    final clara = result.newFriends.first;
    expect(
      (clara.name, clara.month, clara.day, clara.year),
      ('Clara', 3, 4, 1980),
    );
    expect((clara.source, clara.sourceId), (ImportSource.contacts, 's1'));
    expect(clara.photo, isNotNull);
    expect(clara.groupName, isNull);
    expect(result.newFriends.last.year, isNull);
    expect(result.updates.map((u) => u.friendId), ['f-jorg', 'f-ben']);
    expect(result.changeCount, 4);
  });

  test('date update keeps the saved year when the candidate has none', () {
    final update = plan(ImportSelection(candidateIds: {'moved'}))
        .updates
        .single;
    expect((update.month, update.day, update.year), (8, 1, 1985));
    expect(update.previous, const BirthdayDate(month: 7, day: 21, year: 1985));
  });

  test('year update adds the candidate year', () {
    final update = plan(ImportSelection(candidateIds: {'year'})).updates.single;
    expect(
      (update.friendId, update.month, update.day, update.year),
      ('f-ben', 1, 2, 1990),
    );
    expect(update.previous.year, isNull);
  });

  test('unselected and already-there candidates are skipped', () {
    expect(
      plan(const ImportSelection(candidateIds: {'there'})).isEmpty,
      isTrue,
    );
    expect(plan(const ImportSelection(candidateIds: {})).isEmpty, isTrue);
  });

  test('year overrides apply when valid, invalid ones are ignored', () {
    final valid = plan(
      ImportSelection(
        candidateIds: {'new-no-year', 'moved'},
        yearOverrides: {'new-no-year': 1992, 'moved': 1984},
      ),
    );
    expect(valid.newFriends.single.year, 1992);
    expect(valid.updates.single.year, 1984);
    final invalid = plan(
      ImportSelection(
        candidateIds: {'new-no-year'},
        yearOverrides: {'new-no-year': 1993},
      ),
    );
    expect(
      invalid.newFriends.single.year,
      isNull,
      reason: '1993 has no 29 Feb',
    );
    final future = plan(
      ImportSelection(candidateIds: {'new'}, yearOverrides: {'new': 2030}),
    );
    expect(future.newFriends.single.year, 1980);
  });

  test('group and photo choice apply to new people', () {
    final result = plan(
      ImportSelection(
        candidateIds: everything,
        groupName: '  Family ',
        importPhotos: false,
      ),
    );
    // A predefined group's label is stored as its id.
    expect(result.newFriends.every((f) => f.groupName == '@family'), isTrue);
    expect(result.newFriends.every((f) => f.photo == null), isTrue);
    final blank = plan(ImportSelection(candidateIds: {'new'}, groupName: '  '));
    expect(blank.newFriends.single.groupName, isNull);
    final custom =
        plan(ImportSelection(candidateIds: {'new'}, groupName: ' Chor '));
    expect(custom.newFriends.single.groupName, 'Chor');
  });

  test('a saved person gets at most one update', () {
    final rivals = matchCandidates(
      [
        candidate('m1', 'Max', 4, 4, year: 1970),
        candidate('m2', 'Max', 6, 6, year: 1971),
      ],
      [person('f-max', 'Max', 1, 2, year: 1970)],
    ).matches;
    final result = buildImportPlan(
      rivals,
      ImportSelection(candidateIds: {'m1', 'm2'}),
      today: today,
    );
    expect(result.updates.single.candidateId, 'm1');
  });
}
