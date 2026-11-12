import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail_screen.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_launches.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';
import 'package:memento_mori_life_in_weeks/widget_launches.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _today = DateTime(2026, 11, 2);
const String _widgetUri = 'mementomori://widget?homeWidget';
const MethodChannel _channel = MethodChannel('home_widget');
const EventChannel _clicks = EventChannel('home_widget/updates');

/// Widget taps driven by the test.
class _FakeWidgetLaunches implements WidgetLaunches {
  final StreamController<void> taps = StreamController<void>.broadcast();

  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) =>
      taps.stream.listen((_) => onLaunch());
}

/// Notification taps driven by the test.
class _FakeNotificationLaunches implements NotificationLaunches {
  final StreamController<NotificationLaunch> taps =
      StreamController<NotificationLaunch>.broadcast();

  @override
  StreamSubscription<void> listen(void Function(NotificationLaunch) onLaunch) =>
      taps.stream.listen(onLaunch);
}

Friend _friend(String id, String name) => Friend(
      id: id,
      name: name,
      birthDate: DateTime(1985, 4, 12),
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    );

Future<void> _init() async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': DateTime(1990, 11, 17).toIso8601String(),
    'language': 'en',
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': '[]',
    // The Compass setup already opened by itself once.
    'compass_setup': '{"autoOpened":true}',
    // These tests check the direct routing; the weekly moment has its own.
    WeekMomentStore.enabledKey: false,
  });
  CompassSetupStore.clearCacheForTesting();
  await WeekMomentStore.initialize();
  PackageInfo.setMockInitialValues(
    appName: 'Memento Mori',
    packageName: 'test',
    version: '1.2.3',
    buildNumber: '45',
    buildSignature: '',
  );
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
}

