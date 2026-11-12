import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/onboarding/onboarding_answers.dart';
import 'package:memento_mori_life_in_weeks/onboarding/onboarding_screen.dart';
import 'package:memento_mori_life_in_weeks/onboarding/reminder_opt_in.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_dots.dart';
import 'package:memento_mori_life_in_weeks/onboarding/theme_toggle.dart';
import 'package:memento_mori_life_in_weeks/onboarding/support_step.dart';
import 'package:memento_mori_life_in_weeks/support/support_channel.dart';
import 'package:memento_mori_life_in_weeks/support/support_scope.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_fonts.dart';
import 'support/lifespan_test_data.dart';

final DateTime _today = DateTime(2026, 11, 2);

/// The date the tests pick: the picker opens on 1996 (today − 30 years),
/// so tapping "1996", then "15", then OK gives 15 Nov 1996.
final DateTime _picked = DateTime(1996, 11, 15);

class _FakeReminders implements ReminderOptIn {
  int enabled = 0;
  int skipped = 0;

  @override
  Future<void> enable() async => enabled++;

  @override
  Future<void> skip() async => skipped++;
}

Future<void> _init({
  bool animations = false,
  String lang = 'en',
  Map<String, Object> extra = const {},
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (_) async => true,
      );
  final visual = VisualizationSettings(enableAnimations: animations);
  SharedPreferences.setMockInitialValues({
    'language': lang,
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': '[]',
    ...extra,
  });
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
}

/// Counts taps on the sponsor link instead of opening a browser.
class _FakeSupportLink {
  int opened = 0;

  Future<void> call(BuildContext context) async => opened++;
}

