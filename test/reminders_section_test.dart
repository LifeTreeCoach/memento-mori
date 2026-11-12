import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_permission.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/settings/notifications_blocked_tile.dart';
import 'package:memento_mori_life_in_weeks/settings/reminders_section.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A system permission the test controls.
class _FakePermission implements NotificationPermission {
  _FakePermission({this.granted = false, this.grantOnRequest = false});

  bool granted;
  bool grantOnRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async {
    requests++;
    if (grantOnRequest) granted = true;
    return granted;
  }

  @override
  Future<void> openSystemSettings() async => settingsOpened++;
}

const _blockedEn = 'Notifications are blocked — reminders can’t be shown';
const _blockedDe =
    'Benachrichtigungen sind blockiert – Erinnerungen können nicht angezeigt werden';

Future<void> _init({bool remindersOn = true, String lang = 'en'}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (_) async => null,
  );
  SharedPreferences.setMockInitialValues({
    'language': lang,
    'friends_data': '[]',
    'weekly_reminder_enabled': remindersOn,
    'birthday_notifications_enabled': remindersOn,
  });
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
  await FriendsService.initialize();
}

Future<void> _pump(WidgetTester tester, NotificationPermission permission,
    {String lang = 'en'}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.light),
    locale: Locale(lang),
    supportedLocales: [
      for (final code in AppLocalizations.supportedLanguages) Locale(code),
    ],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(
      body: ListView(children: [RemindersSection(permission: permission)]),
    ),
  ));
  await tester.pumpAndSettle();
}

/// The app's font, so label widths match the device.
Future<void> _loadInterFonts() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}

Finder get _warning => find.byType(NotificationsBlockedTile);

void main() {
  testWidgets('no warning while notifications are allowed', (tester) async {
    await _init();
    await _pump(tester, _FakePermission(granted: true));
    expect(_warning, findsNothing);
  });

  testWidgets('warns when reminders are on but notifications are blocked',
      (tester) async {
    await _init();
    await _pump(tester, _FakePermission());
    expect(find.text(_blockedEn), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
  });

  testWidgets('the warning is localized in German', (tester) async {
    await _init(lang: 'de');
    await _pump(tester, _FakePermission(), lang: 'de');
    expect(find.text(_blockedDe), findsOneWidget);
    expect(find.text('Erlauben'), findsOneWidget);
  });

  testWidgets('no warning when every reminder is off', (tester) async {
    await _init(remindersOn: false);
    await _pump(tester, _FakePermission());
    expect(_warning, findsNothing);
  });

  testWidgets('Allow asks again and hides the warning once granted',
      (tester) async {
    await _init();
    final permission = _FakePermission(grantOnRequest: true);
    await _pump(tester, permission);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(permission.requests, 1);
    expect(permission.settingsOpened, 0);
    expect(_warning, findsNothing);
  });

  testWidgets('Allow opens system settings when the prompt is refused',
      (tester) async {
    await _init();
    final permission = _FakePermission();
    await _pump(tester, permission);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(permission.settingsOpened, 1);
    expect(_warning, findsOneWidget);
  });

  testWidgets('re-checks the status when the app resumes', (tester) async {
    await _init();
    final permission = _FakePermission();
    await _pump(tester, permission);
    expect(_warning, findsOneWidget);
    permission.granted = true; // allowed in the system settings
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(_warning, findsNothing);
  });

  testWidgets('switching a reminder on while blocked asks and then warns',
      (tester) async {
    await _init(remindersOn: false);
    final permission = _FakePermission();
    await _pump(tester, permission);
    expect(_warning, findsNothing);
    await tester.tap(find.text('Birthday reminders'));
    await tester.pumpAndSettle();
    expect(permission.requests, 1);
    expect(_warning, findsOneWidget);
  });

  group('Compass reminder rhythm', () {
    testWidgets('shows the stored rhythm and its explanation', (tester) async {
      await _init();
      await _pump(tester, _FakePermission(granted: true));
      expect(find.byKey(const ValueKey('settings_weekly_reflection')),
          findsOneWidget);
      expect(find.text('Compass reminder'), findsOneWidget);
      expect(find.text('Sundays at 7\u00A0pm: a question for the week.'),
          findsOneWidget);
    });

    testWidgets('every 4 weeks asks for permission, anchors and explains',
        (tester) async {
      await _init(remindersOn: false);
      final permission = _FakePermission(granted: true);
      await _pump(tester, permission);
      expect(find.text('No Compass reminders.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rhythm_every_4_weeks')));
      await tester.pumpAndSettle();
      expect(permission.requests, 1);
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.every4Weeks);
      expect(SettingsService.getRhythmAnchor(), isNotNull);
      expect(SettingsService.isWeeklyReminderEnabled(), isTrue);
      expect(
          find.text('Every four weeks, Sundays at 7\u00A0pm: '
              'where do you stand in your phase?'),
          findsOneWidget);
    });

    testWidgets('off does not ask for permission', (tester) async {
      await _init();
      final permission = _FakePermission(granted: true);
      await _pump(tester, permission);
      await tester.tap(find.byKey(const ValueKey('rhythm_off')));
      await tester.pumpAndSettle();
      expect(permission.requests, 0);
      expect(SettingsService.getReminderRhythm(), ReminderRhythm.off);
      expect(SettingsService.isWeeklyReminderEnabled(), isFalse);
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('fits a 393x851 phone in $lang', (tester) async {
        tester.view.physicalSize = const Size(393, 851);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _loadInterFonts();
        await _init(lang: lang);
        await _pump(tester, _FakePermission(granted: true), lang: lang);
        expect(tester.takeException(), isNull);
        for (final key in ['rhythm_weekly', 'rhythm_every_4_weeks', 'rhythm_off']) {
          final label = tester.renderObject<RenderParagraph>(
              find.byKey(ValueKey(key)));
          expect(label.didExceedMaxLines, isFalse, reason: '$lang $key');
          // One line: the label is as wide as its text.
          expect(label.size.width,
              closeTo(label.getMaxIntrinsicWidth(double.infinity), 0.5),
              reason: '$lang $key');
        }
      });
    }
  });
}
