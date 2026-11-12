import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/data/picked_files.dart';
import 'package:share_plus/share_plus.dart' show XFile;

/// Counts cleanups; [fail] makes the cleanup throw.
class _CountingPicker extends FilePickerPlatform {
  int cleared = 0;
  bool fail = false;

  @override
  Future<void> clearTemporaryFiles() async {
    cleared++;
    if (fail) throw StateError('no cache');
  }
}

final class _File extends PlatformFile {
  _File([this.filePath = '/tmp/x.vcf']);

  final String filePath;

  @override
  String get name => 'x.vcf';

  @override
  Uri get uri => Uri.file(filePath);

  @override
  XFile get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => 0;

  @override
  Future<int?> length() async => 0;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => const Stream.empty();
}

PlatformFile _file() => _File();

void main() {
  late _CountingPicker picker;

  setUp(() {
    picker = _CountingPicker();
    FilePickerPlatform.instance = picker;
  });

  test('clears the copy after reading the picked file', () async {
    final text = await readPickedFile(() async => _file(), (f) async => f.name);
    expect(text, 'x.vcf');
    expect(picker.cleared, 1);
  });

  test('clears even when nothing was picked', () async {
    final text = await readPickedFile<String>(
      () async => null,
      (f) async => '',
    );
    expect(text, isNull);
    expect(picker.cleared, 1);
  });

  test('clears when reading fails, and the error still surfaces', () async {
    await expectLater(
      readPickedFile<String>(
        () async => _file(),
        (f) async => throw const FormatException('bad'),
      ),
      throwsFormatException,
    );
    expect(picker.cleared, 1);
  });

  test('a failed cleanup does not throw', () async {
    picker.fail = true;
    await clearPickedFileCopies();
    expect(picker.cleared, 1);
  });

  group('iOS', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('picked_ios_'));
    tearDown(() => temp.deleteSync(recursive: true));

    File write(String relativePath) =>
        File('${temp.path}/$relativePath')
          ..createSync(recursive: true)
          ..writeAsStringSync('x');

    Future<void> clearOnIOS(PlatformFile? file) => clearPickedFileCopies(
      file: file,
      platform: TargetPlatform.iOS,
      temporaryDirectory: temp,
    );

    test('deletes only the picked copy and its own folder', () async {
      final picked = write('UUID-1/backup.json');
      final otherPlugin = write('image_picker_123.jpg');
      final otherFolder = write('share_plus/export.json');

      await clearOnIOS(_File(picked.path));

      expect(picked.existsSync(), isFalse);
      expect(Directory('${temp.path}/UUID-1').existsSync(), isFalse);
      expect(otherPlugin.existsSync(), isTrue);
      expect(otherFolder.existsSync(), isTrue);
      expect(picker.cleared, 0, reason: 'would empty the whole temp dir');
    });

    test('keeps the folder when it still holds other files', () async {
      final picked = write('UUID-2/a.vcf');
      final sibling = write('UUID-2/b.vcf');

      await clearOnIOS(_File(picked.path));

      expect(picked.existsSync(), isFalse);
      expect(sibling.existsSync(), isTrue);
    });

    test('removes empty Inbox folders, keeps non-empty ones', () async {
      final picked = write('UUID-3/a.vcf');
      Directory('${temp.path}/app-Inbox').createSync();
      final inUse = write('other-Inbox/b.vcf');

      await clearOnIOS(_File(picked.path));

      expect(Directory('${temp.path}/app-Inbox').existsSync(), isFalse);
      expect(inUse.existsSync(), isTrue);
    });

    test('a picked copy directly in the temp dir goes, the dir stays',
        () async {
      final picked = write('a.vcf');
      await clearOnIOS(_File(picked.path));
      expect(picked.existsSync(), isFalse);
      expect(temp.existsSync(), isTrue);
    });

    test('never deletes a file outside the temp directory', () async {
      final outside = Directory.systemTemp.createTempSync('picked_out_');
      addTearDown(() => outside.deleteSync(recursive: true));
      final file = File('${outside.path}/keep.vcf')..writeAsStringSync('x');

      await clearOnIOS(_File(file.path));

      expect(file.existsSync(), isTrue);
    });

    test('nothing picked or already gone: no error, nothing cleared',
        () async {
      final other = write('image_picker_1.jpg');
      await clearOnIOS(null);
      await clearOnIOS(_File('${temp.path}/gone/x.vcf'));
      expect(other.existsSync(), isTrue);
      expect(picker.cleared, 0);
    });

    test('readPickedFile deletes the copy after reading', () async {
      final picked = write('UUID-4/backup.json');
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      // Default temp dir (Directory.systemTemp) holds [temp]: the copy goes,
      // the plugin's whole-temp-dir clear is never called on iOS.
      final name = await readPickedFile(
        () async => _File(picked.path),
        (f) async => f.name,
      );
      expect(name, 'x.vcf');
      expect(picked.existsSync(), isFalse);
      expect(picker.cleared, 0);
    });

    test('deletePickedCopy does nothing on Android', () async {
      final picked = write('UUID-5/a.vcf');
      await deletePickedCopy(
        _File(picked.path),
        platform: TargetPlatform.android,
        temporaryDirectory: temp,
      );
      expect(picked.existsSync(), isTrue);
    });
  });
}
