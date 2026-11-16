import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_form/friend_estimate_launcher.dart';
import 'package:memento_mori_life_in_weeks/friend_form/lifespan_estimate_tile.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_screen.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/onboarding_answers.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/lifespan_test_data.dart';

/// Guards that a lifespan estimate keeps only its result: none of its
/// answers (country, sex, lifestyle, health conditions) or internals may
/// end up in the preferences, a friend's JSON or a backup.

final DateTime _now = DateTime(2026, 11, 5);
final DateTime _birth = DateTime(1990, 6, 15);

/// Every answer set, incl. several health conditions.
const LifestyleAnswers _allAnswers = LifestyleAnswers(
  smoking: Smoking.currentHeavy,
  activity: Activity.guideline,
  alcohol: Alcohol.from15to28,
  bmi: BmiBand.over30,
  social: SocialConnection.oftenLonely,
  conditions: {ChronicCondition.copd, ChronicCondition.type2Diabetes},
);

LifespanProfile _fullProfile() => LifespanProfile.applied(
  estimate: LifespanEstimator(lifespanTestData.tables).estimate(
    country: 'DE',
    sex: Sex.female,
    birthDate: _birth,
    now: _now,
    answers: _allAnswers,
  ),
  answers: _allAnswers,
  years: 77,
);

/// Words that would reveal an answer or an internal of the estimate.
final List<String> _forbidden = [
  for (final condition in ChronicCondition.values) condition.name,
  for (final factor in LifestyleFactor.values) factor.name,
  for (final option in [
    Smoking.currentHeavy,
    Activity.guideline,
    Alcohol.from15to28,
    BmiBand.over30,
    SocialConnection.oftenLonely,
  ])
    option.name,
  'conditions',
  'multiplier',
  'conditionMultiplier',
  'gains',
  'country',
  'sex',
];

void _expectNoAnswers(String text, String where) {
  for (final word in _forbidden) {
    expect(
      RegExp('\\b$word\\b').hasMatch(text),
      isFalse,
      reason: '"$word" found in $where: $text',
    );
  }
}

Future<void> _expectCleanPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in prefs.getKeys()) {
    _expectNoAnswers(key, 'a preferences key');
    _expectNoAnswers('${prefs.get(key)}', 'preference "$key"');
  }
}

Future<void> _init() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (_) async => true,
      );
  SharedPreferences.setMockInitialValues({
    'birth_date': _birth.toIso8601String(),
    'language': 'en',
    'life_expectancy_years': 80,
    'lifespan_visualization_enabled': false,
    'friends_data': '[]',
  });
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
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
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => screen)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Friend _anna() => Friend(
  id: 'a',
  name: 'Anna',
  birthDate: DateTime(1995, 9, 1),
  createdDate: DateTime(2026),
  lastUpdated: DateTime(2026),
);

void main() {
  setUp(_init);

  testWidgets('the user\'s own estimate keeps only its result', (
    tester,
  ) async {
    final controller = AppSettingsController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      LifespanEstimateScreen(
        settings: controller,
        birthDate: _birth,
        initial: LifespanProfile(
          country: 'DE',
          sex: Sex.female,
          answers: _allAnswers,
        ),
        loadData: loadLifespanTestData,
        now: _now,
      ),
    );
    await _tapKey(tester, 'lifespan_show_estimate');
    await _tapKey(tester, 'lifespan_apply');
    expect(find.byType(LifespanEstimateScreen), findsNothing);

    expect(SettingsService.getLifespanResult(), isNotNull);
    await _expectCleanPrefs();
  });

  test('the onboarding saves only the result', () async {
    await OnboardingAnswers(
      birthDate: _birth,
      lifeExpectancyYears: 77,
      lifespan: _fullProfile(),
    ).save(null);
    expect(SettingsService.getLifespanResult()!.years, 77);
    await _expectCleanPrefs();
  });

  testWidgets('a person\'s estimate keeps only the years', (tester) async {
    await FriendsService.addFriend(_anna());
    Future<LifespanProfile?> launcher(
      BuildContext context,
      FriendEstimateRequest request,
    ) async => _fullProfile();
    await _pump(
      tester,
      AddFriendScreen(friend: _anna(), estimateLauncher: launcher),
    );
    await tester.ensureVisible(find.byType(LifespanEstimateTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = (await FriendsService.getAllFriends()).single;
    expect(saved.estimatedYears, 77);
    _expectNoAnswers(jsonEncode(saved.toMap()), 'Friend.toMap');
    _expectNoAnswers(FriendsService.encodeBackup([saved]), 'the backup');
    await _expectCleanPrefs();
  });
}
