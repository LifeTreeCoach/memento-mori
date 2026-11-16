import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_sections.dart';
import 'package:memento_mori_life_in_weeks/friend_form/friend_estimate_launcher.dart';
import 'package:memento_mori_life_in_weeks/friend_form/lifespan_estimate_tile.dart';
import 'package:memento_mori_life_in_weeks/friend_form/lifespan_slider.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/l10n/friend_estimate_strings.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/friend_estimate_fixtures.dart';

Friend _anna({
  bool hasYear = true,
  int? estimatedYears,
  int lifespan = 80,
}) => Friend(
  id: 'a',
  name: 'Anna',
  birthDate: hasYear ? DateTime(1995, 9, 1) : DateTime(2000, 9, 1),
  hasBirthYear: hasYear,
  customLifespan: lifespan,
  createdDate: DateTime(2025),
  lastUpdated: DateTime(2025),
  estimatedYears: estimatedYears,
);

/// Records requests and answers with [result].
class _FakeLauncher {
  _FakeLauncher(this.result);

  final LifespanProfile? result;
  final List<FriendEstimateRequest> requests = [];

  Future<LifespanProfile?> call(
    BuildContext context,
    FriendEstimateRequest request,
  ) async {
    requests.add(request);
    return result;
  }
}

Future<void> _pump(WidgetTester tester, Widget home) async {
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
      home: home,
    ),
  );
  await tester.pump();
}

/// Pushes the form so Back has somewhere to go.
Widget _opener(Friend friend, _FakeLauncher launcher) => Builder(
  builder: (context) => Scaffold(
    body: TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AddFriendScreen(friend: friend, estimateLauncher: launcher.call),
        ),
      ),
      child: const Text('open'),
    ),
  ),
);

final Finder _tile = find.byType(LifespanEstimateTile);
final String _start = friendEstimateStringsEn['form_estimate_start']!;
final String _adjusted = friendEstimateStringsEn['form_estimate_adjusted']!;
String _from(int n) => 'From an estimate · about $n years';

Future<void> _openForm(
  WidgetTester tester,
  Friend friend,
  _FakeLauncher l,
) async {
  await _pump(tester, _opener(friend, l));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

int _sliderValue(WidgetTester tester) => tester
    .widget<LifespanSlider>(find.byType(LifespanSlider, skipOffstage: false))
    .lifespan;

Future<void> _tapTile(WidgetTester tester) async {
  await tester.ensureVisible(_tile);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ListTile).last);
  await tester.pumpAndSettle();
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

  group('FriendEstimateStatus', () {
    test('follows the estimate and the slider', () {
      expect(FriendEstimateStatus.of(null, 80), FriendEstimateStatus.none);
      expect(
        FriendEstimateStatus.of(86, 86),
        FriendEstimateStatus.fromEstimate,
      );
      expect(
        FriendEstimateStatus.of(86, 90),
        FriendEstimateStatus.adjusted,
      );
    });
  });

  test('an estimate always starts without answers', () {
    final initial = FriendEstimateRequest.initialProfile();
    expect(initial.country, isNull);
    expect(initial.sex, isNull);
    expect(initial.answers.isEmpty, isTrue);
    expect(initial.applied, isNull);
  });

  testWidgets('hidden without a birth year', (tester) async {
    await _openForm(tester, _anna(hasYear: false), _FakeLauncher(null));
    expect(_tile, findsNothing);
  });

  testWidgets('applying sets the slider and moving it shows "Adjusted"', (
    tester,
  ) async {
    final launcher = _FakeLauncher(appliedFriendProfile(years: 86));
    await _openForm(tester, _anna(), launcher);
    expect(find.text(_start), findsOneWidget);
    expect(
      find.text(friendEstimateStringsEn['form_estimate_privacy']!),
      findsOneWidget,
    );

    await _tapTile(tester);
    final request = launcher.requests.single;
    expect(request.name, 'Anna');
    expect(request.currentYears, 80);
    expect(request.initial.country, isNull);
    expect(request.initial.answers.isEmpty, isTrue);
    expect(find.text(_from(86)), findsOneWidget);
    expect(_sliderValue(tester), 86);

    await tester.ensureVisible(find.byType(Slider, skipOffstage: false));
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(find.text(_adjusted), findsOneWidget);
  });

  testWidgets('forget clears the estimated years and keeps the number', (tester) async {
    await _openForm(
      tester,
      _anna(estimatedYears: 86, lifespan: 86),
      _FakeLauncher(null),
    );
    expect(find.text(_from(86)), findsOneWidget);
    await tester.ensureVisible(_tile);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(friendEstimateStringsEn['form_estimate_forget']!),
    );
    await tester.pumpAndSettle();
    expect(find.text(_start), findsOneWidget);
    expect(_sliderValue(tester), 86);
  });

  testWidgets('cancelling the estimate changes nothing', (tester) async {
    await _openForm(tester, _anna(), _FakeLauncher(null));
    await _tapTile(tester);
    expect(find.text(_start), findsOneWidget);
    // Not dirty: Back leaves without asking.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('an applied estimate counts as an unsaved change', (
    tester,
  ) async {
    final launcher = _FakeLauncher(appliedFriendProfile(years: 80));
    await _openForm(tester, _anna(), launcher);
    await _tapTile(tester); // same number, but new answers
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('open'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('the estimate is saved with the person', (tester) async {
    final anna = _anna();
    await FriendsService.addFriend(anna);
    await _openForm(tester, anna, _FakeLauncher(appliedFriendProfile()));
    await _tapTile(tester);
    await tester.ensureVisible(find.text('Save changes', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    final saved = (await FriendsService.getAllFriends()).single;
    expect(saved.customLifespan, 86);
    expect(saved.estimatedYears, 86);
    expect(saved.lifespanFromEstimate, isTrue);
  });

  testWidgets('an empty name asks for one first', (tester) async {
    final launcher = _FakeLauncher(appliedFriendProfile());
    await _openForm(tester, _anna(), launcher);
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump();
    await _tapTile(tester);
    expect(launcher.requests, isEmpty);
    expect(
      find.text(friendEstimateStringsEn['form_estimate_name_first']!),
      findsOneWidget,
    );
  });

  group('detail caption', () {
    final caption =
        friendEstimateStringsEn['friend_detail_lifespan_estimated']!;

    Future<void> pumpSection(WidgetTester tester, Friend friend) =>
        _pump(tester, Scaffold(body: FriendPersonalSection(friend: friend)));

    testWidgets('shown when the number comes from the estimate', (
      tester,
    ) async {
      await pumpSection(
        tester,
        _anna(estimatedYears: 86, lifespan: 86),
      );
      expect(find.text(caption), findsOneWidget);
    });

    testWidgets('hidden once the number was adjusted or without one', (
      tester,
    ) async {
      await pumpSection(
        tester,
        _anna(estimatedYears: 86, lifespan: 90),
      );
      expect(find.text(caption), findsNothing);
      await pumpSection(tester, _anna());
      expect(find.text(caption), findsNothing);
    });
  });

  test('estimate strings exist in every language', () {
    final keys = friendEstimateStringsEn.keys.toSet();
    for (final table in [
      friendEstimateStringsDe,
      friendEstimateStringsFr,
      friendEstimateStringsEs,
    ]) {
      expect(table.keys.toSet(), keys);
    }
    for (final code in AppLocalizations.supportedLanguages) {
      expect(
        AppLocalizations.valuesFor(code).keys,
        containsAll(keys),
        reason: code,
      );
    }
  });
}
