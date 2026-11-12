import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_hero.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_lifespan_visualization.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/info_row.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/friend_detail_screen.dart';
import 'package:memento_mori_life_in_weeks/friend_form/group_field.dart';
import 'package:memento_mori_life_in_weeks/friend_form/lifespan_slider.dart';
import 'package:memento_mori_life_in_weeks/l10n/friend_form_strings.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _today = DateTime(2026, 11, 2);

Friend _friend({DateTime? birthDate, String? group}) => Friend(
      id: '1',
      name: 'Anna Lopez',
      birthDate: birthDate ?? DateTime(1995, 11, 14),
      groupName: group,
      createdDate: DateTime(2025, 1, 1),
      lastUpdated: DateTime(2025, 1, 1),
    );

Future<void> _pump(WidgetTester tester, Widget home,
    {String lang = 'en'}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.light),
    locale: Locale(lang),
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'birth_date': DateTime(1990, 11, 17).toIso8601String(),
      'lifespan_visualization_enabled': false,
    });
    await SettingsService.initialize();
  });

  test('friend form strings exist in English and German', () {
    expect(friendFormStringsEn.keys.toSet(), friendFormStringsDe.keys.toSet());
  });

  group('FriendText', () {
    final en = FriendText(AppLocalizations(const Locale('en')));
    final de = FriendText(AppLocalizations(const Locale('de')));

    test('pluralizes age, years and days', () {
      expect(en.age(1), '1\u00A0year old');
      expect(en.age(31), '31\u00A0years old');
      expect(de.age(31), '31\u00A0Jahre alt');
      expect(en.years(1), '1\u00A0year');
      expect(de.days(2), '2\u00A0Tage');
    });

    test('describes the next birthday', () {
      final next = UpcomingBirthday.forFriend(_friend(), _today);
      expect(en.turns(next), 'turns 31 · in 12\u00A0days');
    });

    test('remaining years, or a gentle text beyond the expectancy', () {
      expect(en.remaining(_friend(), today: _today), en.years(50));
      final older = _friend(birthDate: DateTime(1938, 6, 12));
      expect(en.remaining(older, today: _today), 'Beyond the expected time');
      expect(de.remaining(older, today: _today),
          'Über die erwartete Zeit hinaus');
    });

    test('share text names the friend and the app', () {
      final text = en.shareText(_friend());
      expect(text, contains('Anna Lopez'));
      expect(text, contains('Memento Mori'));
      expect(text, isNot(contains('{')));
    });
  });

  group('FriendHero', () {
    testWidgets('shows age, countdown and birthdays together', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: FriendHero(
            friend: _friend(group: 'Family'),
            today: _today,
            userBirthDate: DateTime(1990, 11, 17),
            userLifeExpectancyYears: 80,
          ),
        ),
      );
      expect(find.text('Anna Lopez'), findsOneWidget);
      expect(find.text('30\u00A0years old'), findsOneWidget);
      expect(find.text('turns 31 · in 12\u00A0days'), findsOneWidget);
      expect(find.textContaining('more birthdays together'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
    });

    testWidgets('hides birthdays together without a user birth date',
        (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: FriendHero(
            friend: _friend(birthDate: DateTime(1995, 11, 2)),
            today: _today,
            userLifeExpectancyYears: 80,
          ),
        ),
      );
      expect(find.text('turns 31 today 🎂'), findsOneWidget);
      expect(find.textContaining('together'), findsNothing);
    });
  });

  group('beyond the expected lifespan', () {
    final older = _friend(birthDate: DateTime(1938, 6, 12));

    testWidgets('detail shows no negative years', (tester) async {
      await SharedPreferences.getInstance()
          .then((p) => p.setBool('lifespan_visualization_enabled', true));
      await SettingsService.initialize();
      await _pump(tester, FriendDetailScreen(friend: older), lang: 'de');
      expect(find.text('JEDER TAG EIN GESCHENK'), findsOneWidget);
      await tester.scrollUntilVisible(
          find.text('Über die erwartete Zeit hinaus'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.textContaining(RegExp(r'-\d')), findsNothing);
    });

    testWidgets('lifespan card shows a gift instead of a number',
        (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: FriendLifespanVisualization(
                friend: older, enableAnimation: false),
          ),
        ),
        lang: 'de',
      );
      expect(find.text(FriendLifespanVisualization.giftSymbol), findsOneWidget);
      expect(find.text('JEDER TAG EIN GESCHENK'), findsOneWidget);
      expect(find.textContaining(RegExp(r'-\d')), findsNothing);
    });

    testWidgets('lifespan slider says so instead of a negative',
        (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: LifespanSlider(lifespan: 80, currentAge: 88, onChanged: (_) {}),
        ),
      );
      expect(find.text('Beyond the expected time'), findsOneWidget);
      expect(find.textContaining(RegExp(r'-\d')), findsNothing);
    });
  });

  group('InfoRow', () {
    test('label grows to its longest word while the value still fits', () {
      double width(double label, double value) => InfoRow.labelWidthFor(
          available: 300, longestLabelWord: label, longestValueWord: value);
      expect(width(50, 40), 120); // the usual 2/5
      expect(width(160, 40), 160); // a long compound gets its width
      expect(width(280, 40), 300 - InfoRow.gap - 40); // the value keeps room
      expect(width(280, 250), 120); // no room: back to the usual share
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('detail labels never break mid-word ($lang)',
          (tester) async {
        await SharedPreferences.getInstance()
            .then((p) => p.setBool('lifespan_visualization_enabled', true));
        await SettingsService.initialize();
        tester.view.physicalSize = const Size(393 * 3, 4000 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.build(
              style: ThemeStyle.stoic, brightness: Brightness.light),
          locale: Locale(lang),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: [
            for (final code in AppLocalizations.supportedLanguages) Locale(code),
          ],
          // The test font draws every glyph 1em wide, about twice as wide
          // as the app's fonts; scale it to real proportions.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(0.6)),
            child: child!,
          ),
          home: FriendDetailScreen(
              friend: _friend(birthDate: DateTime(1938, 6, 12), group: 'Familie')),
        ));
        await tester.pump();
        final rows = find.byType(InfoRow);
        expect(rows, findsWidgets);
        for (final element in rows.evaluate()) {
          final row = element.widget as InfoRow;
          final label = tester.renderObject<RenderParagraph>(find.descendant(
              of: find.byWidget(row), matching: find.text(row.label)));
          // Every line break falls between words: the label is at least as
          // wide as its longest word.
          expect(label.size.width,
              greaterThanOrEqualTo(label.getMinIntrinsicWidth(double.infinity) - 0.5),
              reason: row.label);
        }

        // The details dialog (AlertDialog measures intrinsic widths).
        await tester.tap(find.text(
            AppLocalizations(Locale(lang)).translate('lifespan_details')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsOneWidget);
      });
    }
  });

  testWidgets('detail screen renders localized in German', (tester) async {
    await _pump(tester, FriendDetailScreen(friend: _friend()), lang: 'de');
    expect(find.text('GEBURTSTAG'), findsOneWidget);
    expect(find.text('30\u00A0Jahre alt'), findsOneWidget);
    expect(find.textContaining('_'), findsNothing); // no raw keys
  });

  testWidgets('form validates the name with a localized message',
      (tester) async {
    await _pump(tester, const AddFriendScreen());
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Please enter a name'), findsOneWidget);
  });

  group('form accessibility', () {
    testWidgets('name and group fields expose their labels', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, const AddFriendScreen());
      expect(find.bySemanticsLabel('Name'), findsOneWidget);
      // The lifespan section sits between them: scroll to the group.
      await tester.scrollUntilVisible(find.byType(GroupField), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.bySemanticsLabel(RegExp(r'^Group \(optional\)')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('German labels too', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, const AddFriendScreen(), lang: 'de');
      expect(find.bySemanticsLabel('Name'), findsOneWidget);
      // The lifespan section sits between them: scroll to the group.
      await tester.scrollUntilVisible(find.byType(GroupField), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.bySemanticsLabel(RegExp(r'^Gruppe \(optional\)')), findsOneWidget);
      semantics.dispose();
    });

    for (final (lang, expected) in [
      ('en', 'Life expectancy: 80\u00A0years'),
      ('de', 'Lebenserwartung: 80\u00A0Jahre'),
    ]) {
      testWidgets('lifespan slider reads "$expected", not a percent ($lang)',
          (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          Scaffold(
            body: LifespanSlider(lifespan: 80, currentAge: 30, onChanged: (_) {}),
          ),
          lang: lang,
        );
        expect(find.semantics.byValue(expected), findsOne);
        expect(find.semantics.byValue(RegExp('%')), findsNothing);
        semantics.dispose();
      });
    }
  });
}
