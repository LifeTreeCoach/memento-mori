/// Cleanup of the copies the file picker keeps of picked files.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Deletes the file picker's copies of picked files. Never throws: a failed
/// cleanup must not fail the import that read the file.
///
/// Android copies every pick into `cache/file_picker/`, which the plugin's
/// `clearTemporaryFiles` removes (only that folder, so it is safe). On iOS
/// that call empties the whole `NSTemporaryDirectory()`, including temp
/// files of other plugins (image_picker, share_plus) that may still be in
/// use, so there only the copy of [file] is deleted ([deletePickedCopy]).
/// [platform] and [temporaryDirectory] are for tests.
Future<void> clearPickedFileCopies({
  PlatformFile? file,
  TargetPlatform? platform,
  Directory? temporaryDirectory,
}) async {
  try {
    if ((platform ?? defaultTargetPlatform) == TargetPlatform.iOS) {
      await deletePickedCopy(
        file,
        platform: TargetPlatform.iOS,
        temporaryDirectory: temporaryDirectory,
      );
    } else {
      await FilePicker.clearTemporaryFiles();
    }
  } catch (e) {
    debugPrint('Picked file copies not cleared: $e');
  }
}

/// On iOS, deletes the picker's copy of [file] (see [deletePickedCopyAt]);
/// elsewhere does nothing (the plugin's cache folder is cleared by
/// [clearPickedFileCopies]). Never throws.
Future<void> deletePickedCopy(
  PlatformFile? file, {
  TargetPlatform? platform,
  Directory? temporaryDirectory,
}) async {
  final path = file?.path;
  if (path == null) return;
  if ((platform ?? defaultTargetPlatform) != TargetPlatform.iOS) return;
  try {
    await deletePickedCopyAt(path, temporaryDirectory ?? Directory.systemTemp);
  } catch (e) {
    debugPrint('Picked file copy not deleted: $e');
  }
}

/// Deletes image_picker's copy of a picked photo at [filePath] once it was
/// stored: the plugin leaves it in the cache (Android) / temp (iOS)
/// directory, which [temporaryDirectory] (default: path_provider's) names.
/// Only a file inside that directory is deleted. Never throws.
Future<void> deletePickedImageCopy(
  String filePath, {
  Directory? temporaryDirectory,
}) async {
  try {
    await deletePickedCopyAt(
      filePath,
      temporaryDirectory ?? await getTemporaryDirectory(),
    );
  } catch (e) {
    debugPrint('Picked photo copy not deleted (${e.runtimeType})');
  }
}

/// Deletes the picked copy at [filePath] if it lies in [temporaryDirectory]
/// (a file elsewhere is not the picker's copy and stays). The picker moves
/// each pick into a folder of its own directly in the temp directory; that
/// folder goes too once empty, as do empty `*-Inbox` folders the document
/// picker leaves there. Nothing else in the temp directory is touched.
@visibleForTesting
Future<void> deletePickedCopyAt(
  String filePath,
  Directory temporaryDirectory,
) async {
  final file = File(filePath);
  if (!await file.exists()) return;
  final temp = await temporaryDirectory.resolveSymbolicLinks();
  final folder = await file.parent.resolveSymbolicLinks();
  if (folder != temp && !_isInside(folder, temp)) return;
  await file.delete();
  if (Directory(folder).parent.path == temp) {
    await _deleteIfEmpty(Directory(folder));
  }
  await _deleteEmptyInboxes(Directory(temp));
}

bool _isInside(String path, String directory) =>
    path.startsWith('$directory${Platform.pathSeparator}');

/// Removes [directory] only when it is empty (a non-recursive delete fails
/// otherwise, which is ignored).
Future<void> _deleteIfEmpty(Directory directory) async {
  try {
    await directory.delete();
  } on FileSystemException {
    // Not empty (or already gone): keep it.
  }
}

Future<void> _deleteEmptyInboxes(Directory temp) async {
  await for (final entry in temp.list(followLinks: false)) {
    if (entry is Directory && entry.path.endsWith('-Inbox')) {
      await _deleteIfEmpty(entry);
    }
  }
}

/// Picks a file with [pick], reads it with [read] and removes the
/// picker's copy afterwards, whether reading worked or not.
/// Returns null when nothing was picked.
Future<T?> readPickedFile<T>(
  Future<PlatformFile?> Function() pick,
  Future<T> Function(PlatformFile file) read,
) async {
  PlatformFile? file;
  try {
    file = await pick();
    return file == null ? null : await read(file);
  } finally {
    await clearPickedFileCopies(file: file);
  }
}

/// A picked file above the size a reader accepts.
class PickedFileTooLargeException implements Exception {
  const PickedFileTooLargeException(this.maxBytes);

  final int maxBytes;

  @override
  String toString() => 'PickedFileTooLargeException(max $maxBytes bytes)';
}

/// The bytes of [file], refused with a [PickedFileTooLargeException] when it
/// is larger than [maxBytes]: checked against the size the picker reports
/// before anything is read, and again while streaming (a size it doesn't
/// know, or one that is wrong), so a huge file is never read fully.
Future<Uint8List> readPickedBytes(PlatformFile file, {required int maxBytes}) async {
  final knownLength = file.lengthSync() ?? await file.length();
  if (knownLength != null && knownLength > maxBytes) {
    throw PickedFileTooLargeException(maxBytes);
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in file.readAsByteStream()) {
    if (bytes.length + chunk.length > maxBytes) {
      throw PickedFileTooLargeException(maxBytes);
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}
