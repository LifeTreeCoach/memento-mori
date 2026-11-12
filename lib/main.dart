import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';
import 'package:memento_mori_life_in_weeks/onboarding/onboarding_screen.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/support/support_scope.dart';
import 'package:memento_mori_life_in_weeks/support/support_service.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';
import 'package:memento_mori_life_in_weeks/widget_service.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_service.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';

/*
0. PErsonalisierung --> Name wie man angesprochen werden möchte
1. Kachel-Zoom funkitoinert hat derzeit aber schon einige Schwächen
1.1 Bei der Darstellung sollte sich auch der Text unten ändern und ich sollte immer den aktuellen bereich sehen
1.2 Langsam
2. Wöchentliche Erinnerung
3. Widget-Feature
4. Die Möglichkeiten das Leben in Seasons einzuteilen. Und dann auch zu tracken wie lange die Season noch dauert
5. GGfs. das Logo durch eine Sanduhr ersetzte, welche die verbleibende Lebenszeit visualisiert
6. Auf das Klicken der Raster sollte eine Art zoom in die verschiedenen Darstellungen erfolgen können (die mit der Einstellung der Kachenln also den Lebenszeit in Wochen, Monanten usw. verknüpft ist)
7. es macht ggfs. auch Sinn das wenn man eine Season hat das die mit einem Ziel verknüpft ist und das natürlich auch mit den Zielen der Woche
8. Zitate zu den Erinnerungen
9. Freunde Feature --> Freunde-Feature
10. Teilen Feature 
11. Websetei bei Lifetrea
12. E

Letztlich soll die App mir dabei helfen meine Ziele für mein Leben zu erreichen. Um dies zu tun will ich einerseits die "dringlichkeit" also was man so schön als "the need for urgency" bezeichnet
und das entsprechend zu visualisieren. Andererseits soll die App mir dabei helfen mein Ziel in kleinere Zwischenziele zu unterteilen.
*/



/// Bundled OFL fonts; their licenses appear on the Flutter licenses page.
const Map<String, String> _fontLicenses = {
  'Fraunces': 'assets/fonts/licenses/fraunces-OFL.txt',
  'Inter': 'assets/fonts/licenses/inter-OFL.txt',
  'Nunito': 'assets/fonts/licenses/nunito-OFL.txt',
};

/// Bundled data for the life expectancy estimate (life tables, country names).
const Map<String, String> _dataLicenses = {
  'UN World Population Prospects 2024': 'assets/lifespan/licenses/wpp.txt',
  'Unicode CLDR': 'assets/lifespan/licenses/unicode.txt',
};

void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in {..._fontLicenses, ..._dataLicenses}.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  // Only settings are needed for the first frame (theme, language, routing).
  await SettingsService.initialize();
  // Records the first use (support prompt schedule) on the first launch.
  await _guarded('Support service', SupportService.initialize);
  // Compass state is read by the Life tab's question card on the first frame.
  await _guarded('Compass service', CompassService.initialize);
  await _guarded('Compass setup', CompassSetupStore.initialize);
  // Records the day the weekly moment arrived (no catch-up before it).
  await _guarded('Week moment', WeekMomentStore.initialize);
  // Friend photos are resolved against this run's documents directory.
  await _guarded('Avatar store', AvatarStore.init);
  runApp(MementoMoriApp());
  unawaited(_startBackgroundServices());
}

/// Notifications, widget inputs and reminders, started after the first frame
/// was requested so they don't delay app start.
///
/// Each step is guarded on its own so one failing plugin doesn't skip the
/// others (and never surfaces as an unhandled async error).
Future<void> _startBackgroundServices() async {
  // Wired first and synchronously: friend changes must always reschedule.
  FriendsService.onFriendsChanged = ReminderService.refreshBirthdayReminders;
  // Friend changes update the synced calendar events (when sync is set up).
  CalendarService.attachToFriendsService();
  // "Gentle only" and question swaps change the weekly reflection's text.
  ReminderService.attachToCompassService();
  // Coming back to the app plans the next birthday reminders (throttled):
  // only the soonest ones fit the OS notification budget.
  // The binding keeps the listener for the app's lifetime.
  AppLifecycleListener(onResume: _refreshRemindersOnResume);
  await _guarded('Notification service', NotificationService.initialize);
  await _guarded('Widget service', WidgetService.initialize);
  await _guarded('Friends service', FriendsService.initialize);
  // Catches up on calendar changes a failed or skipped sync left pending.
  unawaited(CalendarService.requestSync());
  // Photos of people deleted in an earlier session (after their undo).
  await _guarded('Avatar cleanup', FriendsService.removeOrphanedAvatars);
  // Notification permission is requested later, when the user opts into reminders.
  await _guarded('Reminder service', ReminderService.initialize);
  // Onboarding schedules everything when it finishes (with the chosen
  // name and language), so a first launch doesn't schedule twice.
  if (!SettingsService.hasCompletedOnboarding()) return;
  // Reschedule so ages/texts are current and the next birthdays are queued.
  await _guarded('Reminder rescheduling', ReminderService.rescheduleAll);
}

