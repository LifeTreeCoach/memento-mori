import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people_import/contacts_source.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/contacts_explainer_sheet.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/contacts_import_screen.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_candidate_row.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_model.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_screen.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_source_sheet.dart';
import 'package:memento_mori_life_in_weeks/people_import/vcard_parser.dart';

import '../../support/fake_contacts_source.dart';
import 'import_ui_helpers.dart';

/// Opens [sheet] from a button, as the app does.
class _SheetLauncher extends StatelessWidget {
  const _SheetLauncher(this.sheet);

  final Widget sheet;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => sheet,
        ),
        child: const Text('open'),
      ),
    ),
  );
}

ImportFound _found(int count, {ContactsAccess? access, bool vcard = false}) {
  return ImportFound(
    candidates: [
      for (var i = 0; i < count; i++)
        contactCandidate(
          'Person with a rather long name number $i',
          1 + i % 12,
          1 + i % 28,
          year: i.isEven ? 1950 + i % 60 : null,
        ),
    ],
    access: access,
    vcard: vcard
        ? const VCardParseResult(
            candidates: [],
            cardCount: 400,
            withoutBirthday: 120,
            invalidBirthday: 3,
            withoutName: 2,
          )
        : null,
  );
}

void main() {
  for (final lang in AppLocalizations.supportedLanguages) {
    group('no overflow at 393x851 ($lang)', () {
      for (final picker in [false, true]) {
        testWidgets('source sheet (picker: $picker)', (tester) async {
          await pumpImportApp(
            tester,
            _SheetLauncher(ImportSourceSheet(pickerSupported: picker)),
            services: fakeServices(),
            lang: lang,
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('explainer', (tester) async {
        await pumpImportApp(
          tester,
          const _SheetLauncher(ContactsExplainerSheet()),
          services: fakeServices(),
          lang: lang,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('denied state', (tester) async {
        await initImportPrefs(const []);
        await pumpImportApp(
          tester,
          ContactsImportScreen(
            services: fakeServices(contacts: FakeContactsSource()),
            initialAccess: ContactsAccess.permanentlyDenied,
          ),
          services: fakeServices(),
          lang: lang,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('review with notes, counters and a year field', (
        tester,
      ) async {
        await initImportPrefs([savedFriend('Someone', DateTime(1990, 1, 1))]);
        final found = _found(12, access: ContactsAccess.limited, vcard: true);
        await pumpImportApp(
          tester,
          ImportReviewScreen(load: () async => found, services: fakeServices()),
          services: fakeServices(),
          lang: lang,
        );
        await settleAsync(tester);
        final badge = find.byIcon(Icons.add).first;
        await tester.ensureVisible(badge);
        await tester.tap(badge);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ImportCandidateRow), findsWidgets);
      });
    });
  }

  testWidgets('300 candidates are built lazily and quickly', (tester) async {
    await initImportPrefs(const []);
    final found = _found(300);
    final watch = Stopwatch()..start();
    await pumpImportApp(
      tester,
      ImportReviewScreen(load: () async => found, services: fakeServices()),
      services: fakeServices(),
    );
    await settleAsync(tester);
    watch.stop();

    final built = find.byType(ImportCandidateRow).evaluate().length;
    expect(built, greaterThan(0));
    expect(built, lessThan(40));
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  });
}
