import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_matcher.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_plan.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_model.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/update_targets.dart';

import '../import_test_helpers.dart';

void main() {
  ImportReviewModel model() => ImportReviewModel(
    matchCandidates(
      [
        candidate('a', 'Anna', 5, 1, year: 1990, photo: true),
        candidate('e', 'Emil', 2, 14),
        candidate('b', 'Ben', 3, 1, year: 1980),
        candidate('c', 'Cleo', 8, 8, year: 1995),
      ],
      [
        person('pb', 'Ben', 3, 1, year: 1980),
        person('pc', 'Cleo', 7, 7, year: 1995),
      ],
    ),
  );

  test('new people start ticked, a differing date is opt-in', () {
    final review = model();
    expect(review.selectedCount, 2);
    expect(review.isSelected('c'), isFalse);
    expect(review.alreadyCount, 1);
    expect(review.hasPhotos, isTrue);
  });

  test('hasPhotos only when a candidate has a photo', () {
    final review = ImportReviewModel(
      matchCandidates([
        candidate('e', 'Emil', 2, 14),
        candidate('f', 'Finn', 4, 4, year: 1990),
      ], const []),
    );
    expect(review.hasPhotos, isFalse);
  });

  test('hasPhotos ignores photos of people already there', () {
    final review = ImportReviewModel(
      matchCandidates(
        [
          candidate('b', 'Ben', 3, 1, year: 1980, photo: true),
          candidate('e', 'Emil', 2, 14),
        ],
        [person('pb', 'Ben', 3, 1, year: 1980)],
      ),
    );
    expect(review.hasPhotos, isFalse);
  });

  test('hasPhotos counts a differing date or an addable year', () {
    final review = ImportReviewModel(
      matchCandidates(
        [
          candidate('c', 'Cleo', 8, 8, year: 1995, photo: true),
          candidate('d', 'Dora', 9, 9, year: 1970, photo: true),
        ],
        [
          person('pc', 'Cleo', 7, 7, year: 1995),
          person('pd', 'Dora', 9, 9),
        ],
      ),
    );
    expect(review.visible(MatchStatus.dateDiffers), hasLength(1));
    expect(review.hasPhotos, isTrue);
  });

  test('already there cannot be ticked', () {
    final review = model();
    review.toggle(review.visible(MatchStatus.alreadyThere).single);
    expect(review.isSelected('b'), isFalse);
  });

  test('select all / none only touch what the search shows', () {
    final review = model()..search = 'cle';
    review.selectAllVisible(true);
    expect(review.selectedCount, 3);
    review.search = '';
    review.selectAllVisible(false);
    expect(review.selectedCount, 0);
  });

  test('selection carries years, group and the photo choice', () {
    final review = model()
      ..setYear('e', 1988)
      ..setGroupName(' Family ')
      ..setImportPhotos(false);
    final plan = buildImportPlan(review.result.matches, review.selection);

    final emil = plan.newFriends.firstWhere((p) => p.name == 'Emil');
    expect(emil.year, 1988);
    expect(emil.groupName, '@family'); // predefined group id
    expect(plan.newFriends.every((p) => p.photo == null), isTrue);
  });

  group('updates of the same saved person', () {
    // Two "Max Muster" contacts with different dates, one saved Max.
    ImportReviewModel rivals() => ImportReviewModel(
      matchCandidates(
        [
          candidate('m1', 'Max Muster', 4, 4, year: 1970),
          candidate('m2', 'Max Muster', 6, 6, year: 1971),
          candidate('n', 'Nora', 1, 1),
        ],
        [person('pm', 'Max Muster', 1, 2, year: 1970)],
      ),
    );

    test('both are "date differs" for the same person', () {
      final review = rivals();
      final differs = review.visible(MatchStatus.dateDiffers);
      expect(differs.map((m) => m.existing!.id), ['pm', 'pm']);
    });

    test('ticking one unticks the other', () {
      final review = rivals();
      final differs = review.visible(MatchStatus.dateDiffers);
      review.toggle(differs[0]);
      expect(review.isSelected('m1'), isTrue);
      review.toggle(differs[1]);
      expect(review.isSelected('m2'), isTrue);
      expect(review.isSelected('m1'), isFalse);
      expect(review.isSelected('n'), isTrue);
    });

    test('select all ticks the first one per person', () {
      final review = rivals()..selectAllVisible(true);
      expect(review.isSelected('m1'), isTrue);
      expect(review.isSelected('m2'), isFalse);
      expect(review.selectedCount, 2);
    });

    test('select all keeps the update already ticked', () {
      final review = rivals();
      review.toggle(review.visible(MatchStatus.dateDiffers)[1]);
      review.selectAllVisible(true);
      expect(review.isSelected('m2'), isTrue);
      expect(review.isSelected('m1'), isFalse);
    });

    test('the plan changes the saved person only once', () {
      final review = rivals()..selectAllVisible(true);
      final plan = buildImportPlan(review.result.matches, review.selection);
      expect(plan.updates.single.candidateId, 'm1');
    });
  });

  group('updateTargets / keepOneUpdatePerPerson', () {
    final matches = matchCandidates(
      [
        candidate('x1', 'Xia', 4, 4, year: 1970),
        candidate('x2', 'Xia', 6, 6, year: 1971),
        candidate('y', 'Yan', 3, 3, year: 1990),
      ],
      [person('px', 'Xia', 1, 2, year: 1970), person('py', 'Yan', 3, 3)],
    ).matches;

    test('maps updates to the saved person', () {
      expect(updateTargets(matches), {'x1': 'px', 'x2': 'px', 'y': 'py'});
    });

    test('keeps the preferred one, else the first', () {
      final targets = updateTargets(matches);
      final first = {'x1', 'x2', 'y'};
      keepOneUpdatePerPerson(matches, first, targets);
      expect(first, {'x1', 'y'});
      final preferred = {'x1', 'x2'};
      keepOneUpdatePerPerson(matches, preferred, targets, preferred: {'x2'});
      expect(preferred, {'x2'});
    });
  });

  test('a typed year ticks the row and unticks its rivals', () {
    final review = ImportReviewModel(
      matchCandidates(
        [
          candidate('z1', 'Zoe', 4, 4, year: 1970),
          candidate('z2', 'Zoe', 6, 6),
        ],
        [person('pz', 'Zoe', 1, 2, year: 1970)],
      ),
    );
    review.toggle(review.visible(MatchStatus.dateDiffers).first);
    review.setYear('z2', 1980);
    expect(review.isSelected('z2'), isTrue);
    expect(review.isSelected('z1'), isFalse);
  });

  group('carryOver', () {
    test('keeps ticks, years and options of candidates still there', () {
      final before = model()
        ..setImportPhotos(false)
        ..setGroupName('Family');
      before.toggle(before.visible(MatchStatus.newPerson).first); // Anna off
      before.setYear('e', 1984);
      final after = ImportReviewModel(
        matchCandidates([
          candidate('a', 'Anna', 5, 1, year: 1990, photo: true),
          candidate('e', 'Emil', 2, 14),
          candidate('f', 'Finn', 4, 4, year: 1990), // newly shared
        ], const []),
      )..carryOver(before);

      expect(after.isSelected('a'), isFalse);
      expect(after.isSelected('e'), isTrue);
      expect(after.yearFor('e'), 1984);
      expect(after.isSelected('f'), isTrue);
      expect(after.importPhotos, isFalse);
      expect(after.groupName, 'Family');
    });

    test('null keeps the defaults', () {
      final review = model()..carryOver(null);
      expect(review.selectedCount, 2);
    });
  });
}
