import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/enhanced_friends_screen.dart';
import 'package:memento_mori_life_in_weeks/people_import/contacts_source.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/contacts_explainer_sheet.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_screen.dart';

import '../../support/fake_contacts_source.dart';
import 'import_ui_helpers.dart';

void main() {
  final anna = contactCandidate('Anna', 5, 1, year: 1990);

  Future<FakeContactsSource> startContacts(
    WidgetTester tester, {
    ContactsAccess initial = ContactsAccess.notDetermined,
    ContactsAccess afterRequest = ContactsAccess.granted,
  }) async {
    final contacts = FakeContactsSource(
      candidates: [anna],
      initialAccess: initial,
      accessAfterRequest: afterRequest,
    );
    await initImportPrefs(const []);
    await pumpImportApp(
      tester,
      EnhancedFriendsScreen(now: importToday),
      services: fakeServices(contacts: contacts),
    );
    await tester.tap(find.text('Import birthdays'));
    await settleAsync(tester);
    await tester.tap(find.text('From contacts'));
    await settleAsync(tester);
    return contacts;
  }

  testWidgets('explains before the first system prompt', (tester) async {
    final contacts = await startContacts(tester);

    expect(find.byType(ContactsExplainerSheet), findsOneWidget);
    expect(contacts.requestCount, 0);

    await tester.tap(find.text('Continue'));
    await settleAsync(tester);

    expect(contacts.requestCount, 1);
    expect(find.byType(ImportReviewScreen), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('cancelling the explainer never prompts', (tester) async {
    final contacts = await startContacts(tester);

    await tester.tap(find.text('Cancel'));
    await settleAsync(tester);

    expect(contacts.requestCount, 0);
    expect(find.byType(ImportReviewScreen), findsNothing);
  });

  testWidgets('no explainer once access was granted', (tester) async {
    final contacts = await startContacts(
      tester,
      initial: ContactsAccess.granted,
    );

    expect(find.byType(ContactsExplainerSheet), findsNothing);
    expect(contacts.requestCount, 0);
    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('denied: explains and can ask again', (tester) async {
    final contacts = await startContacts(
      tester,
      afterRequest: ContactsAccess.denied,
    );
    await tester.tap(find.text('Continue'));
    await settleAsync(tester);

    expect(find.text('No access to your contacts'), findsOneWidget);
    expect(find.text('Ask again'), findsOneWidget);

    contacts.currentAccess = ContactsAccess.granted; // the user says yes
    await tester.tap(find.text('Ask again'));
    await settleAsync(tester);

    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('permanently denied: opens settings, re-checks on resume', (
    tester,
  ) async {
    final contacts = await startContacts(
      tester,
      initial: ContactsAccess.permanentlyDenied,
    );

    expect(find.byType(ContactsExplainerSheet), findsNothing);
    await tester.tap(find.text('Allow in settings'));
    await settleAsync(tester);
    expect(contacts.openSettingsCount, 1);

    contacts.currentAccess = ContactsAccess.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settleAsync(tester);

    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('limited access: note with a link to the settings', (
    tester,
  ) async {
    final contacts = await startContacts(
      tester,
      initial: ContactsAccess.limited,
    );

    expect(find.text('You shared only selected contacts'), findsOneWidget);
    await tester.tap(find.text('Share more'));
    await settleAsync(tester);
    expect(contacts.openSettingsCount, 1);
  });

  testWidgets('read error shows a calm message', (tester) async {
    final contacts = FakeContactsSource(
      initialAccess: ContactsAccess.granted,
      readError: Exception('plugin'),
    );
    await initImportPrefs(const []);
    await pumpImportApp(
      tester,
      EnhancedFriendsScreen(now: importToday),
      services: fakeServices(contacts: contacts),
    );
    await tester.tap(find.text('Import birthdays'));
    await settleAsync(tester);
    await tester.tap(find.text('From contacts'));
    await settleAsync(tester);

    expect(find.text('Your contacts couldn’t be read.'), findsOneWidget);
  });
}
