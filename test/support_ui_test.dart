import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/diagnostics_screen.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/home_screen.dart';
import 'package:memento_mori_life_in_weeks/life/life_header.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/support_section.dart';
import 'package:memento_mori_life_in_weeks/settings_screen.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/support/support_service.dart';
import 'package:memento_mori_life_in_weeks/widget_launches.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/prompt_card_layout.dart';

final DateTime _today = DateTime(2026, 11, 2);

/// Counts taps on the sponsor link instead of opening a browser.
class _FakeLink {
  int opened = 0;

  Future<void> call(BuildContext context) async => opened++;
}

/// Settings and the support schedule; [firstUse] null = first session.
Future<void> _init({
  String lang = 'en',
  String? firstUse = '2026-10-01',
  Map<String, Object> extra = const {},
}) async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': DateTime(1990, 11, 17).toIso8601String(),
    'language': lang,
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': '[]',
    'first_use_date': ?firstUse,
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
  await SupportService.initialize(today: _today);
  await FriendsService.clearCacheForTesting();
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Size physicalSize = const Size(1080, 2340),
  double devicePixelRatio = 2.75,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    AppSettingsScope(
      controller: controller,
      child: MaterialApp(
        theme: controller.lightTheme,
        locale: controller.locale,
        supportedLocales: [
          for (final code in AppLocalizations.supportedLanguages) Locale(code),
        ],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _loadInterFonts() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}

final Finder _card = find.byKey(const ValueKey('life_support_card'));

class _NoWidgetLaunches implements WidgetLaunches {
  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) =>
      const Stream<void>.empty().listen(null);
}

