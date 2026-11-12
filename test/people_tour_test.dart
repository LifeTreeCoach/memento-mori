import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/enhanced_friends_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/people_sections.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour_trigger.dart';
import 'package:memento_mori_life_in_weeks/people/tour/tour_person_row.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:memento_mori_life_in_weeks/widget_launches.dart';

import 'support/compass_test_app.dart';

class _NoWidgetLaunches implements WidgetLaunches {
  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) =>
      const Stream<void>.empty().listen(null);
}

Friend _friend(String name, DateTime birthDate, {String? group}) => Friend(
      id: name,
      name: name,
      birthDate: birthDate,
      groupName: group,
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    );

final List<Friend> _withGroup = [
  _friend('Anna', DateTime(1990, 11, 12), group: 'Family'),
  _friend('Ben', DateTime(1980, 3, 1)),
];

final List<Friend> _noGroup = [
  _friend('Anna', DateTime(1990, 11, 12)),
  _friend('Ben', DateTime(1980, 3, 1)),
];

Future<void> _init(List<Friend> friends) => initCompassTest(
      toursSeen: false,
      extra: {
        'friends_data': jsonEncode([for (final f in friends) f.toMap()]),
      },
    );

Finder _key(String key) => find.byKey(ValueKey(key));

Finder get _tourTitle => _key('tour_title');

String _titleText(WidgetTester tester) =>
    tester.widget<Text>(_tourTitle).data!;

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// Steps through the tour, collecting every title.
Future<List<String>> _walkTour(WidgetTester tester) async {
  final titles = <String>[];
  while (_tourTitle.evaluate().isNotEmpty) {
    titles.add(_titleText(tester));
    final next = _key('tour_next');
    await _tap(tester, next.evaluate().isNotEmpty ? 'tour_next' : 'tour_done');
  }
  return titles;
}

Future<void> _pumpPeople(WidgetTester tester) =>
    pumpCompassApp(tester, EnhancedFriendsScreen(now: compassToday),
        size: const Size(393, 851));

Future<void> _openTab(WidgetTester tester, IconData icon) async {
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.byIcon(icon)));
  await tester.pumpAndSettle();
}

Future<void> _openPeopleTab(WidgetTester tester) =>
    _openTab(tester, Icons.people_outline_rounded);

bool _seen(String id) => TourProgressStore.isSeen(id);

