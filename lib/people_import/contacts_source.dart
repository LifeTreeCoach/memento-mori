/// Reading birthdays from the device address book (read-only).
library;

import 'package:flutter_contacts/flutter_contacts.dart';

import 'birthday_candidate.dart';
import 'contact_birthday_texts.dart';
import 'contact_mapping.dart';
import 'contact_thumbnails.dart';

export 'contact_mapping.dart' show ContactsAccess;

/// The device contacts as a source of birthdays; the UI depends on this,
/// tests use a fake.
abstract class ContactsSource {
  const ContactsSource();

  /// The current access, without asking.
  Future<ContactsAccess> access();

  /// Shows the system prompt (read only) when the user has not decided yet;
  /// otherwise returns the current access.
  Future<ContactsAccess> requestAccess();

  /// Every contact with a valid birthday; [BirthdayCandidate.photo] is set
  /// only for contacts that have a photo. Empty without access.
  Future<List<BirthdayCandidate>> readBirthdays();

  /// Opens the app's page in the system settings (to allow access after
  /// "don't ask again", or to share more contacts on iOS).
  Future<void> openSettings();
}

/// [ContactsSource] backed by `flutter_contacts` (Android `READ_CONTACTS`,
/// iOS `CNContactStore`, including iOS 18's limited access).
class DeviceContactsSource extends ContactsSource {
  const DeviceContactsSource({
    this.today,
    this.birthdayTexts = const ContactBirthdayTexts(),
    this.thumbnails = const ContactThumbnails(),
  });

  /// Fixed "today" for the birth-date plausibility check (tests).
  final DateTime? today;

  /// Raw birthday texts for the dates the plugin cannot parse (Android).
  final ContactBirthdayTexts birthdayTexts;

  /// Thumbnails of the contacts with a birthday (photo presence).
  final ContactThumbnails thumbnails;

  static const _permission = PermissionType.read;

  /// Events (birthdays) plus Android's stable lookup key; id and display
  /// name always come along. No photos: only the contacts with a birthday
  /// get theirs read, by [thumbnails].
  static const Set<ContactProperty> _properties = {
    ContactProperty.event,
    ContactProperty.identifiers,
  };

  @override
  Future<ContactsAccess> access() async => contactsAccessFromStatus(
    await FlutterContacts.permissions.check(_permission),
  );

  @override
  Future<ContactsAccess> requestAccess() async => contactsAccessFromStatus(
    await FlutterContacts.permissions.request(_permission),
  );

  @override
  Future<List<BirthdayCandidate>> readBirthdays() async {
    if (!(await access()).canRead) return const [];
    final contacts = await FlutterContacts.getAll(properties: _properties);
    final candidates = candidatesFromContacts(
      contacts,
      today: today,
      birthdayTexts: await birthdayTexts.read(),
    );
    final photos = await thumbnails.read(candidates.map(contactIdOf).toList());
    return withContactThumbnails(candidates, photos);
  }

  @override
  Future<void> openSettings() => FlutterContacts.permissions.openSettings();
}