void _refreshRemindersOnResume() {
  // Onboarding schedules everything when it finishes.
  if (!SettingsService.hasCompletedOnboarding()) return;
  unawaited(ReminderService.refreshBirthdayRemindersOnResume());
}

Future<void> _guarded(String step, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    debugPrint('$step initialization failed: $e');
  }
}

class MementoMoriApp extends StatefulWidget {
  const MementoMoriApp({super.key});

  @override
  State<MementoMoriApp> createState() => _MementoMoriAppState();
}

class _MementoMoriAppState extends State<MementoMoriApp> {
  final AppSettingsController _settings = AppSettingsController();

  /// Coffee link or rate + recommend, from the build flavor and platform.
  final SupportSetup _support = SupportSetup.fromEnvironment();
  bool hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    hasCompletedOnboarding = SettingsService.hasCompletedOnboarding();
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  /// Legacy callback used by screens that write settings directly.
  void _onSettingsChanged() => _settings.reload();

  @override
  Widget build(BuildContext context) {
    return SupportScope(
      setup: _support,
      child: AppSettingsScope(
        controller: _settings,
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => _buildApp(),
        ),
      ),
    );
  }

  Widget _home() => hasCompletedOnboarding
      ? const AppShell()
      : OnboardingScreen(onLanguageChange: _onSettingsChanged);

  Route<void> _homeRoute() => MaterialPageRoute<void>(
        settings: const RouteSettings(name: Navigator.defaultRouteName),
        builder: (_) => _home(),
      );

  Widget _buildApp() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _settings.lightTheme,
      darkTheme: _settings.darkTheme,
      themeMode: _settings.themeMode,
      // The app has no named routes. Launch intents (e.g. the home-screen
      // widget's glance-action URI) must never be treated as a route.
      onGenerateInitialRoutes: (_) => [_homeRoute()],
      onUnknownRoute: (settings) => _UnknownRouteFallback.route(settings),
      locale: _settings.locale,
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: [
        for (final code in AppLocalizations.supportedLanguages) Locale(code),
      ],
    );
  }
}

/// Shown for a route name the app doesn't know: closes itself so the
/// current screen stays visible instead of crashing.
class _UnknownRouteFallback extends StatefulWidget {
  const _UnknownRouteFallback();

  static Route<void> route(RouteSettings settings) => PageRouteBuilder<void>(
        settings: settings,
        opaque: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => const _UnknownRouteFallback(),
      );

  @override
  State<_UnknownRouteFallback> createState() => _UnknownRouteFallbackState();
}

class _UnknownRouteFallbackState extends State<_UnknownRouteFallback> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/*
void main() {
  runApp(MementoMoriApp());
}

class MementoMoriApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MementoMoriGrid(),
    );
  }
}

class MementoMoriGrid extends StatelessWidget {
  final int totalWeeks = 80 * 52; // 80 Jahre, 52 Wochen pro Jahr
  final DateTime birthDate = DateTime(1990, 11, 17); // Geburtsdatum hier nur ein Beispiel

  @override
  Widget build(BuildContext context) {
    // Anzahl der gelebten Wochen berechnen
    int currentWeekNumber = ((DateTime.now().difference(birthDate).inDays) / 7).floor();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Titel links, Logo rechts
          children: [
            Text('Memento Mori – Lebenswochen'), // Titel links
            Image.asset(
              'assets/icon/icon_in_app.png',
              height: 40, // Größe des Logos anpassen
              width: 40, // Breite des Logos anpassen
              fit: BoxFit.contain, // Das Bild proportional skalieren
            ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(2),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 52, // 52 Wochen pro Jahr
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: totalWeeks,
        itemBuilder: (context, index) {
          bool isPastWeek = index < currentWeekNumber;
          return Container(
            decoration: BoxDecoration(
              color: isPastWeek ? Colors.black : Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.5), width: 0.5),
            ),
          );
        },
      ),
    );
  }
}
*/