Future<void> _pump(
  WidgetTester tester,
  ReminderOptIn reminders, {
  Size physicalSize = const Size(1280, 2856),
  double devicePixelRatio = 3,
  _FakeSupportLink? supportLink,
  SupportChannel channel = SupportChannel.link,
}) async {
  final link = supportLink ?? _FakeSupportLink();
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    SupportScope(
      setup: SupportSetup(channel: channel),
      child: AppSettingsScope(
        controller: controller,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => MaterialApp(
            theme: controller.lightTheme,
            darkTheme: controller.darkTheme,
            themeMode: controller.themeMode,
            locale: controller.locale,
            supportedLocales: [
              for (final code in AppLocalizations.supportedLanguages)
                Locale(code),
            ],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: OnboardingScreen(
              onLanguageChange: controller.reload,
              reminders: reminders,
              now: _today,
              loadLifespanData: loadLifespanTestData,
              openSupportLink: link.call,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _continue => find.widgetWithText(FilledButton, 'Continue');

Future<void> _pickBirthDate(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding_birth_date')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('1996'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('15'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Picks 15 Nov 1996 in any app language (the confirm button is the
/// dialog's last text button).
Future<void> _pickBirthDateIn(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding_birth_date')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('1996'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('15'));
  await tester.tap(find.byType(TextButton).last);
  await tester.pumpAndSettle();
}

/// From the estimate step: "Keep 80 years" leaves the default and moves on.
Future<void> _skipEstimate(
  WidgetTester tester, {
  String label = 'Keep 80\u00A0years',
}) async {
  await tester.tap(find.text(label));
  await tester.pump(); // starts the step switch (the reveal may animate)
}

/// Birth date → estimate (skipped) → the reveal.
Future<void> _toReveal(WidgetTester tester) async {
  await _pickBirthDate(tester);
  await tester.tap(_continue);
  await tester.pumpAndSettle();
  await _skipEstimate(tester);
  await tester.pumpAndSettle();
}

Future<void> _toReminders(WidgetTester tester) async {
  await _toReveal(tester);
  await tester.tap(_continue);
  await tester.pumpAndSettle();
}

/// Reminders step → "Not now" → the support step.
Future<void> _toSupport(WidgetTester tester) async {
  await _toReminders(tester);
  await tester.tap(find.text('Not now'));
  await tester.pumpAndSettle();
}

/// The support step alone, framed as in the onboarding (top bar height,
/// safe area) on a Pixel 5 (393x851 logical pixels).
Future<void> _pumpSupportStep(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: controller.lightTheme,
      locale: controller.locale,
      supportedLocales: [
        for (final code in AppLocalizations.supportedLanguages) Locale(code),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 56),
              Expanded(
                child: SupportStep(
                  busy: false,
                  onStart: () {},
                  onSupport: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _letsStart => find.widgetWithText(FilledButton, 'Let’s start');

/// The app text [key] in [lang], with [replacements] filled in.
String _text(
  String key, {
  String lang = 'en',
  Map<String, String> replacements = const {},
}) => AppLocalizations(Locale(lang)).translate(key, replacements: replacements);

/// The onboarding's estimate title, greeting [name] when given.
String _estimateTitle({String? name, String lang = 'en'}) => name == null
    ? _text('onboarding_estimate_title', lang: lang)
    : _text(
        'onboarding_estimate_title_named',
        lang: lang,
        replacements: {'name': name},
      );

String _weekText(int lifeExpectancy) {
  final calc = LifeCalculator(
    birthDate: _picked,
    lifeExpectancyYears: lifeExpectancy,
    now: _today,
  );
  final n = calc.currentWeekNumber;
  final formatted = n >= 1000
      ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}'
      : '$n';
  return _text('onboarding_reveal_week', replacements: {'n': formatted});
}

LifeGridPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is LifeGridPainter,
    ),
  );
  return paint.painter! as LifeGridPainter;
}

Future<void> _loadInterFonts() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}

void main() {
  testWidgets('German name label fits on a Pixel 5 without an ellipsis', (
    tester,
  ) async {
    await _loadInterFonts(); // the app's text font, for real text widths
    await _init(lang: 'de');
    await _pump(
      tester,
      _FakeReminders(),
      physicalSize: const Size(1080, 2340),
      devicePixelRatio: 2.75,
    );
    final label = tester.renderObject<RenderParagraph>(
      find.text('Wie sollen wir dich nennen?'),
    );
    expect(label.didExceedMaxLines, isFalse);
    expect(find.text('Optional'), findsOneWidget);
  });

  group('SystemReminderOptIn.skip', () {
    test('turns weekly and birthday reminders off', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await _init();
      await FriendsService.initialize();
      expect(SettingsService.isWeeklyReminderEnabled(), isTrue);
      expect(FriendsService.isBirthdayNotificationsEnabled(), isTrue);

      await const SystemReminderOptIn().skip();

      expect(SettingsService.isWeeklyReminderEnabled(), isFalse);
      expect(FriendsService.isBirthdayNotificationsEnabled(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('weekly_reminder_enabled'), isFalse);
    });
  });

  group('OnboardingAnswers', () {
    test('only a date before today is valid', () {
      final answers = OnboardingAnswers();
      expect(answers.hasValidBirthDate(_today), isFalse);
      answers.birthDate = _today;
      expect(answers.hasValidBirthDate(_today), isFalse);
      answers.birthDate = DateTime(2026, 11, 1);
      expect(answers.hasValidBirthDate(_today), isTrue);
    });

    test('life expectancy is clamped to the settings range', () {
      expect(OnboardingAnswers.clampLifeExpectancy(20), 50);
      expect(OnboardingAnswers.clampLifeExpectancy(200), 110);
      expect(OnboardingAnswers.clampLifeExpectancy(85), 85);
    });
  });

  group('Onboarding flow', () {
    testWidgets('continue stays disabled until a birth date is chosen', (
      tester,
    ) async {
      await _init();
      await _pump(tester, _FakeReminders());
      expect(find.text('Your life, in weeks.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);

      await _pickBirthDate(tester);
      expect(find.text('15 Nov 1996'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
    });

    testWidgets('the reveal shows the current week number', (tester) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await _toReveal(tester);

      expect(find.text(_weekText(80)), findsOneWidget);
      expect(find.text('Make it count.'), findsOneWidget);
      final calc = LifeCalculator(birthDate: _picked, now: _today);
      expect(_painter(tester).livedCells, calc.weeksLived);
      expect(_painter(tester).geometry.totalCells, 80 * 52);
    });

    testWidgets('life expectancy stepper updates the grid total', (
      tester,
    ) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await _toReveal(tester);

      await tester.tap(find.byTooltip('More years'));
      await tester.pumpAndSettle();
      expect(find.text('81\u00A0years'), findsOneWidget);
      expect(_painter(tester).geometry.totalCells, 81 * 52);
    });

    testWidgets('the reveal animates from zero to the current week', (
      tester,
    ) async {
      await _init(animations: true);
      await _pump(tester, _FakeReminders());
      await _pickBirthDate(tester);
      await tester.tap(_continue);
      await tester.pumpAndSettle();
      await _skipEstimate(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painter(tester).livedCells, 0);

      await tester.pump(const Duration(milliseconds: 900));
      final midway = _painter(tester).livedCells;
      final calc = LifeCalculator(birthDate: _picked, now: _today);
      expect(midway, greaterThan(0));
      expect(midway, lessThan(calc.weeksLived));

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 700));
      expect(_painter(tester).livedCells, calc.weeksLived);
      expect(find.text(_weekText(80)), findsOneWidget);
    });

    testWidgets('German shows the week with a dot separator', (tester) async {
      await _init(lang: 'de');
      await _pump(tester, _FakeReminders());
      await tester.tap(find.byKey(const ValueKey('onboarding_birth_date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1996'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
      await tester.pumpAndSettle();
      await _skipEstimate(tester, label: '80\u00A0Jahre behalten');
      await tester.pumpAndSettle();
      final week = LifeCalculator(
        birthDate: _picked,
        now: _today,
      ).currentWeekNumber;
      final de = '${week ~/ 1000}.${(week % 1000).toString().padLeft(3, '0')}';
      expect(
        find.text(
          _text('onboarding_reveal_week', lang: 'de', replacements: {'n': de}),
        ),
        findsOneWidget,
      );
      expect(find.text('Nutze sie.'), findsOneWidget);
    });

    testWidgets('language button switches the reveal on a Pixel 5', (
      tester,
    ) async {
      await _init();
      await _pump(
        tester,
        _FakeReminders(),
        physicalSize: const Size(1080, 2340),
        devicePixelRatio: 2.75,
      );
      await _toReveal(tester);

      final button = find.byKey(
        const ValueKey('onboarding_reveal_language_button'),
      );
      expect(
        find.descendant(of: button, matching: find.text('English')),
        findsOneWidget,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      for (final code in AppLocalizations.supportedLanguages) {
        expect(
          find.text(AppLocalizations.languageNames[code]!),
          findsWidgets,
          reason: code,
        );
      }
      await tester.tap(find.text('Deutsch').last);
      await tester.pumpAndSettle();

      expect(SettingsService.getLanguage(), 'de');
      expect(find.text('Nutze sie.'), findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.text('Deutsch')),
        findsOneWidget,
      );
    });

    testWidgets('back returns to the previous step', (tester) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await _pickBirthDate(tester);
      await tester.tap(_continue);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Your life, in weeks.'), findsOneWidget);
      expect(find.text('15 Nov 1996'), findsOneWidget);
    });

    testWidgets('"Not now" skips reminders and moves on to support', (
      tester,
    ) async {
      await _init();
      final reminders = _FakeReminders();
      await _pump(tester, reminders);
      await _toReminders(tester);
      expect(find.text('Remember the people who matter.'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(reminders.enabled, 0);
      expect(reminders.skipped, 1);
      expect(find.text('One last thing.'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 5 of 5'), findsOneWidget);
      expect(SettingsService.hasCompletedOnboarding(), isFalse);

      await tester.tap(_letsStart);
      await tester.pumpAndSettle();
      expect(SettingsService.hasCompletedOnboarding(), isTrue);
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('the coffee link opens and stays on the support step', (
      tester,
    ) async {
      await _init();
      final link = _FakeSupportLink();
      await _pump(tester, _FakeReminders(), supportLink: link);
      await _toSupport(tester);

      await tester.tap(find.text('Buy me a coffee'));
      await tester.pumpAndSettle();
      expect(link.opened, 1);
      expect(find.text('One last thing.'), findsOneWidget);
      expect(SettingsService.hasCompletedOnboarding(), isFalse);

      await tester.tap(_letsStart);
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('back from the support step returns to reminders', (
      tester,
    ) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await _toSupport(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Remember the people who matter.'), findsOneWidget);
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('the support step fits a 393x851 screen in $lang', (
        tester,
      ) async {
        await _loadInterFonts();
        await _init(lang: lang);
        await _pumpSupportStep(tester);

        final values = AppLocalizations.valuesFor(lang);
        final body = find.text(values['onboarding_support_body']!);
        expect(tester.takeException(), isNull);
        expect(find.text(values['onboarding_support_title']!), findsOneWidget);
        expect(
          tester.getBottomLeft(body).dy,
          lessThan(tester.getTopLeft(find.byType(FilledButton)).dy),
          reason: 'the whole text shows above the buttons without scrolling',
        );
        for (final key in ['onboarding_support_start', 'support_coffee']) {
          final label = find.text(values[key]!);
          expect(label, findsOneWidget, reason: key);
          expect(
            tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
            isFalse,
            reason: key,
          );
        }
      });
    }

    testWidgets('finishing saves the answers and opens the app', (
      tester,
    ) async {
      await _init();
      final reminders = _FakeReminders();
      await _pump(tester, reminders);
      await tester.enterText(find.byType(TextField), 'Ada');
      await _toReminders(tester);

      await tester.tap(find.text('Turn on reminders'));
      await tester.pumpAndSettle();
      expect(reminders.enabled, 1);
      expect(SettingsService.hasCompletedOnboarding(), isFalse);
      await tester.tap(_letsStart);
      await tester.pumpAndSettle();
      expect(SettingsService.hasCompletedOnboarding(), isTrue);
      expect(SettingsService.getBirthDate(), _picked);
      expect(SettingsService.getLifeExpectancyYears(), 80);
      expect(SettingsService.getUserName(), 'Ada');
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      // Skipped estimate: nothing about it is stored.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lifespan_estimate'), isNull);
      expect(prefs.getString('lifespan_country'), isNull);
    });

    testWidgets(
      'five steps: birth date, estimate, reveal, reminders, support',
      (tester) async {
        expect(OnboardingScreen.steps, [
          OnboardingStep.birthDate,
          OnboardingStep.estimate,
          OnboardingStep.reveal,
          OnboardingStep.reminders,
          OnboardingStep.support,
        ]);
        await _init();
        await _pump(tester, _FakeReminders());
        expect(find.bySemanticsLabel('Step 1 of 5'), findsOneWidget);
        await _pickBirthDate(tester);
        await tester.tap(_continue);
        await tester.pumpAndSettle();
        expect(find.text(_estimateTitle()), findsOneWidget);
        expect(find.bySemanticsLabel('Step 2 of 5'), findsOneWidget);
      },
    );

    group('store builds (rate channel)', () {
      test('four steps: no support step', () {
        expect(
          OnboardingScreen.stepsFor(SupportChannel.link),
          OnboardingScreen.steps,
        );
        expect(OnboardingScreen.stepsFor(SupportChannel.rate), [
          OnboardingStep.birthDate,
          OnboardingStep.estimate,
          OnboardingStep.reveal,
          OnboardingStep.reminders,
        ]);
      });

      for (final enable in [true, false]) {
        testWidgets(
          'the reminders choice (${enable ? 'on' : 'not now'}) finishes '
          'the onboarding',
          (tester) async {
            await _init();
            final reminders = _FakeReminders();
            final link = _FakeSupportLink();
            await _pump(
              tester,
              reminders,
              supportLink: link,
              channel: SupportChannel.rate,
            );
            expect(find.bySemanticsLabel('Step 1 of 4'), findsOneWidget);
            await _toReminders(tester);
            expect(find.bySemanticsLabel('Step 4 of 4'), findsOneWidget);

            await tester.tap(
              find.text(enable ? 'Turn on reminders' : 'Not now'),
            );
            await tester.pumpAndSettle();
            expect(reminders.enabled, enable ? 1 : 0);
            expect(reminders.skipped, enable ? 0 : 1);
            expect(find.byType(SupportStep), findsNothing);
            expect(find.text('Buy me a coffee'), findsNothing);
            expect(SettingsService.hasCompletedOnboarding(), isTrue);
            expect(SettingsService.getBirthDate(), _picked);
            expect(find.byType(AppShell), findsOneWidget);
            expect(find.byType(OnboardingScreen), findsNothing);
            expect(link.opened, 0);
          },
        );
      }
    });

    testWidgets('an applied estimate drives the reveal and is saved', (
      tester,
    ) async {
      await _init();
      final reminders = _FakeReminders();
      await _pump(tester, reminders);
      await _pickBirthDate(tester);
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('lifespan_sex_female')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lifespan_show_estimate')));
      await tester.pumpAndSettle();
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('lifespan_slider')),
      );
      slider.onChanged!(92);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('lifespan_apply')));
      await tester.tap(find.byKey(const ValueKey('lifespan_apply')));
      await tester.pumpAndSettle();

      expect(find.text('92\u00A0years'), findsOneWidget);
      expect(_painter(tester).geometry.totalCells, 92 * 52);

      await tester.tap(_continue);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn on reminders'));
      await tester.pumpAndSettle();
      expect(SettingsService.getLifeExpectancyYears(), 92);
      expect(SettingsService.getLifespanSex(), Sex.female);
      expect(SettingsService.getLifespanCountry(), isNotNull);
      expect(SettingsService.getLifespanAnswers().isEmpty, isTrue);
      expect(SettingsService.getLifespanEstimate()!.appliedYears, 92);
    });

    testWidgets('back inside the estimate walks its pages first', (
      tester,
    ) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await _pickBirthDate(tester);
      await tester.tap(_continue);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lifespan_personal')));
      await tester.pumpAndSettle();
      expect(find.text('QUESTION 1 OF 6'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text(_estimateTitle()), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Your life, in weeks.'), findsOneWidget);
    });
  });

  group('Greeting by name', () {
    /// Types [name] on the first step, then picks the date and continues
    /// to the estimate.
    Future<void> toEstimate(WidgetTester tester, {String? name}) async {
      if (name != null) {
        await tester.enterText(find.byType(TextField), name);
      }
      await _pickBirthDate(tester);
      await tester.tap(_continue);
      await tester.pumpAndSettle();
    }

    testWidgets('a name greets on the estimate and the reveal', (tester) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await toEstimate(tester, name: 'Daniel');

      expect(find.text(_estimateTitle(name: 'Daniel')), findsOneWidget);
      expect(
        find.text('Daniel, what should guide your life calendar?'),
        findsOneWidget,
      );
      expect(find.text(_estimateTitle()), findsNothing);

      await _skipEstimate(tester);
      await tester.pumpAndSettle();
      expect(find.text('Make it count, Daniel.'), findsOneWidget);
      expect(find.text('Make it count.'), findsNothing);
    });

    for (final (label, name) in [('no name', null), ('only spaces', '   ')]) {
      testWidgets('$label: the plain title and tagline', (tester) async {
        await _init();
        await _pump(tester, _FakeReminders());
        await toEstimate(tester, name: name);

        expect(find.text(_estimateTitle()), findsOneWidget);

        await _skipEstimate(tester);
        await tester.pumpAndSettle();
        expect(find.text('Make it count.'), findsOneWidget);
        expect(find.textContaining('Make it count,'), findsNothing);
      });
    }

    testWidgets('the estimate intro starts from the current years', (
      tester,
    ) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await toEstimate(tester);

      expect(
        find.text(
          _text('onboarding_estimate_intro', replacements: {'n': '80'}),
        ),
        findsOneWidget,
      );
      expect(find.text(_text('estimate_title')), findsNothing);
      expect(find.text(_text('estimate_intro')), findsNothing);
    });

    testWidgets('switching to German on the estimate keeps the greeting', (
      tester,
    ) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await toEstimate(tester, name: 'Daniel');

      await tester.tap(
        find.byKey(const ValueKey('onboarding_language_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deutsch').last);
      await tester.pumpAndSettle();

      expect(SettingsService.getLanguage(), 'de');
      expect(
        find.text(_estimateTitle(name: 'Daniel', lang: 'de')),
        findsOneWidget,
      );
      expect(
        find.text('Daniel, woran soll sich dein Lebenskalender orientieren?'),
        findsOneWidget,
      );
      expect(
        find.text(
          _text(
            'onboarding_estimate_intro',
            lang: 'de',
            replacements: {'n': '80'},
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('Top bar: language and light/dark', () {
    void platformDark(WidgetTester tester) {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    }

    Brightness shownBrightness(WidgetTester tester, Type screen) =>
        Theme.of(tester.element(find.byType(screen))).brightness;

    final chip = find.byKey(const ValueKey('onboarding_language_button'));

    testWidgets('starts light even when the platform is dark', (tester) async {
      platformDark(tester);
      await _init();
      await _pump(tester, _FakeReminders());
      expect(shownBrightness(tester, OnboardingScreen), Brightness.light);
      expect(find.byTooltip('Dark mode'), findsOneWidget);
    });

    testWidgets('a stored "system" choice follows the dark platform', (
      tester,
    ) async {
      platformDark(tester);
      await _init(extra: {'brightness': 'system'});
      await _pump(tester, _FakeReminders());
      expect(shownBrightness(tester, OnboardingScreen), Brightness.dark);
      expect(find.byTooltip('Light mode'), findsOneWidget);
    });

    testWidgets('the toggle stores dark and the app stays dark after '
        'finishing', (tester) async {
      await _init();
      await _pump(tester, _FakeReminders());
      await tester.tap(find.byTooltip('Dark mode'));
      await tester.pumpAndSettle();
      expect(SettingsService.getBrightness(), 'dark');
      expect(shownBrightness(tester, OnboardingScreen), Brightness.dark);
      expect(find.byTooltip('Light mode'), findsOneWidget);

      await _toReminders(tester);
      await tester.tap(find.text('Turn on reminders'));
      await tester.pumpAndSettle();
      await tester.tap(_letsStart);
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(shownBrightness(tester, AppShell), Brightness.dark);
    });

    testWidgets('the language chip on page 1 switches the strings', (
      tester,
    ) async {
      await _init();
      await _pump(tester, _FakeReminders());
      expect(find.descendant(of: chip, matching: find.text('EN')), findsOne);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deutsch').last);
      await tester.pumpAndSettle();
      expect(SettingsService.getLanguage(), 'de');
      expect(find.text('Dein Leben in Wochen.'), findsOneWidget);
      expect(find.descendant(of: chip, matching: find.text('DE')), findsOne);
      expect(find.byTooltip('Dunkler Modus'), findsOneWidget);
    });

    testWidgets('both controls have semantics labels', (tester) async {
      final semantics = tester.ensureSemantics();
      await _init();
      await _pump(tester, _FakeReminders());
      expect(find.bySemanticsLabel('Language: English'), findsOneWidget);
      expect(
        tester.getSemantics(
          find.descendant(
            of: find.byType(ThemeToggle),
            matching: find.byType(IconButton),
          ),
        ),
        isSemantics(tooltip: 'Dark mode', isButton: true),
      );
      semantics.dispose();
    });

    for (final (name, size, dpr) in [
      ('Pixel 5', const Size(1080, 2340), 2.75),
      ('360 dp', const Size(1080, 2340), 3.0),
    ]) {
      testWidgets('page 1 with the year strip fits $name in every language', (
        tester,
      ) async {
        await loadAppFonts();
        for (final lang in AppLocalizations.supportedLanguages) {
          await _init(lang: lang);
          await _pump(
            tester,
            _FakeReminders(),
            physicalSize: size,
            devicePixelRatio: dpr,
          );
          await _pickBirthDateIn(tester);
          expect(tester.takeException(), isNull, reason: lang);
          final viewport = tester.getRect(
            find.byKey(const ValueKey('step_layout_scroll')),
          );
          final caption = find.byKey(const ValueKey('onboarding_year_caption'));
          expect(tester.widget<Text>(caption).data, isNotEmpty);
          expect(
            tester.getRect(find.byType(TextField)).bottom,
            lessThanOrEqualTo(viewport.bottom),
            reason: '$lang: the name field shows without scrolling',
          );
        }
      });
    }

    testWidgets('page 1 settles after the date: nothing keeps moving', (
      tester,
    ) async {
      await _init(animations: true);
      await _pump(tester, _FakeReminders());
      await _pickBirthDate(tester); // pumpAndSettle returns
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(
        find.text('Week\u00A051 of your current year of life'),
        findsOneWidget,
      );
    });

    for (final width in [320.0, 360.0, 393.0]) {
      testWidgets('fits ${width.toInt()} dp with the dots centred', (
        tester,
      ) async {
        await _init(lang: 'de');
        await _pump(
          tester,
          _FakeReminders(),
          physicalSize: Size(width * 3, 2400),
        );
        await _pickBirthDate(tester);
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle(); // second step: back arrow shown too
        expect(tester.takeException(), isNull);
        final dots = tester.getRect(find.byType(StepDots));
        expect(dots.center.dx, closeTo(width / 2, 0.5));
        final controls = tester.getRect(chip);
        expect(controls.left, greaterThan(dots.right));
        final toggle = tester.getRect(find.byType(ThemeToggle));
        expect(toggle.right, lessThanOrEqualTo(width));
        final back = tester.getRect(find.byTooltip('Zurück'));
        expect(back.right, lessThan(dots.left));
      });
    }
  });
}
