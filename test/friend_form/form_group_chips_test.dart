import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Friend _friend(String id, String? group) => Friend(
      id: id,
      name: id,
      birthDate: DateTime(1990, 5, 1),
      groupName: group,
      createdDate: DateTime(2025),
      lastUpdated: DateTime(2025),
    );

Future<void> _pumpForm(WidgetTester tester, Friend? friend) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('de'),
    supportedLocales: [
      for (final code in AppLocalizations.supportedLanguages) Locale(code),
    ],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: AddFriendScreen(friend: friend),
  ));
  await tester.pumpAndSettle();
}

Finder _chip(String label) =>
    find.widgetWithText(ChoiceChip, label, skipOffstage: false);

void main() {
  setUpAll(() => initializeDateFormatting());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    await FriendsService.clearCacheForTesting();
    await FriendsService.addFriends([
      _friend('Anna', 'Testgruppe'),
      _friend('Ben', '@family'),
      _friend('Cleo', null),
    ]);
  });

  testWidgets('editing another person offers the custom groups after the '
      'predefined ones', (tester) async {
    await _pumpForm(tester, _friend('Cleo', null));
    for (final label in ['Familie', 'Freunde', 'Testgruppe']) {
      expect(_chip(label), findsOneWidget, reason: label);
    }
    final labels = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip, skipOffstage: false))
        .map((chip) => (chip.label as Text).data)
        .toList();
    expect(labels, ['Familie', 'Freunde', 'Testgruppe']);
  });

  testWidgets('custom groups show even before the friends were loaded',
      (tester) async {
    await FriendsService.clearCacheForTesting(); // stored, not loaded yet
    await _pumpForm(tester, null);
    expect(_chip('Testgruppe'), findsOneWidget);
  });
}
