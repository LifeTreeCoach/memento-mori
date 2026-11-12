import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_empty_header.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

import 'support/app_fonts.dart';

const _phoneWidth = 393.0;

Widget _app(Widget child, {
  String language = 'en',
  ThemeStyle style = ThemeStyle.stoic,
  double textScale = 1.0,
}) =>
    MaterialApp(
      theme: AppTheme.build(style: style, brightness: Brightness.light),
      locale: Locale(language),
      supportedLocales: [
        for (final code in AppLocalizations.supportedLanguages) Locale(code),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: page!,
      ),
      home: Scaffold(body: child),
    );

Widget _eyebrowIn(double width) => Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: const FittingPhaseEyebrow(long: 'Your life phase', short: 'Phase'),
      ),
    );

/// Pumps [app] and waits for the localizations to load.
Future<void> _pump(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the long label when it fits on one line', (tester) async {
    await _pump(tester, _app(_eyebrowIn(300)));
    expect(find.text('YOUR LIFE PHASE'), findsOneWidget);
    expect(find.text('PHASE'), findsNothing);
  });

  testWidgets('falls back to the short label in a narrow space', (tester) async {
    await _pump(tester, _app(_eyebrowIn(70)));
    expect(find.text('PHASE'), findsOneWidget);
    expect(find.text('YOUR LIFE PHASE'), findsNothing);
  });

  testWidgets('a larger text scale can switch to the short label',
      (tester) async {
    await _pump(tester, _app(_eyebrowIn(150)));
    expect(find.text('YOUR LIFE PHASE'), findsOneWidget);
    await _pump(tester, _app(_eyebrowIn(150), textScale: 2));
    expect(find.text('PHASE'), findsOneWidget);
  });

  for (final style in ThemeStyle.values) {
    for (final language in AppLocalizations.supportedLanguages) {
      testWidgets(
          'empty Compass header keeps the long label on a phone '
          '($language, ${style.name}, text 1.3)', (tester) async {
        tester.view.physicalSize = const Size(_phoneWidth * 3, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PhaseEmptyHeader(onSet: () {}),
          ),
          language: language,
          style: style,
          textScale: 1.3,
        ));
        await tester.pumpAndSettle();
        final long = AppLocalizations(Locale(language))
            .translate('phase_header_eyebrow')
            .toUpperCase();
        expect(find.text(long), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
