import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_applier.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_plan.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_candidate_row.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_model.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_screen.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_services.dart';
import 'package:memento_mori_life_in_weeks/people_import/vcard_source.dart';

import '../../support/fake_contacts_source.dart';
import 'import_ui_helpers.dart';

/// Pushes the review for [found]; the popped outcome lands in [popped].
class _Launcher extends StatelessWidget {
  const _Launcher({required this.found, required this.popped});

  final ImportFound found;
  final List<ImportOutcome?> popped;

  @override
  Widget build(BuildContext context) {
    final services = ImportServicesScope.of(context);
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async => popped.add(
            await Navigator.of(context).push<ImportOutcome>(
              MaterialPageRoute(
                builder: (_) => ImportReviewScreen(
                  load: () async => found,
                  services: services,
                ),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}

/// An applier whose [apply] finishes only when the test says so.
class _HeldApplier extends ImportApplier {
  final Completer<ImportOutcome> release = Completer<ImportOutcome>();
  ImportPlan? plan;

  @override
  Future<ImportOutcome> apply(ImportPlan plan) {
    this.plan = plan;
    return release.future;
  }
}

final Finder _listScrollable = find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  final saved = [
    savedFriend('Ben', DateTime(1980, 3, 1)), // already there
    savedFriend('Cleo', DateTime(1995, 7, 7)), // date differs
    savedFriend('Dora', DateTime(2000, 9, 9), hasYear: false), // year addable
  ];
  final candidates = [
    contactCandidate('Anna', 5, 1, year: 1990, photo: true),
    contactCandidate('Emil', 2, 14), // no year
    contactCandidate('Ben', 3, 1, year: 1980),
    contactCandidate('Cleo', 8, 8, year: 1995),
    contactCandidate('Dora', 9, 9, year: 1970),
  ];

  Future<List<ImportOutcome?>> openReview(
    WidgetTester tester, {
    List<BirthdayCandidate>? found,
    ImportServices? services,
  }) async {
    final popped = <ImportOutcome?>[];
    await initImportPrefs(saved);
    await pumpImportApp(
      tester,
      _Launcher(
        found: ImportFound(candidates: found ?? candidates),
        popped: popped,
      ),
      services: services ?? fakeServices(),
    );
    await tester.tap(find.text('open'));
    await settleAsync(tester);
    return popped;
  }

  testWidgets('header, sections and default selection', (tester) async {
    await openReview(tester);

    expect(find.text('5 birthdays found · 1 already there'), findsOneWidget);
    expect(find.text('NEW · 2'), findsOneWidget);
    expect(find.text('DIFFERENT DATE · 1'), findsOneWidget);
    expect(find.text('ADD YEAR · 1'), findsOneWidget);
    expect(find.text('ALREADY THERE · 1'), findsOneWidget);
    expect(find.text('7 Jul 1995 → 8 Aug 1995'), findsOneWidget);
    // Ben stays collapsed; new + year addable are ticked, the date is opt-in.
    expect(find.text('Ben'), findsNothing);
    expect(find.text('Add 3 people'), findsOneWidget);
    expect(find.text('Import photos'), findsOneWidget);
  });

  testWidgets('already there expands but cannot be ticked', (tester) async {
    await openReview(tester);
    final toggle = find.byKey(const ValueKey('import-already-toggle'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ben'),
      200,
      scrollable: _listScrollable,
    );
    await tester.ensureVisible(find.text('Ben'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ben'));
    await tester.pumpAndSettle();

    expect(find.text('Add 3 people'), findsOneWidget);
  });

  testWidgets('search, none and all', (tester) async {
    await openReview(tester);
    await tester.enterText(find.byType(TextField).first, 'emi');
    await tester.pumpAndSettle();

    expect(find.byType(ImportCandidateRow), findsOneWidget);
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(find.text('Add 2 people'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(find.text('Nobody selected'), findsOneWidget);
    final apply = tester.widget<FilledButton>(
      find.byKey(const ValueKey('import-apply')),
    );
    expect(apply.onPressed, isNull);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Add 4 people'), findsOneWidget);
  });

  testWidgets('the button shows progress while the import is saved', (
    tester,
  ) async {
    final applier = _HeldApplier();
    final popped = await openReview(
      tester,
      services: ImportServices(
        contacts: FakeContactsSource(),
        picker: FakePickedContactsSource(),
        vcard: VCardSource(pickFile: () async => null),
        applier: applier,
        requestNotificationPermission: () async => true,
        today: importToday,
      ),
    );
    final apply = find.byKey(const ValueKey('import-apply'));
    await tester.tap(apply);
    await tester.pump();

    expect(
      find.descendant(
        of: apply,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);
    expect(popped, isEmpty);

    applier.release.complete(
      const ImportOutcome(addedIds: ['x'], previous: []),
    );
    await tester.pumpAndSettle();
    expect(popped.single!.addedCount, 1);
    expect(applier.plan!.newFriends, hasLength(2));
  });

  testWidgets('year field validates and is applied', (tester) async {
    final popped = await openReview(tester);
    expect(find.text('no year'), findsOneWidget);
    await tester.tap(find.text('no year'));
    await tester.pumpAndSettle();

    final yearField = find.widgetWithText(TextField, 'Year');
    await tester.enterText(yearField, '2099');
    await tester.pumpAndSettle();
    expect(find.text('Not a valid year'), findsOneWidget);

    await tester.enterText(yearField, '1988');
    await tester.pumpAndSettle();
    expect(find.text('Not a valid year'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('import-apply')));
    await settleAsync(tester);

    expect(popped.single!.addedCount, 2);
    expect(popped.single!.updatedCount, 1); // Dora's year
    final friends = await tester.runAsync(FriendsService.getAllFriends);
    final emil = friends!.firstWhere((f) => f.name == 'Emil');
    expect(emil.hasBirthYear, isTrue);
    expect(emil.birthDate, DateTime(1988, 2, 14));
  });

  testWidgets('group for everyone and photos switch', (tester) async {
    final popped = await openReview(tester);
    await tester.tap(find.text('Import photos'));
    await tester.pumpAndSettle();
    final photos = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('import-photos-switch')),
    );
    expect(photos.value, isFalse);
    await tester.tap(find.text('Group for everyone (optional)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('import-group-tile')),
        matching: find.byType(TextField),
      ),
      'Imported',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-apply')));
    await settleAsync(tester);

    expect(popped.single!.addedCount, 2);
    final friends = await tester.runAsync(FriendsService.getAllFriends);
    final anna = friends!.firstWhere((f) => f.name == 'Anna');
    expect(anna.groupName, 'Imported');
    expect(anna.avatarPath, isNull);
    expect(anna.importSource, 'contacts');
  });

  testWidgets('no photo switch when nobody has a photo', (tester) async {
    await openReview(
      tester,
      found: [contactCandidate('Emil', 2, 14), contactCandidate('Finn', 4, 4)],
    );

    expect(find.text('Add 2\u00A0people'), findsOneWidget);
    expect(find.byKey(const ValueKey('import-photos-switch')), findsNothing);
    expect(find.byKey(const ValueKey('import-group-tile')), findsOneWidget);
  });

  testWidgets('no options when everyone is already there', (tester) async {
    await openReview(
      tester,
      found: [contactCandidate('Ben', 3, 1, year: 1980, photo: true)],
    );

    expect(find.text('1\u00A0birthday found · 1 already there'), findsOneWidget);
    expect(find.byKey(const ValueKey('import-photos-switch')), findsNothing);
    expect(find.byKey(const ValueKey('import-group-tile')), findsNothing);
    expect(find.byType(TextField), findsNothing, reason: 'no search field');
    expect(find.text('All'), findsNothing);
    expect(find.text('None'), findsNothing);
  });

  testWidgets('no photo switch when only "already there" has a photo', (
    tester,
  ) async {
    await openReview(
      tester,
      found: [
        contactCandidate('Ben', 3, 1, year: 1980, photo: true),
        contactCandidate('Emil', 2, 14),
      ],
    );

    expect(find.text('Add 1\u00A0person'), findsOneWidget);
    expect(find.byKey(const ValueKey('import-photos-switch')), findsNothing);
    expect(find.byType(TextField), findsWidgets, reason: 'search shown');
  });

  testWidgets('a valid year replaces the "no year" badge', (tester) async {
    await openReview(tester);
    final emilDate = find.byWidgetPredicate(
      (widget) => widget is Text && (widget.data ?? '').contains('1988'),
    );
    await tester.tap(find.text('no year'));
    await tester.pumpAndSettle();

    final yearField = find.widgetWithText(TextField, 'Year');
    await tester.enterText(yearField, '1988');
    await tester.pumpAndSettle();
    expect(find.text('no year'), findsNothing);
    expect(emilDate, findsOneWidget);

    await tester.enterText(yearField, '2099');
    await tester.pumpAndSettle();
    expect(find.text('no year'), findsOneWidget);
    expect(emilDate, findsNothing);

    await tester.enterText(yearField, '');
    await tester.pumpAndSettle();
    expect(find.text('no year'), findsOneWidget);
  });

  testWidgets('two updates of one person exclude each other', (tester) async {
    BirthdayCandidate cleo(String id, int month) => BirthdayCandidate(
      id: id,
      displayName: 'Cleo',
      month: month,
      day: 8,
      year: 1995,
      source: ImportSource.contacts,
      sourceId: 'src-$id',
    );
    await openReview(tester, found: [cleo('c1', 8), cleo('c2', 9)]);
    expect(find.text('DIFFERENT DATE · 2'), findsOneWidget);

    Checkbox box(String id) => tester.widget<Checkbox>(
      find.descendant(
        of: find.byKey(ValueKey('import-row-$id')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('import-row-c1')));
    await tester.pumpAndSettle();
    expect(box('c1').value, isTrue);

    await tester.tap(find.byKey(const ValueKey('import-row-c2')));
    await tester.pumpAndSettle();
    expect(box('c2').value, isTrue);
    expect(box('c1').value, isFalse);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(box('c2').value, isTrue);
    expect(box('c1').value, isFalse);
  });
}
