import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result_store.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/conditions_page.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_flow.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_steps.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/sources_sheet.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/lifespan_test_data.dart';

final DateTime _now = DateTime(2026, 11, 5);
final DateTime _birth = DateTime(1990, 6, 15);

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: [
    for (final code in AppLocalizations.supportedLanguages) Locale(code),
  ],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: Scaffold(body: SafeArea(child: home)),
);

void _pixel5(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

bool _checked(WidgetTester tester, String key) =>
    tester.widget<CheckboxListTile>(find.byKey(ValueKey(key))).value!;

/// The conditions page with its answer kept in a [StatefulBuilder].
Future<List<Set<ChronicCondition>?>> _pumpPage(
  WidgetTester tester, {
  Set<ChronicCondition>? initial,
  VoidCallback? onSkip,
}) async {
  _pixel5(tester);
  final answers = <Set<ChronicCondition>?>[];
  var answer = initial;
  await tester.pumpWidget(
    _app(
      StatefulBuilder(
        builder: (context, setState) => ConditionsPage(
          answer: answer,
          onAnswer: (value) {
            answers.add(value);
            setState(() => answer = value);
          },
          onNext: () {},
          onSkip: () {
            answers.add(null);
            onSkip?.call();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return answers;
}

/// Pumps the whole flow; returns the applied lifestyle answers.
Future<List<LifestyleAnswers>> _pumpFlow(
  WidgetTester tester, {
  LifespanProfile initial = const LifespanProfile(),
  DateTime? birthDate,
}) async {
  _pixel5(tester);
  final applied = <LifestyleAnswers>[];
  await tester.pumpWidget(
    _app(
      LifespanEstimateFlow(
        birthDate: birthDate ?? _birth,
        currentYears: 80,
        initial: initial,
        now: _now,
        deviceCountryCode: 'DE',
        loadData: loadLifespanTestData,
        onApply: (_, _, answers) => applied.add(answers),
        onSkip: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return applied;
}

/// From the basics page through the five lifestyle questions.
Future<void> _toConditions(WidgetTester tester) async {
  await _tapKey(tester, 'lifespan_personal');
  for (var i = 0; i < LifestyleFactor.values.length; i++) {
    await _tapKey(tester, 'lifespan_next');
  }
}

final Finder _note = find.byKey(const ValueKey('lifespan_conditions_note'));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await SettingsService.initialize();
  });

  group('toggles', () {
    test('a condition clears "none"; the last one unticked is null', () {
      final ticked = toggleCondition(const {}, ChronicCondition.stroke);
      expect(ticked, {ChronicCondition.stroke});
      expect(toggleCondition(ticked, ChronicCondition.stroke), isNull);
    });

    test('"none" clears every condition; unticking it is null', () {
      expect(toggleNoCondition({ChronicCondition.copd}), isEmpty);
      expect(toggleNoCondition(null), isEmpty);
      expect(toggleNoCondition(const {}), isNull);
    });
  });

  group('QuestionSteps', () {
    test('conditions are the last question, the result comes after', () {
      expect(QuestionSteps.questionCount, LifestyleFactor.values.length + 1);
      expect(QuestionSteps.conditions, QuestionSteps.questionCount);
      expect(QuestionSteps.result, QuestionSteps.conditions + 1);
      expect(QuestionSteps.isLastQuestion(QuestionSteps.conditions), isTrue);
      expect(QuestionSteps.factorAt(QuestionSteps.conditions), isNull);
      expect(QuestionSteps.factorAt(1), LifestyleFactor.values.first);
    });

    test('answeredCount counts the conditions answer, also "none"', () {
      expect(QuestionSteps.answeredCount(const LifestyleAnswers()), 0);
      expect(
        QuestionSteps.answeredCount(
          const LifestyleAnswers(smoking: Smoking.never, conditions: {}),
        ),
        2,
      );
    });
  });

  group('ConditionsPage', () {
    testWidgets('ticks conditions; "none" is exclusive', (tester) async {
      final answers = await _pumpPage(tester);
      expect(find.text('QUESTION 6 OF 6'), findsOneWidget);
      await _tapKey(tester, 'lifespan_condition_type2Diabetes');
      await _tapKey(tester, 'lifespan_condition_copd');
      expect(answers.last, {
        ChronicCondition.type2Diabetes,
        ChronicCondition.copd,
      });

      await _tapKey(tester, 'lifespan_condition_none');
      expect(answers.last, isEmpty);
      expect(_checked(tester, 'lifespan_condition_none'), isTrue);
      expect(_checked(tester, 'lifespan_condition_copd'), isFalse);

      await _tapKey(tester, 'lifespan_condition_stroke');
      expect(answers.last, {ChronicCondition.stroke});
      expect(_checked(tester, 'lifespan_condition_none'), isFalse);
    });

    testWidgets('says the answers are never saved', (tester) async {
      await _pumpPage(tester);
      final hint = find.byKey(const ValueKey('lifespan_conditions_privacy'));
      expect(hint, findsOneWidget);
      expect(
        tester.widget<Text>(hint).data,
        'These answers are never saved – they’re only used to calculate '
        'your number.',
      );
    });

    testWidgets('skip answers null', (tester) async {
      var skipped = false;
      final answers = await _pumpPage(
        tester,
        initial: {ChronicCondition.kidney},
        onSkip: () => skipped = true,
      );
      expect(_checked(tester, 'lifespan_condition_kidney'), isTrue);
      await _tapKey(tester, 'lifespan_skip_question');
      expect(skipped, isTrue);
      expect(answers.single, isNull);
    });
  });

  group('flow', () {
    testWidgets('conditions come last; a ticked one shows the calm note', (
      tester,
    ) async {
      final applied = await _pumpFlow(tester);
      await _toConditions(tester);
      expect(find.text('QUESTION 6 OF 6'), findsOneWidget);
      await _tapKey(tester, 'lifespan_condition_heartAttack');
      await _tapKey(tester, 'lifespan_next');
      expect(find.byKey(const ValueKey('lifespan_apply')), findsOneWidget);
      expect(_note, findsOneWidget);
      expect(
        find.text(
          'Treatment and care change a lot. This is a rough planning number, '
          'not medical advice – your doctor knows your situation best.',
        ),
        findsOneWidget,
      );
      await _tapKey(tester, 'lifespan_apply');
      expect(applied.single.conditions, {ChronicCondition.heartAttack});
    });

    testWidgets('"none of these" shows no note and is kept', (tester) async {
      final applied = await _pumpFlow(tester);
      await _toConditions(tester);
      await _tapKey(tester, 'lifespan_condition_none');
      await _tapKey(tester, 'lifespan_next');
      expect(_note, findsNothing);
      await _tapKey(tester, 'lifespan_apply');
      expect(applied.single.conditions, isEmpty);
    });

    testWidgets('skip clears a stored answer and shows the result', (
      tester,
    ) async {
      final applied = await _pumpFlow(
        tester,
        initial: const LifespanProfile(
          answers: LifestyleAnswers(conditions: {ChronicCondition.copd}),
        ),
      );
      await _toConditions(tester);
      expect(_checked(tester, 'lifespan_condition_copd'), isTrue);
      await _tapKey(tester, 'lifespan_skip_question');
      expect(_note, findsNothing);
      await _tapKey(tester, 'lifespan_apply');
      expect(applied.single.conditions, isNull);
    });

    testWidgets('no note under 18, even with stored conditions', (
      tester,
    ) async {
      await _pumpFlow(
        tester,
        birthDate: DateTime(2012, 1, 1),
        initial: const LifespanProfile(
          answers: LifestyleAnswers(conditions: {ChronicCondition.stroke}),
        ),
      );
      await _tapKey(tester, 'lifespan_show_estimate');
      expect(_note, findsNothing);
    });

    testWidgets('the sources sheet lists the condition studies', (
      tester,
    ) async {
      await _pumpFlow(tester);
      await _tapKey(tester, 'lifespan_show_estimate');
      await _tapKey(tester, 'lifespan_sources');
      expect(find.text('STUDIES ON HEALTH CONDITIONS'), findsOneWidget);
      for (final citation in conditionCitations) {
        await tester.ensureVisible(find.text(citation));
        expect(find.text(citation), findsOneWidget);
      }
    });
  });

  group('storage', () {
    for (final conditions in [
      {ChronicCondition.type1Diabetes, ChronicCondition.heartFailure},
      <ChronicCondition>{},
      null,
    ]) {
      test('conditions $conditions are never stored', () async {
        final estimate = LifespanEstimator(
          lifespanTestData.tables,
        ).estimate(country: 'DE', sex: Sex.male, birthDate: _birth, now: _now);
        await const SettingsLifespanResultStore().save(
          LifespanProfile.applied(
            estimate: estimate,
            answers: LifestyleAnswers(
              activity: Activity.some,
              conditions: conditions,
            ),
            years: 84,
          ),
        );
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getKeys().where((key) => key.startsWith('lifespan')),
          [SettingsService.lifespanResultKey],
        );
        final stored = prefs.getString(SettingsService.lifespanResultKey)!;
        expect(stored, isNot(contains('conditions')));
        for (final condition in ChronicCondition.values) {
          expect(stored, isNot(contains(condition.name)));
        }
        expect(const SettingsLifespanResultStore().load()!.years, 84);
      });
    }
  });
}
