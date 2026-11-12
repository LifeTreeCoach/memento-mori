import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people_import/vcard_source.dart';

final _today = DateTime(2026, 11, 7);

/// How often the picker's cached copies were cleared.
int _cleared = 0;

VCardSource _source(Future<Uint8List?> Function() pick) => VCardSource(
  pickFile: pick,
  clearPickedFiles: () async => _cleared++,
  today: _today,
);

Matcher _problem(VCardFileProblem problem) => throwsA(
  isA<VCardFileException>().having((e) => e.problem, 'problem', problem),
);

void main() {
  setUp(() => _cleared = 0);

  test('parses the picked file (in the background isolate)', () async {
    final bytes = File('test/fixtures/vcard/google_contacts.vcf')
        .readAsBytesSync();
    final result = await _source(() async => bytes).pickAndParse();
    expect(result!.cardCount, 6);
    expect(result.candidates, isNotEmpty);
  });

  test('decodes Latin-1 files', () async {
    final text = 'BEGIN:VCARD\r\nVERSION:2.1\r\nFN:Jürgen\r\n'
        'BDAY:1970-01-02\r\nEND:VCARD\r\n';
    final result =
        await _source(() async => Uint8List.fromList(latin1.encode(text)))
            .pickAndParse();
    expect(result!.candidates.single.displayName, 'Jürgen');
  });

  test('cancelled pick gives null', () async {
    expect(await _source(() async => null).pickAndParse(), isNull);
  });

  test('a file that is no vCard (e.g. a JSON backup) is reported', () async {
    final bytes = Uint8List.fromList(utf8.encode('{"friends": []}'));
    await expectLater(
      _source(() async => bytes).pickAndParse(),
      _problem(VCardFileProblem.notVCard),
    );
  });

  test('a vCard without birthdays still parses', () async {
    final bytes = Uint8List.fromList(
      utf8.encode('BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Ana\r\nEND:VCARD\r\n'),
    );
    final result = await _source(() async => bytes).pickAndParse();
    expect(result!.cardCount, 1);
    expect(result.candidates, isEmpty);
  });

  group('the picked file copy is cleared', () {
    test('after a successful read', () async {
      final bytes = File('test/fixtures/vcard/google_contacts.vcf')
          .readAsBytesSync();
      await _source(() async => bytes).pickAndParse();
      expect(_cleared, 1);
    });

    test('after a cancelled pick', () async {
      await _source(() async => null).pickAndParse();
      expect(_cleared, 1);
    });

    test('after a failed read', () async {
      await expectLater(
        _source(() async => throw const FileSystemException('gone'))
            .pickAndParse(),
        _problem(VCardFileProblem.unreadable),
      );
      expect(_cleared, 1);
    });

    test('after a file that is too large', () async {
      await expectLater(
        _source(() async => throw const VCardFileException(
              VCardFileProblem.tooLarge,
            )).pickAndParse(),
        _problem(VCardFileProblem.tooLarge),
      );
      expect(_cleared, 1);
    });
  });

  test('the picker offers only vCard extensions', () {
    expect(vCardFileExtensions, ['vcf', 'vcard']);
  });

  test('too large and unreadable files throw VCardFileException', () async {
    final large = _source(
      () async => Uint8List(maxVCardFileBytes + 1),
    ).pickAndParse();
    await expectLater(
      large,
      throwsA(
        isA<VCardFileException>().having(
          (e) => e.problem,
          'problem',
          VCardFileProblem.tooLarge,
        ),
      ),
    );
    final broken = _source(
      () async => throw const FileSystemException('gone'),
    ).pickAndParse();
    await expectLater(
      broken,
      throwsA(
        isA<VCardFileException>().having(
          (e) => e.problem,
          'problem',
          VCardFileProblem.unreadable,
        ),
      ),
    );
  });
}
