import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/compass_setup_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_launches.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_screen.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';
import 'package:memento_mori_life_in_weeks/widget_launches.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/compass_test_app.dart';

/// Sunday 15 Nov 2026: the weekly reminder fires at 19:00.
final DateTime _reminderDay = DateTime(2026, 11, 15);
final DateTime _sundayEvening = DateTime(2026, 11, 15, 20);

/// Wednesday after it: past the catch-up window.
final DateTime _wednesday = DateTime(2026, 11, 18, 20);

final Finder _moment = find.byType(WeekMomentScreen);
final Finder _setup = find.byType(CompassSetupScreen);

class _NoWidgetLaunches implements WidgetLaunches {
  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) =>
      const Stream<void>.empty().listen(null);
}

/// Notification taps driven by the test.
class _FakeNotificationLaunches implements NotificationLaunches {
  final StreamController<NotificationLaunch> taps =
      StreamController<NotificationLaunch>.broadcast();

  @override
  StreamSubscription<void> listen(void Function(NotificationLaunch) onLaunch) =>
      taps.stream.listen(onLaunch);
}

/// Weekly reminders, the feature present since before the reminder, the
/// Compass setup already auto-opened (unless [setupDue]).
Future<void> _init({
  bool onboarded = false,
  bool setupDue = false,
  Map<String, Object> extra = const {},
}) async {
  await initCompassTest(extra: {
    SettingsService.reminderRhythmKey: 'weekly',
    WeekMomentStore.sinceKey: '2026-11-01',
    if (onboarded) 'onboarding_completed': true,
    if (!setupDue) 'compass_setup': '{"autoOpened":true}',
    ...extra,
  });
  await WeekMomentStore.initialize();
}

Future<void> _removeBirthDate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('birth_date');
  await SettingsService.initialize();
}

/// Pumps the shell at a Pixel 5's size; the moment never settles, so
/// frames are pumped instead of settling.
Future<void> _pumpShell(
  WidgetTester tester, {
  NotificationLaunches notifications = const PlatformNotificationLaunches(),
  DateTime? clock,
  DateTime Function()? clockOf,
}) async {
  tester.view.physicalSize = const Size(393, 851) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  final time = clock ?? _wednesday;
  await tester.pumpWidget(AppSettingsScope(
    controller: controller,
    child: MaterialApp(
      theme: controller.lightTheme,
      locale: controller.locale,
      supportedLocales: [
        for (final code in AppLocalizations.supportedLanguages) Locale(code),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: AppShell(
        now: DateTime(time.year, time.month, time.day),
        clock: clockOf ?? () => time,
        widgetLaunches: _NoWidgetLaunches(),
        notificationLaunches: notifications,
      ),
    ),
  ));
  await _frames(tester, const Duration(milliseconds: 300));
}

/// Lets [duration] pass in frames of 50 ms.
Future<void> _frames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < duration; t += frame) {
    await tester.pump(frame);
  }
}

int _selectedTab(WidgetTester tester) => tester
    .widget<NavigationBar>(find.byType(NavigationBar, skipOffstage: false))
    .selectedIndex;

Future<void> _openTab(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await _frames(tester, const Duration(milliseconds: 500));
}

/// Skips to the final act and taps its [key] button, then lets the fade
/// and the shell's tab switch run.
Future<void> _leaveMoment(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(const ValueKey('week_moment_skip')));
  await _frames(tester, const Duration(milliseconds: 800));
  // Step 1 of the card: go on without writing, then leave from step 2.
  await tester.tap(find.byKey(const ValueKey('week_moment_close_secondary')));
  await _frames(tester, const Duration(milliseconds: 800));
  await tester.tap(find.byKey(ValueKey(key)));
  await _frames(tester, const Duration(seconds: 1));
}

Future<void> _tapReminder(
    WidgetTester tester, _FakeNotificationLaunches notifications) async {
  notifications.taps.add(CompassLaunch(reminderDay: _reminderDay));
  await _frames(tester, const Duration(milliseconds: 600));
}

void _pushScreen(WidgetTester tester, String text) {
  Navigator.of(tester.element(find.byType(NavigationBar))).push(
    MaterialPageRoute<void>(builder: (_) => Scaffold(body: Text(text))),
  );
}

