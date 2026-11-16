import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_screen.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/result_page.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/life_expectancy_sheet.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/lifespan_test_data.dart';

/// Layout checks of the estimate flow on a Pixel 5 (393x851 logical, status
/// and navigation bar insets) with the app's real fonts and dark theme.
final DateTime _now = DateTime(2026, 11, 5);
final DateTime _birth = DateTime(1990, 6, 15);

const double _dpr = 2.75;

Future<void> _loadFonts() async {
  final families = {
    AppTheme.sansFamily: ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold'],
    AppTheme.serifFamily: ['Fraunces-Regular', 'Fraunces-SemiBold'],
    AppTheme.roundedFamily: ['Nunito-SemiBold', 'Nunito-Bold'],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await loader.load();
  }
}

Future<void> _init({int lifeExpectancy = 80}) async {
  SharedPreferences.setMockInitialValues({
    'birth_date': _birth.toIso8601String(),
    'language': 'en',
    'life_expectancy_years': lifeExpectancy,
    'friends_data': '[]',
  });
  await SettingsService.initialize();
}

/// Pixel 5 in logical pixels.
const Size _pixel5Size = Size(1080 / _dpr, 2340 / _dpr);

/// A small 320 dp wide phone.
const Size _narrowSize = Size(320, 568);

void _pixel5(
  WidgetTester tester, {
  double keyboard = 0,
  Size size = _pixel5Size,
}) {
  tester.view.physicalSize = size * _dpr;
  tester.view.devicePixelRatio = _dpr;
  tester.view.padding = const FakeViewPadding(
    top: 32 * _dpr,
    bottom: 24 * _dpr,
  );
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * _dpr);
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, String language) {
  return MaterialApp(
    theme: AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.dark),
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

/// Pumps the Settings variant of the flow (app bar + pinned actions).
Future<void> _pumpScreen(
  WidgetTester tester,
  String language, {
  double keyboard = 0,
  Size size = _pixel5Size,
}) async {
  _pixel5(tester, keyboard: keyboard, size: size);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(const SizedBox()); // fresh state on every pump
  await tester.pumpWidget(
    _app(
      LifespanEstimateScreen(
        settings: controller,
        birthDate: _birth,
        loadData: loadLifespanTestData,
        now: _now,
      ),
      language,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

double _top(WidgetTester tester, String key) =>
    tester.getTopLeft(find.byKey(ValueKey(key))).dy;

void main() {
  setUpAll(_loadFonts);
  setUp(_init);

  for (final language in AppLocalizations.supportedLanguages) {
    final values = AppLocalizations.valuesFor(language);

    testWidgets('the app bar title fits in $language', (tester) async {
      await _pumpScreen(tester, language);
      final title = find.text(values['estimate_screen_title']!);
      expect(title, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
        isFalse,
      );
    });

    testWidgets('the personal card shows without scrolling in $language', (
      tester,
    ) async {
      await _pumpScreen(tester, language);
      expect(tester.takeException(), isNull);
      final card = find.byKey(const ValueKey('lifespan_personal'));
      expect(card, findsOneWidget);
      expect(
        tester.getBottomLeft(card).dy,
        lessThanOrEqualTo(_top(tester, 'lifespan_show_estimate')),
        reason: 'the whole card is above the pinned buttons',
      );
    });

    testWidgets('the BMI line stays visible while typing in $language', (
      tester,
    ) async {
      // A Gboard-sized keyboard on a Pixel 5.
      await _pumpScreen(tester, language, keyboard: 300);
      await _tapKey(tester, 'lifespan_personal');
      for (var i = 0; i < 3; i++) {
        await _tapKey(tester, 'lifespan_next');
      }
      await tester.tap(find.byKey(const ValueKey('lifespan_height')));
      await tester.enterText(
        find.byKey(const ValueKey('lifespan_height')),
        '180',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lifespan_weight')));
      await tester.enterText(
        find.byKey(const ValueKey('lifespan_weight')),
        '75',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final next = _top(tester, 'lifespan_next');
      final result = find.textContaining(
        values['estimate_weight_result']!.split('{band}').first.trim(),
      );
      final privacy = find.text(values['estimate_weight_privacy']!);
      for (final line in [result, privacy]) {
        expect(line, findsOneWidget);
        expect(tester.getBottomLeft(line).dy, lessThanOrEqualTo(next));
      }
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('lifespan_weight'))).dy,
        greaterThanOrEqualTo(kToolbarHeight + 32),
        reason: 'the field itself stays below the app bar',
      );
    });
  }

  for (final (name, size) in [
    ('a Pixel 5', _pixel5Size),
    ('320 dp', _narrowSize),
  ]) {
    for (final language in AppLocalizations.supportedLanguages) {
      testWidgets('the conditions question fits $name in $language', (
        tester,
      ) async {
        await _pumpScreen(tester, language, size: size);
        await _tapKey(tester, 'lifespan_personal');
        for (var i = 0; i < LifestyleFactor.values.length; i++) {
          await _tapKey(tester, 'lifespan_next');
        }
        expect(tester.takeException(), isNull);
        final actions = _top(tester, 'lifespan_next');
        for (final key in [
          for (final c in ChronicCondition.values)
            'lifespan_condition_${c.name}',
          'lifespan_condition_none',
        ]) {
          await tester.ensureVisible(find.byKey(ValueKey(key)));
          await tester.pumpAndSettle();
          expect(
            tester.getBottomLeft(find.byKey(ValueKey(key))).dy,
            lessThanOrEqualTo(actions),
            reason: '$key scrolls clear of the pinned buttons',
          );
        }
        await _tapKey(tester, 'lifespan_condition_stroke');
        for (final key in ['lifespan_next', 'lifespan_skip_question']) {
          final button = find.byKey(ValueKey(key));
          expect(
            tester.getBottomLeft(button).dy,
            lessThanOrEqualTo(size.height),
          );
          final label = find.descendant(
            of: button,
            matching: find.byType(Text),
          );
          expect(
            tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
            isFalse,
          );
        }
        await _tapKey(tester, 'lifespan_next');
        expect(tester.takeException(), isNull);
        final note = find.byKey(const ValueKey('lifespan_conditions_note'));
        await tester.ensureVisible(note);
        await tester.pumpAndSettle();
        expect(note, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('result page', () {
    Future<void> toResult(WidgetTester tester, {int current = 80}) async {
      await _init(lifeExpectancy: current);
      await _pumpScreen(tester, 'de');
      await _tapKey(tester, 'lifespan_show_estimate');
    }

    void setSlider(WidgetTester tester, int years) {
      tester
          .widget<Slider>(find.byKey(const ValueKey('lifespan_slider')))
          .onChanged!(years.toDouble());
    }

    testWidgets('one "keep" button when the value equals the setting', (
      tester,
    ) async {
      await toResult(tester);
      setSlider(tester, 80);
      await tester.pumpAndSettle();
      expect(find.text('80\u00A0Jahre behalten'), findsOneWidget);
      expect(find.text('80\u00A0Jahre übernehmen'), findsNothing);
      expect(find.byType(TextButton), findsNWidgets(1)); // only "Sources"

      setSlider(tester, 86);
      await tester.pumpAndSettle();
      expect(find.text('86\u00A0Jahre übernehmen'), findsOneWidget);
      expect(find.text('80\u00A0Jahre behalten'), findsOneWidget);
    });

    testWidgets('keeping the same value still saves the estimate', (
      tester,
    ) async {
      await toResult(tester);
      setSlider(tester, 80);
      await tester.pumpAndSettle();
      await _tapKey(tester, 'lifespan_apply');
      expect(find.byType(LifespanEstimateScreen), findsNothing);
      expect(SettingsService.getLifespanResult()!.years, 80);
      expect(SettingsService.getLifeExpectancyYears(), 80);
    });

    testWidgets('the slider announces years, not a percentage', (tester) async {
      final handle = tester.ensureSemantics();
      await toResult(tester);
      setSlider(tester, 87);
      await tester.pumpAndSettle();
      expect(find.semantics.byValue('87\u00A0Jahre'), findsOne);
      expect(find.semantics.byValue(RegExp('%')), findsNothing);
      handle.dispose();
    });
  });

  testWidgets('the life expectancy sheet slider announces years', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    _pixel5(tester);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLifeExpectancySheet(context, 81),
              child: const Text('open'),
            ),
          ),
        ),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.semantics.byValue('81\u00A0years'), findsOne);
    expect(
      find.text(
        '80 is just a round starting value – a lens, not a prediction.',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
  for (final language in AppLocalizations.supportedLanguages) {
    testWidgets('the "chance to reach" captions keep apart in $language', (
      tester,
    ) async {
      _pixel5(tester);
      const estimate = LifespanEstimate(
        country: 'ESP',
        sex: Sex.female,
        age: 36,
        mean: 87,
        p25: 83,
        median: 88,
        p75: 95,
        reach80: 0.84,
        reach90: 0.47,
        multiplier: 1,
        recommendedYears: 87,
        gains: {},
      );
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ResultPage(
              estimate: estimate,
              years: 87,
              currentYears: 80,
              keepLabel: 'keep',
              onYearsChanged: (_) {},
              onApply: () {},
              onKeep: () {},
            ),
          ),
          language,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Finder caption(int age) => find
          .descendant(
            of: find.byKey(ValueKey('estimate_reach_$age')),
            matching: find.byType(Text),
          )
          .last;
      final firstEnd = tester.getTopRight(caption(80)).dx;
      final secondStart = tester.getTopLeft(caption(90)).dx;
      expect(secondStart - firstEnd, greaterThanOrEqualTo(24));
    });
  }
}
