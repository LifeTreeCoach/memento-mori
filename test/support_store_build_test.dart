import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/home_screen.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_screen.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/support/project_links.dart';
import 'package:memento_mori_life_in_weeks/support/store_actions.dart';
import 'package:memento_mori_life_in_weeks/support/store_listing.dart';
import 'package:memento_mori_life_in_weeks/support/support_channel.dart';
import 'package:memento_mori_life_in_weeks/support/support_scope.dart';
import 'package:memento_mori_life_in_weeks/support/support_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/money_words.dart';
import 'support/prompt_card_layout.dart';

/// The support spots per [SupportChannel]: store builds (rate) ask for a
/// rating or a recommendation and never show money wording; builds outside
/// the stores (link) keep the coffee link (support_ui_test.dart).

final DateTime _today = DateTime(2026, 11, 2);

final StoreListing _play = StoreListing.resolve(
  flavor: 'play',
  platform: TargetPlatform.android,
);

/// Records rate / recommend calls instead of opening a store or a sheet.
class _FakeStoreActions implements StoreActions {
  final List<StoreListing> rated = [];
  final List<StoreListing> recommended = [];

  @override
  Future<void> rate(BuildContext context, StoreListing listing) async =>
      rated.add(listing);

  @override
  Future<void> recommend(BuildContext context, StoreListing listing) async =>
      recommended.add(listing);
}

Future<void> _init({
  String lang = 'en',
  String? firstUse = '2026-10-01',
}) async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': DateTime(1990, 11, 17).toIso8601String(),
    'language': lang,
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': '[]',
    'first_use_date': ?firstUse,
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

