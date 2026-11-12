import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';

Friend _anna() => Friend(
      id: 'a',
      name: 'Anna',
      birthDate: DateTime(1990, 5, 1),
      createdDate: DateTime(2026),
      lastUpdated: DateTime(2026),
    );

final _compass = CompassData(
  intentions: [
    Intention(
      id: 'i',
      title: 'Write letters',
      area: LifeArea.relationships,
      horizon: Horizon.thisSeason,
      status: IntentionStatus.now,
      createdAt: DateTime(2026, 2, 3),
    ),
  ],
  moments: [Moment(id: 'm', title: 'Wedding', date: DateTime(2018, 9, 1))],
);

void main() {
  test('backup round trip keeps friends and Compass data', () {
    final backup = FriendsService.encodeBackup([_anna()], compass: _compass);
    expect(jsonDecode(backup)['version'], '1.5');

    final contents = FriendsService.decodeBackupContents(backup);
    expect(contents.entries.single.friend.name, 'Anna');
    final compass = contents.compass!;
    expect(compass.intentions.single.title, 'Write letters');
    expect(compass.intentions.single.horizon, Horizon.thisSeason);
    expect(compass.moments.single.date, DateTime(2018, 9, 1));
  });

  test('a backup with Compass data and no friends is valid', () {
    final backup = FriendsService.encodeBackup([], compass: _compass);
    final contents = FriendsService.decodeBackupContents(backup);
    expect(contents.entries, isEmpty);
    expect(contents.compass!.moments, hasLength(1));
    expect(FriendsService.decodeBackup(backup), isEmpty);
  });

  test('empty Compass data is left out of the file', () {
    final backup = FriendsService.encodeBackup([_anna()], compass: CompassData.empty);
    expect((jsonDecode(backup) as Map).containsKey('compass'), isFalse);
    expect(FriendsService.decodeBackupContents(backup).compass, isNull);
  });

  test('a backup with neither friends nor Compass data is rejected', () {
    final backup = FriendsService.encodeBackup([]);
    expect(
      () => FriendsService.decodeBackupContents(backup),
      throwsA(isA<FriendsBackupException>().having(
          (e) => e.messageKey, 'messageKey', 'import_export_error_no_valid_friends')),
    );
  });

  test('1.0 and 1.1 backups still import, without Compass data', () {
    for (final version in ['1.0', '1.1']) {
      final backup = jsonEncode({
        'version': version,
        'friends': [_anna().toMap()],
      });
      final contents = FriendsService.decodeBackupContents(backup);
      expect(contents.entries.single.friend.name, 'Anna', reason: version);
      expect(contents.compass, isNull);
    }
  });

  test('a broken compass section does not break the friends', () {
    final backup = jsonEncode({
      'version': '1.2',
      'friends': [_anna().toMap()],
      'compass': 'garbage',
    });
    final contents = FriendsService.decodeBackupContents(backup);
    expect(contents.entries, hasLength(1));
    expect(contents.compass, isNull);
  });

  test('1.3 keeps phases and the kind, phase and due date of intentions', () {
    final compass = CompassData(
      phases: [
        LifePhase(
            id: 'p', preset: PhasePreset.family, start: DateTime(2023, 5, 1)),
      ],
      intentions: [
        Intention(
          id: 'j',
          title: 'Picnic',
          status: IntentionStatus.now,
          createdAt: DateTime(2026),
          kind: IntentionKind.enjoy,
          phaseId: 'p',
          dueDate: DateTime(2027, 5, 1),
        ),
      ],
    );
    final backup = FriendsService.encodeBackup([], compass: compass);
    final restored = FriendsService.decodeBackupContents(backup).compass!;
    expect(restored.phases.single.preset, PhasePreset.family);
    expect(restored.phases.single.start, DateTime(2023, 5, 1));
    final intention = restored.intentions.single;
    expect(intention.kind, IntentionKind.enjoy);
    expect(intention.phaseId, 'p');
    expect(intention.dueDate, DateTime(2027, 5, 1));
  });

  test('the note of a moment survives a backup', () {
    final compass = CompassData(moments: [
      Moment(id: 'n', title: 'Concert', date: DateTime(2026, 3, 1),
          note: 'Dancing with Lea'),
    ]);
    final backup = FriendsService.encodeBackup([], compass: compass);
    final restored = FriendsService.decodeBackupContents(backup).compass!;
    expect(restored.moments.single.note, 'Dancing with Lea');
  });

  test('a 1.2 backup without phases still imports', () {
    final backup = jsonEncode({
      'version': '1.2',
      'friends': [_anna().toMap()],
      'compass': {
        'intentions': [_compass.intentions.single.toJson()],
        'moments': [],
      },
    });
    final compass = FriendsService.decodeBackupContents(backup).compass!;
    expect(compass.intentions.single.title, 'Write letters');
    expect(compass.intentions.single.kind, isNull);
    expect(compass.phases, isEmpty);
  });
}