Future<void> _pumpShell(
  WidgetTester tester,
  WidgetLaunches launches, {
  NotificationLaunches notificationLaunches =
      const PlatformNotificationLaunches(),
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1080, 12000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(AppSettingsScope(
    controller: controller,
    child: MaterialApp(
      theme: controller.lightTheme,
      locale: controller.locale,
      supportedLocales: const [Locale('en'), Locale('de')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: AppShell(
        now: _today,
        widgetLaunches: launches,
        notificationLaunches: notificationLaunches,
      ),
    ),
  ));
  settle ? await tester.pumpAndSettle() : await _pumpFrames(tester);
}

/// The friend detail keeps animating, so it never settles: pump a while.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// The shell's selected tab, also while a screen covers it.
int _selectedTab(WidgetTester tester) => tester
    .widget<NavigationBar>(find.byType(NavigationBar, skipOffstage: false))
    .selectedIndex;

void _pushScreen(WidgetTester tester, String text) {
  Navigator.of(tester.element(find.byType(NavigationBar))).push(
    MaterialPageRoute<void>(builder: (_) => Scaffold(body: Text(text))),
  );
}

void main() {
  group('AppShell', () {
    testWidgets('a widget tap shows the Life tab', (tester) async {
      await _init();
      final launches = _FakeWidgetLaunches();
      await _pumpShell(tester, launches);
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), 3);

      launches.taps.add(null);
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), 0);
    });

    testWidgets('a widget tap closes screens pushed above the shell',
        (tester) async {
      await _init();
      final launches = _FakeWidgetLaunches();
      await _pumpShell(tester, launches);
      await tester.tap(find.text('People').last);
      await tester.pumpAndSettle();
      _pushScreen(tester, 'Friend detail');
      await tester.pumpAndSettle();
      expect(find.text('Friend detail'), findsOneWidget);

      launches.taps.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Friend detail'), findsNothing);
      expect(_selectedTab(tester), 0);
    });

    testWidgets('stops listening when disposed', (tester) async {
      await _init();
      final launches = _FakeWidgetLaunches();
      await _pumpShell(tester, launches);
      expect(launches.taps.hasListener, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(launches.taps.hasListener, isFalse);
    });
  });

  group('AppShell notification taps', () {
    testWidgets('a Compass notification tap shows the Compass tab',
        (tester) async {
      await _init();
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, _FakeWidgetLaunches(),
          notificationLaunches: notifications);
      await tester.tap(find.text('People').last);
      await tester.pumpAndSettle();
      _pushScreen(tester, 'Friend detail');
      await tester.pumpAndSettle();

      notifications.taps.add(const CompassLaunch());
      await tester.pumpAndSettle();
      expect(find.text('Friend detail'), findsNothing);
      expect(_selectedTab(tester), 1);
    });

    testWidgets('a dated Compass tap shows the Compass tab too',
        (tester) async {
      await _init();
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, _FakeWidgetLaunches(),
          notificationLaunches: notifications);
      await tester.tap(find.text('People').last);
      await tester.pumpAndSettle();

      notifications.taps.add(CompassLaunch(reminderDay: DateTime(2026, 11, 15)));
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), 1);
    });

    testWidgets('a birthday tap shows People with that friend on top',
        (tester) async {
      await _init();
      await FriendsService.addFriend(_friend('f1', 'Mila'));
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, _FakeWidgetLaunches(),
          notificationLaunches: notifications);
      _pushScreen(tester, 'Something else');
      await tester.pumpAndSettle();

      notifications.taps.add(const PeopleLaunch(friendId: 'f1'));
      await _pumpFrames(tester);
      expect(find.text('Something else'), findsNothing);
      expect(_selectedTab(tester), 2);
      final detail = find.byType(FriendDetailScreen);
      expect(detail, findsOneWidget);
      expect(tester.widget<FriendDetailScreen>(detail).friend.id, 'f1');

      // Back lands on the People tab.
      await tester.pageBack();
      await _pumpFrames(tester);
      expect(detail, findsNothing);
      expect(_selectedTab(tester), 2);
    });

    testWidgets('a tap for an unknown friend or the refresh note shows People',
        (tester) async {
      await _init();
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, _FakeWidgetLaunches(),
          notificationLaunches: notifications);

      notifications.taps.add(const PeopleLaunch(friendId: 'gone'));
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), 2);
      expect(find.byType(FriendDetailScreen), findsNothing);

      await tester.tap(find.text('Life').last);
      await tester.pumpAndSettle();
      notifications.taps.add(const PeopleLaunch());
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), 2);
      expect(find.byType(FriendDetailScreen), findsNothing);
    });

    testWidgets('the birthday tap that launched the app opens the friend',
        (tester) async {
      await _init();
      await FriendsService.addFriend(_friend('f2', 'Noah'));
      NotificationTaps.resetForTesting();
      addTearDown(NotificationTaps.resetForTesting);
      NotificationTaps.report('${BirthdayReminderScheduler.payloadPrefix}f2');
      await _pumpShell(tester, _FakeWidgetLaunches(), settle: false);
      expect(_selectedTab(tester), 2);
      expect(
          tester.widget<FriendDetailScreen>(find.byType(FriendDetailScreen))
              .friend
              .id,
          'f2');
    });

    testWidgets('the tap that launched the app opens Compass on start',
        (tester) async {
      await _init();
      NotificationTaps.resetForTesting();
      addTearDown(NotificationTaps.resetForTesting);
      NotificationTaps.report(ReminderService.compassPayload);
      await _pumpShell(tester, _FakeWidgetLaunches());
      expect(_selectedTab(tester), 1);
    });

    testWidgets('stops listening when disposed', (tester) async {
      await _init();
      final notifications = _FakeNotificationLaunches();
      await _pumpShell(tester, _FakeWidgetLaunches(),
          notificationLaunches: notifications);
      expect(notifications.taps.hasListener, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(notifications.taps.hasListener, isFalse);
    });
  });

  group('NotificationLaunch.fromPayload', () {
    NotificationLaunch? parse(String payload) =>
        NotificationLaunch.fromPayload(payload);

    test('Compass payloads, the old weekly one too', () {
      expect(parse(ReminderService.compassPayload), const CompassLaunch());
      expect(parse(ReminderService.weeklyReminderPayload), const CompassLaunch());
    });

    test('a dated Compass payload carries its local day', () {
      expect(parse('compass:2026-11-15'),
          CompassLaunch(reminderDay: DateTime(2026, 11, 15)));
      expect(parse('compass:2028-02-29'),
          CompassLaunch(reminderDay: DateTime(2028, 2, 29)));
      expect(parse(WeeklyReflectionPlanner.payloadFor(DateTime(2027, 1, 3, 19))),
          CompassLaunch(reminderDay: DateTime(2027, 1, 3)));
    });

    test('a dated Compass payload is not equal to an undated one', () {
      expect(parse('compass:2026-11-15'), isNot(const CompassLaunch()));
      expect(CompassLaunch(reminderDay: DateTime(2026, 11, 15)).hashCode,
          CompassLaunch(reminderDay: DateTime(2026, 11, 15)).hashCode);
    });

    test('an invalid or empty date still opens Compass, without a day', () {
      for (final payload in [
        'compass:',
        'compass:2026-13-40',
        'compass:2027-02-29',
        'compass:2026-11-31',
        'compass:2026-1-5',
        'compass:20261115',
        'compass:2026-11-15T19:00',
        'compass:yesterday',
      ]) {
        expect(parse(payload), const CompassLaunch(), reason: payload);
      }
    });

    test('a birthday reminder opens its friend', () {
      expect(parse('${BirthdayReminderScheduler.payloadPrefix}1700000000001'),
          const PeopleLaunch(friendId: '1700000000001'));
      expect(parse('${BirthdayReminderScheduler.testPayloadPrefix}7'),
          const PeopleLaunch(friendId: '7'));
    });

    test('the refresh note and a reminder without id open People only', () {
      expect(parse(BirthdayReminderScheduler.refreshPayload),
          const PeopleLaunch());
      expect(parse(BirthdayReminderScheduler.payloadPrefix),
          const PeopleLaunch());
    });

    test('other payloads open nothing', () {
      expect(parse('friend:1'), isNull);
      expect(parse('birthdays'), isNull);
    });
  });

  group('PlatformNotificationLaunches', () {
    setUp(NotificationTaps.resetForTesting);
    tearDown(NotificationTaps.resetForTesting);

    Future<List<NotificationLaunch>> launchesOf(
        void Function() reportTaps) async {
      final launches = <NotificationLaunch>[];
      final subscription =
          const PlatformNotificationLaunches().listen(launches.add);
      reportTaps();
      await pumpEventQueue();
      await subscription.cancel();
      return launches;
    }

    Future<int> countLaunches(void Function() reportTaps) async =>
        (await launchesOf(reportTaps)).length;

    test('reports Compass payloads, old weekly ones too', () async {
      expect(
          await countLaunches(() {
            NotificationTaps.report(ReminderService.compassPayload);
            NotificationTaps.report(ReminderService.weeklyReminderPayload);
          }),
          2);
    });

    test('reports a dated Compass tap with its day', () async {
      expect(
          await launchesOf(
              () => NotificationTaps.report('compass:2026-11-15')),
          [CompassLaunch(reminderDay: DateTime(2026, 11, 15))]);
    });

    test('ignores other and missing payloads', () async {
      expect(
          await countLaunches(() {
            NotificationTaps.report('friend:1');
            NotificationTaps.report(null);
          }),
          0);
    });

    test('reports birthday taps as People launches', () async {
      expect(
          await launchesOf(() {
            NotificationTaps.report('birthday:42');
            NotificationTaps.report(ReminderService.compassPayload);
          }),
          [const PeopleLaunch(friendId: '42'), const CompassLaunch()]);
    });

    test('keeps a tap reported before anyone listens', () async {
      NotificationTaps.report(ReminderService.compassPayload);
      expect(await countLaunches(() {}), 1);
      // Delivered once only.
      expect(await countLaunches(() {}), 0);
    });

    test('keeps a dated tap reported before anyone listens', () async {
      NotificationTaps.report('compass:2026-11-15');
      expect(await launchesOf(() {}),
          [CompassLaunch(reminderDay: DateTime(2026, 11, 15))]);
    });
  });

  group('HomeWidgetLaunches', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(_channel, null);
      messenger.setMockStreamHandler(_clicks, null);
    });

    void mockInitialLaunch(String? uri) {
      messenger.setMockMethodCallHandler(_channel, (call) async {
        return call.method == 'initiallyLaunchedFromHomeWidget' ? uri : null;
      });
    }

    Future<int> countLaunches() async {
      var launches = 0;
      final subscription =
          const HomeWidgetLaunches().listen(() => launches++);
      await pumpEventQueue();
      await subscription.cancel();
      return launches;
    }

    test('reports a launch from the widget and later clicks', () async {
      mockInitialLaunch(_widgetUri);
      messenger.setMockStreamHandler(
        _clicks,
        MockStreamHandler.inline(onListen: (_, sink) => sink.success(_widgetUri)),
      );
      expect(await countLaunches(), 2);
    });

    test('a normal launch reports only clicks', () async {
      mockInitialLaunch(null);
      messenger.setMockStreamHandler(
        _clicks,
        MockStreamHandler.inline(onListen: (_, sink) => sink.success(_widgetUri)),
      );
      expect(await countLaunches(), 1);
    });

    test('without the plugin nothing is reported', () async {
      expect(await countLaunches(), 0);
    });
  });

  group('PendingWidgetLaunches', () {
    /// Native flag fake: [pending] taps recorded, consumed one call at a time.
    late List<bool> answers;
    late StreamController<void> checks;

    setUp(() {
      answers = [];
      checks = StreamController<void>.broadcast();
    });

    PendingWidgetLaunches launches() => PendingWidgetLaunches(
          consumePending: () async =>
              answers.isEmpty ? false : answers.removeAt(0),
          checks: checks.stream,
        );

    Future<int> count(List<bool> flags, {int checksAfterStart = 0}) async {
      answers = flags;
      var launched = 0;
      final subscription = launches().listen(() => launched++);
      await pumpEventQueue();
      for (var i = 0; i < checksAfterStart; i++) {
        checks.add(null);
        await pumpEventQueue();
      }
      await subscription.cancel();
      return launched;
    }

    test('a tap recorded before listening is reported at start', () async {
      expect(await count([true]), 1);
    });

    test('a normal start reports nothing', () async {
      expect(await count([false]), 0);
    });

    test('a tap on a warm start is reported on the next check (resume)',
        () async {
      expect(await count([false, true], checksAfterStart: 1), 1);
    });

    test('a tap is reported once although resume and the native call both '
        'check', () async {
      expect(await count([false, true, false], checksAfterStart: 2), 1);
    });

    test('every tap is reported, also with the same URI', () async {
      expect(await count([false, true, true], checksAfterStart: 2), 2);
    });

    test('a failing check reports nothing and keeps listening', () async {
      var calls = 0;
      var launched = 0;
      final subscription = PendingWidgetLaunches(
        consumePending: () async {
          if (calls++ == 0) throw PlatformException(code: 'gone');
          return true;
        },
        checks: checks.stream,
      ).listen(() => launched++);
      await pumpEventQueue();
      expect(launched, 0);
      checks.add(null);
      await pumpEventQueue();
      expect(launched, 1);
      await subscription.cancel();
    });

    test('stops checking when cancelled', () async {
      final subscription = launches().listen(() {});
      await pumpEventQueue();
      expect(checks.hasListener, isTrue);
      await subscription.cancel();
      expect(checks.hasListener, isFalse);
    });
  });

  group('PendingWidgetLaunches.android', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = PendingWidgetLaunches.channel;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('asks MainActivity at start and when it reports a tap', () async {
      final answers = [false, true];
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'consumeWidgetLaunch');
        return answers.removeAt(0);
      });
      var launched = 0;
      final subscription =
          PendingWidgetLaunches.android().listen(() => launched++);
      await pumpEventQueue();
      expect(launched, 0);

      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall('widgetLaunched')),
        (_) {},
      );
      await pumpEventQueue();
      expect(launched, 1);
      await subscription.cancel();
    });

    test('without MainActivity nothing is reported', () async {
      var launched = 0;
      final subscription =
          PendingWidgetLaunches.android().listen(() => launched++);
      await pumpEventQueue();
      expect(launched, 0);
      await subscription.cancel();
    });
  });
}
