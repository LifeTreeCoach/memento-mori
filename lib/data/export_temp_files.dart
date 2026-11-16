/// Temporary copies of backups made for sharing.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Where backups shared as files are written (plain JSON with personal data),
/// and their cleanup.
///
/// A shared file cannot be deleted right after the share sheet returns: the
/// receiving app may still be reading it. Instead the folder is emptied
/// before the next export and once at every app start ([purge]).
///
/// Also purged: share_plus's own copies (Android copies every shared file
/// into `cache/share_plus/` and clears that folder only on the next share)
/// and backups that older versions wrote directly into the temp directory.
class ExportTempFiles {
  /// [baseDirectory] replaces the app's temp/cache directory (tests).
  const ExportTempFiles({Directory? baseDirectory})
      : _baseDirectory = baseDirectory; // ignore: prefer_initializing_formals

  final Directory? _baseDirectory;

  /// Folder in the temp directory that holds shared backups.
  static const String folderName = 'exports';

  /// share_plus's copy folder on Android.
  static const String sharePlusFolderName = 'share_plus';

  /// Name prefix of backups older versions left in the temp directory.
  static const String legacyBackupPrefix = 'memento_backup_';

  Future<Directory> _base() async =>
      _baseDirectory ?? await getTemporaryDirectory();

  /// An empty exports folder's file named [fileName], to be written and
  /// shared. Earlier exports are purged first.
  Future<File> fileFor(String fileName) async {
    await purge();
    final folder = Directory('${(await _base()).path}/$folderName');
    await folder.create(recursive: true);
    return File('${folder.path}/$fileName');
  }

  /// Deletes every shared backup and share_plus copy. Never throws.
  Future<void> purge() async {
    try {
      final base = await _base();
      await _deleteFolder(Directory('${base.path}/$folderName'));
      await _deleteFolder(Directory('${base.path}/$sharePlusFolderName'));
      await _deleteLegacyBackups(base);
    } catch (e) {
      debugPrint('Export temp files not purged (${e.runtimeType})');
    }
  }

  static Future<void> _deleteFolder(Directory folder) async {
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  static Future<void> _deleteLegacyBackups(Directory base) async {
    if (!await base.exists()) return;
    await for (final entry in base.list(followLinks: false)) {
      final name = entry.uri.pathSegments.last;
      if (entry is File &&
          name.startsWith(legacyBackupPrefix) &&
          name.endsWith('.json')) {
        await entry.delete();
      }
    }
  }
}
