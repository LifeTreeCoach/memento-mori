import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/vcard_parser.dart';

void main() {
  final today = DateTime(2026, 11, 7);
  VCardParseResult parseText(String text, {bool includePhotos = true}) =>
      parseVCards(text, includePhotos: includePhotos, today: today);
  VCardParseResult fixture(String name) => parseText(
    decodeVCardBytes(File('test/fixtures/vcard/$name').readAsBytesSync()),
  );
  BirthdayCandidate byName(VCardParseResult result, String name) =>
      result.candidates.singleWhere((c) => c.displayName == name);

  test('Google Contacts export (3.0)', () {
    final result = fixture('google_contacts.vcf');
    expect(result.cardCount, 6);
    expect(result.candidates.map((c) => c.displayName), [
      'Anna Schmidt',
      "Ben O'Connor",
      'Clara Meier, Dr.',
      'Daniel Long-Name',
    ]);
    final anna = byName(result, 'Anna Schmidt');
    expect((anna.year, anna.month, anna.day), (1988, 5, 13));
    expect(anna.source, ImportSource.vcard);
    expect(anna.id, 'vcard:0');
    final ben = byName(result, "Ben O'Connor");
    expect((ben.year, ben.month, ben.day), (null, 5, 13));
    expect(byName(result, 'Clara Meier, Dr.').year, 1992);
    expect(result.withoutBirthday, 1);
    expect(result.invalidBirthday, 1);
    expect(result.skippedCount, 2);
  });

  test('iCloud export: omitted year, UID, inline photo, item groups', () async {
    final result = fixture('icloud.vcf');
    expect(result.candidates, hasLength(3));
    final jorg = byName(result, 'Jörg Müller');
    expect((jorg.year, jorg.month, jorg.day), (null, 7, 21));
    expect(jorg.sourceId, 'A1B2C3D4-0000-4E5F-9A8B-ICLOUD000001');
    final photo = await jorg.photo!.load();
    expect(photo!.sublist(1, 4), 'PNG'.codeUnits);
    final helene = byName(result, 'Hélène Lefèvre');
    expect(helene.year, 1975);
    expect(helene.photo, isNull, reason: 'photo URIs are skipped');
    final jose = byName(result, 'José García');
    expect((jose.year, jose.month, jose.day), (null, 2, 29));
  });

  test('Outlook 2.1: quoted-printable, charsets, soft breaks', () async {
    final result = fixture('outlook_21.vcf');
    expect(result.candidates.map((c) => c.displayName), [
      'Jörg Müller',
      'Renée Dubois',
      'Sophie Grünwald',
    ]);
    expect(byName(result, 'Jörg Müller').year, 1985);
    final sophie = byName(result, 'Sophie Grünwald');
    expect((sophie.year, sophie.month, sophie.day), (1983, 8, 15));
    expect(await sophie.photo!.load(), isNotEmpty);
  });

  test('vCard 4.0: basic dates, data URI photo, VALUE=text', () async {
    final result = fixture('vcard_40.vcf');
    expect(result.cardCount, 4);
    final zoe = byName(result, 'Zoë Fischer');
    expect((zoe.year, zoe.month, zoe.day), (1996, 4, 15));
    expect(zoe.sourceId, 'urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1');
    expect(await zoe.photo!.load(), isNotEmpty);
    final max = byName(result, 'Max Weber');
    expect((max.year, max.month, max.day), (null, 12, 24));
    expect(byName(result, 'Lea Braun').year, 2001);
    expect(result.invalidBirthday, 1);
  });

  test('includePhotos: false drops photos', () {
    final result = parseText(
      File('test/fixtures/vcard/vcard_40.vcf').readAsStringSync(),
      includePhotos: false,
    );
    expect(result.candidates.every((c) => c.photo == null), isTrue);
  });

  test('N fallback builds "Given Family" with escapes', () {
    final result = parseText(
      'BEGIN:VCARD\nVERSION:3.0\nN:Doe\\;Smith;Jane,Mary;;Dr.;\n'
      'BDAY:1980-01-02\nEND:VCARD\n',
    );
    expect(result.candidates.single.displayName, 'Jane Mary Doe;Smith');
  });

  test('cards without any name are counted', () {
    final result = parseText('BEGIN:VCARD\nBDAY:1980-01-02\nEND:VCARD');
    expect(result.candidates, isEmpty);
    expect(result.withoutName, 1);
  });

  test('lower-case property names, LF only, several BDAY lines', () {
    final result = parseText(
      'begin:vcard\nversion:3.0\nfn:Kim\nbday:not a date\nbday:2000-03-04\n'
      'end:vcard',
    );
    final kim = result.candidates.single;
    expect((kim.year, kim.month, kim.day), (2000, 3, 4));
  });

  test('robust to garbage', () {
    for (final text in [
      '',
      'hello world',
      'BEGIN:VCARD\nFN:Open card\nBDAY:2000-01-01',
      'END:VCARD\nBEGIN:VCARD\n:\n;;;\nFN\nPHOTO;ENCODING=b:@@@\n'
          'FN:Ok\nBDAY:2000-01-01\nEND:VCARD',
      'BEGIN:VCARD\nN;ENCODING=QUOTED-PRINTABLE:=ZZ=\nBDAY:2000-01-01\nEND:VCARD',
    ]) {
      expect(() => parseText(text), returnsNormally, reason: text);
    }
    final mixed = parseText(
      'END:VCARD\nBEGIN:VCARD\n:\n;;;\nFN\nPHOTO;ENCODING=b:@@@\n'
      'FN:Ok\nBDAY:2000-01-01\nEND:VCARD',
    );
    expect(mixed.candidates.single.displayName, 'Ok');
    expect(mixed.candidates.single.photo, isNull);
  });

  test('nested AGENT cards are ignored', () {
    final result = parseText(
      'BEGIN:VCARD\nFN:Boss\nAGENT:\nBEGIN:VCARD\nFN:Assistant\n'
      'BDAY:1999-09-09\nEND:VCARD\nBDAY:1970-01-05\nEND:VCARD',
    );
    expect(result.cardCount, 1);
    expect(result.candidates.single.displayName, 'Boss');
    expect(result.candidates.single.year, 1970);
  });

  test('decodeVCardBytes: UTF-8 with BOM and Latin-1 fallback', () {
    expect(
      decodeVCardBytes([0xEF, 0xBB, 0xBF, ...utf8.encode('Jörg')]),
      'Jörg',
    );
    expect(decodeVCardBytes(latin1.encode('Jörg')), 'Jörg');
  });
}
