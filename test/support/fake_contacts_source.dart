import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/contacts_source.dart';

/// [ContactsSource] for widget tests: a fixed list of candidates and a
/// scripted permission flow.
class FakeContactsSource extends ContactsSource {
  FakeContactsSource({
    this.candidates = const [],
    this.initialAccess = ContactsAccess.notDetermined,
    this.accessAfterRequest = ContactsAccess.granted,
    this.readError,
  }) : currentAccess = initialAccess;

  /// What [readBirthdays] returns; tests change it to simulate more
  /// shared contacts.
  List<BirthdayCandidate> candidates;
  final ContactsAccess initialAccess;

  /// What the "system prompt" answers when access was not decided yet.
  final ContactsAccess accessAfterRequest;

  /// Thrown by [readBirthdays] when set (plugin failure).
  final Object? readError;

  /// The access now; tests set it to simulate a change in the settings.
  ContactsAccess currentAccess;
  int requestCount = 0;
  int readCount = 0;
  int openSettingsCount = 0;

  @override
  Future<ContactsAccess> access() async => currentAccess;

  @override
  Future<ContactsAccess> requestAccess() async {
    requestCount++;
    if (currentAccess == ContactsAccess.notDetermined ||
        currentAccess == ContactsAccess.denied) {
      currentAccess = accessAfterRequest;
    }
    return currentAccess;
  }

  @override
  Future<List<BirthdayCandidate>> readBirthdays() async {
    readCount++;
    final error = readError;
    if (error != null) throw error;
    return currentAccess.canRead ? candidates : const [];
  }

  @override
  Future<void> openSettings() async => openSettingsCount++;
}
