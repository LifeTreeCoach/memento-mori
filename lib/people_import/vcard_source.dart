/// Picking a .vcf file and reading its birthdays.
library;

import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../data/picked_files.dart';
import 'vcard_parser.dart';

/// Returns the bytes of the file the user picked, or null when cancelled.
typedef VCardFilePicker = Future<Uint8List?> Function();

/// Turns the picked bytes into the parse result.
typedef VCardBytesParser =
    Future<VCardParseResult> Function(Uint8List bytes, {DateTime? today});

/// Removes the copies the file picker keeps of picked files (app cache).
typedef PickedFileCleaner = Future<void> Function();

/// Why a picked file could not be read.
enum VCardFileProblem { tooLarge, unreadable, notVCard }

/// The picked file cannot be read; [problem] says why.
class VCardFileException implements Exception {
  const VCardFileException(this.problem);

  final VCardFileProblem problem;

  @override
  String toString() => 'VCardFileException(${problem.name})';
}

/// Files above this size are refused (a full address book with photos is a
/// few MB).
const int maxVCardFileBytes = 64 * 1024 * 1024;

/// Reads birthdays from a vCard file the user picks.
class VCardSource {
  const VCardSource({
    this.pickFile = pickVCardFile,
    this.parse = parseVCardBytesInBackground,
    this.clearPickedFiles = clearPickedFileCopies,
    this.today,
  });

  final VCardFilePicker pickFile;
  final VCardBytesParser parse;

  /// Runs after every pick (read, cancelled or failed), so no copy of the
  /// address book stays in the app cache (on iOS it only knows the file by
  /// path, so [pickVCardFile] deletes that copy itself).
  final PickedFileCleaner clearPickedFiles;

  /// Fixed "today" for the birth-date plausibility check (tests).
  final DateTime? today;

  /// Lets the user pick a file and parses it; null when cancelled. Throws
  /// [VCardFileException] for files that are too large, unreadable or hold
  /// no `BEGIN:VCARD` at all (e.g. a JSON backup picked by mistake).
  Future<VCardParseResult?> pickAndParse() async {
    final bytes = await _pickBytes();
    if (bytes == null) return null;
    if (bytes.length > maxVCardFileBytes) {
      throw const VCardFileException(VCardFileProblem.tooLarge);
    }
    final result = await parse(bytes, today: today);
    if (result.cardCount == 0) {
      throw const VCardFileException(VCardFileProblem.notVCard);
    }
    return result;
  }

  /// The picked bytes; the picker's cached copy is removed in any case.
  Future<Uint8List?> _pickBytes() async {
    try {
      return await pickFile();
    } on VCardFileException {
      rethrow;
    } catch (e) {
      debugPrint('vCard file not read: $e');
      throw const VCardFileException(VCardFileProblem.unreadable);
    } finally {
      await clearPickedFiles();
    }
  }
}

/// Extensions offered by the vCard picker. Android filters by the MIME
/// types its `MimeTypeMap` knows for them: `vcf` -> `text/x-vcard`,
/// `vcard` -> `text/vcard` (an unknown one is skipped by the plugin), so
/// files stored under either type stay selectable and other files (e.g.
/// JSON backups) are hidden; iOS maps both to `public.vcard`. A provider
/// that ignores the filter can still hand over another file: it is
/// reported as [VCardFileProblem.notVCard].
const List<String> vCardFileExtensions = ['vcf', 'vcard'];

/// The system file picker for a vCard file.
Future<Uint8List?> pickVCardFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: vCardFileExtensions,
  );
  if (file == null) return null;
  try {
    if ((file.lengthSync() ?? 0) > maxVCardFileBytes) {
      throw const VCardFileException(VCardFileProblem.tooLarge);
    }
    return await file.readAsBytes(); // size checked again by VCardSource
  } finally {
    // iOS: this pick's copy (VCardSource clears Android's picker cache).
    await deletePickedCopy(file);
  }
}

/// Decodes and parses [bytes] on a background isolate (large address books
/// with photos would block the UI).
Future<VCardParseResult> parseVCardBytesInBackground(
  Uint8List bytes, {
  DateTime? today,
}) {
  return Isolate.run(() => parseVCardBytes(bytes, today: today));
}

/// Decodes (UTF-8, Latin-1 fallback) and parses [bytes].
VCardParseResult parseVCardBytes(Uint8List bytes, {DateTime? today}) =>
    parseVCards(decodeVCardBytes(bytes), today: today);
