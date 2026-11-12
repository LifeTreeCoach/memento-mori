import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_sheet/phase_sheet.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_permission.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/compass_test_app.dart';

/// A system permission the test controls.
class _FakePermission implements NotificationPermission {
  int requests = 0;

  @override
  Future<bool> isGranted() async => true;

  @override
  Future<bool> request() async {
    requests++;
    return true;
  }

  @override
  Future<void> openSystemSettings() async {}
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(_key(key)).data!;

/// "Building up" since 2 Sep 2022 (50 months on [compassToday]), planned
/// until 2 Jan 2028 (14 months left).
Future<LifePhase> _seedPhase({DateTime? plannedEnd}) =>
    CompassService.startPhase(
      preset: PhasePreset.buildUp,
      start: DateTime(2022, 9, 2),
      plannedEnd: plannedEnd ?? DateTime(2028, 1, 2),
      today: compassToday,
    );

/// Three "Now" intentions of the phase; the first one lived.
Future<List<Intention>> _seedIntentions() async {
  final added = [
    for (final title in ['Run a half marathon', 'Learn Italian', 'Call Anna'])
      (await CompassService.addIntention(title: title, today: compassToday))
          .intention,
  ];
  await CompassService.complete(added.first.id, today: compassToday);
  return added;
}

Future<void> _openSheet(WidgetTester tester, {Size? size}) async {
  await pumpCompassApp(tester, CompassScreen(now: compassToday),
      size: size ?? const Size(393, 4000));
  await tester.tap(_key('compass_phase_name'));
  await tester.pumpAndSettle();
}

Intention _intention(String id) =>
    CompassService.data.intentions.firstWhere((i) => i.id == id);

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (_) async => null,
    );
    await initCompassTest();
  });

  testWidgets('tapping the header opens the sheet with dates and stats',
      (tester) async {
    await _seedPhase();
    await _openSheet(tester);
    expect(_key('phase_sheet'), findsOneWidget);
    expect(find.text('YOUR PHASE'), findsOneWidget);
    expect(find.text('since September 2022 · planned until January 2028'),
        findsOneWidget);
    final months = find.descendant(
        of: _key('phase_stat_months'), matching: find.text('50'));
    expect(months, findsOneWidget);
    expect(find.text('months so far'), findsOneWidget);
    // 50 of 431 months lived so far.
    expect(find.descendant(of: _key('phase_stat_share'), matching: find.text('12%')),
        findsOneWidget);
    expect(find.descendant(of: _key('phase_stat_left'), matching: find.text('14')),
        findsOneWidget);
    expect(find.text('months still planned'), findsOneWidget);
    expect(_key('intention_week_dots'), findsOneWidget);
  });

  testWidgets('a muted hint ties "Now" to the phase', (tester) async {
    await _seedPhase();
    await _openSheet(tester);
    expect(find.text('Your intentions in “Now” belong to this phase. When it '
        'ends, you decide what comes along.'), findsOneWidget);
  });

  testWidgets('the edit pencil still opens the editor', (tester) async {
    await _seedPhase();
    await pumpCompassApp(tester, CompassScreen(now: compassToday));
    await _tap(tester, 'compass_phase_edit');
    expect(_key('phase_apply'), findsOneWidget);
    expect(_key('phase_sheet'), findsNothing);
  });

  testWidgets('without a birth date no share, without a plan "open"',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('birth_date');
    await CompassService.startPhase(
        preset: PhasePreset.study, start: DateTime(2024, 1, 1), today: compassToday);
    await _openSheet(tester);
    expect(_key('phase_stat_share'), findsNothing);
    expect(find.descendant(of: _key('phase_stat_left'), matching: find.text('open')),
        findsOneWidget);
    expect(find.textContaining('no planned end'), findsWidgets);
  });

  testWidgets('the review counts lived, open and let go intentions',
      (tester) async {
    await _seedPhase();
    final added = await _seedIntentions();
    await _openSheet(tester);
    expect(_text(tester, 'phase_bilanz_summary'), '1 of 3 intentions lived');
    expect(_key('phase_bilanz_lived_${added[0].id}'), findsOneWidget);
    expect(_key('phase_bilanz_open_${added[1].id}'), findsOneWidget);
    expect(find.text('Still open. What should happen to it?'), findsNWidgets(2));

    await _tap(tester, 'phase_bilanz_let_go_button_${added[1].id}');
    expect(_intention(added[1].id).status, IntentionStatus.letGo);
    expect(_key('phase_bilanz_let_go_${added[1].id}'), findsOneWidget);
    expect(_key('phase_bilanz_open_${added[1].id}'), findsNothing);
    expect(_text(tester, 'phase_bilanz_summary'), '1 of 3 intentions lived');
  });

  testWidgets('"Move to Someday" takes an intention out of the phase',
      (tester) async {
    await _seedPhase();
    final added = await _seedIntentions();
    await _openSheet(tester);
    await _tap(tester, 'phase_bilanz_someday_${added[2].id}');
    expect(_intention(added[2].id).status, IntentionStatus.someday);
    expect(_intention(added[2].id).phaseId, isNull);
    expect(_text(tester, 'phase_bilanz_summary'), '1 of 2 intentions lived');
  });

  testWidgets('no intentions: a calm empty line', (tester) async {
    await _seedPhase();
    await _openSheet(tester);
    expect(_text(tester, 'phase_bilanz_summary'),
        'No intentions in this phase yet – that’s fine too.');
  });

  testWidgets('the rhythm control sets the reminder rhythm', (tester) async {
    await _seedPhase();
    final permission = _FakePermission();
    await pumpCompassApp(
      tester,
      Scaffold(
        body: PhaseSheet(
          today: compassToday,
          birthDate: compassBirthDate,
          permission: permission,
          onEarlier: () {},
          onDuration: () {},
        ),
      ),
    );
    await _tap(tester, 'rhythm_every_4_weeks');
    expect(ReminderService.rhythm(), ReminderRhythm.every4Weeks);
    expect(permission.requests, 1);

    await _tap(tester, 'rhythm_off');
    expect(ReminderService.rhythm(), ReminderRhythm.off);
    expect(permission.requests, 1);
  });

  testWidgets('"Carry on" closes the sheet, "Close phase" starts closing',
      (tester) async {
    await _seedPhase();
    await _openSheet(tester);
    await _tap(tester, 'phase_sheet_continue');
    expect(_key('phase_sheet'), findsNothing);

    await tester.tap(_key('compass_phase_name'));
    await tester.pumpAndSettle();
    await _tap(tester, 'phase_sheet_close');
    expect(_key('phase_sheet'), findsNothing);
    expect(_key('phase_close_note'), findsOneWidget);
  });

  testWidgets('"Add earlier phases" and "Change planned duration" open above',
      (tester) async {
    await _seedPhase();
    await _openSheet(tester);
    await _tap(tester, 'phase_sheet_earlier');
    expect(find.text('A phase lasts until the next one begins.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tap(tester, 'phase_sheet_duration');
    await _tap(tester, 'duration_choice_24');
    await _tap(tester, 'duration_apply');
    expect(CompassService.data.phases.single.plannedEnd, DateTime(2028, 11, 2));
    expect(find.descendant(of: _key('phase_stat_left'), matching: find.text('24')),
        findsOneWidget);
  });

  testWidgets('with earlier phases the button edits instead of adds',
      (tester) async {
    await _seedPhase();
    await _openSheet(tester);
    expect(find.text('Add earlier phases'), findsOneWidget);
    expect(find.text('Edit earlier phases'), findsNothing);
    await _tap(tester, 'phase_sheet_continue');

    await CompassService.startPhase(
        preset: PhasePreset.study,
        start: DateTime(2018, 10, 1),
        today: compassToday);
    await tester.tap(_key('compass_phase_name'));
    await tester.pumpAndSettle();
    expect(find.text('Edit earlier phases'), findsOneWidget);
    expect(find.text('Add earlier phases'), findsNothing);
    await _tap(tester, 'phase_sheet_earlier');
    expect(find.text('A phase lasts until the next one begins.'), findsOneWidget);
  });

  group('fits a Pixel 5 (393 x 851)', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('in $lang without overflow', (tester) async {
        await initCompassTest(lang: lang);
        await _seedPhase();
        await _seedIntentions();
        await CompassService.letGoIntention(
            CompassService.data.intentions.last.id, today: compassToday);
        await _openSheet(tester, size: const Size(393, 851));
        await tester.ensureVisible(_key('phase_sheet_duration'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
