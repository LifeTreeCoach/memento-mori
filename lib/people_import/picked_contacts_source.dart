/// Contacts the user picks in the system contact picker (Android 17+,
/// iOS): no permission, only the chosen people are shared with the app.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'birthday_candidate.dart';
import 'birthday_text_parser.dart';

/// A source that lets the user pick contacts in a system dialog.
abstract class PickedContactsSource {
  const PickedContactsSource();

  /// Whether the system picker exists on this device (Android 17+, iOS).
  Future<bool> isSupported();

  /// Opens the picker and returns the picked contacts with a valid birthday
  /// plus how many had none; empty when cancelled or unsupported.
  Future<PickedContacts> pickContacts();
}

/// What the user picked: the contacts with a valid birthday and the count of
/// named ones without a usable birthday (none, or not a readable date).
class PickedContacts {
  const PickedContacts({this.candidates = const [], this.withoutBirthday = 0});

  static const PickedContacts none = PickedContacts();

  final List<BirthdayCandidate> candidates;
  final int withoutBirthday;

  /// Nothing picked (cancelled, unsupported or only nameless entries).
  bool get isEmpty => candidates.isEmpty && withoutBirthday == 0;
}

/// Prefix of the candidate ids of picked contacts.
const String pickedContactCandidatePrefix = 'picked:';

/// [PickedContactsSource] over the MethodChannel `memento/contacts_picker`
/// (native side: Android's `MainActivity` + `contacts/ContactsPicker.kt`,
/// iOS `Runner/ContactsPicker.swift` + `PickedContact.swift`):
/// - `isSupported` -> bool
/// - `pickContacts` -> list of maps `{id: String?` (lookup key, else contact
///   id; iOS: CNContact identifier), `displayName: String, birthday: String` (raw `Event.START_DATE`,
///   e.g. `1990-05-01`, `--05-01`; iOS sends these two forms), `thumbnail:
///   Uint8List?}`; null or an empty list when cancelled.
///
/// Without the native side (older builds) it reports "unsupported".
class ChannelPickedContactsSource extends PickedContactsSource {
  const ChannelPickedContactsSource({
    this.channel = const MethodChannel('memento/contacts_picker'),
    this.today,
  });

  final MethodChannel channel;

  /// Fixed "today" for the birth-date plausibility check (tests).
  final DateTime? today;

  @override
  Future<bool> isSupported() async {
    try {
      return await channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<PickedContacts> pickContacts() async {
    try {
      final picked = await channel.invokeListMethod<Object?>('pickContacts');
      return pickedContactsFromMaps(picked ?? const [], today: today);
    } on MissingPluginException {
      return PickedContacts.none;
    } on PlatformException catch (e) {
      debugPrint('Contact picker failed: $e');
      return PickedContacts.none;
    }
  }
}

/// Candidates for the maps sent by the native picker; entries without a
/// name or a valid birthday are skipped.
@visibleForTesting
List<BirthdayCandidate> candidatesFromPickedContacts(
  List<Object?> picked, {
  DateTime? today,
}) => pickedContactsFromMaps(picked, today: today).candidates;

/// [PickedContacts] for the maps sent by the native picker: entries without
/// a name are ignored, named ones without a valid birthday are counted.
@visibleForTesting
PickedContacts pickedContactsFromMaps(List<Object?> picked, {DateTime? today}) {
  final candidates = <BirthdayCandidate>[];
  var withoutBirthday = 0;
  for (var index = 0; index < picked.length; index++) {
    final entry = picked[index];
    if (entry is! Map || _nameOf(entry).isEmpty) continue;
    final candidate = _candidateFromMap(entry, index, today);
    candidate == null ? withoutBirthday++ : candidates.add(candidate);
  }
  return PickedContacts(
    candidates: candidates,
    withoutBirthday: withoutBirthday,
  );
}

String _nameOf(Map entry) => (entry['displayName'] as String?)?.trim() ?? '';

BirthdayCandidate? _candidateFromMap(Map entry, int index, DateTime? today) {
  final name = _nameOf(entry);
  final date = parseBirthdayText(entry['birthday'] as String?, today: today);
  if (name.isEmpty || date == null) return null;
  final id = entry['id'] as String?;
  final thumbnail = entry['thumbnail'];
  return BirthdayCandidate(
    id: '$pickedContactCandidatePrefix${id ?? index}',
    displayName: name,
    month: date.month,
    day: date.day,
    year: date.year,
    source: ImportSource.contacts,
    sourceId: id,
    photo: thumbnail is Uint8List && thumbnail.isNotEmpty
        ? CandidatePhoto.memory(thumbnail)
        : null,
  );
}
