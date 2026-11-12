import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/enhanced_friends_screen.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_source_sheet.dart';
import 'package:memento_mori_life_in_weeks/settings/data_section.dart';

import 'import_ui_helpers.dart';

void main() {
  testWidgets('People empty state offers the import', (tester) async {
    await initImportPrefs(const []);
    await pumpImportApp(
      tester,
      EnhancedFriendsScreen(now: importToday),
      services: fakeServices(),
    );

    await tester.tap(find.text('Import birthdays'));
    await settleAsync(tester);

    expect(find.byType(ImportSourceSheet), findsOneWidget);
    expect(find.text('From contacts'), findsOneWidget);
    expect(find.text('From a vCard file (.vcf)'), findsOneWidget);
    expect(
      find.text(
        'Everything stays on your device. The app has no internet access.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('People overflow menu offers the import', (tester) async {
    await initImportPrefs([savedFriend('Anna', DateTime(1990, 5, 1))]);
    await pumpImportApp(
      tester,
      EnhancedFriendsScreen(now: importToday),
      services: fakeServices(),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import birthdays'));
    await settleAsync(tester);

    expect(find.byType(ImportSourceSheet), findsOneWidget);
  });

  testWidgets('Settings > Data offers the import', (tester) async {
    await initImportPrefs(const []);
    await pumpImportApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: DataSection())),
      services: fakeServices(),
    );

    await tester.tap(find.text('Import birthdays'));
    await settleAsync(tester);

    expect(find.byType(ImportSourceSheet), findsOneWidget);
  });

  group('system contact picker', () {
    Future<void> openSheet(WidgetTester tester, {required bool picker}) async {
      await initImportPrefs(const []);
      await pumpImportApp(
        tester,
        EnhancedFriendsScreen(now: importToday),
        services: fakeServices(
          picker: FakePickedContactsSource(supported: picker),
        ),
      );
      await tester.tap(find.text('Import birthdays'));
      await settleAsync(tester);
    }

    testWidgets('splits the contacts option when the picker exists', (
      tester,
    ) async {
      await openSheet(tester, picker: true);

      expect(find.text('Choose contacts'), findsOneWidget);
      expect(find.text('Search all contacts with a birthday'), findsOneWidget);
      expect(find.text('From contacts'), findsNothing);
      expect(find.text('Recommended'), findsOneWidget);
    });

    testWidgets('keeps one contacts option without the picker', (tester) async {
      await openSheet(tester, picker: false);

      expect(find.text('Choose contacts'), findsNothing);
      expect(find.text('Search all contacts with a birthday'), findsNothing);
      expect(find.text('From contacts'), findsOneWidget);
    });
  });
}
