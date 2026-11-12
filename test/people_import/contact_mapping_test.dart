import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/contact_birthday_texts.dart';
import 'package:memento_mori_life_in_weeks/people_import/contact_mapping.dart';
import 'package:memento_mori_life_in_weeks/people_import/picked_contacts_source.dart';

final _today = DateTime(2026, 11, 7);

Event _birthday(int month, int day, {int? year}) => Event(
  year: year,
  month: month,
  day: day,
  label: const Label(EventLabel.birthday),
);

Contact _contact(
  String? id,
  String? name,
  List<Event> events, {
  String? lookupKey,
}) {
  return Contact(
    id: id,
    displayName: name,
    events: events,
    android: lookupKey == null
        ? null
        : AndroidData(identifiers: AndroidIdentifiers(lookupKey: lookupKey)),
  );
}

BirthdayCandidate? _map(Contact contact) =>
    candidateFromContact(contact, today: _today);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('candidateFromContact', () {
    test('maps a birthday with year', () {
      final candidate = _map(
        _contact('7', '  Anna Berg ', [_birthday(5, 1, year: 1990)]),
      )!;
      expect(candidate.id, 'contact:7');
      expect(candidate.displayName, 'Anna Berg');
      expect((candidate.year, candidate.month, candidate.day), (1990, 5, 1));
      expect(candidate.source, ImportSource.contacts);
      expect(candidate.sourceId, '7');
      expect(candidate.photo, isNull);
    });

    test('a missing year and Apple 1604 mean no year', () {
      expect(_map(_contact('1', 'A', [_birthday(2, 29)]))!.year, isNull);
      final apple = _map(_contact('2', 'B', [_birthday(3, 4, year: 1604)]))!;
      expect((apple.year, apple.month, apple.day), (null, 3, 4));
    });

    test('ignores anniversaries and other events', () {
      final contact = _contact('1', 'A', [
        const Event(
          year: 2010,
          month: 6,
          day: 1,
          label: Label(EventLabel.anniversary),
        ),
        const Event(month: 7, day: 2),
      ]);
      expect(_map(contact), isNull);
    });

    test('takes the first valid birthday', () {
      final contact = _contact('1', 'A', [
        _birthday(2, 30, year: 1990),
        _birthday(8, 9, year: 1985),
      ]);
      expect(_map(contact)!.month, 8);
    });

    test('skips contacts without id, name or valid birthday', () {
      expect(_map(_contact(null, 'A', [_birthday(1, 1)])), isNull);
      expect(_map(_contact('1', '  ', [_birthday(1, 1)])), isNull);
      expect(_map(_contact('1', null, [_birthday(1, 1)])), isNull);
      expect(_map(_contact('1', 'A', const [])), isNull);
      expect(_map(_contact('1', 'A', [_birthday(1, 1, year: 2030)])), isNull);
    });

    test('prefers the Android lookup key as source id', () {
      final contact = _contact('1', 'A', [_birthday(1, 1)], lookupKey: '0r7-x');
      expect(_map(contact)!.sourceId, '0r7-x');
      expect(contactSourceId(_contact('9', 'B', const [])), '9');
    });

    test('photo comes from photoFor with the contact id', () async {
      final requested = <String>[];
      final candidate = candidateFromContact(
        _contact('42', 'A', [_birthday(1, 1)]),
        today: _today,
        photoFor: (id) {
          requested.add(id);
          return CandidatePhoto.lazy(() async => Uint8List.fromList([9]));
        },
      )!;
      expect(requested, ['42']);
      expect(await candidate.photo!.load(), [9]);
    });

    test('thumbnails become photos, contacts without one get none', () async {
      final candidates = candidatesFromContacts([
        _contact('1', 'A', [_birthday(1, 1)]),
        _contact('2', 'B', [_birthday(2, 2)]),
      ], today: _today);
      expect(candidates.map(contactIdOf), ['1', '2']);
      expect(candidates.any((c) => c.hasPhoto), isFalse);

      final result = withContactThumbnails(candidates, {
        '2': Uint8List.fromList([7]),
      });
      expect(result.map((c) => c.hasPhoto), [false, true]);
      expect(await result.last.photo!.load(), [7]);
    });

    test('candidatesFromContacts keeps order and drops the rest', () {
      final result = candidatesFromContacts([
        _contact('1', 'A', [_birthday(1, 1)]),
        _contact('2', 'B', const []),
        _contact('3', 'C', [_birthday(3, 3, year: 1970)]),
      ], today: _today);
      expect(result.map((c) => c.displayName), ['A', 'C']);
    });

    test('parses the raw birthday text the plugin dropped', () {
      final result = candidatesFromContacts(
        [
          _contact('1', 'Dotted', const []),
          _contact('2', 'No year', const []),
          _contact('3', 'Apple', const []),
          _contact('4', 'Garbage', const []),
          _contact('5', 'None', const []),
        ],
        today: _today,
        birthdayTexts: const {
          '1': '15.08.1992',
          '2': '--07-14',
          '3': '1604-03-02',
          '4': 'soon',
        },
      );
      expect(
        [for (final c in result) (c.displayName, c.year, c.month, c.day)],
        [
          ('Dotted', 1992, 8, 15),
          ('No year', null, 7, 14),
          ('Apple', null, 3, 2),
        ],
      );
    });

    test('prefers the parsed event over the raw text', () {
      final candidate = candidateFromContact(
        _contact('1', 'A', [_birthday(5, 1, year: 1990)]),
        today: _today,
        birthdayText: '15.08.1992',
      )!;
      expect((candidate.year, candidate.month, candidate.day), (1990, 5, 1));
    });

    test('falls back to the raw text when the parsed event is invalid', () {
      final candidate = candidateFromContact(
        _contact('1', 'A', [_birthday(2, 30, year: 1990)]),
        today: _today,
        birthdayText: '1.2.1990',
      )!;
      expect((candidate.year, candidate.month, candidate.day), (1990, 2, 1));
    });
  });

  group('ContactBirthdayTexts', () {
    test('without the native side the map is empty', () async {
      const texts = ContactBirthdayTexts(
        channel: MethodChannel('test/no_birthday_texts'),
      );
      expect(await texts.read(), isEmpty);
    });

    test('reads the channel map', () async {
      const channel = MethodChannel('test/birthday_texts');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            call.method == 'birthdayTexts' ? {'7': '15.08.1992'} : null,
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      const texts = ContactBirthdayTexts(channel: channel);
      expect(await texts.read(), {'7': '15.08.1992'});
    });
  });

  test('contactsAccessFromStatus covers every plugin status', () {
    expect(
      {
        for (final status in PermissionStatus.values)
          status: contactsAccessFromStatus(status),
      },
      {
        PermissionStatus.granted: ContactsAccess.granted,
        PermissionStatus.limited: ContactsAccess.limited,
        PermissionStatus.denied: ContactsAccess.denied,
        PermissionStatus.permanentlyDenied: ContactsAccess.permanentlyDenied,
        PermissionStatus.restricted: ContactsAccess.restricted,
        PermissionStatus.notDetermined: ContactsAccess.notDetermined,
      },
    );
    expect(ContactsAccess.limited.canRead, isTrue);
    expect(ContactsAccess.denied.canRead, isFalse);
    expect(ContactsAccess.permanentlyDenied.needsSettings, isTrue);
  });

  group('picked contacts', () {
    test('maps the native maps, skipping invalid entries', () {
      final result = candidatesFromPickedContacts([
        {
          'id': 'lk1',
          'displayName': 'Anna',
          'birthday': '1990-05-01',
          'thumbnail': Uint8List.fromList([1, 2]),
        },
        {'displayName': 'Ben', 'birthday': '--12-24'},
        {'id': 'x', 'displayName': '', 'birthday': '1990-05-01'},
        {'id': 'y', 'displayName': 'Bad', 'birthday': 'soon'},
        'not a map',
      ], today: _today);
      expect(result.map((c) => c.id), ['picked:lk1', 'picked:1']);
      expect(result.first.sourceId, 'lk1');
      expect(result.first.hasPhoto, isTrue);
      expect((result.last.year, result.last.month), (null, 12));
      expect(result.last.sourceId, isNull);
    });

    test('counts named contacts without a usable birthday', () {
      final result = pickedContactsFromMaps([
        {'id': 'a', 'displayName': 'Anna', 'birthday': '15.08.1992'},
        {'id': 'b', 'displayName': 'Ben', 'birthday': ''},
        {'id': 'c', 'displayName': 'Cleo', 'birthday': 'soon'},
        {'id': 'd', 'displayName': ' ', 'birthday': ''},
        'not a map',
      ], today: _today);
      expect(result.candidates.single.displayName, 'Anna');
      expect(result.withoutBirthday, 2);
      expect(result.isEmpty, isFalse);
    });

    test('only contacts without birthday are not empty', () {
      final result = pickedContactsFromMaps([
        {'id': 'b', 'displayName': 'Ben', 'birthday': ''},
      ], today: _today);
      expect(result.candidates, isEmpty);
      expect(result.isEmpty, isFalse);
      expect(pickedContactsFromMaps(const []).isEmpty, isTrue);
    });

    test('maps the iOS picker maps (identifier, no year, thumbnail)', () {
      const identifier = '410FE041-5C4E-48DA-B4DE-04C15EA3DBAC:ABPerson';
      final result = pickedContactsFromMaps([
        {
          'id': identifier,
          'displayName': 'Ada Lovelace',
          'birthday': '--12-10',
          'thumbnail': Uint8List.fromList([7]),
        },
        {'id': 'g', 'displayName': 'Grace', 'birthday': '1906-12-09'},
      ], today: _today);
      final ada = result.candidates.first;
      expect(ada.id, 'picked:$identifier');
      expect(ada.sourceId, identifier);
      expect((ada.year, ada.month, ada.day), (null, 12, 10));
      expect(ada.hasPhoto, isTrue);
      expect(result.candidates.last.year, 1906);
      expect(result.withoutBirthday, 0);
    });

    test('a native error (picker busy) picks nobody', () async {
      const channel = MethodChannel('test/busy_picker');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'busy');
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      const source = ChannelPickedContactsSource(channel: channel);
      expect((await source.pickContacts()).isEmpty, isTrue);
    });

    test('without the native side it is unsupported and empty', () async {
      const source = ChannelPickedContactsSource(
        channel: MethodChannel('test/no_picker'),
      );
      expect(await source.isSupported(), isFalse);
      expect((await source.pickContacts()).isEmpty, isTrue);
    });

    test('reads the channel result', () async {
      const channel = MethodChannel('test/picker');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return switch (call.method) {
              'isSupported' => true,
              'pickContacts' => [
                {'id': 'a', 'displayName': 'Anna', 'birthday': '19900501'},
              ],
              _ => null,
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final source = ChannelPickedContactsSource(
        channel: channel,
        today: _today,
      );
      expect(await source.isSupported(), isTrue);
      expect(
        (await source.pickContacts()).candidates.single.displayName,
        'Anna',
      );
    });
  });
}
