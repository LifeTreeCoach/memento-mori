import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/enhanced_friends_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_tile.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/scroll_thread_probe.dart';
import 'support/tours_seen.dart';

final DateTime _today = DateTime(2026, 11, 2);

Map<String, dynamic> _friend(String name, DateTime birthDate, {String? group}) =>
    Friend(
      id: name,
      name: name,
      birthDate: birthDate,
      groupName: group,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    ).toMap();

/// Friends stored the way FriendsService persists them: a JSON list of
/// Friend maps under 'friends_data'.
Future<void> _initWith(List<Map<String, dynamic>> friends) async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': DateTime(1990, 11, 17).toIso8601String(),
    'language': 'en',
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': jsonEncode(friends),
    ...toursSeenPrefs,
  });
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
  await reloadTourProgress();
}

Future<void> _pumpPeople(WidgetTester tester,
    {String lang = 'en',
    bool inShell = false,
    Size physicalSize = const Size(1080, 3400)}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.dark),
    locale: Locale(lang),
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    // The app shell wraps the tab in its own (FAB-less) Scaffold.
    home: inShell
        ? Scaffold(body: EnhancedFriendsScreen(now: _today))
        : EnhancedFriendsScreen(now: _today),
  ));
  await tester.pumpAndSettle();
}

void main() {
  final friends = [
    _friend('Anna', DateTime(1990, 11, 2)), // today, turns 36
    _friend('Cleo', DateTime(1995, 11, 12), group: 'Family'), // in 10 days
    _friend('Ben', DateTime(1980, 3, 1)),
  ];

  testWidgets('shows Today, Next 30 days and Everyone sections',
      (tester) async {
    await _initWith(friends);
    await _pumpPeople(tester);

    expect(find.text('People'), findsWidgets);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('NEXT 30\u00A0DAYS'), findsOneWidget);
    expect(find.text('EVERYONE'), findsOneWidget);
    expect(find.text('turns 36 today 🎂'), findsNWidgets(2)); // Today + Everyone
    expect(find.text('turns 31 · in 10\u00A0days'), findsNWidgets(2));
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('3 people · 1 today · 2 in 30\u00A0days'), findsOneWidget);
    // Anna and Cleo: every birthday up to the user's 80th (2070-11-17)
    // -> 45 each, shown twice; Ben is capped by his own 80th in 2060.
    expect(find.text('≈ 45 more birthdays together'), findsNWidgets(4));
    expect(find.text('≈ 34 more birthdays together'), findsOneWidget);
  });

  testWidgets('reloads when friends change elsewhere (e.g. import in Settings)',
      (tester) async {
    await _initWith(friends);
    await _pumpPeople(tester);
    expect(find.text('Dora'), findsNothing);

    await tester.runAsync(() => FriendsService.addFriend(Friend(
          id: 'Dora',
          name: 'Dora',
          birthDate: DateTime(1985, 11, 20), // in 18 days: near the top
          createdDate: DateTime(2020),
          lastUpdated: DateTime(2020),
        )));
    // The listener's reload awaits the service outside the fake clock.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('Dora'), findsWidgets);
  });

  testWidgets('group chips filter the list', (tester) async {
    await _initWith(friends);
    await _pumpPeople(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Family'));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsNothing);
    expect(find.text('Cleo'), findsNWidgets(2)); // Next 30 days + Everyone
    expect(find.text('TODAY'), findsNothing);
    expect(find.text('1 of 3 people · 0 today · 1 in 30\u00A0days'), findsOneWidget);
  });

  testWidgets('summary counts the selected group in German', (tester) async {
    await _initWith(friends);
    await _pumpPeople(tester, lang: 'de');

    // The typed "Family" was migrated to the predefined group: German label.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Familie'));
    await tester.pumpAndSettle();
    expect(find.text('1 von 3 Personen · 0 heute · 1 in 30\u00A0Tagen'), findsOneWidget);
  });

  testWidgets('search shows a flat results list', (tester) async {
    await _initWith(friends);
    await _pumpPeople(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'be');
    await tester.pumpAndSettle();
    expect(find.text('RESULTS'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('Anna'), findsNothing);
  });

  testWidgets('empty state invites to add someone, in German too',
      (tester) async {
    await _initWith(const []);
    await _pumpPeople(tester, lang: 'de');

    expect(find.text('Die Menschen, die du liebst – in der Zeit.'),
        findsOneWidget);
    expect(find.text('Person hinzufügen'), findsOneWidget);
    expect(find.text('EVERYONE'), findsNothing);
  });

  testWidgets('undo snackbar does not cover the Add FAB inside the app shell',
      (tester) async {
    await _initWith(friends);
    await _pumpPeople(tester, inShell: true);
    final fab = find.byType(FloatingActionButton);

    await tester.fling(find.text('Ben'), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();

    final snackBar = find.byType(SnackBar);
    expect(snackBar, findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(
      find.descendant(
          of: find.byType(EnhancedFriendsScreen), matching: snackBar),
      findsOneWidget,
    );
    // A floating snackbar in the tab's own Scaffold is laid out around
    // the FAB instead of on top of it.
    final snackRect = tester.getRect(find.descendant(
        of: snackBar, matching: find.byType(Material)).first);
    expect(snackRect.overlaps(tester.getRect(fab)), isFalse);
  });

  testWidgets('scroll thread shows on a phone and ends above the FAB',
      (tester) async {
    await _initWith([
      for (var i = 0; i < 12; i++) _friend('Friend $i', DateTime(1980, 3, 1)),
    ]);
    await _pumpPeople(tester, physicalSize: phoneViewport * 3);
    await tester.pump(); // scroll metrics arrive after the first frame

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(scrollThreadOpacity(tester), 1);
    final thread = tester.getRect(find.byKey(ScrollThread.threadKey));
    expect(thread.bottom, phoneViewport.height - 88);
  });

  testWidgets('builds only the visible rows of a long list', (tester) async {
    await _initWith([
      for (var i = 0; i < 300; i++)
        _friend('Person ${i.toString().padLeft(3, '0')}',
            DateTime(1980, 1 + i % 12, 1 + i % 28)),
    ]);
    final watch = Stopwatch()..start();
    await _pumpPeople(tester, physicalSize: phoneViewport * 3);
    watch.stop();

    final built = find.byType(FriendTile, skipOffstage: false).evaluate();
    expect(built.length, lessThan(60)); // of 300 (+ 30-day duplicates)
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));

    // The last person is still reachable by scrolling.
    await tester.scrollUntilVisible(find.text('Person 299'), 2000,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Person 299'), findsWidgets);
  });
}
