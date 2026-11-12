import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_launch_requests.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/encounter_dots.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/together_view.dart';
import 'package:memento_mori_life_in_weeks/friend_detail_screen.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/meeting_frequency.dart';
import 'package:memento_mori_life_in_weeks/people/shared_time.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _userBirth = DateTime(1990, 11, 17);

Friend _anna({String name = 'Anna', MeetingFrequency? frequency, DateTime? birth}) =>
    Friend(
      id: 'anna',
      name: name,
      birthDate: birth ?? DateTime(1995, 11, 14),
      meetingFrequency: frequency,
      createdDate: DateTime(2025),
      lastUpdated: DateTime(2025),
    );

Future<void> _init({
  Friend? friend,
  String? view,
  bool withBirthDate = true,
  String lang = 'en',
}) async {
  SharedPreferences.setMockInitialValues({
    if (withBirthDate) 'birth_date': _userBirth.toIso8601String(),
    'language': lang,
    'friends_data': jsonEncode([(friend ?? _anna()).toMap()]),
    SettingsService.friendLifespanViewKey: ?view,
  });
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
  CompassService.clearCacheForTesting();
  await CompassService.initialize();
}

/// Pumps the detail screen of [friend]; the "Their life" chart animates
/// forever, so this never waits for animations to settle.
Future<void> _pump(WidgetTester tester, Friend friend,
    {String lang = 'en', Size size = const Size(393, 4000), Key? key}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
    home: FriendDetailScreen(key: key, friend: friend),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

SharedTime _sharedTimeOf(Friend friend) => SharedTime.compute(
      friend: friend,
      userBirthDate: _userBirth,
      userLifeExpectancyYears: SettingsService.getLifeExpectancyYears(),
      today: DateTime.now(),
    )!;

void main() {
  setUpAll(() => initializeDateFormatting());

  test('importing a backup keeps the meeting frequency', () async {
    await _init();
    final backup = FriendsService.encodeBackup(
        [_anna(name: 'Cleo', frequency: MeetingFrequency.weekly)]);
    await FriendsService.importBackupEntries(
        FriendsService.decodeBackupEntries(backup));
    final cleo = (await FriendsService.getAllFriends())
        .firstWhere((friend) => friend.name == 'Cleo');
    expect(cleo.meetingFrequency, MeetingFrequency.weekly);
  });

  testWidgets('no switch without the user birth date', (tester) async {
    await _init(withBirthDate: false, view: 'together');
    await _pump(tester, _anna());
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.byType(TogetherView), findsNothing);
  });

  testWidgets('the switch is remembered across screens', (tester) async {
    await _init();
    await _pump(tester, _anna());
    expect(find.byType(TogetherView), findsNothing);

    await tester.tap(find.text('Together'));
    await _settle(tester);
    expect(find.byType(TogetherView), findsOneWidget);
    expect(SettingsService.getFriendLifespanView(), 'together');

    await _pump(tester, _anna(name: 'Ben'), key: const ValueKey('ben'));
    expect(find.byType(TogetherView), findsOneWidget);

    await tester.tap(find.text('Their life'));
    await _settle(tester);
    expect(find.byType(TogetherView), findsNothing);
    expect(SettingsService.getFriendLifespanView(), 'life');
  });

  testWidgets('shows the shared years and the birthdays', (tester) async {
    await _init(view: 'together');
    await _pump(tester, _anna());
    final time = _sharedTimeOf(_anna());
    final years = time.remainingYears.round();
    expect(find.text('You likely still share about $years\u00A0years'), findsOneWidget);
    expect(find.text('≈ ${time.birthdaysTogether} more shared birthdays'),
        findsOneWidget);
    expect(find.byType(EncounterDots), findsNothing);
    expect(find.text('Every encounter counts.'), findsOneWidget);
    expect(find.text('Each of these encounters counts.'), findsNothing);
  });

  testWidgets('choosing a frequency persists it and shows encounters',
      (tester) async {
    await _init(view: 'together');
    await _pump(tester, _anna());

    await tester.tap(find.text('Monthly'));
    await _settle(tester);
    final stored = (await FriendsService.getAllFriends()).single;
    expect(stored.meetingFrequency, MeetingFrequency.monthly);
    final encounters =
        _sharedTimeOf(_anna()).meetingsLeft(MeetingFrequency.monthly)!;
    expect(find.text('≈ $encounters more encounters'), findsOneWidget);
    expect(find.byType(EncounterDots), findsOneWidget);
    expect(find.text('One dot = 10 encounters'), findsOneWidget);
    expect(find.text('Each of these encounters counts.'), findsOneWidget);

    // Tapping the chosen chip again clears it.
    await tester.tap(find.text('Monthly'));
    await _settle(tester);
    expect((await FriendsService.getAllFriends()).single.meetingFrequency, isNull);
    expect(find.byType(EncounterDots), findsNothing);
  });

  testWidgets('a stored frequency is shown right away', (tester) async {
    final friend = _anna(frequency: MeetingFrequency.yearly);
    await _init(friend: friend, view: 'together');
    await _pump(tester, friend);
    final encounters =
        _sharedTimeOf(friend).meetingsLeft(MeetingFrequency.yearly)!;
    expect(find.text('≈ $encounters more encounters'), findsOneWidget);
    expect(find.text('One dot = 10 encounters'), findsNothing);
  });

  testWidgets('beyond expectancy: a gift, no numbers', (tester) async {
    final friend = _anna(birth: DateTime(1930, 1, 1));
    await _init(friend: friend, view: 'together');
    await _pump(tester, friend);
    expect(find.text('Every shared day is a gift.'), findsOneWidget);
    expect(find.text('How often do you see each other?'), findsNothing);
    expect(find.text('Every encounter counts.'), findsOneWidget);
    expect(find.text('Plan time together'), findsOneWidget);
  });

  group('Plan time together', () {
    testWidgets('creates a "Now" intention', (tester) async {
      await _init(view: 'together');
      await _pump(tester, _anna());
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      final intention = CompassService.data.intentions.single;
      expect(intention.title, 'Time with Anna');
      expect(intention.status, IntentionStatus.now);
      expect(intention.area, LifeArea.relationships);
      expect(find.text('“Time with Anna” is now in your Compass.'), findsOneWidget);
    });

    testWidgets('"Open" on the snackbar asks to show the Compass',
        (tester) async {
      await _init(view: 'together');
      await _pump(tester, _anna());
      var requests = 0;
      final subscription = CompassLaunchRequests.listen(() => requests++);
      addTearDown(subscription.cancel);
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(SnackBarAction, 'Open'));
      await _settle(tester);
      expect(requests, 1);
    });

    testWidgets('goes to "Someday" when "Now" is full', (tester) async {
      await _init(view: 'together');
      for (var i = 0; i < nowLimit; i++) {
        await CompassService.addIntention(title: 'Busy $i');
      }
      await _pump(tester, _anna());
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      final intention = CompassService.data.intentions.last;
      expect(intention.title, 'Time with Anna');
      expect(intention.status, IntentionStatus.someday);
      final l10n = AppLocalizations(const Locale('en'));
      expect(find.text(l10n.translate('compass_now_full_saved')), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Open'), findsOneWidget);
    });
  });

  group('Plan time together, once', () {
    testWidgets('a second tap adds nothing and offers to open the Compass',
        (tester) async {
      await _init(view: 'together');
      await _pump(tester, _anna());
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      final intention = CompassService.data.intentions.single;
      expect(intention.friendId, 'anna');
      expect(find.text('“Time with Anna” is already in your Compass.'),
          findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Open'), findsOneWidget);
    });

    testWidgets('finds the linked intention after it was renamed and moved',
        (tester) async {
      await _init(view: 'together');
      final added = await CompassService.addIntention(
          title: 'Coffee with Anna', friendId: 'anna');
      await CompassService.moveToSomeday(added.intention.id);
      await _pump(tester, _anna());
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      expect(CompassService.data.intentions, hasLength(1));
      expect(find.text('“Coffee with Anna” is already in your Compass.'),
          findsOneWidget);
    });

    testWidgets('an older unlinked intention matches by its exact title',
        (tester) async {
      await _init(view: 'together');
      await CompassService.addIntention(title: 'Time with Anna');
      await _pump(tester, _anna());
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      expect(CompassService.data.intentions, hasLength(1));
      expect(find.text('“Time with Anna” is already in your Compass.'),
          findsOneWidget);
    });

    testWidgets('a done intention does not count; a new one is added',
        (tester) async {
      await _init(view: 'together');
      final added = await CompassService.addIntention(
          title: 'Time with Anna', friendId: 'anna');
      await CompassService.complete(added.intention.id);
      await _pump(tester, _anna());
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      expect(CompassService.data.withStatus(IntentionStatus.now).single.title,
          'Time with Anna');
      expect(find.text('“Time with Anna” is now in your Compass.'),
          findsOneWidget);
    });

    testWidgets('another person\'s intention does not block', (tester) async {
      await _init(view: 'together');
      await CompassService.addIntention(
          title: 'Time with Anna', friendId: 'someone-else');
      await _pump(tester, _anna());
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      expect(CompassService.data.intentions, hasLength(2));
    });

    testWidgets('the snackbar stays well past the 4 s default', (tester) async {
      await _init(view: 'together');
      await _pump(tester, _anna());
      await tester.tap(find.text('Plan time together'));
      await _settle(tester);
      await tester.pump(const Duration(seconds: 6));
      expect(find.widgetWithText(SnackBarAction, 'Open'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await _settle(tester);
      expect(find.widgetWithText(SnackBarAction, 'Open'), findsNothing);
    });
  });

  group('fits a 393x851 phone', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('in $lang', (tester) async {
        final friend = _anna(
          name: 'Maximiliane Alexandra von Hohenzollern-Sigmaringen',
          frequency: MeetingFrequency.fewTimesYear,
        );
        await _init(friend: friend, view: 'together', lang: lang);
        await _pump(tester, friend, lang: lang, size: const Size(393, 851));
        final l10n = AppLocalizations(Locale(lang));
        for (final key in ['together_view_together', 'together_plan']) {
          await tester.scrollUntilVisible(
              find.text(l10n.translate(key)), 200,
              scrollable: find.byType(Scrollable).first);
          await _settle(tester);
        }
        // Every chip, including the longest label, is laid out.
        for (final f in MeetingFrequency.values) {
          expect(find.text(l10n.translate('together_freq_${f.name}')),
              findsOneWidget);
        }
        expect(tester.takeException(), isNull);

        // Daily: the most dots.
        await tester.ensureVisible(
            find.text(l10n.translate('together_freq_daily')));
        await _settle(tester);
        await tester.tap(find.text(l10n.translate('together_freq_daily')));
        await _settle(tester);
        await tester.scrollUntilVisible(
            find.text(l10n.translate('together_plan')), 200,
            scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
