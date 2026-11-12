import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/data/backup_avatar.dart';
import 'package:path_provider/path_provider.dart';

/// Friend photos in the app's `avatars` folder (inside the documents
/// directory, which [baseDirectory] provides; injectable for tests).
class AvatarStore {
  const AvatarStore({this.baseDirectory = getApplicationDocumentsDirectory});

  final Future<Directory> Function() baseDirectory;

  static int _counter = 0;

  /// Documents directory of this run, cached by [init] so photos can be
  /// resolved synchronously while building widgets.
  static String? _documentsPath;
  static final Map<String, String> _resolvedPaths = {};

  /// Caches the documents directory; call once before `runApp`.
  static Future<void> init({
    Future<Directory> Function() documentsDirectory =
        getApplicationDocumentsDirectory,
  }) async {
    _documentsPath = (await documentsDirectory()).path;
    _resolvedPaths.clear();
  }

  @visibleForTesting
  static void resetForTest() {
    _documentsPath = null;
    _resolvedPaths.clear();
  }

  /// The file to load for a stored avatar path, using the documents
  /// directory cached by [init] (results are cached per path).
  static String? resolve(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    final documentsPath = _documentsPath;
    if (documentsPath == null) return stored;
    return _resolvedPaths[stored] ??=
        resolvePath(stored, documentsPath: documentsPath)!;
  }

  /// The file to load for a [stored] avatar path: the stored file if it
  /// exists, else the photo of the same name in `<documentsPath>/avatars`.
  ///
  /// Stored paths are absolute, but on iOS the app container (and so the
  /// absolute path) changes on updates, restores and device transfers,
  /// while the unique file names stay. Null for a missing [stored] path;
  /// [stored] unchanged without a [documentsPath].
  static String? resolvePath(
    String? stored, {
    required String? documentsPath,
    bool Function(String path) exists = _fileExists,
  }) {
    if (stored == null || stored.isEmpty) return null;
    if (documentsPath == null) return stored;
    final current = '$documentsPath/avatars/${_fileName(stored)}';
    if (stored == current || exists(stored)) return stored;
    return current;
  }

  static bool _fileExists(String path) => File(path).existsSync();

  Future<Directory> _avatarsDirectory() async {
    final directory = Directory('${(await baseDirectory()).path}/avatars');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  /// Writes [bytes] to a new, unique file and returns its path.
  Future<String> save(List<int> bytes, {String extension = 'jpg'}) async {
    final directory = await _avatarsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/avatar_${stamp}_${_counter++}.$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// The photo at the stored [path] (see [resolvePath]) for a backup; null
  /// when there is none or it cannot be read.
  Future<BackupAvatar?> readForBackup(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final documentsPath = (await baseDirectory()).path;
      final file = File(resolvePath(path, documentsPath: documentsPath)!);
      if (!await file.exists() || await file.length() > BackupAvatar.maxBytes) {
        return null;
      }
      return BackupAvatar.fromBytes(await file.readAsBytes());
    } catch (e) {
      debugPrint('Avatar not exported ($path): $e');
      return null;
    }
  }

  /// Deletes the photos in the avatars folder that none of [keptPaths]
  /// points to and returns how many were deleted.
  ///
  /// Matched by file name, not full path: on iOS the app container (and so
  /// the absolute path) can change between updates, while the unique file
  /// names stay. Never throws; files that cannot be deleted are skipped.
  Future<int> removeUnreferenced(Iterable<String?> keptPaths) async {
    final kept = {
      for (final path in keptPaths)
        if (path != null && path.isNotEmpty) _fileName(path),
    };
    var removed = 0;
    try {
      final directory = Directory('${(await baseDirectory()).path}/avatars');
      if (!await directory.exists()) return 0;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File || kept.contains(_fileName(entity.path))) continue;
        try {
          await entity.delete();
          removed++;
        } catch (e) {
          debugPrint('Avatar not deleted (${entity.path}): $e');
        }
      }
    } catch (e) {
      debugPrint('Avatar cleanup skipped: $e');
    }
    return removed;
  }

  static String _fileName(String path) =>
      path.substring(path.lastIndexOf(RegExp(r'[/\\]')) + 1);

  /// Saves an imported [avatar] and returns its new path; null on failure.
  Future<String?> restore(BackupAvatar? avatar) async {
    if (avatar == null) return null;
    try {
      return await save(avatar.bytes, extension: avatar.extension);
    } catch (e) {
      debugPrint('Avatar not imported: $e');
      return null;
    }
  }
}
