import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/enhanced_friends_screen.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/contacts_source.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/contacts_explainer_sheet.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_screen.dart';
import 'package:memento_mori_life_in_weeks/people_import/vcard_source.dart';

import '../../support/fake_contacts_source.dart';
import 'import_ui_helpers.dart';

const _vcf = '''
BEGIN:VCARD
VERSION:3.0
FN:Vera Card
BDAY:1985-04-12
END:VCARD
''';

final _ios = TargetPlatformVariant.only(TargetPlatform.iOS);
final _android = TargetPlatformVariant.only(TargetPlatform.android);

void main() {
  final anna = contactCandidate('Anna', 5, 1, year: 1990);
  final ben = contactCandidate('Ben', 6, 2, year: 1988);

  Future<void> openSourceSheet(
    WidgetTester tester,
    FakeContactsSource contacts, {
    VCardSource? vcard,
    FakePickedContactsSource? picker,
  }) async {
    await initImportPrefs(const []);
    await pumpImportApp(
      tester,
      EnhancedFriendsScreen(now: importToday),
      services: fakeServices(contacts: contacts, vcard: vcard, picker: picker),
    );
    await tester.tap(find.text('Import birthdays'));
    await settleAsync(tester);
  }

  Future<void> openContacts(
    WidgetTester tester,
    FakeContactsSource contacts, {
    VCardSource? vcard,
  }) async {
    await openSourceSheet(tester, contacts, vcard: vcard);
    await tester.tap(find.text('From contacts'));
    await settleAsync(tester);
  }

  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settleAsync(tester);
  }

  group('source sheet subtitle', () {
    const google =
        'Also covers the birthdays in Google Calendar – they come from your '
        'contacts.';
    const apple =
        'Your contacts’ birthdays – also the ones in the Birthdays calendar '
        'of Apple Calendar.';

    testWidgets('iOS mentions Apple Calendar', (tester) async {
      await openSourceSheet(tester, FakeContactsSource());
      expect(find.textContaining(apple), findsOneWidget);
      expect(find.textContaining('Google Calendar'), findsNothing);
    }, variant: _ios);

    testWidgets('Android mentions Google Calendar', (tester) async {
      await openSourceSheet(tester, FakeContactsSource());
      expect(find.textContaining(google), findsOneWidget);
      expect(find.textContaining('Apple Calendar'), findsNothing);
    }, variant: _android);
  });

  group('contact picker', () {
    const iosPickSub =
        'No permission needed · only the people you choose are shared';

    Future<void> openWithPicker(
      WidgetTester tester, {
      List<BirthdayCandidate> picked = const [],
    }) async {
      await openSourceSheet(
        tester,
        FakeContactsSource(candidates: [anna]),
        picker: FakePickedContactsSource(supported: true, picked: picked),
      );
    }

    testWidgets('iOS: "Choose contacts" first, full search second', (
      tester,
    ) async {
      await openWithPicker(tester);
      final choose = find.text('Choose contacts');
      final all = find.text('Search all contacts with a birthday');
      expect(choose, findsOneWidget);
      expect(all, findsOneWidget);
      expect(tester.getTopLeft(choose).dy, lessThan(tester.getTopLeft(all).dy));
      expect(find.textContaining(iosPickSub), findsOneWidget);
      expect(find.textContaining('100'), findsNothing);
      expect(find.text('From contacts'), findsNothing);
    }, variant: _ios);

    testWidgets('Android keeps the 100-per-round hint', (tester) async {
      await openWithPicker(tester);
      expect(find.textContaining('up to 100'), findsOneWidget);
      expect(find.textContaining(iosPickSub), findsNothing);
    }, variant: _android);

    testWidgets('iOS: picked people go to the review list', (tester) async {
      await openWithPicker(tester, picked: [ben]);
      await tester.tap(find.text('Choose contacts'));
      await settleAsync(tester);
      expect(find.byType(ImportReviewScreen), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
      expect(find.byType(ContactsExplainerSheet), findsNothing);
    }, variant: _ios);
  });

  group('explainer', () {
    const choice =
        'iOS lets you share all contacts or only selected ones – both work.';

    testWidgets('iOS adds the line about sharing all or some', (tester) async {
      await openContacts(tester, FakeContactsSource(candidates: [anna]));
      expect(find.byType(ContactsExplainerSheet), findsOneWidget);
      expect(find.textContaining('Memento Mori reads'), findsOneWidget);
      expect(find.text(choice), findsOneWidget);
    }, variant: _ios);

    testWidgets('Android has no such line', (tester) async {
      await openContacts(tester, FakeContactsSource(candidates: [anna]));
      expect(find.byType(ContactsExplainerSheet), findsOneWidget);
      expect(find.text(choice), findsNothing);
    }, variant: _android);
  });

  group('refused access', () {
    testWidgets('iOS: soft text, settings and the vCard route', (tester) async {
      final contacts = FakeContactsSource(
        initialAccess: ContactsAccess.permanentlyDenied,
      );
      final vcard = VCardSource(
        pickFile: () async => Uint8List.fromList(utf8.encode(_vcf)),
        clearPickedFiles: () async {},
      );
      await openContacts(tester, contacts, vcard: vcard);

      expect(
        find.textContaining('allow access to your contacts anytime'),
        findsOneWidget,
      );
      expect(find.textContaining('turned off in the system'), findsNothing);
      await tester.tap(find.text('Allow in settings'));
      await settleAsync(tester);
      expect(contacts.openSettingsCount, 1);

      await tester.tap(find.text('Choose a vCard file instead'));
      await settleAsync(tester);
      expect(find.byType(ImportReviewScreen), findsOneWidget);
      expect(find.text('Vera Card'), findsOneWidget);
    }, variant: _ios);

    testWidgets('Android: settings text without the vCard button', (
      tester,
    ) async {
      await openContacts(
        tester,
        FakeContactsSource(initialAccess: ContactsAccess.permanentlyDenied),
      );
      expect(find.textContaining('turned off in the system'), findsOneWidget);
      expect(find.text('Choose a vCard file instead'), findsNothing);
    }, variant: _android);

    testWidgets('denied offers the vCard route next to asking again', (
      tester,
    ) async {
      await openContacts(
        tester,
        FakeContactsSource(initialAccess: ContactsAccess.denied),
      );
      expect(find.textContaining('Memento Mori can’t see'), findsOneWidget);
      expect(find.text('Ask again'), findsOneWidget);
      expect(find.text('Choose a vCard file instead'), findsOneWidget);
    });
  });

  group('limited access', () {
    testWidgets('resume reads again and keeps the choices', (tester) async {
      final contacts = FakeContactsSource(
        candidates: [anna],
        initialAccess: ContactsAccess.limited,
      );
      await openContacts(tester, contacts);
      expect(find.text('Add 1\u00A0person'), findsOneWidget);
      await tester.tap(find.text('Anna')); // untick
      await tester.pumpAndSettle();
      expect(find.text('Nobody selected'), findsOneWidget);

      await tester.tap(find.text('Share more'));
      await settleAsync(tester);
      expect(contacts.openSettingsCount, 1);
      contacts.candidates = [anna, ben]; // the user shared Ben
      await resume(tester);

      expect(find.text('Ben'), findsOneWidget);
      expect(find.text('2\u00A0birthdays found'), findsOneWidget);
      expect(find.text('Add 1\u00A0person'), findsOneWidget); // Ben only
    });

    testWidgets('resume with full access drops the limited note', (
      tester,
    ) async {
      final contacts = FakeContactsSource(
        candidates: [anna],
        initialAccess: ContactsAccess.limited,
      );
      await openContacts(tester, contacts);
      expect(find.text('You shared only selected contacts'), findsOneWidget);

      contacts.currentAccess = ContactsAccess.granted;
      await resume(tester);
      expect(find.text('You shared only selected contacts'), findsNothing);
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('empty state explains and offers to share more', (
      tester,
    ) async {
      final contacts = FakeContactsSource(
        initialAccess: ContactsAccess.limited,
      );
      await openContacts(tester, contacts);

      expect(find.text('No birthdays found'), findsOneWidget);
      expect(
        find.textContaining('You shared only selected contacts'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('import-empty-share-more')));
      await settleAsync(tester);
      expect(contacts.openSettingsCount, 1);

      contacts.candidates = [anna];
      await resume(tester);
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('empty state with full access keeps the plain tips', (
      tester,
    ) async {
      await openContacts(
        tester,
        FakeContactsSource(initialAccess: ContactsAccess.granted),
      );
      expect(find.text('No birthdays found'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('import-empty-share-more')),
        findsNothing,
      );
    });
  });
}
