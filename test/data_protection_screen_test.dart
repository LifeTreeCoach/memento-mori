import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/data_protection_screen.dart';
import 'package:memento_mori_life_in_weeks/settings/data_section.dart';
import 'package:memento_mori_life_in_weeks/support/project_links.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

import 'support/app_fonts.dart';
import 'support/money_words.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  String lang = 'en',
  TargetPlatform platform = TargetPlatform.android,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(1179, 15000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: theme ?? ThemeData(platform: platform),
    locale: Locale(lang),
    supportedLocales: [
      for (final code in AppLocalizations.supportedLanguages) Locale(code),
    ],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  ));
  await tester.pumpAndSettle();
}

String _t(String lang, String key) => AppLocalizations.valuesFor(lang)[key]!;

/// Pixel 5 in logical pixels (1080x2340 physical at 2.75).
const double _pixel5Dpr = 2.75;
const Size _pixel5Size = Size(1080 / _pixel5Dpr, 2340 / _pixel5Dpr);

void main() {
  group('on a Pixel 5 with the app fonts', () {
    setUpAll(loadAppFonts);

    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('the app bar title fits in $lang', (tester) async {
        await _pump(
          tester,
          const Scaffold(),
          lang: lang,
          theme: AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.dark),
        );
        tester.view.physicalSize = _pixel5Size * _pixel5Dpr;
        tester.view.devicePixelRatio = _pixel5Dpr;
        // Pushed from Settings, as in the app: the back button takes room.
        tester.state<NavigatorState>(find.byType(Navigator)).push(
            MaterialPageRoute<void>(builder: (_) => const DataProtectionScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsOneWidget);

        final title = find.text(_t(lang, 'data_protection_screen_title'));
        expect(title, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
          isFalse,
        );
      });
    }
  });

  for (final lang in AppLocalizations.supportedLanguages) {
    testWidgets('renders every section in $lang', (tester) async {
      await _pump(tester, const DataProtectionScreen(), lang: lang);

      for (final key in [
        'data_protection_screen_title',
        'data_protection_intro',
        'data_protection_encrypted_title',
        'data_protection_encrypted_body',
        'data_protection_health_title',
        'data_protection_health_body',
        'data_protection_backup_title',
        'data_protection_backup_android',
        'data_protection_export_title',
        'data_protection_export_body',
        'data_protection_readable_title',
        'data_protection_readable_body',
        'data_protection_offline_title',
        'data_protection_offline_body',
        'data_protection_policy_link',
      ]) {
        expect(find.text(_t(lang, key)), findsOneWidget, reason: key);
      }
      expect(find.byType(ScrollThread), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the iPhone backup text on iOS', (tester) async {
    await _pump(tester, const DataProtectionScreen(),
        platform: TargetPlatform.iOS);

    expect(find.text(_t('en', 'data_protection_backup_ios')), findsOneWidget);
    expect(find.text(_t('en', 'data_protection_backup_android')), findsNothing);
  });

  testWidgets('the policy link opens the privacy policy', (tester) async {
    final opened = <String>[];
    await _pump(
      tester,
      DataProtectionScreen(openLink: (_, url) async => opened.add(url)),
    );

    await tester.tap(find.byKey(DataProtectionScreen.policyLinkKey));
    await tester.pump();

    expect(opened, [ProjectLinks.privacy]);
  });

  testWidgets('has no money wording in any language', (tester) async {
    for (final lang in AppLocalizations.supportedLanguages) {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        await _pump(tester, const DataProtectionScreen(),
            lang: lang, platform: platform);
        for (final text in renderedTexts(tester)) {
          expect(moneyWords.hasMatch(text), isFalse, reason: '$lang: $text');
        }
      }
    }
  });

  testWidgets('the Data tile opens the screen and passes the link opener',
      (tester) async {
    final opened = <String>[];
    await _pump(
      tester,
      Scaffold(
        body: ListView(children: [
          DataSection(openLink: (_, url) async => opened.add(url)),
        ]),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('settings-data-protection')));
    await tester.pumpAndSettle();

    expect(find.byType(DataProtectionScreen), findsOneWidget);
    await tester.tap(find.byKey(DataProtectionScreen.policyLinkKey));
    await tester.pump();
    expect(opened, [ProjectLinks.privacy]);
  });
}
