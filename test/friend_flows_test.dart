import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_actions.dart';
import 'package:memento_mori_life_in_weeks/people/open_friend_detail.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Friend _friend(String id, String name, DateTime birthDate) => Friend(
      id: id,
      name: name,
      birthDate: birthDate,
      createdDate: DateTime(2025),
      lastUpdated: DateTime(2025),
    );

Future<void> _pump(WidgetTester tester, Widget home, {String lang = 'en'}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: Locale(lang),
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  ));
  await tester.pump();
}

/// A list-like page that opens the detail screen, as the People tab does.
class _Opener extends StatelessWidget {
  const _Opener({required this.friend, required this.actions});

  final Friend friend;
  final FriendActions actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton(onPressed: () {}),
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openFriendDetail(context, friend, actions),
            child: const Text('open'),
          ),
        ),
      );
}

/// Pushes the form from a page so Back has somewhere to go.
class _FormOpener extends StatelessWidget {
  const _FormOpener({this.friend});

  final Friend? friend;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddFriendScreen(friend: friend))),
          child: const Text('open'),
        ),
      );
}

void main() {
  setUpAll(() => initializeDateFormatting());

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'birth_date': DateTime(1990, 11, 17).toIso8601String(),
      'lifespan_visualization_enabled': false,
    });
    await SettingsService.initialize();
    await FriendsService.clearCacheForTesting();
  });

  group('delete from the detail screen', () {
    Future<void> tapDeleteButton(WidgetTester tester) async {
      final button = find.byIcon(Icons.delete_outline);
      await tester.scrollUntilVisible(button, 300);
      await tester.tap(button);
    }

    testWidgets('returns to the list and offers undo there', (tester) async {
      final anna = _friend('a', 'Anna', DateTime(1990, 5, 1));
      await FriendsService.addFriend(anna);
      var reloads = 0;
      final actions = FriendActions(onChanged: () async => reloads++);
      await _pump(tester, _Opener(friend: anna, actions: actions));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tapDeleteButton(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('cannot be undone'), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget); // back on the list
      expect(find.text('Anna removed'), findsOneWidget);
      expect(await FriendsService.getAllFriends(), isEmpty);
      expect(reloads, 1);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect((await FriendsService.getAllFriends()).single.name, 'Anna');
    });

    testWidgets('cancelling keeps the friend and the detail screen', (tester) async {
      final anna = _friend('a', 'Anna', DateTime(1990, 5, 1));
      await FriendsService.addFriend(anna);
      await _pump(tester,
          _Opener(friend: anna, actions: FriendActions(onChanged: () async {})));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tapDeleteButton(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsNothing);
      expect(await FriendsService.getAllFriends(), hasLength(1));
    });
  });

  group('unsaved changes in the form', () {
    final anna = _friend('a', 'Anna', DateTime(1990, 5, 1));

    Future<void> openForm(WidgetTester tester, {String lang = 'en'}) async {
      await FriendsService.addFriend(anna);
      await _pump(tester, _FormOpener(friend: anna), lang: lang);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('unchanged -> Back leaves without asking', (tester) async {
      await openForm(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('changed -> asks; Keep editing stays, Discard leaves', (tester) async {
      await openForm(tester, lang: 'de');
      await tester.enterText(find.widgetWithText(TextFormField, 'Anna'), 'Anna B');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Änderungen verwerfen?'), findsOneWidget);
      await tester.tap(find.text('Weiter bearbeiten'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verwerfen'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      // Nothing was saved.
      expect((await FriendsService.getAllFriends()).single.name, 'Anna');
    });

    testWidgets('changed and saved -> leaves without asking', (tester) async {
      await openForm(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Anna'), 'Anna B');
      await tester.pump();
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  testWidgets('upcoming card lists every birthday of the soonest day', (tester) async {
    final today = DateTime(2026, 11, 2);
    final upcoming = UpcomingBirthday.soonest([
      _friend('b', 'Ben', DateTime(1995, 11, 2)),
      _friend('a', 'Anna', DateTime(1990, 11, 2)),
      _friend('c', 'Cleo', DateTime(1990, 11, 3)),
    ], today);
    final opened = <String>[];
    await _pump(
      tester,
      Scaffold(
        body: UpcomingBirthdayCard(
          upcoming: upcoming,
          onOpen: (friend) => opened.add(friend.name),
        ),
      ),
      lang: 'de',
    );
    expect(find.text('Anna wird heute 36 🎂'), findsOneWidget);
    expect(find.text('Ben wird heute 31 🎂'), findsOneWidget);
    expect(find.textContaining('Cleo'), findsNothing);
    await tester.tap(find.text('Ben wird heute 31 🎂'));
    expect(opened, ['Ben']);
  });
}