Future<void> _resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('reminder tap', () {
    testWidgets('shows the moment, then Continue opens Compass',
        (tester) async {
      await _init();
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, notifications: notifications);

      await _tapReminder(tester, notifications);
      expect(_moment, findsOneWidget);
      expect(_selectedTab(tester), 0);
      expect(WeekMomentStore.lastShown, _reminderDay);

      await _leaveMoment(tester, 'week_moment_plan_primary');
      expect(_moment, findsNothing);
      expect(_selectedTab(tester), 1);
    });

    testWidgets('Close stays on the current tab', (tester) async {
      await _init();
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, notifications: notifications);
      await _openTab(tester, Icons.people_outline_rounded);

      await _tapReminder(tester, notifications);
      expect(_moment, findsOneWidget);
      await _leaveMoment(tester, 'week_moment_plan_secondary');
      expect(_moment, findsNothing);
      expect(_selectedTab(tester), 2);
    });

    testWidgets('closes screens above the shell first', (tester) async {
      await _init();
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, notifications: notifications);
      _pushScreen(tester, 'Friend detail');
      await _frames(tester, const Duration(milliseconds: 500));

      await _tapReminder(tester, notifications);
      expect(find.text('Friend detail'), findsNothing);
      expect(_moment, findsOneWidget);
    });

    for (final (name, setUp) in <(String, Future<void> Function())>[
      ('without a birth date', _removeBirthDate),
      ('when switched off', () => WeekMomentStore.setEnabled(false)),
      ('when already shown', () => WeekMomentStore.markShown(_reminderDay)),
    ]) {
      testWidgets('opens Compass straight away $name', (tester) async {
        await _init();
        await setUp();
        final notifications = _FakeNotificationLaunches();
        await _pumpShell(tester, notifications: notifications);

        await _tapReminder(tester, notifications);
        expect(_moment, findsNothing);
        expect(_selectedTab(tester), 1);
      });
    }

    testWidgets('the tap that launched the app shows the moment',
        (tester) async {
      await _init();
      NotificationTaps.resetForTesting();
      addTearDown(NotificationTaps.resetForTesting);
      NotificationTaps.report('compass:2026-11-15');
      await _pumpShell(tester);
      await _frames(tester, const Duration(milliseconds: 500));
      expect(_moment, findsOneWidget);

      await _leaveMoment(tester, 'week_moment_plan_primary');
      expect(_selectedTab(tester), 1);
    });

    testWidgets('a due Compass setup opens only after the moment',
        (tester) async {
      await _init(setupDue: true);
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, notifications: notifications);

      await _tapReminder(tester, notifications);
      expect(_moment, findsOneWidget);
      expect(_setup, findsNothing);

      await _leaveMoment(tester, 'week_moment_plan_primary');
      expect(_moment, findsNothing);
      expect(_selectedTab(tester), 1);
      expect(_setup, findsOneWidget);
    });
  });

  group('catch-up', () {
    testWidgets('shows once on Sunday evening, not again on resume',
        (tester) async {
      await _init(onboarded: true);
      await _pumpShell(tester, clock: _sundayEvening);
      expect(_moment, findsNothing);

      await _frames(tester, const Duration(milliseconds: 700));
      expect(_moment, findsOneWidget);
      expect(WeekMomentStore.lastShown, _reminderDay);
      await _leaveMoment(tester, 'week_moment_plan_secondary');
      expect(_moment, findsNothing);
      expect(_selectedTab(tester), 0);

      await _resume(tester);
      await _frames(tester, const Duration(seconds: 1));
      expect(_moment, findsNothing);
    });

    testWidgets('Continue opens Compass', (tester) async {
      await _init(onboarded: true);
      await _pumpShell(tester, clock: _sundayEvening);
      await _frames(tester, const Duration(milliseconds: 700));
      expect(_moment, findsOneWidget);

      await _leaveMoment(tester, 'week_moment_plan_primary');
      expect(_selectedTab(tester), 1);
    });

    testWidgets('shows when only an earlier reminder was shown',
        (tester) async {
      await _init(onboarded: true);
      await WeekMomentStore.markShown(DateTime(2026, 11, 8));
      await _pumpShell(tester, clock: _sundayEvening);
      await _frames(tester, const Duration(milliseconds: 700));
      expect(_moment, findsOneWidget);
    });

    testWidgets('shows on resume once it became due', (tester) async {
      await _init(onboarded: true);
      // Saturday: last Sunday's reminder is past its window.
      var now = DateTime(2026, 11, 14, 12);
      await _pumpShell(tester, clockOf: () => now);
      await _frames(tester, const Duration(seconds: 1));
      expect(_moment, findsNothing);

      now = _sundayEvening;
      await _resume(tester);
      await _frames(tester, const Duration(milliseconds: 500));
      expect(_moment, findsNothing, reason: 'waits for the settle pause');
      await _frames(tester, const Duration(milliseconds: 500));
      expect(_moment, findsOneWidget);
    });

    testWidgets('not before onboarding finished', (tester) async {
      await _init();
      await _pumpShell(tester, clock: _sundayEvening);
      await _frames(tester, const Duration(seconds: 1));
      expect(_moment, findsNothing);
      expect(WeekMomentStore.lastShown, isNull);
    });

    testWidgets('not over a pushed route', (tester) async {
      await _init(onboarded: true);
      await _pumpShell(tester, clock: _sundayEvening);
      _pushScreen(tester, 'A sheet');
      await _frames(tester, const Duration(seconds: 1));
      expect(find.text('A sheet'), findsOneWidget);
      expect(_moment, findsNothing);
      expect(WeekMomentStore.lastShown, isNull);
    });

    testWidgets('a reminder tap meanwhile wins', (tester) async {
      await _init(onboarded: true);
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester,
          notifications: notifications, clock: _sundayEvening);
      notifications.taps.add(CompassLaunch(reminderDay: _reminderDay));
      await _frames(tester, const Duration(seconds: 1));
      expect(_moment, findsOneWidget);

      await _leaveMoment(tester, 'week_moment_plan_primary');
      expect(_moment, findsNothing);
      expect(_selectedTab(tester), 1);
      await _frames(tester, const Duration(seconds: 1));
      expect(_moment, findsNothing);
    });
  });
}
