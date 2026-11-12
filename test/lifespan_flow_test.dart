import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/lifespan_bar.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_profile_store.dart';
import 'package:memento_mori_life_in_weeks/lifespan/applied_estimate.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/country_picker_sheet.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_intro.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_data.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_flow.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_screen.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_page.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_screen.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_fonts.dart';
import 'support/lifespan_test_data.dart';

final DateTime _now = DateTime(2026, 11, 5);
final DateTime _birth = DateTime(1990, 6, 15);

class _Applied {
  _Applied(this.years, this.estimate, this.answers);
  final int years;
  final LifespanEstimate estimate;
  final LifestyleAnswers answers;
}

Future<void> _init({Map<String, Object> extra = const {}}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (_) async => true,
      );
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': _birth.toIso8601String(),
    'language': 'en',
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': '[]',
    ...extra,
  });
  PackageInfo.setMockInitialValues(
    appName: 'Memento Mori',
    packageName: 'test',
    version: '1.2.3',
    buildNumber: '45',
    buildSignature: '',
  );
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
}

Widget _app(Widget home, {String language = 'en'}) {
  return MaterialApp(
    theme: AppTheme.build(
      style: ThemeStyle.stoic,
      brightness: Brightness.light,
    ),
    locale: Locale(language),
    supportedLocales: [
      for (final code in AppLocalizations.supportedLanguages) Locale(code),
    ],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  );
}

void _pixel5(WidgetTester tester, {double devicePixelRatio = 2.75}) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
}

