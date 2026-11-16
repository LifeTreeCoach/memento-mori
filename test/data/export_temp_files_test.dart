import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/data/export_temp_files.dart';

void main() {
  late Directory base;
  late ExportTempFiles files;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('export_temp_files_test');
    files = ExportTempFiles(baseDirectory: base);
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  Future<File> write(String relativePath) async {
    final file = File('${base.path}/$relativePath');
    await file.parent.create(recursive: true);
    return file..writeAsStringSync('{"friends":[]}');
  }

  test('fileFor returns a file in the exports folder', () async {
    final file = await files.fileFor('memento_backup_2026-11-13.json');

    expect(file.path, '${base.path}/exports/memento_backup_2026-11-13.json');
    expect(await file.parent.exists(), isTrue);
  });

  test('fileFor purges earlier exports first', () async {
    final earlier = await write('exports/memento_backup_2026-01-01.json');

    await files.fileFor('memento_backup_2026-11-13.json');

    expect(await earlier.exists(), isFalse);
  });

  test('purge deletes exports, share_plus copies and legacy backups', () async {
    final export = await write('exports/memento_backup_2026-01-01.json');
    final shareCopy = await write('share_plus/memento_backup_2026-01-01.json');
    final legacy = await write('memento_backup_2025-05-05.json');

    await files.purge();

    expect(await export.exists(), isFalse);
    expect(await shareCopy.exists(), isFalse);
    expect(await legacy.exists(), isFalse);
    expect(await Directory('${base.path}/exports').exists(), isFalse);
    expect(await Directory('${base.path}/share_plus').exists(), isFalse);
  });

  test('purge keeps everything else in the temp directory', () async {
    final other = await write('file_picker/contacts.vcf');
    final otherJson = await write('settings.json');
    final namedFolder = await write('memento_backup_folder/keep.txt');

    await files.purge();

    expect(await other.exists(), isTrue);
    expect(await otherJson.exists(), isTrue);
    expect(await namedFolder.exists(), isTrue);
  });

  test('purge never throws, also without a temp directory', () async {
    await base.delete(recursive: true);

    await expectLater(files.purge(), completes);
  });
}
