import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_launch_requests.dart';
import 'package:memento_mori_life_in_weeks/diagnostics_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/pending_notifications_section.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_screen.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';

import 'support/compass_test_app.dart';

Future<void> _pump(
  WidgetTester tester,
  PendingNotificationsLoader load, {
  String lang = 'en',
}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(lang),
      supportedLocales: const [Locale('en'), Locale('de')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: DiagnosticsScreen(loadPendingNotifications: load),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets [duration] pass in frames of 50 ms (the moment never settles).
Future<void> _frames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < duration; t += frame) {
    await tester.pump(frame);
  }
}

Future<void> _pumpInApp(WidgetTester tester) async {
  await initCompassTest();
  await WeekMomentStore.initialize();
  await pumpCompassApp(
    tester,
    DiagnosticsScreen(loadPendingNotifications: () async => []),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('lists pending notifications sorted by id', (tester) async {
    await _pump(
      tester,
      () async => const [
        PendingNotificationRequest(42, 'Anna', 'Turns 30 today', 'friend:a'),
        PendingNotificationRequest(7, null, null, null),
      ],
    );
    expect(find.text('Pending notifications (2)'), findsOneWidget);
    expect(find.text('Send Compass question now'), findsOneWidget);
    expect(find.text('(no title)'), findsOneWidget);
    expect(find.text('Turns 30 today\nPayload: friend:a'), findsOneWidget);
    final first = tester.getTopLeft(find.text('#7')).dy;
    final second = tester.getTopLeft(find.text('#42')).dy;
    expect(first, lessThan(second));
  });

  testWidgets('refresh reloads the list', (tester) async {
    var pending = <PendingNotificationRequest>[];
    var loads = 0;
    await _pump(tester, () async {
      loads++;
      return pending;
    });
    expect(find.text('No pending notifications'), findsOneWidget);
    pending = const [PendingNotificationRequest(1, 'Weekly', null, null)];
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.text('Weekly'), findsOneWidget);
  });

  testWidgets('shows an error when loading fails, in German', (tester) async {
    await _pump(tester, () async => throw Exception('no plugin'), lang: 'de');
    expect(find.text('Geplante Benachrichtigungen'), findsOneWidget);
    expect(
      find.text('Geplante Benachrichtigungen konnten nicht geladen werden'),
      findsOneWidget,
    );
    expect(find.byTooltip('Aktualisieren'), findsOneWidget);
  });

  group('weekly moment', () {
    testWidgets('lists both tiles', (tester) async {
      await _pumpInApp(tester);
      expect(
        find.byKey(const ValueKey('diagnostics_week_moment')),
        findsOneWidget,
      );
      expect(find.text('Show weekly moment now'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('diagnostics_week_moment_reset')),
        findsOneWidget,
      );
    });

    testWidgets('reset forgets the last shown reminder', (tester) async {
      await _pumpInApp(tester);
      await WeekMomentStore.markShown(DateTime(2026, 11, 15));
      await tester.tap(
        find.byKey(const ValueKey('diagnostics_week_moment_reset')),
      );
      await tester.pumpAndSettle();
      expect(WeekMomentStore.lastShown, isNull);
      expect(WeekMomentStore.since, WeekMomentStore.diagnosticsSince);
      expect(find.text('Weekly moment reset'), findsOneWidget);
    });

    testWidgets('shows the moment; "Plan the week" requests the Compass tab', (
      tester,
    ) async {
      CompassLaunchRequests.resetForTesting();
      addTearDown(CompassLaunchRequests.resetForTesting);
      var requests = 0;
      final subscription = CompassLaunchRequests.listen(() => requests++);
      addTearDown(subscription.cancel);
      await _pumpInApp(tester);

      await tester.tap(find.byKey(const ValueKey('diagnostics_week_moment')));
      await _frames(tester, const Duration(milliseconds: 600));
      expect(find.byType(WeekMomentScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('week_moment_skip')));
      await _frames(tester, const Duration(milliseconds: 800));
      await tester.tap(find.byKey(const ValueKey('week_moment_close_secondary')));
      await _frames(tester, const Duration(milliseconds: 800));
      await tester.tap(find.byKey(const ValueKey('week_moment_plan_primary')));
      await _frames(tester, const Duration(seconds: 1));
      expect(find.byType(WeekMomentScreen), findsNothing);
      expect(requests, 1);
    });
  });
}
