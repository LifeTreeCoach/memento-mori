import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/main.dart';
import 'package:memento_mori_life_in_weeks/onboarding/first_launch_logo.dart';
import 'package:memento_mori_life_in_weeks/onboarding/onboarding_screen.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_color_schemes.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _init({
  Map<String, Object> extra = const {},
  bool animations = true,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (_) async => true,
      );
  final visual = VisualizationSettings(enableAnimations: animations);
  SharedPreferences.setMockInitialValues({
    'language': 'en',
    'visualization_settings': jsonEncode(visual.toMap()),
    ...extra,
  });
  await SettingsService.initialize();
}

/// A plain app showing the logo, with a marker page as [FirstLaunchLogo.next].
Future<void> _pumpLogo(WidgetTester tester) {
  return tester.pumpWidget(MaterialApp(
    home: FirstLaunchLogo(next: (_) => const Text('next')),
  ));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(Motion.firstLaunchLogo);
  await tester.pump(Motion.short);
  await tester.pump(Motion.short);
  await tester.pump(Motion.short);
}

void main() {
  group('claimFirstLaunch', () {
    test('shows the logo once on the first launch', () async {
      await _init();
      expect(FirstLaunchLogo.claimFirstLaunch(), isTrue);
      expect(SettingsService.hasShownIntroLogo(), isTrue);
      expect(FirstLaunchLogo.claimFirstLaunch(), isFalse);
    });

    test('never shows it to people who already onboarded', () async {
      await _init(extra: {'onboarding_completed': true});
      expect(FirstLaunchLogo.claimFirstLaunch(), isFalse);
      // Marked, so a later "Start fresh" doesn't show it either.
      expect(SettingsService.hasShownIntroLogo(), isTrue);
      SettingsService.setOnboardingCompleted(false);
      expect(FirstLaunchLogo.claimFirstLaunch(), isFalse);
    });

    test('shouldShow only without onboarding and before the first time', () {
      expect(FirstLaunchLogo.shouldShow(onboarded: false, shown: false), isTrue);
      expect(FirstLaunchLogo.shouldShow(onboarded: false, shown: true), isFalse);
      expect(FirstLaunchLogo.shouldShow(onboarded: true, shown: false), isFalse);
    });
  });

  group('duration', () {
    test('is half the measured launch screen time, within 500-1200 ms', () {
      final ms = Motion.firstLaunchLogo.inMilliseconds;
      expect(ms, inInclusiveRange(500, 1200));
    });

    test('the widget uses the motion constant by default', () {
      expect(
        FirstLaunchLogo(next: (_) => const SizedBox()).duration,
        Motion.firstLaunchLogo,
      );
    });
  });

  group('FirstLaunchLogo', () {
    setUp(() => _init());

    testWidgets('shows the badge, then replaces itself with next',
        (tester) async {
      await _pumpLogo(tester);
      expect(find.image(const AssetImage(FirstLaunchLogo.asset)), findsOneWidget);
      expect(find.bySemanticsLabel('Memento Mori'), findsOneWidget);
      expect(find.text('next'), findsNothing);

      await tester.pump(Motion.firstLaunchLogo ~/ 2);
      expect(find.text('next'), findsNothing);

      await _settle(tester);
      expect(find.text('next'), findsOneWidget);
      expect(find.byType(FirstLaunchLogo), findsNothing);
    });

    testWidgets('a tap skips it', (tester) async {
      await _pumpLogo(tester);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(FirstLaunchLogo));
      await tester.pump();
      await tester.pump(Motion.short);
      await tester.pump(Motion.short);
      expect(find.text('next'), findsOneWidget);
      expect(find.byType(FirstLaunchLogo), findsNothing);
    });

    testWidgets('reduced motion: no fades, same time on screen',
        (tester) async {
      await _init(animations: false);
      await _pumpLogo(tester);
      expect(
        find.descendant(
          of: find.byType(FirstLaunchLogo),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      await tester.pump(Motion.firstLaunchLogo - const Duration(milliseconds: 1));
      expect(find.text('next'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('the background matches the native launch screen',
        (tester) async {
      expect(FirstLaunchLogo.backgroundFor(Brightness.light),
          AppColorSchemes.paper);
      expect(FirstLaunchLogo.backgroundFor(Brightness.dark),
          AppColorSchemes.ink);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _pumpLogo(tester);
      final box = tester.widget<ColoredBox>(find
          .descendant(
            of: find.byType(FirstLaunchLogo),
            matching: find.byType(ColoredBox),
          )
          .first);
      expect(box.color, AppColorSchemes.ink);
    });
  });

  group('MementoMoriApp', () {
    testWidgets('first launch: logo, then onboarding; not on the next start',
        (tester) async {
      await _init();
      await tester.pumpWidget(const MementoMoriApp());
      await tester.pump(); // localizations load
      expect(find.byType(FirstLaunchLogo), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      await _settle(tester);
      expect(find.byType(FirstLaunchLogo), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Next app start (onboarding still open): straight to the onboarding.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MementoMoriApp());
      await tester.pump();
      expect(find.byType(FirstLaunchLogo), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });
}
