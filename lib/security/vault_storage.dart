import 'dart:io';
import 'dart:typed_data';

/// Byte storage for named vault records (one blob per name).
abstract class VaultStorage {
  /// Names of all stored records.
  Future<List<String>> names();

  /// The record's bytes, or null if it does not exist.
  Future<Uint8List?> read(String name);

  /// Replaces the record atomically: readers see the old or the new bytes,
  /// never a mix.
  Future<void> write(String name, List<int> bytes);

  /// Deletes the record; no error if it does not exist.
  Future<void> delete(String name);

  /// Deletes every record.
  Future<void> deleteAll();
}

/// [VaultStorage] keeping each record in `<dir>/<name>.bin`.
///
/// A write goes to `<name>.bin.tmp` (flushed) and is then renamed over the
/// record, so a crash leaves either the old or the new file. Stray `.tmp`
/// files from an interrupted write are ignored and cleaned up by [names].
class FileVaultStorage implements VaultStorage {
  FileVaultStorage(this.dir);

  final Directory dir;

  static const String recordSuffix = '.bin';
  static const String tempSuffix = '.bin.tmp';

  File _recordFile(String name) =>
      File('${dir.path}${Platform.pathSeparator}$name$recordSuffix');

  File _tempFile(String name) =>
      File('${dir.path}${Platform.pathSeparator}$name$tempSuffix');

  @override
  Future<List<String>> names() async {
    final names = <String>[];
    for (final file in await _files()) {
      final base = _baseName(file);
      if (base.endsWith(tempSuffix)) {
        await _deleteQuietly(file);
      } else if (base.endsWith(recordSuffix)) {
        names.add(base.substring(0, base.length - recordSuffix.length));
      }
    }
    return names..sort();
  }

  @override
  Future<Uint8List?> read(String name) async {
    final file = _recordFile(name);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    await dir.create(recursive: true);
    final temp = _tempFile(name);
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(_recordFile(name).path);
  }

  @override
  Future<void> delete(String name) => _deleteQuietly(_recordFile(name));

  @override
  Future<void> deleteAll() async {
    for (final file in await _files()) {
      final base = _baseName(file);
      if (base.endsWith(recordSuffix) || base.endsWith(tempSuffix)) {
        await _deleteQuietly(file);
      }
    }
  }

  Future<List<File>> _files() async {
    if (!await dir.exists()) return const [];
    return dir.list().where((entity) => entity is File).cast<File>().toList();
  }

  static String _baseName(File file) => file.uri.pathSegments.last;

  static Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } on PathNotFoundException {
      // Already gone.
    }
  }
}
