import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_launch_requests.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/compass_section.dart';
import 'package:memento_mori_life_in_weeks/settings_screen.dart';
import 'package:memento_mori_life_in_weeks/widget_launches.dart';

import 'support/compass_test_app.dart';

class _NoWidgetLaunches implements WidgetLaunches {
  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) =>
      const Stream<void>.empty().listen(null);
}

Widget _shell() =>
    AppShell(now: compassToday, widgetLaunches: _NoWidgetLaunches());

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Future<void> _openCompassTab(WidgetTester tester) async {
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.explore_outlined)));
  await tester.pumpAndSettle();
}

Finder get _lifeCard => find.byKey(const ValueKey('life_compass_card'));

void main() {
  setUpAll(() => initializeDateFormatting());
  // The Compass setup already opened by itself once (see
  // compass_setup_test.dart), so the tab shows the Compass right away.
  setUp(() => initCompassTest(extra: {'compass_setup': '{"autoOpened":true}'}));

  group('tabs', () {
    testWidgets('order is Life, Compass, People, Settings', (tester) async {
      await pumpCompassApp(tester, _shell());
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      final labels = [
        for (final d in bar.destinations) (d as NavigationDestination).label,
      ];
      expect(labels, ['Life', 'Compass', 'People', 'Settings']);
    });

    testWidgets('the Compass tab shows the Compass screen', (tester) async {
      await pumpCompassApp(tester, _shell());
      await _openCompassTab(tester);
      expect(_selectedTab(tester), 1);
      expect(find.byType(CompassScreen), findsOneWidget);
      expect(find.text('QUESTION OF THE WEEK · COURAGE'),
          findsOneWidget);
    });

    testWidgets('an in-app request closes pushed screens, shows Compass',
        (tester) async {
      await pumpCompassApp(tester, _shell());
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Pushed detail'))));
      await tester.pumpAndSettle();
      expect(find.text('Pushed detail'), findsOneWidget);

      CompassLaunchRequests.request();
      await tester.pumpAndSettle();
      expect(find.text('Pushed detail'), findsNothing);
      expect(_selectedTab(tester), 1);
    });

    testWidgets('the Compass tab follows changes made elsewhere',
        (tester) async {
      await pumpCompassApp(tester, _shell());
      await _openCompassTab(tester);
      await CompassService.addIntention(title: 'Write to Ben');
      await tester.pumpAndSettle();
      expect(find.text('Write to Ben'), findsOneWidget);
    });
  });

  group('Life tab question card', () {
    testWidgets('opens the Compass tab', (tester) async {
      await pumpCompassApp(tester, _shell());
      expect(_lifeCard, findsOneWidget);
      await tester.tap(find.text('Open Compass'));
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), 1);
    });

    testWidgets('is hidden once the question is put away this week',
        (tester) async {
      await pumpCompassApp(tester, _shell());
      await CompassService.dismissQuestion(compassToday);
      await tester.pumpAndSettle();
      expect(_lifeCard, findsNothing);
    });

    testWidgets('comes back after "Show this week\'s question" in Compass',
        (tester) async {
      await CompassService.dismissQuestion(compassToday);
      await pumpCompassApp(tester, _shell());
      expect(_lifeCard, findsNothing);
      await _openCompassTab(tester);
      await tester.tap(find.byKey(const ValueKey('compass_show_question')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Life').last);
      await tester.pumpAndSettle();
      expect(_lifeCard, findsOneWidget);
    });

    testWidgets('can be turned off in Settings', (tester) async {
      await pumpCompassApp(tester, _shell());
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Question on the Life tab'));
      await tester.pumpAndSettle();
      expect(CompassService.showLifeCard, isFalse);
      await tester.tap(find.text('Life').last);
      await tester.pumpAndSettle();
      expect(_lifeCard, findsNothing);
    });
  });

  group('Settings section', () {
    testWidgets('switches gentle questions and grid marks', (tester) async {
      await pumpCompassApp(tester, SettingsScreen());
      expect(find.byType(CompassSection), findsOneWidget);
      expect(find.text('COMPASS'), findsOneWidget);

      await tester.tap(find.text('Gentle questions only'));
      await tester.pumpAndSettle();
      expect(CompassService.gentleOnly, isTrue);
      expect(
          tester
              .widget<SwitchListTile>(
                  find.byKey(const ValueKey('compass_setting_gentle')))
              .value,
          isTrue);

      expect(CompassService.showGridMarks, isTrue);
      await tester.tap(find.text('Show moments on the life grid'));
      await tester.pumpAndSettle();
      expect(CompassService.showGridMarks, isFalse);
    });

    testWidgets('"Life phases" opens the editor without a phase',
        (tester) async {
      await pumpCompassApp(tester, SettingsScreen());
      final row = find.byKey(const ValueKey('compass_setting_phases'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('phase_apply')), findsOneWidget);
    });

    testWidgets('"Life phases" opens the phase sheet', (tester) async {
      await CompassService.startPhase(
          preset: PhasePreset.buildUp, start: DateTime(2022, 9, 2));
      await pumpCompassApp(tester, SettingsScreen());
      final row = find.byKey(const ValueKey('compass_setting_phases'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('phase_sheet')), findsOneWidget);
      expect(find.text('Building up'), findsWidgets);
    });
  });

  group('fits a Pixel 5 (393 x 851)', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('in $lang without overflow', (tester) async {
        await initCompassTest(lang: lang);
        await _seedLongData();
        await pumpCompassApp(tester, _shell(), size: const Size(393, 851));
        await _scrollThrough(tester, atBottom: () {
          expect(_lifeCard, findsOneWidget);
        });

        await _openCompassTab(tester);
        await _scrollTo(tester, const ValueKey('compass_someday_toggle'));
        await tester.tap(find.byKey(const ValueKey('compass_someday_toggle')));
        await tester.pumpAndSettle();
        await _scrollThrough(tester);
        await _openSheets(tester, lang);

        for (final tab in [Icons.people_outline_rounded, Icons.settings_outlined]) {
          await tester.tap(find.byIcon(tab));
          await tester.pumpAndSettle();
          await _scrollThrough(tester);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}

/// Long titles and every optional field, in German-length words.
Future<void> _seedLongData() async {
  const long = 'Mit meiner Großmutter die Familiengeschichte aufschreiben, '
      'bevor Erinnerungen verloren gehen';
  final kinds = [IntentionKind.doTask, IntentionKind.enjoy, null];
  final areas = [LifeArea.relationships, LifeArea.contribution, null];
  for (var i = 0; i < 3; i++) {
    await CompassService.addIntention(
      title: long,
      note: '$long. $long.',
      area: areas[i],
      horizon: const Horizon.byAge(100),
      kind: kinds[i],
      dueDate: i == 1 ? DateTime(2027, 9, 30) : null,
      today: compassToday,
    );
  }
  await CompassService.startPhase(
    preset: PhasePreset.careerStart,
    start: DateTime(2024, 3, 1),
    plannedEnd: DateTime(2028, 1, 1),
    today: compassToday,
  );
  await CompassService.addIntention(
      title: long, status: IntentionStatus.someday, area: LifeArea.adventure);
  for (final area in [...LifeArea.values, null]) {
    await CompassService.addMoment(
        title: long, date: DateTime(2001, 1, 1), area: area);
  }
}

/// Scrolls the current tab to the bottom (calls [atBottom]) and back.
Future<void> _scrollThrough(WidgetTester tester, {VoidCallback? atBottom}) async {
  for (var i = 0; i < 6; i++) {
    await tester.dragFrom(const Offset(380, 600), const Offset(0, -700));
    await tester.pumpAndSettle();
  }
  atBottom?.call();
  for (var i = 0; i < 6; i++) {
    await tester.dragFrom(const Offset(380, 300), const Offset(0, 700));
    await tester.pumpAndSettle();
  }
}

/// Scrolls the Compass tab until the widget with [key] is visible.
Future<void> _scrollTo(WidgetTester tester, Key key) async {
  final scrollable = find.descendant(
      of: find.byType(CompassScreen), matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(find.byKey(key), 200,
      scrollable: scrollable.first);
  await tester.pumpAndSettle();
}

/// Opens the intention flow ("More" open, "by an age" picked), the edit
/// sheet of an intention and the moment sheet.
Future<void> _openSheets(WidgetTester tester, String lang) async {
  final strings = AppLocalizations.valuesFor(lang);
  final addIntention = find.byKey(const ValueKey('compass_add_intention'));
  await _scrollTo(tester, const ValueKey('compass_add_intention'));
  await tester.tap(addIntention);
  await tester.pumpAndSettle();
  final more = find.byKey(const ValueKey('intention_more'));
  await tester.ensureVisible(more);
  await tester.tap(more);
  await tester.pumpAndSettle();
  final byAge = find.text(strings['compass_horizon_by_age_chip']!);
  await tester.ensureVisible(byAge);
  await tester.tap(byAge);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('add_intention_back')));
  await tester.pumpAndSettle();

  final intention = CompassService.data.withStatus(IntentionStatus.now).first;
  final card = find.byKey(ValueKey('compass_intention_${intention.id}'));
  await _scrollTo(tester, ValueKey('compass_intention_${intention.id}'));
  await tester.tap(find.descendant(of: card, matching: find.byType(Text)).first);
  await tester.pumpAndSettle();
  final enjoy = find.byKey(const ValueKey('intention_kind_enjoy'));
  await tester.ensureVisible(enjoy);
  await tester.tap(enjoy);
  await tester.pumpAndSettle();
  final cancel = find.text(strings['compass_cancel']!);
  await tester.ensureVisible(cancel);
  await tester.pumpAndSettle();
  await tester.tap(cancel);
  await tester.pumpAndSettle();

  final addMoment = find.byKey(const ValueKey('compass_add_moment'));
  await _scrollTo(tester, const ValueKey('compass_add_moment'));
  await tester.tap(addMoment);
  await tester.pumpAndSettle();
  await tester.tap(find.text(strings['compass_cancel']!));
  await tester.pumpAndSettle();
}