void main() {
  setUpAll(() => initializeDateFormatting());

  group('empty list', () {
    setUp(() => _init(const []));

    testWidgets('shows add, import and the menu, in that order',
        (tester) async {
      await _pumpPeople(tester);
      expect(find.text('Tip 1 of 3'), findsOneWidget);
      expect(await _walkTour(tester),
          ['Your people', 'Birthdays you already have', 'More options']);
      expect(_seen(PeopleTour.emptyId), isTrue);
      expect(_seen(PeopleTour.listId), isFalse);
    });

    testWidgets('the list tour follows once someone was added',
        (tester) async {
      await TourProgressStore.markSeen(PeopleTour.emptyId);
      await _pumpPeople(tester);
      expect(_tourTitle, findsNothing);

      await tester.runAsync(() => FriendsService.addFriend(_noGroup.first));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(_tourTitle, findsNothing, reason: 'waits for the list to settle');

      // The reload ran outside the fake clock, so does its timer.
      await tester.runAsync(() => Future<void>.delayed(
          PeopleTour.settleDelay + const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(_titleText(tester), 'Birthday reminders');
    });
  });

  group('with people', () {
    testWidgets('shows all five steps when a group is in use',
        (tester) async {
      await _init(_withGroup);
      await _pumpPeople(tester);
      expect(find.text('Tip 1 of 5'), findsOneWidget);
      expect(await _walkTour(tester), [
        'Birthday reminders',
        'Groups',
        'A life in weeks',
        'More options',
        'Add someone',
      ]);
      expect(_seen(PeopleTour.listId), isTrue);
    });

    testWidgets('leaves out the groups step without groups', (tester) async {
      await _init(_noGroup);
      await _pumpPeople(tester);
      expect(find.text('Tip 1 of 4'), findsOneWidget);
      expect(await _walkTour(tester), isNot(contains('Groups')));
    });

    testWidgets('marks the empty tour seen too', (tester) async {
      await _init(_noGroup);
      await _pumpPeople(tester);
      expect(_seen(PeopleTour.emptyId), isTrue);
    });

    testWidgets('"How People works" in the menu replays it', (tester) async {
      await _init(_noGroup);
      await TourProgressStore.markSeen(PeopleTour.listId);
      await _pumpPeople(tester);
      expect(_tourTitle, findsNothing);

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('How People works'));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(_titleText(tester), 'Birthday reminders');
    });
  });

  group('in the shell', () {
    setUp(() => _init(_noGroup));

    Widget shell() =>
        AppShell(now: compassToday, widgetLaunches: _NoWidgetLaunches());

    testWidgets('only on the People tab, and only once', (tester) async {
      await pumpCompassApp(tester, shell(), size: const Size(393, 851));
      expect(_tourTitle, findsNothing, reason: 'not on the Life tab');

      await _openPeopleTab(tester);
      expect(_titleText(tester), 'Birthday reminders');
      await _tap(tester, 'tour_skip');

      await _openTab(tester, Icons.hourglass_empty_rounded);
      await _openPeopleTab(tester);
      expect(_tourTitle, findsNothing);
    });

    testWidgets('shows again after "Show hints again" in Settings',
        (tester) async {
      await TourProgressStore.markSeen(PeopleTour.listId);
      // Tall enough for the whole Settings list.
      await pumpCompassApp(tester, shell(), size: const Size(393, 8000));
      await _openTab(tester, Icons.settings_outlined);
      await _tap(tester, 'settings_show_tips_tile');
      expect(_seen(PeopleTour.listId), isFalse);

      await _openPeopleTab(tester);
      expect(_titleText(tester), 'Birthday reminders');
    });
  });

  group('trigger', () {
    setUp(() => _init(const []));

    testWidgets('does not start under a sheet', (tester) async {
      final anchors = TourAnchors();
      await pumpCompassApp(
        tester,
        TourAnchorScope(
          anchors: anchors,
          child: const Scaffold(
            body: TourAnchor(
                id: PeopleTour.addAnchor,
                child: SizedBox(height: 80, width: 80)),
          ),
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      final trigger =
          PeopleTourTrigger(contextOf: () => context, anchors: anchors);
      showModalBottomSheet<void>(
          context: context, builder: (_) => const SizedBox(height: 200));
      await tester.pumpAndSettle();

      unawaited(trigger.startIfDue(
          empty: true, tabVisible: () => true, blocked: () => false));
      await tester.pumpAndSettle();
      expect(_tourTitle, findsNothing);
      expect(_seen(PeopleTour.emptyId), isFalse);
    });
  });

  group('tour row', () {
    test('is the topmost person, with their section', () {
      final today = DateTime(2026, 11, 2);
      final soon = _friend('Soon', DateTime(1990, 11, 12));
      final later = _friend('Later', DateTime(1980, 3, 1));
      expect(tourPersonRowOf(PeopleSections.of([later, soon], today)),
          (section: 'upcoming', friendId: 'Soon'));
      expect(tourPersonRowOf(PeopleSections.of([later], today)),
          (section: 'everyone', friendId: 'Later'));
      expect(tourPersonRowOf(PeopleSections.of(const [], today)), isNull);
    });
  });

  test('every People tour text exists in every language', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      final values = AppLocalizations.valuesFor(lang);
      for (final step in PeopleTour.allSteps) {
        expect(values[step.titleKey], isNotNull, reason: '$lang ${step.id}');
        expect(values[step.bodyKey], isNotNull, reason: '$lang ${step.id}');
      }
      expect(values['tour_people_help'], isNotNull, reason: lang);
    }
  });
}
