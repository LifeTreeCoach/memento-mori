import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/security/personal_store.dart';
import 'package:memento_mori_life_in_weeks/security/ui/unsaved_changes_notice.dart';

/// Only the unsaved-changes part of a store; `VaultPersonalStore`'s own
/// tracking is covered in `vault_personal_store_test.dart`.
class _FakeStore extends PersonalStore {
  final ValueNotifier<bool> unsaved = ValueNotifier(false);
  bool retrySucceeds = true;
  int retries = 0;

  @override
  ValueListenable<bool> get hasUnsavedChanges => unsaved;

  @override
  Future<bool> retryUnsaved() async {
    retries++;
    if (retrySucceeds) unsaved.value = false;
    return retrySucceeds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeStore store;

  String en(String key) => AppLocalizations.valuesFor('en')[key]!;

  Future<void> pumpNotice(WidgetTester tester) async {
    store = _FakeStore();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            UnsavedChangesNotice(store: store, child: child!),
        home: const Scaffold(body: Text('home')),
      ),
    );
  }

  Future<void> failSave(WidgetTester tester) async {
    store.unsaved.value = true;
    await tester.pumpAndSettle();
  }

  testWidgets('a failed save shows the message once', (tester) async {
    await pumpNotice(tester);
    await failSave(tester);
    // More failing writes while it is visible: no second message.
    store.unsaved.value = false;
    store.unsaved.value = true;
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text(en('vault_unsaved_message')), findsOneWidget);
    expect(find.text(en('vault_unsaved_retry')), findsOneWidget);
  });

  testWidgets('"Try again" retries and confirms the save', (tester) async {
    await pumpNotice(tester);
    await failSave(tester);

    await tester.tap(find.text(en('vault_unsaved_retry')));
    await tester.pumpAndSettle();

    expect(store.retries, 1);
    expect(find.text(en('vault_unsaved_saved')), findsOneWidget);
    expect(find.text(en('vault_unsaved_message')), findsNothing);
  });

  testWidgets('"Try again" failing again shows the message again',
      (tester) async {
    await pumpNotice(tester);
    await failSave(tester);
    store.retrySucceeds = false;

    await tester.tap(find.text(en('vault_unsaved_retry')));
    await tester.pumpAndSettle();

    expect(store.retries, 1);
    expect(find.text(en('vault_unsaved_message')), findsOneWidget);
    expect(find.text(en('vault_unsaved_saved')), findsNothing);
  });

  testWidgets('a later successful save hides the message', (tester) async {
    await pumpNotice(tester);
    await failSave(tester);

    store.unsaved.value = false;
    await tester.pumpAndSettle();

    expect(find.text(en('vault_unsaved_message')), findsNothing);
  });

  testWidgets('comes back after another snackbar pushed it aside',
      (tester) async {
    await pumpNotice(tester);
    await failSave(tester);
    ScaffoldMessenger.of(tester.element(find.text('home')))
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Undo offer')));
    await tester.pumpAndSettle();
    expect(find.text('Undo offer'), findsOneWidget);
    expect(find.text(en('vault_unsaved_message')), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(en('vault_unsaved_message')), findsOneWidget);
  });

  testWidgets('stays away once dismissed by the user', (tester) async {
    await pumpNotice(tester);
    await failSave(tester);

    await tester.drag(
      find.text(en('vault_unsaved_message')),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();

    expect(find.text(en('vault_unsaved_message')), findsNothing);
  });
}