/// Pumps the flow alone; returns the list that collects applied results.
Future<List<_Applied>> _pumpFlow(
  WidgetTester tester, {
  DateTime? birthDate,
  LifespanProfile initial = const LifespanProfile(),
  String? deviceCountry = 'DE',
  String language = 'en',
  LifespanDataLoader? loadData,
  VoidCallback? onSkip,
  GlobalKey<LifespanEstimateFlowState>? key,
  double devicePixelRatio = 2.75,
  EstimateIntro? intro,
}) async {
  _pixel5(tester, devicePixelRatio: devicePixelRatio);
  await tester.pumpWidget(const SizedBox()); // fresh state on every pump
  final applied = <_Applied>[];
  await tester.pumpWidget(
    _app(
      Scaffold(
        body: SafeArea(
          child: LifespanEstimateFlow(
            key: key,
            birthDate: birthDate ?? _birth,
            currentYears: 80,
            initial: initial,
            now: _now,
            deviceCountryCode: deviceCountry,
            loadData: loadData ?? loadLifespanTestData,
            onApply: (years, estimate, answers) =>
                applied.add(_Applied(years, estimate, answers)),
            onSkip: onSkip ?? () {},
            intro: intro,
          ),
        ),
      ),
      language: language,
    ),
  );
  await tester.pumpAndSettle();
  return applied;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

LifespanEstimate _population(String country, Sex sex, {DateTime? birth}) =>
    LifespanEstimator(lifespanTestData.tables).estimate(
      country: country,
      sex: sex,
      birthDate: birth ?? _birth,
      now: _now,
    );

void main() {
  setUp(() => _init());

  group('LifespanEstimateFlow', () {
    testWidgets('prefills the device country, else World', (tester) async {
      await _pumpFlow(tester);
      expect(find.text('Germany'), findsOneWidget);
      expect(find.text('A starting point for your years'), findsOneWidget);

      await _pumpFlow(tester, deviceCountry: 'XX');
      expect(find.text('World'), findsOneWidget);
    });

    testWidgets('a stored country wins over the device region', (tester) async {
      await _pumpFlow(
        tester,
        initial: const LifespanProfile(country: 'FR', sex: Sex.female),
      );
      expect(find.text('France'), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('lifespan_sex_female')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('country names follow the app language', (tester) async {
      await _pumpFlow(tester, language: 'fr');
      expect(find.text('Allemagne'), findsOneWidget);
      expect(find.text('Voir mon estimation'), findsOneWidget);
    });

    testWidgets('picks a country via accent-insensitive search', (
      tester,
    ) async {
      final applied = await _pumpFlow(tester, deviceCountry: 'US');
      await _tapKey(tester, 'lifespan_country');
      await tester.enterText(
        find.byKey(const ValueKey('lifespan_country_search')),
        'cote',
      );
      await tester.pumpAndSettle();
      expect(find.text('Côte d’Ivoire'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'United States'), findsNothing);
      await tester.tap(find.text('Côte d’Ivoire'));
      await tester.pumpAndSettle();
      expect(find.text('Côte d’Ivoire'), findsOneWidget);

      await _tapKey(tester, 'lifespan_show_estimate');
      await _tapKey(tester, 'lifespan_apply');
      expect(applied.single.estimate.country, 'CI');
    });

    testWidgets('search shows a calm message when nothing matches', (
      tester,
    ) async {
      await _pumpFlow(tester);
      await _tapKey(tester, 'lifespan_country');
      await tester.enterText(
        find.byKey(const ValueKey('lifespan_country_search')),
        'zzzz',
      );
      await tester.pumpAndSettle();
      expect(find.text('No country matches.'), findsOneWidget);
    });

    testWidgets('skipping all questions gives the population estimate', (
      tester,
    ) async {
      final applied = await _pumpFlow(tester);
      await _tapKey(tester, 'lifespan_sex_male');
      await _tapKey(tester, 'lifespan_personal');
      expect(find.text('QUESTION 1 OF 6'), findsOneWidget);
      await _tapKey(tester, 'lifespan_skip_rest');

      final expected = _population('DE', Sex.male);
      expect(
        find.text('About ${expected.mean.round()}\u00A0years'),
        findsOneWidget,
      );
      expect(
        find.text(
          'People with answers like yours live on average to about '
          '${expected.mean.round()}; for half of them it’s between '
          '${expected.p25.round()} and ${expected.p75.round()}.',
        ),
        findsOneWidget,
      );
      expect(find.text('What tends to help'), findsNothing);

      await _tapKey(tester, 'lifespan_apply');
      final result = applied.single;
      expect(result.answers.isEmpty, isTrue);
      expect(result.estimate.multiplier, 1.0);
      expect(result.estimate.mean, closeTo(expected.mean, 1e-9));
      expect(result.years, expected.recommendedYears);
    });

    testWidgets('answers change the estimate and show possible gains', (
      tester,
    ) async {
      final applied = await _pumpFlow(tester);
      await _tapKey(tester, 'lifespan_personal');
      // Smoking: "Yes, 10 or more a day" (index 4).
      await _tapKey(tester, 'lifespan_option_smoking_4');
      await _tapKey(tester, 'lifespan_next');
      // Activity: "Hardly at all".
      await _tapKey(tester, 'lifespan_option_activity_0');
      await _tapKey(tester, 'lifespan_next');
      // Alcohol: prefer not to say (default), then the weight page.
      await _tapKey(tester, 'lifespan_next');
      await tester.enterText(
        find.byKey(const ValueKey('lifespan_height')),
        '180',
      );
      await tester.enterText(
        find.byKey(const ValueKey('lifespan_weight')),
        '75',
      );
      await tester.pumpAndSettle();
      expect(find.text('Your range: BMI 18.5 to 25'), findsOneWidget);
      expect(
        find.text('Only the range is kept, never your height or weight.'),
        findsOneWidget,
      );
      await _tapKey(tester, 'lifespan_next');
      expect(find.text('QUESTION 5 OF 6'), findsOneWidget);
      await _tapKey(tester, 'lifespan_next');
      expect(find.text('QUESTION 6 OF 6'), findsOneWidget);
      await _tapKey(tester, 'lifespan_next'); // last: "Show my estimate"

      final population = _population('WLD', Sex.unspecified);
      await _tapText(tester, 'What tends to help');
      expect(find.text('Smoking'), findsOneWidget);
      expect(find.textContaining('about +'), findsWidgets);

      await _tapKey(tester, 'lifespan_apply');
      final result = applied.single;
      expect(result.answers.smoking, Smoking.currentHeavy);
      expect(result.answers.activity, Activity.inactive);
      expect(result.answers.alcohol, isNull);
      expect(result.answers.bmi, BmiBand.healthy);
      expect(result.answers.social, isNull);
      expect(result.estimate.multiplier, greaterThan(1));
      expect(population.mean, isNot(result.estimate.mean));
    });

    testWidgets('the slider fine-tunes the applied years', (tester) async {
      final applied = await _pumpFlow(tester);
      await _tapKey(tester, 'lifespan_show_estimate');
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('lifespan_slider')),
      );
      expect(slider.min, 50);
      expect(slider.max, 110);
      slider.onChanged!(95);
      await tester.pumpAndSettle();
      expect(find.text('Use 95\u00A0years'), findsOneWidget);
      await _tapKey(tester, 'lifespan_apply');
      expect(applied.single.years, 95);
    });

    testWidgets('the sources sheet lists the UN data and the studies', (
      tester,
    ) async {
      await _pumpFlow(tester);
      await _tapKey(tester, 'lifespan_show_estimate');
      expect(
        find.text(
          'Statistical estimate from UN data (WPP 2024). '
          'You can change it anytime.',
        ),
        findsOneWidget,
      );
      await _tapKey(tester, 'lifespan_sources');
      expect(
        find.textContaining('World Population Prospects 2024'),
        findsOneWidget,
      );
      expect(find.textContaining('CC BY 3.0 IGO'), findsOneWidget);
      expect(find.textContaining('Jha P'), findsOneWidget);
    });

    testWidgets('back walks the pages, then reports the first page', (
      tester,
    ) async {
      final key = GlobalKey<LifespanEstimateFlowState>();
      await _pumpFlow(tester, key: key);
      await _tapKey(tester, 'lifespan_personal');
      await _tapKey(tester, 'lifespan_next');
      expect(find.text('QUESTION 2 OF 6'), findsOneWidget);
      expect(key.currentState!.back(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('QUESTION 1 OF 6'), findsOneWidget);
      expect(key.currentState!.back(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Germany'), findsOneWidget);
      expect(key.currentState!.back(), isFalse);
    });

    testWidgets('no lifestyle questions under 18', (tester) async {
      final applied = await _pumpFlow(
        tester,
        birthDate: DateTime(2012, 1, 1),
        initial: const LifespanProfile(
          answers: LifestyleAnswers(smoking: Smoking.currentHeavy),
        ),
      );
      expect(find.text('Make it more personal'), findsNothing);
      await _tapKey(tester, 'lifespan_show_estimate');
      await _tapKey(tester, 'lifespan_apply');
      expect(applied.single.answers.isEmpty, isTrue);
      expect(applied.single.estimate.multiplier, 1.0);
    });

    testWidgets('a failed load keeps the current value', (tester) async {
      var skipped = 0;
      await _pumpFlow(
        tester,
        loadData: () async => throw StateError('no asset'),
        onSkip: () => skipped++,
      );
      expect(
        find.text(
          'The data couldn’t be loaded right now. '
          'Your current number stays as it is.',
        ),
        findsOneWidget,
      );
      await _tapText(tester, 'Keep 80\u00A0years');
      expect(skipped, 1);
    });

    group('an intro from the caller', () {
      const intro = EstimateIntro(title: 'Caller title', text: 'Caller text');
      final values = AppLocalizations.valuesFor('en');

      testWidgets('replaces the default title and text', (tester) async {
        await _pumpFlow(tester, intro: intro);
        expect(find.text('Caller title'), findsOneWidget);
        expect(find.text('Caller text'), findsOneWidget);
        expect(find.text(values['estimate_title']!), findsNothing);
        expect(find.text(values['estimate_intro']!), findsNothing);
      });

      testWidgets('titles the failed page too', (tester) async {
        await _pumpFlow(
          tester,
          intro: intro,
          loadData: () async => throw StateError('no asset'),
        );
        expect(find.text('Caller title'), findsOneWidget);
        expect(find.text(values['estimate_title']!), findsNothing);
      });

      testWidgets('without one the default texts show', (tester) async {
        await _pumpFlow(tester);
        expect(find.text(values['estimate_title']!), findsOneWidget);
        expect(find.text(values['estimate_intro']!), findsOneWidget);
      });
    });

    testWidgets('the baseline bar follows the sex choice, without a number', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpFlow(tester);
      final bar = find.byKey(const ValueKey('lifespan_baseline_bar'));
      double share() => tester.widget<LifespanBar>(bar).fractions.today;
      final everyone = _population('DE', Sex.unspecified).recommendedYears;
      expect(share(), closeTo(everyone / estimateMaxYears, 1e-9));
      expect(
        find.bySemanticsLabel(
          'A bar showing the average lifespan for these answers',
        ),
        findsOneWidget,
      );
      expect(find.text('$everyone'), findsNothing);

      await _tapKey(tester, 'lifespan_sex_female');
      expect(share(), greaterThan(everyone / estimateMaxYears));
      await _tapKey(tester, 'lifespan_sex_male');
      expect(share(), lessThan(everyone / estimateMaxYears));
      expect(tester.binding.hasScheduledFrame, isFalse);
      semantics.dispose();
    });

    for (final (name, dpr) in [('Pixel 5', 2.75), ('360 dp', 3.0)]) {
      testWidgets('the basics page fits $name in every language', (
        tester,
      ) async {
        await loadAppFonts();
        for (final language in AppLocalizations.supportedLanguages) {
          await _pumpFlow(tester, language: language, devicePixelRatio: dpr);
          expect(tester.takeException(), isNull, reason: language);
          final viewport = tester.getRect(
            find.byKey(const ValueKey('step_layout_scroll')),
          );
          final bar = find.byKey(const ValueKey('lifespan_baseline_bar'));
          expect(
            tester.getRect(bar).bottom,
            lessThanOrEqualTo(viewport.bottom),
            reason: '$language: the bar shows without scrolling',
          );
          if (dpr == 2.75) {
            expect(
              tester
                  .getRect(find.byKey(const ValueKey('lifespan_personal')))
                  .bottom,
              lessThanOrEqualTo(viewport.bottom),
              reason: '$language: the card shows without scrolling',
            );
          }
        }
      });
    }

    testWidgets('fits a Pixel 5 in every language', (tester) async {
      for (final language in AppLocalizations.supportedLanguages) {
        await _pumpFlow(tester, language: language);
        await _tapKey(tester, 'lifespan_personal');
        await _tapKey(tester, 'lifespan_option_smoking_4');
        await _tapKey(tester, 'lifespan_skip_rest');
        await _tapText(
          tester,
          AppLocalizations(Locale(language)).translate('estimate_gains_title'),
        );
        expect(tester.takeException(), isNull, reason: language);
      }
    });
  });

  test('every question, option and factor has a string in every language', () {
    for (final language in AppLocalizations.supportedLanguages) {
      final values = AppLocalizations.valuesFor(language);
      for (final factor in LifestyleFactor.values) {
        final keys = [
          LifestyleText.question(factor),
          LifestyleText.hint(factor),
          LifestyleText.factorName(factor),
          for (final option in factor.options)
            LifestyleText.option(factor, option),
        ];
        for (final key in keys) {
          expect(values.containsKey(key), isTrue, reason: '$language $key');
        }
      }
    }
  });

  test('filterCountries ignores case and accents', () {
    final codes = filterCountries(lifespanTestData.countries, 'de', 'OSTERR');
    expect(codes, ['AT']);
    expect(filterCountries(lifespanTestData.countries, 'en', '').first, 'WLD');
  });

  group('storage', () {
    test('profile round-trips through SettingsService', () async {
      final estimate = _population('DE', Sex.female);
      await const SettingsLifespanProfileStore().save(
        LifespanProfile.applied(
          estimate: estimate,
          answers: const LifestyleAnswers(smoking: Smoking.never),
          years: 90,
        ),
      );
      final stored = const SettingsLifespanProfileStore().load();
      expect(stored.country, 'DE');
      expect(stored.sex, Sex.female);
      expect(stored.answers.smoking, Smoking.never);
      expect(stored.applied!.appliedYears, 90);
      expect(stored.applied!.estimate.mean, estimate.mean);
    });

    test('unreadable stored JSON reads as empty', () async {
      await _init(
        extra: {'lifespan_answers': '{oops', 'lifespan_estimate': '[]'},
      );
      expect(SettingsService.getLifespanAnswers().isEmpty, isTrue);
      expect(SettingsService.getLifespanEstimate(), isNull);
    });
  });

  group('Settings', () {
    setUp(() => LifespanEstimateScreen.defaultLoader = loadLifespanTestData);

    Future<void> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 12000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final controller = AppSettingsController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        AppSettingsScope(
          controller: controller,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) =>
                _app(const SettingsScreen(alwaysShowDiagnostics: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the tile opens the estimate; applying saves all keys', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(find.text('Estimate my lifespan'), findsOneWidget);
      expect(find.text('Based on UN data for your country'), findsOneWidget);

      await _tapKey(tester, 'settings_lifespan_estimate');
      expect(find.byType(LifespanEstimateScreen), findsOneWidget);
      // Make sure the result does not depend on the test machine's region.
      await _tapKey(tester, 'lifespan_country');
      await tester.enterText(
        find.byKey(const ValueKey('lifespan_country_search')),
        'germ',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'lifespan_sex_female');
      await _tapKey(tester, 'lifespan_show_estimate');
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('lifespan_slider')),
      );
      slider.onChanged!(97);
      await tester.pumpAndSettle();
      await _tapKey(tester, 'lifespan_apply');

      expect(find.byType(LifespanEstimateScreen), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lifespan_country'), 'DE');
      expect(prefs.getString('lifespan_sex'), 'female');
      expect(jsonDecode(prefs.getString('lifespan_answers')!), {'v': 1});
      final stored = AppliedLifespanEstimate.fromJson(
        jsonDecode(prefs.getString('lifespan_estimate')!)
            as Map<String, Object?>,
      )!;
      expect(stored.appliedYears, 97);
      expect(stored.estimate.country, 'DE');
      expect(prefs.getInt('life_expectancy_years'), 97);
      expect(find.text('97\u00A0years'), findsOneWidget);
      final mean = stored.estimate.mean.round();
      expect(find.textContaining('About $mean · range'), findsOneWidget);
      expect(find.textContaining('adjusted by you'), findsNothing);
    });

    testWidgets('a later change of the years shows "adjusted by you"', (
      tester,
    ) async {
      final estimate = _population('DE', Sex.female);
      await const SettingsLifespanProfileStore().save(
        LifespanProfile.applied(
          estimate: estimate,
          answers: const LifestyleAnswers(),
          years: estimate.recommendedYears,
        ),
      );
      await SettingsService.setLifeExpectancyYears(
        estimate.recommendedYears + 3,
      );
      await pumpSettings(tester);
      expect(find.textContaining('adjusted by you'), findsOneWidget);
    });

    testWidgets('the life expectancy sheet links to the estimate', (
      tester,
    ) async {
      await pumpSettings(tester);
      await _tapText(tester, 'Life expectancy');
      expect(find.text('Estimate from data'), findsOneWidget);
      await _tapKey(tester, 'life_expectancy_estimate');
      expect(find.byType(LifespanEstimateScreen), findsOneWidget);
      // Back from the first page closes the screen without saving.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(LifespanEstimateScreen), findsNothing);
      expect(SettingsService.getLifespanEstimate(), isNull);
    });
  });
}
