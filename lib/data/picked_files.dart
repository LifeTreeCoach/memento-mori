/// Cleanup of the copies the file picker keeps of picked files.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

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
