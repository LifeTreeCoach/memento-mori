import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_text_parser.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_applier.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 7, 12);

/// Smallest valid PNG signature prefix the avatar store accepts.
final _png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);

Friend _saved(String id, String name, DateTime birthDate, {bool year = true}) {
  final created = DateTime(2025, 1, 1);
  return Friend(
    id: id,
    name: name,
    birthDate: birthDate,
    hasBirthYear: year,
    createdDate: created,
    lastUpdated: created,
  );
}

PlannedFriend _planned(
  String name, {
  int month = 5,
  int day = 1,
  int? year,
  CandidatePhoto? photo,
  ImportSource source = ImportSource.contacts,
  String? sourceId,
  String? group,
}) {
  return PlannedFriend(
    candidateId: 'c:$name',
    name: name,
    month: month,
    day: day,
    year: year,
    source: source,
    sourceId: sourceId,
    photo: photo,
    groupName: group,
  );
}

void main() {
  late Directory temp;
  late ImportApplier applier;
  late int changes;
  late List<List<String>> removals;
  late List<Uint8List> resized;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FriendsService.clearCacheForTesting();
    temp = await Directory.systemTemp.createTemp('import_applier');
    resized = [];
    applier = ImportApplier(
      avatarStore: AvatarStore(baseDirectory: () async => temp),
      resizePhoto: (bytes) async {
        resized.add(bytes);
        return _png;
      },
      now: () => _now,
    );
    changes = 0;
    removals = [];
    FriendsService.onFriendsChanged = () async => changes++;
    FriendsService.onFriendsRemoved = (ids) async => removals.add(ids);
  });

  tearDown(() async {
    FriendsService.onFriendsChanged = null;
    FriendsService.onFriendsRemoved = null;
    await temp.delete(recursive: true);
  });

  test('adds new people and updates in one batch', () async {
    await FriendsService.addFriends([
      _saved('old', 'Old', DateTime(2000, 3, 4), year: false),
    ]);
    changes = 0;
    final revision = FriendsService.revision.value;

    final outcome = await applier.apply(
      ImportPlan(
        newFriends: [
          _planned('Anna', year: 1990, sourceId: 'lk1', group: 'Family'),
          _planned('Ben', month: 2, day: 29, source: ImportSource.vcard),
        ],
        updates: [
          const PlannedUpdate(
            candidateId: 'c:old',
            friendId: 'old',
            month: 3,
            day: 4,
            year: 1980,
            previous: BirthdayDate(month: 3, day: 4),
          ),
        ],
      ),
    );

    expect(changes, 1);
    expect(FriendsService.revision.value, revision + 1);
    expect(outcome.addedCount, 2);
    expect(outcome.updatedCount, 1);
    final friends = {
      for (final f in await FriendsService.getAllFriends()) f.name: f,
    };
    final anna = friends['Anna']!;
    expect(anna.birthDate, DateTime(1990, 5, 1));
    expect(anna.hasBirthYear, isTrue);
    expect(anna.importSource, Friend.importSourceContacts);
    expect(anna.importSourceId, 'lk1');
    expect(anna.groupName, 'Family');
    expect(anna.notificationId, isPositive);
    final ben = friends['Ben']!;
    expect(ben.hasBirthYear, isFalse);
    expect(ben.birthDate, DateTime(Friend.noYearStorageYear, 2, 29));
    expect(ben.importSource, Friend.importSourceVcard);
    final old = friends['Old']!;
    expect((old.birthDate, old.hasBirthYear), (DateTime(1980, 3, 4), true));
    expect(old.lastUpdated, _now);
  });

  test('photos are resized and saved; missing or huge ones skipped', () async {
    final outcome = await applier.apply(
      ImportPlan(
        newFriends: [
          _planned(
            'Photo',
            photo: CandidatePhoto.memory(Uint8List.fromList([1, 2, 3])),
          ),
          _planned('None', photo: CandidatePhoto.lazy(() async => null)),
          _planned('Huge', photo: CandidatePhoto.memory(Uint8List(3 << 20))),
          _planned(
            'Broken',
            photo: CandidatePhoto.lazy(() async => throw Exception('gone')),
          ),
        ],
        updates: const [],
      ),
    );

    expect(outcome.addedCount, 4);
    expect(resized, hasLength(1));
    final byName = {
      for (final f in await FriendsService.getAllFriends()) f.name: f,
    };
    final path = byName['Photo']!.avatarPath!;
    expect(path, endsWith('.png'));
    expect(File(path).readAsBytesSync(), _png);
    for (final name in ['None', 'Huge', 'Broken']) {
      expect(byName[name]!.avatarPath, isNull, reason: name);
    }
  });

  test('a resizer returning null leaves the person without photo', () async {
    final noPhoto = ImportApplier(
      avatarStore: AvatarStore(baseDirectory: () async => temp),
      resizePhoto: (_) async => null,
      now: () => _now,
    );
    await noPhoto.apply(
      ImportPlan(
        newFriends: [_planned('A', photo: CandidatePhoto.memory(_png))],
        updates: const [],
      ),
    );
    expect((await FriendsService.getAllFriends()).single.avatarPath, isNull);
  });

  test('undo removes added people and restores updated ones', () async {
    final before = _saved('old', 'Old', DateTime(1970, 1, 2));
    await FriendsService.addFriends([before]);
    final outcome = await applier.apply(
      ImportPlan(
        newFriends: [_planned('Anna'), _planned('Ben')],
        updates: [
          const PlannedUpdate(
            candidateId: 'c:old',
            friendId: 'old',
            month: 6,
            day: 7,
            year: 1971,
            previous: BirthdayDate(month: 1, day: 2, year: 1970),
          ),
        ],
      ),
    );
    changes = 0;

    await applier.undo(outcome);

    expect(changes, 1);
    expect(removals, [outcome.addedIds]);
    final friends = await FriendsService.getAllFriends();
    expect(friends.single.birthDate, before.birthDate);
    expect(friends.single.lastUpdated, before.lastUpdated);
  });

  test('undo skips people deleted in the meantime', () async {
    await FriendsService.addFriends([_saved('old', 'Old', DateTime(1970, 1, 2))]);
    final outcome = await applier.apply(
      ImportPlan(
        newFriends: [_planned('Anna'), _planned('Ben')],
        updates: [
          const PlannedUpdate(
            candidateId: 'c:old',
            friendId: 'old',
            month: 6,
            day: 7,
            previous: BirthdayDate(month: 1, day: 2, year: 1970),
          ),
        ],
      ),
    );
    await FriendsService.deleteFriend(outcome.addedIds.first);
    await FriendsService.deleteFriend('old');

    await applier.undo(outcome);

    expect(await FriendsService.getAllFriends(), isEmpty);
  });

  test('updates of people deleted before saving are skipped', () async {
    final outcome = await applier.apply(
      const ImportPlan(
        newFriends: [],
        updates: [
          PlannedUpdate(
            candidateId: 'c',
            friendId: 'missing',
            month: 1,
            day: 1,
            previous: BirthdayDate(month: 2, day: 2),
          ),
        ],
      ),
    );
    expect(outcome.isEmpty, isTrue);
    expect(changes, 0);
  });
}
