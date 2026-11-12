import 'dart:typed_data';

/// Where an imported birthday came from.
enum ImportSource { contacts, vcard }

/// A candidate's photo: bytes already in memory (vCard `PHOTO`) or loaded on
/// demand (contact thumbnails are only read for the people the user picks).
abstract class CandidatePhoto {
  const CandidatePhoto();

  /// Photo bytes that are already decoded.
  const factory CandidatePhoto.memory(Uint8List bytes) = MemoryCandidatePhoto;

  /// Photo read by [loader] when it is needed.
  const factory CandidatePhoto.lazy(Future<Uint8List?> Function() loader) =
      LazyCandidatePhoto;

  /// The image bytes, or null when the source has none (any more).
  Future<Uint8List?> load();
}

/// [CandidatePhoto] holding its bytes.
class MemoryCandidatePhoto extends CandidatePhoto {
  const MemoryCandidatePhoto(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> load() async => bytes;
}

/// [CandidatePhoto] that asks its source when [load] is called.
class LazyCandidatePhoto extends CandidatePhoto {
  const LazyCandidatePhoto(this.loader);

  final Future<Uint8List?> Function() loader;

  @override
  Future<Uint8List?> load() => loader();
}

/// One person with a birthday, read from the device contacts or a vCard file
/// and not yet saved. [id] is unique within one import batch and is what the
/// review list selects; [sourceId] (contact id / vCard `UID`) recognises the
/// same person in a later import.
class BirthdayCandidate {
  const BirthdayCandidate({
    required this.id,
    required this.displayName,
    required this.month,
    required this.day,
    this.year,
    required this.source,
    this.sourceId,
    this.photo,
  });

  final String id;
  final String displayName;
  final int month;
  final int day;

  /// Null when the source has no birth year (`--MM-dd`, Apple's 1604).
  final int? year;
  final ImportSource source;
  final String? sourceId;
  final CandidatePhoto? photo;

  bool get hasYear => year != null;

  bool get hasPhoto => photo != null;

  BirthdayCandidate copyWith({
    int? year,
    String? sourceId,
    CandidatePhoto? photo,
  }) {
    return BirthdayCandidate(
      id: id,
      displayName: displayName,
      month: month,
      day: day,
      year: year ?? this.year,
      source: source,
      sourceId: sourceId ?? this.sourceId,
      photo: photo ?? this.photo,
    );
  }

  @override
  String toString() =>
      'BirthdayCandidate($id, $displayName, ${year ?? '----'}-$month-$day)';
}
