/// Pure conversion of `flutter_contacts` values into import candidates and
/// access states, kept apart from the plugin calls so it can be tested.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'birthday_candidate.dart';
import 'birthday_text_parser.dart';

/// What the app may read from the device contacts.
enum ContactsAccess {
  /// Not asked yet: [ContactsSource.requestAccess] shows the system prompt.
  notDetermined,

  /// Every contact can be read.
  granted,

  /// iOS 18+: only the contacts the user shared can be read.
  limited,

  /// Refused, but the system prompt may be shown again.
  denied,

  /// Refused for good: only the system settings can change it.
  permanentlyDenied,

  /// Blocked by the device (parental controls, MDM); the user cannot allow it.
  restricted;

  /// Whether contacts can be read now (all or the shared ones).
  bool get canRead => this == granted || this == limited;

  /// Whether only the system settings can grant access.
  bool get needsSettings => this == permanentlyDenied;
}

/// [ContactsAccess] for the plugin's [status].
ContactsAccess contactsAccessFromStatus(PermissionStatus status) {
  return switch (status) {
    PermissionStatus.granted => ContactsAccess.granted,
    PermissionStatus.limited => ContactsAccess.limited,
    PermissionStatus.denied => ContactsAccess.denied,
    PermissionStatus.permanentlyDenied => ContactsAccess.permanentlyDenied,
    PermissionStatus.restricted => ContactsAccess.restricted,
    PermissionStatus.notDetermined => ContactsAccess.notDetermined,
  };
}

/// Prefix of the candidate ids of device contacts.
const String contactCandidatePrefix = 'contact:';

/// The contact id behind a candidate made by [candidateFromContact].
String contactIdOf(BirthdayCandidate candidate) =>
    candidate.id.substring(contactCandidatePrefix.length);

/// [candidates] with the [thumbnails] (by contact id) as their photos;
/// candidates without a thumbnail keep `photo == null`.
List<BirthdayCandidate> withContactThumbnails(
  List<BirthdayCandidate> candidates,
  Map<String, Uint8List> thumbnails,
) {
  return [
    for (final candidate in candidates)
      switch (thumbnails[contactIdOf(candidate)]) {
        final bytes? => candidate.copyWith(photo: CandidatePhoto.memory(bytes)),
        null => candidate,
      },
  ];
}

/// The id that recognises [contact] in a later import: Android's lookup key
/// (survives account syncs, unlike the row id), else the contact id (iOS
/// `CNContact.identifier`).
String? contactSourceId(Contact contact) {
  final lookupKey = contact.android?.identifiers?.lookupKey;
  if (lookupKey != null && lookupKey.isNotEmpty) return lookupKey;
  return contact.id;
}

/// The candidate for [contact], or null when it has no id, no name or no
/// valid birthday. Only events labelled birthday count (anniversaries and
/// other dates are ignored); the first valid one wins. Without one, the raw
/// [birthdayText] (which the plugin could not parse, e.g. `15.08.1992`) is
/// parsed with [parseBirthdayText]. A missing year or Apple's 1604 means
/// "no year". [photoFor] builds the (lazy) photo for the contact id.
BirthdayCandidate? candidateFromContact(
  Contact contact, {
  CandidatePhoto? Function(String contactId)? photoFor,
  DateTime? today,
  String? birthdayText,
}) {
  final id = contact.id;
  final name = contact.displayName?.trim() ?? '';
  if (id == null || id.isEmpty || name.isEmpty) return null;
  final birthday =
      _firstBirthday(contact.events, today) ??
      parseBirthdayText(birthdayText, today: today);
  if (birthday == null) return null;
  return BirthdayCandidate(
    id: '$contactCandidatePrefix$id',
    displayName: name,
    month: birthday.month,
    day: birthday.day,
    year: birthday.year,
    source: ImportSource.contacts,
    sourceId: contactSourceId(contact),
    photo: photoFor?.call(id),
  );
}

/// Candidates for every contact with a valid birthday, in [contacts] order.
/// [birthdayTexts] maps contact ids to raw birthday texts (the fallback of
/// [candidateFromContact]).
List<BirthdayCandidate> candidatesFromContacts(
  Iterable<Contact> contacts, {
  CandidatePhoto? Function(String contactId)? photoFor,
  DateTime? today,
  Map<String, String> birthdayTexts = const {},
}) {
  return [
    for (final contact in contacts)
      ?candidateFromContact(
        contact,
        photoFor: photoFor,
        today: today,
        birthdayText: birthdayTexts[contact.id],
      ),
  ];
}

BirthdayDate? _firstBirthday(List<Event> events, DateTime? today) {
  for (final event in events) {
    if (event.label.label != EventLabel.birthday) continue;
    final date = birthdayFromParts(
      year: event.year,
      month: event.month,
      day: event.day,
      today: today,
    );
    if (date != null) return date;
  }
  return null;
}