/// [home] under a [SupportScope]; 1080x2340 at 2.75 = 393x851 (Pixel 5).
Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required SupportSetup support,
  Size physicalSize = const Size(1080, 2340),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    SupportScope(
      setup: support,
      child: AppSettingsScope(
        controller: controller,
        child: MaterialApp(
          theme: controller.lightTheme,
          locale: controller.locale,
          supportedLocales: [
            for (final code in AppLocalizations.supportedLanguages)
              Locale(code),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SupportSetup _rate(_FakeStoreActions actions, {StoreListing? listing}) =>
    SupportSetup(
      channel: SupportChannel.rate,
      listing: listing ?? _play,
      actions: actions,
    );

Future<void> _loadInterFonts() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}

final Finder _card = find.byKey(const ValueKey('life_support_card'));
final Finder _cardAction = find.byKey(const ValueKey('recommend_card_action'));

const Size _wholeSettings = Size(1080, 14000);

void main() {
  group('Settings, rate channel', () {
    testWidgets('"Like Memento Mori?" replaces Support, before About', (
      tester,
    ) async {
      await _init();
      await _pump(
        tester,
        const SettingsScreen(alwaysShowDiagnostics: false),
        support: _rate(_FakeStoreActions()),
        physicalSize: _wholeSettings,
      );
      final section = tester.getTopLeft(find.text('LIKE MEMENTO MORI?')).dy;
      final data = tester.getTopLeft(find.text('DATA')).dy;
      final about = tester.getTopLeft(find.text('ABOUT')).dy;
      expect(data, lessThan(section));
      expect(section, lessThan(about));
      expect(find.text('Rate the app'), findsOneWidget);
      expect(find.text('Recommend to a friend'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('support_remind_switch')),
        findsOneWidget,
      );
      expect(find.text('SUPPORT'), findsNothing);
      expect(find.byKey(const ValueKey('support_coffee_tile')), findsNothing);
    });

    testWidgets('rate and recommend use the store listing; the switch '
        'opts out', (tester) async {
      await _init();
      final actions = _FakeStoreActions();
      await _pump(
        tester,
        const SettingsScreen(alwaysShowDiagnostics: false),
        support: _rate(actions),
        physicalSize: _wholeSettings,
      );
      await tester.tap(find.text('Rate the app'));
      await tester.tap(find.text('Recommend to a friend'));
      expect(actions.rated, [_play]);
      expect(actions.recommended, [_play]);

      await tester.tap(find.byKey(const ValueKey('support_remind_switch')));
      await tester.pumpAndSettle();
      expect(SupportService.optedOut, isTrue);
    });

    testWidgets('without a store listing (iOS before release) only '
        '"Recommend" shows', (tester) async {
      await _init();
      await _pump(
        tester,
        const SettingsScreen(alwaysShowDiagnostics: false),
        support: _rate(_FakeStoreActions(), listing: StoreListing.none),
        physicalSize: _wholeSettings,
      );
      expect(find.text('Rate the app'), findsNothing);
      expect(find.text('Recommend to a friend'), findsOneWidget);
    });

    testWidgets('link channel keeps the coffee tile', (tester) async {
      await _init();
      await _pump(
        tester,
        const SettingsScreen(alwaysShowDiagnostics: false),
        support: const SupportSetup(channel: SupportChannel.link),
        physicalSize: _wholeSettings,
      );
      expect(find.text('Buy me a coffee'), findsOneWidget);
      expect(find.text('LIKE MEMENTO MORI?'), findsNothing);
    });
  });

  group('About, project links in every channel', () {
    final channels = {
      'rate': _rate(_FakeStoreActions()),
      'link': const SupportSetup(channel: SupportChannel.link),
    };
    for (final MapEntry(key: name, value: support) in channels.entries) {
      testWidgets('source code, discussions and privacy open in $name builds', (
        tester,
      ) async {
        await _init();
        final opened = <String>[];
        await _pump(
          tester,
          SettingsScreen(
            alwaysShowDiagnostics: false,
            openProjectLink: (context, url) async => opened.add(url),
          ),
          support: support,
          physicalSize: _wholeSettings,
        );
        expect(find.text('Source code'), findsOneWidget);
        expect(find.text('Open source (GPL-3.0) on GitHub'), findsOneWidget);
        expect(find.text('Ideas & feedback'), findsOneWidget);
        expect(find.text('Discuss on GitHub'), findsOneWidget);
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('What the app stores and where'), findsOneWidget);

        await tester.tap(find.text('Source code'));
        await tester.tap(find.text('Ideas & feedback'));
        await tester.tap(find.text('Privacy'));
        expect(opened, [
          'https://github.com/LifeTreeCoach/memento-mori',
          'https://github.com/LifeTreeCoach/memento-mori/discussions',
          'https://github.com/LifeTreeCoach/memento-mori/blob/main/PRIVACY.md',
        ]);
        expect(opened, [
          ProjectLinks.repository,
          ProjectLinks.discussions,
          ProjectLinks.privacy,
        ]);
      });
    }
  });

  group('Life-tab card, rate channel', () {
    testWidgets('same schedule, rate wording and buttons', (tester) async {
      await _init();
      await _pump(
        tester,
        HomeScreen(now: _today),
        support: _rate(_FakeStoreActions()),
      );
      expect(_card, findsOneWidget);
      expect(
        find.text(
          'You’ve been using Memento Mori for a month. If you like it, a '
          'rating or a recommendation helps a lot.',
        ),
        findsOneWidget,
      );
      expect(find.text('Rate'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('I already did, thanks'), findsOneWidget);
      expect(find.text('Support ☕'), findsNothing);
    });

    testWidgets('is hidden before it is due', (tester) async {
      await _init(firstUse: '2026-10-20');
      await _pump(
        tester,
        HomeScreen(now: _today),
        support: _rate(_FakeStoreActions()),
      );
      expect(_card, findsNothing);
    });

    testWidgets('"Rate" opens the store and counts as shown', (tester) async {
      await _init();
      final actions = _FakeStoreActions();
      await _pump(tester, HomeScreen(now: _today), support: _rate(actions));
      await tester.tap(find.text('Rate'));
      await tester.pumpAndSettle();
      expect(actions.rated, [_play]);
      expect(actions.recommended, isEmpty);
      expect(_card, findsNothing);
      expect(SupportService.lastShown, _today);
      expect(SupportService.alreadySupported, isFalse);
    });

    testWidgets('without a listing the main button recommends', (tester) async {
      await _init();
      final actions = _FakeStoreActions();
      await _pump(
        tester,
        HomeScreen(now: _today),
        support: _rate(actions, listing: StoreListing.none),
      );
      expect(find.text('Rate'), findsNothing);
      await tester.tap(find.text('Recommend'));
      await tester.pumpAndSettle();
      expect(actions.recommended, [StoreListing.none]);
      expect(actions.rated, isEmpty);
      expect(_card, findsNothing);
      expect(SupportService.lastShown, _today);
    });

    testWidgets('"Not now" waits; "I already did, thanks" ends it', (
      tester,
    ) async {
      await _init();
      await _pump(
        tester,
        HomeScreen(now: _today),
        support: _rate(_FakeStoreActions()),
      );
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(_card, findsNothing);
      expect(SupportService.isDue(DateTime(2027, 4, 1)), isTrue);

      SupportService.showNow();
      await tester.pumpAndSettle();
      await tester.tap(find.text('I already did, thanks'));
      await tester.pumpAndSettle();
      expect(SupportService.alreadySupported, isTrue);
      expect(SupportService.isDue(DateTime(2040)), isFalse);
    });
  });

  group('every language', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      final values = AppLocalizations.valuesFor(lang);

      testWidgets('rate builds show no money wording in $lang', (tester) async {
        await _init(lang: lang);
        final support = _rate(_FakeStoreActions());
        await _pump(tester, HomeScreen(now: _today), support: support);
        expect(_card, findsOneWidget);
        final texts = renderedTexts(tester);
        await _pump(
          tester,
          const SettingsScreen(alwaysShowDiagnostics: false),
          support: support,
          physicalSize: _wholeSettings,
        );
        expect(find.text(values['recommend_rate']!), findsOneWidget);
        for (final key in [
          'settings_source_code',
          'settings_source_code_sub',
          'settings_feedback',
          'settings_feedback_sub',
        ]) {
          expect(find.text(values[key]!), findsOneWidget, reason: key);
        }
        texts.addAll(renderedTexts(tester));
        for (final text in texts) {
          expect(text, isNot(matches(moneyWords)), reason: text);
        }
      });

      test('the scan would catch the link wording in $lang', () {
        for (final key in ['support_coffee', 'support_card_body']) {
          expect(values[key], matches(moneyWords), reason: key);
        }
      });

      testWidgets('the rate card fits a 393x851 screen in $lang', (
        tester,
      ) async {
        await _loadInterFonts();
        await _init(lang: lang, firstUse: '2025-05-02');
        await _pump(
          tester,
          HomeScreen(now: _today),
          support: _rate(_FakeStoreActions()),
        );
        expect(tester.takeException(), isNull);
        expect(_card, findsOneWidget);
        for (final key in [
          'recommend_card_rate',
          'support_card_not_now',
          'support_card_done',
        ]) {
          final label = find.text(values[key]!);
          expect(label, findsOneWidget, reason: key);
          expect(
            tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
            isFalse,
            reason: key,
          );
          expect(
            tester.getTopRight(label).dx,
            lessThanOrEqualTo(tester.getTopRight(_card).dx),
            reason: key,
          );
        }
        expect(_cardAction, findsOneWidget);
        expectPromptCardLayout(
          tester,
          primary: values['recommend_card_rate']!,
          notNow: values['support_card_not_now']!,
          done: values['support_card_done']!,
        );
      });

      testWidgets('the Settings section fits a 393x851 screen in $lang', (
        tester,
      ) async {
        await _loadInterFonts();
        await _init(lang: lang);
        await _pump(
          tester,
          const SettingsScreen(alwaysShowDiagnostics: false),
          support: _rate(_FakeStoreActions()),
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('support_remind_switch')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final screenWidth =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        for (final key in [
          'settings_section_recommend',
          'recommend_rate',
          'recommend_rate_sub',
          'recommend_share',
          'recommend_share_sub',
        ]) {
          final text = key == 'settings_section_recommend'
              ? values[key]!.toUpperCase()
              : values[key]!;
          final label = find.text(text);
          expect(label, findsOneWidget, reason: key);
          expect(
            tester.getTopRight(label).dx,
            lessThanOrEqualTo(screenWidth),
            reason: key,
          );
        }
      });
    }
  });
}
