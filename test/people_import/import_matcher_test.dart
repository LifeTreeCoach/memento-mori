import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people_import/existing_person.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_matcher.dart';

import 'import_test_helpers.dart';

void main() {
  final saved = [
    person('f1', 'Jörg Müller', 7, 21, year: 1985),
    person('f2', 'Anna Schmidt', 5, 13),
    person('f3', 'Ben', 1, 2, year: 1990, sourceId: 'contact-42'),
  ];
  MatchStatus statusOf(ImportMatchResult result, String id) =>
      result.matches.singleWhere((m) => m.candidate.id == id).status;

  test('classifies every status', () {
    final result = matchCandidates([
      candidate('new', 'Clara', 3, 4, year: 1980),
      candidate('there', 'Jorg Muller', 7, 21, year: 1985),
      candidate('there-no-year', 'jörg müller', 7, 21),
      candidate('moved', 'Jörg Müller', 8, 1, year: 1985),
      candidate('year', 'Anna  Schmidt', 5, 13, year: 1988),
      candidate('anna-no-year', 'ANNA SCHMIDT', 5, 13),
    ], saved);
    expect(statusOf(result, 'new'), MatchStatus.newPerson);
    expect(statusOf(result, 'there'), MatchStatus.alreadyThere);
    expect(statusOf(result, 'moved'), MatchStatus.dateDiffers);
    expect(statusOf(result, 'year'), MatchStatus.yearAddable);
    expect(
      result.matches.where((m) => m.candidate.id == 'there-no-year'),
      isEmpty,
      reason: 'merged into "there" (same folded name + day)',
    );
    expect(
      result.matches.where((m) => m.candidate.id == 'anna-no-year'),
      isEmpty,
    );
    expect(result.mergedCount, 2);
    final moved = result.matches.singleWhere((m) => m.candidate.id == 'moved');
    expect(moved.existing!.id, 'f1');
    expect(result.count(MatchStatus.newPerson), 1);
    expect(
      result.withStatus(MatchStatus.yearAddable).single.existing!.id,
      'f2',
    );
  });

  test('same source id is the same person even under another name', () {
    final result = matchCandidates([
      candidate(
        'renamed',
        'Benjamin',
        1,
        2,
        year: 1990,
        sourceId: 'contact-42',
      ),
      candidate('corrected', 'Ben B.', 1, 3, sourceId: 'contact-42x'),
    ], saved);
    expect(statusOf(result, 'renamed'), MatchStatus.alreadyThere);
    expect(result.matches.first.existing!.id, 'f3');
    expect(statusOf(result, 'corrected'), MatchStatus.newPerson);
  });

  test('a differing known year counts as a differing date', () {
    final result = matchCandidates([
      candidate('c', 'Jörg Müller', 7, 21, year: 1986),
    ], saved);
    expect(statusOf(result, 'c'), MatchStatus.dateDiffers);
  });

  test('name match prefers the saved person with the same day', () {
    final result = matchCandidates(
      [candidate('c', 'Kim', 9, 9)],
      [
        person('a', 'Kim', 1, 1, year: 1990),
        person('b', 'Kim', 9, 9, year: 1991),
      ],
    );
    expect(result.matches.single.status, MatchStatus.alreadyThere);
    expect(result.matches.single.existing!.id, 'b');
  });

  group('in-batch dedupe', () {
    test('merges by source id and keeps the complete entry', () {
      final merged = dedupeCandidates([
        candidate('a', 'Zoë', 4, 15, sourceId: 'uid-1'),
        candidate('b', 'Zoe Fischer', 4, 15, year: 1996, sourceId: 'uid-1'),
      ]);
      expect(merged.single.id, 'b');
      expect(merged.single.year, 1996);
    });

    test('merges by folded name + day and fills gaps from the other', () {
      final merged = dedupeCandidates([
        candidate('a', 'Zoë Fischer', 4, 15, photo: true),
        candidate('b', 'zoe fischer', 4, 15, year: 1996, sourceId: 'uid-9'),
        candidate('c', 'Zoe Fischer', 4, 16),
      ]);
      expect(merged.map((c) => c.id), ['b', 'c']);
      expect(merged.first.hasPhoto, isTrue);
      expect(merged.first.sourceId, 'uid-9');
    });

    test('a photo breaks the tie only when there is one', () {
      final withPhoto = dedupeCandidates([
        candidate('a', 'Zoe', 4, 15),
        candidate('b', 'Zoe', 4, 15, photo: true),
      ]);
      expect(withPhoto.single.id, 'b');

      final neither = dedupeCandidates([
        candidate('a', 'Zoe', 4, 15),
        candidate('b', 'Zoe', 4, 15),
      ]);
      expect(neither.single.id, 'a');
      expect(neither.single.hasPhoto, isFalse);
    });

    test('chains: a later name match finds a merged source id', () {
      final merged = dedupeCandidates([
        candidate('a', 'Max', 12, 24, sourceId: 'u1'),
        candidate('b', 'Maximilian', 12, 24, sourceId: 'u1', year: 1970),
        candidate('c', 'Maximilian', 12, 24, photo: true),
      ]);
      expect(merged, hasLength(1));
      expect(merged.single.year, 1970);
      expect(merged.single.hasPhoto, isTrue);
    });

    test('scales linearly (10k candidates vs 10k people)', () {
      final many = [
        for (var i = 0; i < 10000; i++)
          candidate('c$i', 'Person $i', 1 + i % 12, 1 + i % 28),
      ];
      final people = [
        for (var i = 0; i < 10000; i += 2)
          person('p$i', 'Person $i', 1 + i % 12, 1 + i % 28),
      ];
      final watch = Stopwatch()..start();
      final result = matchCandidates(many, people);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(result.count(MatchStatus.alreadyThere), 5000);
      expect(result.count(MatchStatus.newPerson), 5000);
    });
  });

  test('existingPersonFromFriend maps id, name and date', () {
    final now = DateTime(2026);
    final view = existingPersonFromFriend(
      Friend(
        id: 'x',
        name: 'Lea',
        birthDate: DateTime(2001, 3, 1),
        createdDate: now,
        lastUpdated: now,
      ),
    );
    expect(
      (view.id, view.name, view.year, view.month, view.day, view.sourceId),
      ('x', 'Lea', 2001, 3, 1, null),
    );
  });

  test('personNameKey folds case, accents and spacing', () {
    expect(personNameKey('  Jörg   Müller '), personNameKey('jorg muller'));
    expect(personNameKey('Straße'), 'strasse');
  });
}
