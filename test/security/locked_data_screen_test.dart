import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/security/ui/locked_data_app.dart';
import 'package:memento_mori_life_in_weeks/security/ui/locked_data_screen.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late int tryAgainCalls;
  late int startFreshCalls;
  late bool unlocks;
  late LockedDataReason stillLockedAs;
  late bool startFreshFails;

  setUp(() {
    tryAgainCalls = 0;
    startFreshCalls = 0;
    unlocks = false;
    stillLockedAs = LockedDataReason.locked;
    startFreshFails = false;
  });

  Future<void> pumpLocked(
    WidgetTester tester, {
    String language = 'en',
    LockedDataReason reason = LockedDataReason.locked,
  }) async {
    SharedPreferences.setMockInitialValues({'language': language});
    await SettingsService.initialize();
    await tester.pumpWidget(
      LockedDataApp(
        reason: reason,
        onTryAgain: () async {
          tryAgainCalls++;
          return unlocks ? null : stillLockedAs;
        },
        onStartFresh: () async {
          startFreshCalls++;
          if (startFreshFails) throw StateError('key not saved');
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  String t(String language, String key) =>
      AppLocalizations.valuesFor(language)[key]!;

  for (final language in AppLocalizations.supportedLanguages) {
    testWidgets('shows the explanation and both actions in $language',
        (tester) async {
      await pumpLocked(tester, language: language);

      for (final key in [
        'vault_locked_title',
        'vault_locked_body',
        'vault_locked_nothing_deleted',
        'vault_locked_unlock_hint',
        'vault_try_again',
        'vault_start_fresh',
      ]) {
        expect(find.text(t(language, key)), findsOneWidget, reason: key);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in AppLocalizations.supportedLanguages) {
    testWidgets('a transient issue offers only Try again in $language',
        (tester) async {
      await pumpLocked(
        tester,
        language: language,
        reason: LockedDataReason.unavailable,
      );

      expect(find.text(t(language, 'vault_try_again')), findsOneWidget);
      expect(find.text(t(language, 'vault_unavailable_hint')), findsOneWidget);
      expect(find.text(t(language, 'vault_start_fresh')), findsNothing);
      expect(find.text(t(language, 'vault_locked_unlock_hint')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Start fresh appears once Try again finds a real lock',
      (tester) async {
    await pumpLocked(tester, reason: LockedDataReason.unavailable);
    expect(find.text(t('en', 'vault_start_fresh')), findsNothing);

    await tester.tap(find.text(t('en', 'vault_try_again')));
    await tester.pumpAndSettle();

    expect(find.text(t('en', 'vault_still_locked')), findsOneWidget);
    expect(find.text(t('en', 'vault_start_fresh')), findsOneWidget);
  });

  testWidgets('Start fresh disappears when the issue turns transient',
      (tester) async {
    stillLockedAs = LockedDataReason.unavailable;
    await pumpLocked(tester);
    expect(find.text(t('en', 'vault_start_fresh')), findsOneWidget);

    await tester.tap(find.text(t('en', 'vault_try_again')));
    await tester.pumpAndSettle();

    expect(find.text(t('en', 'vault_start_fresh')), findsNothing);
    expect(find.text(t('en', 'vault_unavailable_hint')), findsOneWidget);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLocked(tester, language: 'de');

    expect(tester.takeException(), isNull);
    expect(find.text(t('de', 'vault_try_again')).hitTestable(), findsOneWidget);
  });

  testWidgets('Try again calls back and says when it is still locked',
      (tester) async {
    await pumpLocked(tester);

    await tester.tap(find.text(t('en', 'vault_try_again')));
    await tester.pumpAndSettle();

    expect(tryAgainCalls, 1);
    expect(find.text(t('en', 'vault_still_locked')), findsOneWidget);
  });

  testWidgets('Try again shows no message once the data opens',
      (tester) async {
    unlocks = true;
    await pumpLocked(tester);

    await tester.tap(find.text(t('en', 'vault_try_again')));
    await tester.pumpAndSettle();

    expect(tryAgainCalls, 1);
    expect(find.text(t('en', 'vault_still_locked')), findsNothing);
  });

  testWidgets('Start fresh asks first; cancelling deletes nothing',
      (tester) async {
    await pumpLocked(tester);

    await tester.tap(find.text(t('en', 'vault_start_fresh')));
    await tester.pumpAndSettle();

    expect(find.byType(StartFreshDialog), findsOneWidget);
    expect(find.text(t('en', 'vault_start_fresh_body')), findsOneWidget);
    expect(startFreshCalls, 0);

    await tester.tap(find.text(t('en', 'vault_start_fresh_cancel')));
    await tester.pumpAndSettle();

    expect(find.byType(StartFreshDialog), findsNothing);
    expect(startFreshCalls, 0);
  });

  testWidgets('Start fresh runs only after confirming', (tester) async {
    await pumpLocked(tester);

    await tester.tap(find.text(t('en', 'vault_start_fresh')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('en', 'vault_start_fresh_confirm')));
    await tester.pumpAndSettle();

    expect(startFreshCalls, 1);
    expect(find.text(t('en', 'vault_start_fresh_failed')), findsNothing);
  });

  testWidgets('a failed fresh start says so and keeps the screen',
      (tester) async {
    startFreshFails = true;
    await pumpLocked(tester);

    await tester.tap(find.text(t('en', 'vault_start_fresh')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('en', 'vault_start_fresh_confirm')));
    await tester.pumpAndSettle();

    expect(startFreshCalls, 1);
    expect(find.text(t('en', 'vault_start_fresh_failed')), findsOneWidget);
    expect(find.text(t('en', 'vault_try_again')), findsOneWidget);
  });
}
