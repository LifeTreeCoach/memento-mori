import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/enhanced_friends_screen.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour.dart';
import 'package:memento_mori_life_in_weeks/people_import/contacts_source.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_result_report.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_screen.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_services.dart';
import 'package:memento_mori_life_in_weeks/people_import/vcard_source.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';

import '../../support/fake_contacts_source.dart';
import 'import_ui_helpers.dart';

const _vcf = '''
BEGIN:VCARD
VERSION:3.0
FN:Vera Card
BDAY:1985-04-12
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:No Birthday
END:VCARD
''';

void main() {
  final candidates = [
    contactCandidate('Anna', 5, 1, year: 1990),
    contactCandidate('Emil', 2, 14),
    contactCandidate('Ben', 3, 1, year: 1980),
  ];

  Future<void> openPeople(
    WidgetTester tester,
    ImportServices services, {
    bool withBen = false,
  }) async {
    await initImportPrefs([
      if (withBen) savedFriend('Ben', DateTime(1980, 3, 1)),
    ]);
    await pumpImportApp(
      tester,
      EnhancedFriendsScreen(now: importToday),
      services: services,
    );
  }

  Future<void> chooseSource(WidgetTester tester, String source) async {
    final entry = find.text('Import birthdays');
    if (entry.evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Import birthdays'));
    await settleAsync(tester);
    await tester.tap(find.text(source));
    await settleAsync(tester);
  }

  testWidgets('applies in one batch, reports with undo, asks once', (
    tester,
  ) async {
    var permissionRequests = 0;
    bool? snackBarDuringPermission;
    final services = fakeServices(
      contacts: FakeContactsSource(
        candidates: candidates,
        initialAccess: ContactsAccess.granted,
      ),
      requestNotificationPermission: () async {
        permissionRequests++;
        snackBarDuringPermission = find.byType(SnackBar).evaluate().isNotEmpty;
        return true;
      },
    );
    await openPeople(tester, services);
    await chooseSource(tester, 'From contacts');
    final revisionBefore = FriendsService.revision.value;

    await tester.tap(find.text('Add 3 people'));
    await settleAsync(tester);

    expect(find.byType(ImportReviewScreen), findsNothing);
    expect(snackBarDuringPermission, isFalse,
        reason: 'the permission dialog must not cover the undo offer');
    expect(FriendsService.revision.value, revisionBefore + 1); // one batch
    expect(find.text('3 people added'), findsOneWidget);
    expect(permissionRequests, 1);
    final friends = await tester.runAsync(FriendsService.getAllFriends);
    expect(friends!.map((f) => f.name), containsAll(['Anna', 'Emil', 'Ben']));

    await tester.tap(find.text('Undo'));
    await settleAsync(tester);
    expect(await tester.runAsync(FriendsService.getAllFriends), isEmpty);
  });

  testWidgets('nothing new: "No new birthdays", no permission prompt', (
    tester,
  ) async {
    var permissionRequests = 0;
    final services = fakeServices(
      contacts: FakeContactsSource(
        candidates: [candidates.last],
        initialAccess: ContactsAccess.granted,
      ),
      requestNotificationPermission: () async {
        permissionRequests++;
        return true;
      },
    );
    await openPeople(tester, services, withBen: true);
    await chooseSource(tester, 'From contacts');

    expect(find.text('Everyone is already in Memento Mori.'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settleAsync(tester);

    expect(find.text('No new birthdays'), findsOneWidget);
    expect(permissionRequests, 0);
  });

  testWidgets('vCard file: counters and import', (tester) async {
    final vcard = VCardSource(
      pickFile: () async => Uint8List.fromList(utf8.encode(_vcf)),
      parse: (bytes, {today}) async => parseVCardBytes(bytes, today: today),
      today: importToday,
    );
    await openPeople(tester, fakeServices(vcard: vcard));
    await chooseSource(tester, 'From a vCard file (.vcf)');

    expect(find.text('1 birthday found · 1 without birthday'), findsOneWidget);
    await tester.tap(find.text('Add 1 person'));
    await settleAsync(tester);

    expect(find.text('1 person added'), findsOneWidget);
    final friends = await tester.runAsync(FriendsService.getAllFriends);
    expect(friends!.single.importSource, 'vcard');
  });

  testWidgets('the import undo stays 12 s, longer than other undos', (
    tester,
  ) async {
    final services = fakeServices(
      contacts: FakeContactsSource(
        candidates: candidates,
        initialAccess: ContactsAccess.granted,
      ),
    );
    await openPeople(tester, services);
    await chooseSource(tester, 'From contacts');
    await tester.tap(find.text('Add 3\u00A0people'));
    await settleAsync(tester);

    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.duration, ImportResultReport.importUndoDuration);
    expect(bar.duration, const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 11));
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('the People tour waits until the undo offer is gone', (
    tester,
  ) async {
    final tourTitle = find.byKey(const ValueKey('tour_title'));
    final services = fakeServices(
      contacts: FakeContactsSource(
        candidates: candidates,
        initialAccess: ContactsAccess.granted,
      ),
    );
    await openPeople(tester, services);
    await TourProgressStore.reset();
    await TourProgressStore.markSeen(PeopleTour.emptyId);
    await chooseSource(tester, 'From contacts');
    await tester.tap(find.text('Add 3\u00A0people'));
    await settleAsync(tester);

    await tester.pump(PeopleTour.settleDelay * 2);
    await settleAsync(tester);
    expect(find.text('Undo'), findsOneWidget);
    expect(tourTitle, findsNothing, reason: 'would cover the undo offer');

    await tester.pump(ImportResultReport.importUndoDuration);
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    await tester.pump(PeopleTour.settleDelay);
    await settleAsync(tester);
    expect(tester.widget<Text>(tourTitle).data, 'Birthday reminders');
  });

  testWidgets('a picked file that is no vCard is reported, not reviewed', (
    tester,
  ) async {
    var cleared = 0;
    final vcard = VCardSource(
      pickFile: () async => Uint8List.fromList(utf8.encode('{"friends": []}')),
      parse: (bytes, {today}) async => parseVCardBytes(bytes, today: today),
      clearPickedFiles: () async => cleared++,
      today: importToday,
    );
    await openPeople(tester, fakeServices(vcard: vcard));
    await chooseSource(tester, 'From a vCard file (.vcf)');

    expect(find.text('This is not a vCard file (.vcf).'), findsOneWidget);
    expect(find.byType(ImportReviewScreen), findsNothing);
    expect(cleared, 1);
  });

  testWidgets('unreadable vCard file is reported', (tester) async {
    final vcard = VCardSource(
      pickFile: () async =>
          throw const VCardFileException(VCardFileProblem.tooLarge),
    );
    await openPeople(tester, fakeServices(vcard: vcard));
    await chooseSource(tester, 'From a vCard file (.vcf)');

    expect(find.text('This file is too large.'), findsOneWidget);
  });

  testWidgets('picked contacts (Android 17) go straight to the review', (
    tester,
  ) async {
    final picker = FakePickedContactsSource(
      supported: true,
      picked: [candidates.first],
    );
    final contacts = FakeContactsSource();
    await openPeople(tester, fakeServices(picker: picker, contacts: contacts));
    await chooseSource(tester, 'Choose contacts');

    expect(contacts.requestCount, 0);
    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('picked contacts without birthday are counted in the header', (
    tester,
  ) async {
    final picker = FakePickedContactsSource(
      supported: true,
      picked: [candidates.first],
      withoutBirthday: 2,
    );
    await openPeople(tester, fakeServices(picker: picker));
    await chooseSource(tester, 'Choose contacts');

    expect(find.textContaining('2 without birthday'), findsOneWidget);
  });

  testWidgets('picking only contacts without birthday shows the empty state', (
    tester,
  ) async {
    final picker = FakePickedContactsSource(
      supported: true,
      withoutBirthday: 3,
    );
    await openPeople(tester, fakeServices(picker: picker));
    await chooseSource(tester, 'Choose contacts');

    expect(find.text('No birthdays found'), findsOneWidget);
  });
}