void main() {
  group('Life tab support card', () {
    testWidgets('is due a month after the first use, at the top', (
      tester,
    ) async {
      await _init();
      await _pump(tester, HomeScreen(now: _today));
      expect(_card, findsOneWidget);
      expect(
        find.text(
          'You’ve been using Memento Mori for a month. If you like it, '
          'you can support it with a coffee.',
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(_card).dy,
        lessThan(tester.getTopLeft(find.byType(LifeHeader)).dy),
      );
    });

    testWidgets('is hidden before it is due', (tester) async {
      await _init(firstUse: '2026-10-10');
      await _pump(tester, HomeScreen(now: _today));
      expect(_card, findsNothing);
    });

    testWidgets('never shows in the session that recorded the first use', (
      tester,
    ) async {
      await _init(firstUse: null);
      await _pump(tester, HomeScreen(now: _today));
      expect(_card, findsNothing);
    });

    testWidgets('"Support" opens the link and counts as shown', (tester) async {
      await _init();
      final link = _FakeLink();
      await _pump(tester, HomeScreen(now: _today, openSupportLink: link.call));
      await tester.tap(find.text('Support ☕'));
      await tester.pumpAndSettle();
      expect(link.opened, 1);
      expect(_card, findsNothing);
      expect(SupportService.lastShown, _today);
      expect(SupportService.alreadySupported, isFalse);
    });

    testWidgets('"Not now" hides it until the next milestone', (tester) async {
      await _init();
      final link = _FakeLink();
      await _pump(tester, HomeScreen(now: _today, openSupportLink: link.call));
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(link.opened, 0);
      expect(_card, findsNothing);
      expect(SupportService.lastShown, _today);
      expect(SupportService.isDue(DateTime(2027, 4, 1)), isTrue);
    });

    testWidgets('"I already did, thanks" ends the prompts', (tester) async {
      await _init();
      await _pump(tester, HomeScreen(now: _today));
      await tester.tap(find.text('I already did, thanks'));
      await tester.pumpAndSettle();
      expect(_card, findsNothing);
      expect(SupportService.alreadySupported, isTrue);
      expect(SupportService.isDue(DateTime(2040)), isFalse);
    });

    testWidgets('counts years of use', (tester) async {
      await _init(firstUse: '2024-05-02');
      await _pump(tester, HomeScreen(now: _today));
      expect(
        find.textContaining('You’ve been using Memento Mori for 2\u00A0years.'),
        findsOneWidget,
      );
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('fits a 393x851 screen in $lang', (tester) async {
        await _loadInterFonts();
        await _init(lang: lang, firstUse: '2025-05-02');
        await _pump(tester, HomeScreen(now: _today));
        expect(tester.takeException(), isNull);
        expect(_card, findsOneWidget);
        final values = AppLocalizations.valuesFor(lang);
        for (final key in [
          'support_card_support',
          'support_card_not_now',
          'support_card_done',
        ]) {
          final label = find.text(values[key]!);
          expect(label, findsOneWidget, reason: key);
          expect(
            tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
            isFalse,
          );
          expect(
            tester.getTopRight(label).dx,
            lessThanOrEqualTo(tester.getTopRight(_card).dx),
            reason: key,
          );
        }
        expectPromptCardLayout(
          tester,
          primary: values['support_card_support']!,
          notNow: values['support_card_not_now']!,
          done: values['support_card_done']!,
        );
      });
    }
  });

  group('Settings support section', () {
    testWidgets('sits before About and holds the coffee tile', (tester) async {
      await _init();
      await _pump(
        tester,
        const SettingsScreen(alwaysShowDiagnostics: false),
        physicalSize: const Size(1080, 12000),
      );
      final support = tester.getTopLeft(find.text('SUPPORT')).dy;
      final about = tester.getTopLeft(find.text('ABOUT')).dy;
      final data = tester.getTopLeft(find.text('DATA')).dy;
      final tile = tester.getTopLeft(find.text('Buy me a coffee')).dy;
      expect(data, lessThan(support));
      expect(support, lessThan(tile));
      expect(tile, lessThan(about));
      expect(find.text('Support this App'), findsNothing);
      expect(
        find.text(
          'Free, no ads, no tracking, made by one person. If Memento Mori '
          'means something to you, you can support it with a coffee.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the tile opens the link; the switch opts out, persisted', (
      tester,
    ) async {
      await _init();
      final link = _FakeLink();
      await _pump(
        tester,
        Scaffold(
          body: ListView(children: [SupportSection(openLink: link.call)]),
        ),
      );
      await tester.tap(find.text('Buy me a coffee'));
      expect(link.opened, 1);

      final toggle = find.byKey(const ValueKey('support_remind_switch'));
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('support_opt_out'), isTrue);
      expect(SupportService.isDue(DateTime(2030)), isFalse);
    });
  });

  testWidgets('after "I already did" the switch is off; on re-enables it', (
    tester,
  ) async {
    await _init(extra: {'support_done': true});
    await _pump(
      tester,
      Scaffold(
        body: ListView(children: [SupportSection(openLink: _FakeLink().call)]),
      ),
    );
    final toggle = find.byKey(const ValueKey('support_remind_switch'));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(SupportService.alreadySupported, isFalse);
    expect(SupportService.optedOut, isFalse);
  });

  testWidgets('the Settings switch follows "I already did" on the Life tab '
      'while both tabs stay alive', (tester) async {
    await _init();
    await _pump(
      tester,
      AppShell(now: _today, widgetLaunches: _NoWidgetLaunches()),
      physicalSize: const Size(1080, 12000), // the whole Settings list
    );
    final toggle =
        find.byKey(const ValueKey('support_remind_switch'), skipOffstage: false);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(find.text('Life'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already did, thanks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });

  group('Diagnostics', () {
    testWidgets('shows the card now and resets the schedule', (tester) async {
      await _init(extra: {'support_done': true});
      await _pump(
        tester,
        DiagnosticsScreen(loadPendingNotifications: () async => const []),
        physicalSize: const Size(1080, 4000),
      );
      expect(SupportService.isDue(_today), isFalse);
      await tester.tap(find.text('Show support prompt now'));
      await tester.pumpAndSettle();
      expect(SupportService.isDue(_today), isTrue);
      expect(find.text('Support card shown on the Life tab'), findsOneWidget);

      await tester.tap(find.text('Reset support schedule'));
      await tester.pumpAndSettle();
      expect(SupportService.alreadySupported, isFalse);
      expect(SupportService.lastShown, isNull);
      expect(SupportService.firstUse, isNotNull);
    });
  });
}
