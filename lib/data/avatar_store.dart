import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/data/backup_avatar.dart';
import 'package:memento_mori_life_in_weeks/security/vault_cipher.dart';
import 'package:path_provider/path_provider.dart';

/// Friend photos in the app's `avatars` folder (inside the documents
/// directory, which [baseDirectory] provides; injectable for tests).
///
/// Photos are sealed with [cipher] (record [recordName], bound to the file
/// name) before they reach the disk. Without a cipher (vault not configured)
/// release builds refuse to write a photo; debug builds and tests
/// ([allowPlainPhotos]) write plain image files. Plain files written by older
/// versions are always read as they are.
class AvatarStore {
  const AvatarStore({
    this.baseDirectory = getApplicationDocumentsDirectory,
    this._cipher,
    this.allowPlainPhotos = !kReleaseMode,
  });

  final Future<Directory> Function() baseDirectory;

  /// Whether [save] may write an unsealed photo when there is no cipher:
  /// never in release builds, so a photo never reaches the disk in plain
  /// text there.
  final bool allowPlainPhotos;
  final RecordCipher? _cipher;

  /// The cipher of the opened vault, set by [configureCipher].
  static RecordCipher? _configuredCipher;

  /// Sets the cipher used by every store without its own (the vault's,
  /// once it is ready; null while it is not).
  static void configureCipher(RecordCipher? cipher) =>
      _configuredCipher = cipher;

  /// The cipher used for photos when none is passed explicitly.
  static RecordCipher? get configuredCipher => _configuredCipher;

  /// The cipher this store seals and opens photos with.
  RecordCipher? get cipher => _cipher ?? _configuredCipher;

  /// Record name (AAD) a photo is sealed under: the file name only, so a
  /// moved app container (new absolute path) still opens it.
  static String recordName(String path) => 'avatar/${_fileName(path)}';

  /// Room for the envelope around a photo of [BackupAvatar.maxBytes].
  static const int _envelopeAllowance = 64;

  /// The image bytes of the photo file at [path] whose content is [bytes]:
  /// opened with [cipher] when sealed, else returned as they are (plain
  /// files from older versions). Throws a [VaultException] if a sealed photo
  /// cannot be opened, and a [StateError] if there is no cipher for it.
  static Future<Uint8List> openPhoto(
    String path,
    Uint8List bytes,
    RecordCipher? cipher,
  ) async {
    if (!VaultCipher.looksSealed(bytes)) return bytes;
    if (cipher == null) throw StateError('no cipher for a sealed photo');
    return cipher.open(recordName(path), bytes);
  }

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

  /// Writes [bytes] (sealed with [cipher]) to a new, unique file and returns
  /// its path. Without a cipher it throws a [StateError] and writes nothing,
  /// unless [allowPlainPhotos] (debug builds, tests).
  Future<String> save(List<int> bytes, {String extension = 'jpg'}) async {
    final cipher = this.cipher;
    if (cipher == null && !allowPlainPhotos) {
      debugPrint('AvatarStore: photo not saved, encryption is not ready');
      throw StateError('Photo not saved: encryption is not ready');
    }
    final directory = await _avatarsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/avatar_${stamp}_${_counter++}.$extension');
    final content = cipher == null
        ? bytes
        : await cipher.seal(recordName(file.path), bytes);
    await file.writeAsBytes(content, flush: true);
    return file.path;
  }

  /// The photo at the stored [path] (see [resolvePath]) for a backup, as
  /// plain image bytes; null when there is none or it cannot be read or
  /// opened.
  Future<BackupAvatar?> readForBackup(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final documentsPath = (await baseDirectory()).path;
      final file = File(resolvePath(path, documentsPath: documentsPath)!);
      if (!await file.exists() ||
          await file.length() > BackupAvatar.maxBytes + _envelopeAllowance) {
        return null;
      }
      final bytes = await file.readAsBytes();
      return BackupAvatar.fromBytes(await openPhoto(file.path, bytes, cipher));
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

  /// Deletes the whole avatars folder (e.g. when the locked personal data is
  /// replaced by a fresh start). Missing folders are fine.
  Future<void> deleteAll() async {
    final directory = Directory('${(await baseDirectory()).path}/avatars');
    if (await directory.exists()) await directory.delete(recursive: true);
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
