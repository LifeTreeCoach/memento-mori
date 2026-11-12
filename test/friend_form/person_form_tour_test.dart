import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/enhanced_friends_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_form/friend_estimate_launcher.dart';
import 'package:memento_mori_life_in_weeks/friend_form/person_form_tour.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/compass_test_app.dart';

/// Counts the estimates opened from the form.
class _FakeLauncher {
  int calls = 0;

  Future<LifespanProfile?> call(
    BuildContext context,
    FriendEstimateRequest request,
  ) async {
    calls++;
    return null;
  }
}

final Friend _anna = Friend(
  id: 'a',
  name: 'Anna',
  birthDate: DateTime(1995, 9, 1),
  createdDate: DateTime(2025),
  lastUpdated: DateTime(2025),
);

Finder _key(String key) => find.byKey(ValueKey(key));

Finder get _tip => _key('tour_title');

final Finder _nameField =
    find.byType(TextFormField, skipOffstage: false).first;

Future<_FakeLauncher> _pumpForm(
  WidgetTester tester, {
  bool firstPerson = true,
  Friend? friend,
}) async {
  final launcher = _FakeLauncher();
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: AddFriendScreen(
        friend: friend,
        firstPerson: firstPerson,
        estimateLauncher: launcher.call,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return launcher;
}

/// Back to the top of the form, where the name field is.
Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, 3000));
  await tester.pumpAndSettle();
}

/// Taps the name field (as a person would) and types a name.
Future<void> _typeName(WidgetTester tester) async {
  await _scrollToTop(tester);
  await tester.tap(_nameField);
  await tester.pump();
  await tester.enterText(_nameField, 'Anna');
  await tester.pumpAndSettle();
}

/// "Done" on the keyboard: the name field loses focus.
Future<void> _finishName(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// Opens the birthday picker and confirms its preset date.
Future<void> _pickBirthday(WidgetTester tester) async {
  final field = find.byIcon(Icons.cake_outlined, skipOffstage: false);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _focusAndFinishName(WidgetTester tester) async {
  await _scrollToTop(tester);
  await tester.tap(_nameField);
  await tester.pump();
  await _finishName(tester);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    await FriendsService.clearCacheForTesting();
    TourProgressStore.clearCacheForTesting();
  });

  group('PersonFormTour.fits', () {
    bool fits({
      bool isEditing = false,
      bool firstPerson = true,
      String name = 'Anna',
      DateTime? birthDate,
      bool yearUnknown = false,
      bool hasEstimate = false,
    }) =>
        PersonFormTour.fits(
          isEditing: isEditing,
          firstPerson: firstPerson,
          name: name,
          birthDate: birthDate ?? DateTime(1990),
          yearUnknown: yearUnknown,
          hasEstimate: hasEstimate,
        );

    test('needs every condition', () {
      expect(fits(), isTrue);
      expect(fits(isEditing: true), isFalse);
      expect(fits(firstPerson: false), isFalse);
      expect(fits(name: '  '), isFalse);
      expect(fits(yearUnknown: true), isFalse);
      expect(fits(hasEstimate: true), isFalse);
      expect(
        PersonFormTour.fits(
          isEditing: false,
          firstPerson: true,
          name: 'Anna',
          birthDate: null,
          yearUnknown: false,
          hasEstimate: false,
        ),
        isFalse,
      );
    });
  });

  group('estimate tip on the add form', () {
    testWidgets('shows once name and birthday are set, without a counter',
        (tester) async {
      await _pumpForm(tester);
      await _typeName(tester);
      expect(_tip, findsNothing, reason: 'no birthday yet');

      await _pickBirthday(tester);
      expect(find.text('Know more, guess better'), findsOneWidget);
      expect(_key('tour_counter'), findsNothing);
      expect(find.text('Estimate now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(TourProgressStore.isSeen(PersonFormTour.id), isTrue);
    });

    testWidgets('waits for the name field to lose focus', (tester) async {
      await _pumpForm(tester);
      await _pickBirthday(tester);
      expect(_tip, findsNothing, reason: 'no name yet');

      await _typeName(tester);
      expect(_tip, findsNothing, reason: 'still typing');

      await _finishName(tester);
      expect(_tip, findsOneWidget);
    });

    testWidgets('"Estimate now" opens the estimate', (tester) async {
      final launcher = await _pumpForm(tester);
      await _typeName(tester);
      await _pickBirthday(tester);
      await tester.tap(find.text('Estimate now'));
      await tester.pumpAndSettle();
      expect(_tip, findsNothing);
      expect(launcher.calls, 1);
    });

    testWidgets('"Later" does nothing and the tip comes only once, again '
        'after a reset', (tester) async {
      final launcher = await _pumpForm(tester);
      await _typeName(tester);
      await _pickBirthday(tester);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(_tip, findsNothing);
      expect(launcher.calls, 0);

      await _pickBirthday(tester);
      await _focusAndFinishName(tester);
      expect(_tip, findsNothing, reason: 'seen');

      await TourProgressStore.reset();
      await _focusAndFinishName(tester);
      expect(_tip, findsOneWidget);
    });

    testWidgets('not when someone is already saved', (tester) async {
      await _pumpForm(tester, firstPerson: false);
      await _typeName(tester);
      await _pickBirthday(tester);
      expect(_tip, findsNothing);
      expect(TourProgressStore.isSeen(PersonFormTour.id), isFalse);
    });

    testWidgets('not with an unknown year', (tester) async {
      await _pumpForm(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await _typeName(tester);
      await _pickBirthday(tester);
      await _focusAndFinishName(tester);
      expect(_tip, findsNothing);
    });

    testWidgets('not while editing', (tester) async {
      await _pumpForm(tester, friend: _anna);
      await _pickBirthday(tester);
      await _focusAndFinishName(tester);
      expect(_tip, findsNothing);
      expect(TourProgressStore.isSeen(PersonFormTour.id), isFalse);
    });
  });

  group('People tab', () {
    AddFriendScreen openedForm(WidgetTester tester) =>
        tester.widget<AddFriendScreen>(find.byType(AddFriendScreen));

    Finder anchor(String id) =>
        find.byWidgetPredicate((w) => w is TourAnchor && w.id == id);

    testWidgets('opens the form for the first person', (tester) async {
      await initCompassTest();
      await pumpCompassApp(tester, EnhancedFriendsScreen(now: compassToday),
          size: const Size(393, 851));
      await tester.tap(anchor(PeopleTour.addAnchor));
      await tester.pumpAndSettle();
      expect(openedForm(tester).firstPerson, isTrue);
    });

    testWidgets('opens the form for a further person', (tester) async {
      await initCompassTest(extra: {
        'friends_data': jsonEncode([_anna.toMap()]),
      });
      await pumpCompassApp(tester, EnhancedFriendsScreen(now: compassToday),
          size: const Size(393, 851));
      await tester.tap(anchor(PeopleTour.fabAnchor));
      await tester.pumpAndSettle();
      expect(openedForm(tester).firstPerson, isFalse);
    });
  });
}
