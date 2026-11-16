import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result_store.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_screen.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_fonts.dart';
import 'support/lifespan_test_data.dart';

final DateTime _now = DateTime(2026, 11, 5);
final DateTime _birth = DateTime(1990, 6, 15);
const OtherSubject _ana = OtherSubject('Ana');

const double _dpr = 2.75;
const Size _pixel5Size = Size(1080 / _dpr, 2340 / _dpr);
const Size _narrowSize = Size(320, 568);

/// Keeps the result in memory and counts the saves.
class _FakeStore implements LifespanResultStore {
  _FakeStore([this.stored]);

  LifespanResult? stored;
  int saves = 0;

  @override
  LifespanResult? load() => stored;

  @override
  Future<void> save(LifespanProfile profile) async {
    saves++;
    stored = LifespanResult.of(profile.applied!);
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
    'friends_data': '[]',
  });
  await SettingsService.initialize();
}

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * _dpr;
  tester.view.devicePixelRatio = _dpr;
  tester.view.padding = const FakeViewPadding(
    top: 32 * _dpr,
    bottom: 24 * _dpr,
  );
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, String language) => MaterialApp(
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

/// A host page that pushes [screen] and remembers what it returned.
class _Host extends StatefulWidget {
  const _Host(this.screen);

  final Widget screen;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  LifespanProfile? result;
  bool returned = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        key: const ValueKey('host_open'),
        onPressed: () async {
          final profile = await Navigator.of(context).push(
            MaterialPageRoute<LifespanProfile>(builder: (_) => widget.screen),
          );
          setState(() {
            result = profile;
            returned = true;
          });
        },
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

String _named(Map<String, String> values, String key) =>
    values[key]!.replaceAll('{name}', 'Ana');

LifespanEstimateScreen _otherScreen({
  LifespanResultStore? store,
  LifespanProfile? initial,
}) => LifespanEstimateScreen(
  birthDate: _birth,
  subject: _ana,
  currentYears: 80,
  store: store,
  initial: initial,
  loadData: loadLifespanTestData,
  now: _now,
);

Future<_HostState> _pumpHost(
  WidgetTester tester,
  Widget screen, {
  String language = 'en',
  Size size = _pixel5Size,
}) async {
  _phone(tester, size);
  await tester.pumpWidget(_app(_Host(screen), language));
  await tester.pumpAndSettle();
  await _tapKey(tester, 'host_open');
  return tester.state<_HostState>(find.byType(_Host, skipOffstage: false));
}

void main() {
  setUpAll(loadAppFonts);
  setUp(_init);

  group('subject', () {
    test('self keeps the key, other adds _someone and the name', () {
      const self = SelfSubject();
      expect(self.key('estimate_title'), 'estimate_title');
      expect(self.replacements, isEmpty);
      expect(_ana.key('estimate_title'), 'estimate_title_someone');
      expect(_ana.replacements, {'name': 'Ana'});
      expect(_ana, const OtherSubject('Ana'));
    });

    test('every subject key has a _someone twin in every language', () {
      for (final code in AppLocalizations.supportedLanguages) {
        final values = AppLocalizations.valuesFor(code);
        for (final key in SubjectKeys.all) {
          expect(values[key], isNotNull, reason: '$code: $key');
          expect(values[_ana.key(key)], isNotNull, reason: '$code: $key');
        }
        expect(values['estimate_other_privacy'], isNotNull, reason: code);
      }
    });

    test('subject twins never look like plural forms', () {
      expect(LifespanEstimateSubject.someoneSuffix, isNot('_other'));
      for (final code in AppLocalizations.supportedLanguages) {
        final values = AppLocalizations.valuesFor(code);
        for (final key in SubjectKeys.all) {
          expect(_ana.key(key).endsWith('_other'), isFalse, reason: key);
          expect(values.containsKey('${key}_other'), isFalse, reason: key);
          expect(values.containsKey('${key}_one'), isFalse, reason: key);
        }
      }
    });

    test('questions name the person (in subject position)', () {
      for (final code in AppLocalizations.supportedLanguages) {
        final values = AppLocalizations.valuesFor(code);
        for (final key in [
          'estimate_title',
          'estimate_question_conditions',
          'estimate_question_smoking',
          'estimate_question_activity',
          'estimate_question_alcohol',
          'estimate_question_bmi',
          'estimate_question_social',
          'estimate_result_label',
          'estimate_your_number',
        ]) {
          expect(
            values[_ana.key(key)],
            contains('{name}'),
            reason: '$code: $key',
          );
        }
      }
    });
  });

  for (final language in AppLocalizations.supportedLanguages) {
    final values = AppLocalizations.valuesFor(language);

    testWidgets('the flow about Ana uses the _someone texts in $language', (
      tester,
    ) async {
      final host = await _pumpHost(tester, _otherScreen(), language: language);
      expect(find.text(_named(values, 'estimate_title_someone')), findsOneWidget);
      expect(find.text(values['estimate_title']!), findsNothing);
      expect(find.text(values['estimate_other_privacy']!), findsOneWidget);
      expect(find.text(values['estimate_prefer_not_someone']!), findsOneWidget);

      await _tapKey(tester, 'lifespan_personal');
      expect(
        find.text(_named(values, 'estimate_question_smoking_someone')),
        findsOneWidget,
      );
      expect(find.text(values['estimate_prefer_not_someone']!), findsOneWidget);
      await _tapKey(tester, 'lifespan_option_smoking_1');
      for (var i = 0; i < LifestyleFactor.values.length; i++) {
        await _tapKey(tester, 'lifespan_next');
      }
      expect(
        find.text(_named(values, 'estimate_question_conditions_someone')),
        findsOneWidget,
      );
      expect(
        find.text(_named(values, 'estimate_conditions_privacy_someone')),
        findsOneWidget,
      );
      await _tapKey(tester, 'lifespan_condition_stroke');
      await _tapKey(tester, 'lifespan_next');

      for (final key in [
        'estimate_result_label_someone',
        'estimate_your_number_someone',
      ]) {
        // Section labels are shown in capitals.
        expect(find.text(_named(values, key).toUpperCase()), findsOneWidget);
      }
      expect(
        find.text(_named(values, 'estimate_conditions_note_someone')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await _tapKey(tester, 'lifespan_apply');
      expect(find.byType(LifespanEstimateScreen), findsNothing);
      expect(host.returned, isTrue);
      final profile = host.result!;
      expect(profile.applied, isNotNull);
      expect(profile.answers.smoking, Smoking.quitBefore40);
      expect(profile.answers.conditions, {ChronicCondition.stroke});
      // Nothing about Ana lands in the user's own profile or settings.
      expect(SettingsService.getLifespanResult(), isNull);
      expect(SettingsService.getLifeExpectancyYears(), 80);
    });

    for (final (name, size) in [
      ('a Pixel 5', _pixel5Size),
      ('320 dp', _narrowSize),
    ]) {
      testWidgets('the basics page about Ana fits $name in $language', (
        tester,
      ) async {
        await _pumpHost(tester, _otherScreen(), language: language, size: size);
        expect(tester.takeException(), isNull);
        final actions = tester
            .getTopLeft(find.byKey(const ValueKey('lifespan_show_estimate')))
            .dy;
        for (final key in [
          'lifespan_other_privacy',
          'lifespan_sex_unspecified',
          'lifespan_personal',
        ]) {
          await tester.ensureVisible(find.byKey(ValueKey(key)));
          await tester.pumpAndSettle();
          expect(
            tester.getBottomLeft(find.byKey(ValueKey(key))).dy,
            lessThanOrEqualTo(actions),
            reason: '$key scrolls clear of the pinned buttons',
          );
        }
        final chip = find.byKey(const ValueKey('lifespan_sex_unspecified'));
        expect(tester.getBottomRight(chip).dx, lessThanOrEqualTo(size.width));
        expect(tester.takeException(), isNull);
      });

      testWidgets('the conditions page about Ana fits $name in $language', (
        tester,
      ) async {
        await _pumpHost(tester, _otherScreen(), language: language, size: size);
        await _tapKey(tester, 'lifespan_personal');
        for (var i = 0; i < LifestyleFactor.values.length; i++) {
          await _tapKey(tester, 'lifespan_next');
        }
        expect(tester.takeException(), isNull);
        final actions = tester
            .getTopLeft(find.byKey(const ValueKey('lifespan_next')))
            .dy;
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
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('store injection', () {
    testWidgets('self: starts without answers and saves the result', (
      tester,
    ) async {
      final controller = AppSettingsController();
      addTearDown(controller.dispose);
      final store = _FakeStore(
        const LifespanResult(years: 85, mean: 85, p25: 79, p75: 91),
      );
      final host = await _pumpHost(
        tester,
        LifespanEstimateScreen(
          settings: controller,
          birthDate: _birth,
          store: store,
          loadData: loadLifespanTestData,
          now: _now,
        ),
      );
      final female = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('lifespan_sex_female')),
      );
      expect(female.selected, isFalse);

      await _tapKey(tester, 'lifespan_show_estimate');
      tester
          .widget<Slider>(find.byKey(const ValueKey('lifespan_slider')))
          .onChanged!(93);
      await tester.pumpAndSettle();
      await _tapKey(tester, 'lifespan_apply');

      expect(find.byType(LifespanEstimateScreen), findsNothing);
      expect(store.saves, 1);
      expect(store.stored!.years, 93);
      expect(host.result!.applied!.appliedYears, 93);
      expect(controller.lifeExpectancyYears, 93);
      // The fake replaced the settings store.
      expect(SettingsService.getLifespanResult(), isNull);
    });

    testWidgets('other: saved to the given store, settings untouched', (
      tester,
    ) async {
      final store = _FakeStore();
      final host = await _pumpHost(
        tester,
        _otherScreen(
          store: store,
          initial: const LifespanProfile(country: 'DE', sex: Sex.male),
        ),
      );
      expect(find.text('Germany'), findsOneWidget);
      await _tapKey(tester, 'lifespan_show_estimate');
      await _tapKey(tester, 'lifespan_apply');
      expect(store.saves, 1);
      expect(store.stored, isNotNull);
      expect(host.result!.sex, Sex.male);
      expect(SettingsService.getLifespanResult(), isNull);
      expect(SettingsService.getLifeExpectancyYears(), 80);
    });

    testWidgets('leaving without applying returns null', (tester) async {
      final store = _FakeStore();
      final host = await _pumpHost(tester, _otherScreen(store: store));
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(host.returned, isTrue);
      expect(host.result, isNull);
      expect(store.saves, 0);
    });
  });
}
