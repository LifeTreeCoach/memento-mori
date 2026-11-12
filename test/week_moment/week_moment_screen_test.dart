import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_pose.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_route.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_screen.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_stage.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_notes.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_result.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_turn.dart';

import '../support/app_fonts.dart';

const _timing = WeekMomentTiming();
const _pixel5 = Size(393, 851);
const _nbsp = '\u00A0';
final _skipButton = find.byKey(const ValueKey('week_moment_skip'));
const _turn = WeekTurn(endedWeek: 45, nextWeek: 46);
final _card = find.byKey(const ValueKey('week_moment_closing_card'));
final _stepTitle = find.byKey(const ValueKey('week_moment_step_title'));

Finder _button(ClosingStep step, String which) =>
    find.byKey(ValueKey('week_moment_${step.name}_$which'));

/// Records what the card would save instead of touching the Compass.
class _RecordingNotes extends WeekMomentNotes {
  _RecordingNotes({this.nowFull = false});

  final bool nowFull;
  final List<String> kept = [];
  final List<String> planned = [];

  @override
  Future<Moment?> keepMoment(String text, {required DateTime day}) async {
    kept.add(text);
    return null;
  }

  @override
  Future<AddIntentionResult?> planIntention(
    String text, {
    required DateTime day,
  }) async {
    planned.add(text);
    final intention = Intention(id: 'i', title: text, createdAt: day);
    return AddIntentionResult(intention, nowLimitReached: nowFull);
  }
}

WeekMomentStory _story({
  bool withPhase = true,
  ReminderRhythm rhythm = ReminderRhythm.weekly,
}) => WeekMomentStory.of(
  birthDate: DateTime(1990, 7, 10),
  lifeExpectancyYears: 80,
  today: DateTime(2026, 11, 12),
  phases: [
    if (withPhase)
      LifePhase(
        id: 'now',
        preset: PhasePreset.buildUp,
        start: DateTime(2025, 6, 1),
        plannedEnd: DateTime(2027, 6, 1),
      ),
  ],
  rhythm: rhythm,
  showPhases: true,
);

/// The app around [home] in [lang] at [size], with the given media flags.
Widget _app(
  Widget home, {
  String lang = 'en',
  ThemeStyle style = ThemeStyle.stoic,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool reduceMotion = false,
  bool screenReader = false,
}) => MaterialApp(
  theme: AppTheme.build(style: style, brightness: brightness),
  locale: Locale(lang),
  supportedLocales: [
    for (final code in AppLocalizations.supportedLanguages) Locale(code),
  ],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduceMotion,
      accessibleNavigation: screenReader,
    ),
    child: child!,
  ),
  home: home,
);

Future<void> _pumpMoment(
  WidgetTester tester, {
  WeekMomentStory? story,
  PersonalAddress address = PersonalAddress.none,
  WeekMomentNotes? notes,
  String lang = 'en',
  ThemeStyle style = ThemeStyle.stoic,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool reduceMotion = false,
  bool screenReader = false,
}) async {
  tester.view.physicalSize = _pixel5 * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      WeekMomentScreen(
        story: story ?? _story(),
        address: address,
        turn: _turn,
        notes: notes ?? _RecordingNotes(),
      ),
      lang: lang,
      style: style,
      brightness: brightness,
      textScale: textScale,
      reduceMotion: reduceMotion,
      screenReader: screenReader,
    ),
  );
  await tester.pump(); // the first act starts after the first frame
}

/// Lets [duration] pass in frames of 50 ms.
Future<void> _advance(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < duration; t += frame) {
    await tester.pump(frame);
  }
}

/// Lets the crossfades finish (texts and eyebrows).
Future<void> _settleTexts(WidgetTester tester) =>
    _advance(tester, const Duration(milliseconds: 700));

StagePose _pose(WidgetTester tester) =>
    tester.widget<WeekMomentStage>(find.byType(WeekMomentStage)).pose;

Future<void> _tapStage(WidgetTester tester) async {
  await tester.tapAt(const Offset(196, 300));
  await tester.pump();
}

Future<void> _skip(WidgetTester tester) async {
  await tester.tap(_skipButton);
  await tester.pump();
}

/// Lets the final act's camera move end and the card fade in.
Future<void> _settleFinal(WidgetTester tester) => _advance(
  tester,
  _timing.enter(WeekMomentAct.next) + const Duration(milliseconds: 700),
);

/// Taps [finder] and lets the step change settle.
Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settleTexts(tester);
}

/// Skips to the card and moves on to its plan step without writing.
Future<void> _toPlanStep(WidgetTester tester) async {
  await _skip(tester);
  await _settleFinal(tester);
  await _tapAndSettle(tester, _button(ClosingStep.close, 'secondary'));
}

/// How opaque [finder]'s widget is through the fades above it.
double _opacityOf(WidgetTester tester, Finder finder) {
  final fades = tester.widgetList<FadeTransition>(
    find.ancestor(of: finder, matching: find.byType(FadeTransition)),
  );
  return fades.fold(1.0, (opacity, fade) => opacity * fade.opacity.value);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await loadAppFonts();
  });

  group('sequence', () {
    testWidgets('plays the acts in order by their timing', (tester) async {
      await _pumpMoment(tester);
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('Another week has passed.'), findsOneWidget);
      expect(
        find.text('In your 37th${_nbsp}year of life, 34${_nbsp}weeks remain.'),
        findsOneWidget,
      );
      const acts = [
        (WeekMomentAct.week, 'YOUR PHASE'),
        (WeekMomentAct.phase, 'YOUR LIFE'),
      ];
      for (final (act, next) in acts) {
        await _advance(tester, _timing.enter(act) + _timing.hold(act)!);
        await _settleTexts(tester);
        expect(find.text(next), findsOneWidget, reason: '$act');
      }
      expect(_card, findsNothing);
      const life = WeekMomentAct.life;
      await _advance(tester, _timing.enter(life) + _timing.hold(life)!);
      await _settleTexts(tester);
      expect(find.textContaining('of your phase “Building up”'), findsNothing);
      expect(find.text('YOUR LIFE'), findsNothing);
      expect(_card, findsOneWidget);
      expect(find.text('The week is over.'), findsOneWidget);
      expect(find.text('WEEK${_nbsp}45$_nbsp· COMPLETE'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(_skipButton.hitTestable(), findsNothing);
      expect(_button(ClosingStep.close, 'primary'), findsOneWidget);
      await _settleFinal(tester);
      expect(_pose(tester).pulse, isTrue);
    });

    testWidgets('the phase act tells the week and the planned rest', (
      tester,
    ) async {
      await _pumpMoment(tester);
      await _tapStage(tester);
      await _tapStage(tester);
      await _settleTexts(tester);
      expect(find.text('YOUR PHASE'), findsOneWidget);
      expect(
        find.textContaining('of your phase “Building up”.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('more planned weeks lie ahead.'),
        findsOneWidget,
      );
    });

    testWidgets('the week act fills the passed weeks while entering', (
      tester,
    ) async {
      await _pumpMoment(tester);
      expect(_pose(tester).fill, lessThan(0.2));
      await _advance(
        tester,
        _timing.enter(WeekMomentAct.week) + const Duration(milliseconds: 100),
      );
      expect(_pose(tester).fill, 1);
    });

    testWidgets('a tap during the entry lands the act, the next one advances', (
      tester,
    ) async {
      await _pumpMoment(tester);
      await _advance(tester, const Duration(milliseconds: 100));
      await _tapStage(tester);
      expect(_pose(tester).fill, 1);
      expect(find.text('THIS WEEK'), findsOneWidget);
      await _tapStage(tester);
      await _advance(tester, const Duration(milliseconds: 100));
      final pose = _pose(tester);
      expect(pose.to, WeekMomentAct.phase);
      expect(pose.t, lessThan(1));
      await _tapStage(tester);
      expect(_pose(tester).t, 1);
    });

    testWidgets('Skip jumps to the first step of the card', (tester) async {
      await _pumpMoment(tester);
      await _skip(tester);
      await _settleFinal(tester);
      expect(find.text('The week is over.'), findsOneWidget);
      expect(
        find.text(
          'What was beautiful about it? Hold on to it for a moment$_nbsp– '
          'in your thoughts or in a sentence.',
        ),
        findsOneWidget,
      );
      expect(_skipButton.hitTestable(), findsNothing);
      // Neither a tap on the stage nor time moves the steps on.
      await _tapStage(tester);
      await _advance(tester, const Duration(seconds: 10));
      expect(find.text('The week is over.'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
    });

    testWidgets('without a phase the phase act is left out', (tester) async {
      await _pumpMoment(tester, story: _story(withPhase: false));
      await _advance(
        tester,
        _timing.enter(WeekMomentAct.week) + _timing.hold(WeekMomentAct.week)!,
      );
      await _settleTexts(tester);
      expect(find.text('YOUR LIFE'), findsOneWidget);
      expect(find.text('YOUR PHASE'), findsNothing);
      expect(find.textContaining('lie ahead of you'), findsOneWidget);
    });

    testWidgets('the 4-week rhythm says 4 weeks', (tester) async {
      await _pumpMoment(
        tester,
        story: _story(rhythm: ReminderRhythm.every4Weeks),
      );
      expect(find.text('Another 4${_nbsp}weeks have passed.'), findsOneWidget);
    });
  });

  group('personal address', () {
    testWidgets('the name appears once: in the closing title', (
      tester,
    ) async {
      await _pumpMoment(tester, lang: 'de', address: PersonalAddress('Daniel'));
      expect(find.text('Wieder ist eine Woche vergangen.'), findsOneWidget);
      expect(find.textContaining('Daniel'), findsNothing);
      await _skip(tester);
      await _settleFinal(tester);
      expect(find.text('Daniel, die Woche ist vorbei.'), findsOneWidget);
      expect(find.textContaining('Daniel'), findsOneWidget);
      await _tapAndSettle(tester, _button(ClosingStep.close, 'secondary'));
      expect(find.text('Die neue Woche gehört dir.'), findsOneWidget);
      expect(find.text('Wofür soll sie Platz haben?'), findsOneWidget);
      expect(find.textContaining('Daniel'), findsNothing);
    });

    testWidgets('without a name the sentences go without it', (tester) async {
      await _pumpMoment(tester, lang: 'de');
      expect(find.text('Wieder ist eine Woche vergangen.'), findsOneWidget);
      await _skip(tester);
      await _settleFinal(tester);
      expect(find.text('Die Woche ist vorbei.'), findsOneWidget);
      expect(find.text('WOCHE${_nbsp}45$_nbsp· ABGESCHLOSSEN'), findsOneWidget);
      expect(find.text('1 von 2'), findsOneWidget);
    });
  });

  group('closing steps', () {
    testWidgets('a written note is kept, then the plan step follows', (
      tester,
    ) async {
      final notes = _RecordingNotes();
      await _pumpMoment(tester, notes: notes);
      await _skip(tester);
      await _settleFinal(tester);
      expect(find.byKey(const ValueKey('week_square_filled')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('week_moment_close_field')),
        'A walk in the rain',
      );
      await _tapAndSettle(tester, _button(ClosingStep.close, 'primary'));
      expect(notes.kept, ['A walk in the rain']);
      expect(find.text('The new week is yours.'), findsOneWidget);
      expect(find.text('2 of 2'), findsOneWidget);
      expect(
        find.text('WEEK${_nbsp}46$_nbsp· 28 MORE IN THIS PHASE'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('week_square_framed')), findsOneWidget);
      expect(find.byKey(const ValueKey('week_moment_plan_field')), findsOneWidget);
    });

    testWidgets('"Kept in my thoughts" moves on without saving', (
      tester,
    ) async {
      final notes = _RecordingNotes();
      await _pumpMoment(tester, notes: notes);
      await _toPlanStep(tester);
      expect(notes.kept, isEmpty);
      expect(find.text('The new week is yours.'), findsOneWidget);
    });

    testWidgets('without a phase the plan eyebrow counts the year', (
      tester,
    ) async {
      await _pumpMoment(tester, story: _story(withPhase: false));
      await _toPlanStep(tester);
      expect(
        find.text('WEEK${_nbsp}46$_nbsp· 34 MORE IN THIS YEAR OF LIFE'),
        findsOneWidget,
      );
    });

    testWidgets('back in the plan step returns to the close step', (
      tester,
    ) async {
      await _pumpMoment(tester);
      await _toPlanStep(tester);
      await tester.binding.handlePopRoute();
      await _settleTexts(tester);
      expect(find.text('The week is over.'), findsOneWidget);
      expect(find.byType(WeekMomentScreen), findsOneWidget);
    });

    testWidgets('reduced motion switches the steps at once', (tester) async {
      await _pumpMoment(tester, reduceMotion: true);
      await _skip(tester);
      await tester.pump();
      expect(find.text('The week is over.'), findsOneWidget);
      await tester.tap(_button(ClosingStep.close, 'secondary'));
      await tester.pump();
      expect(find.text('The week is over.'), findsNothing);
      expect(find.text('The new week is yours.'), findsOneWidget);
    });

    testWidgets('the step title is a live region, the field is labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpMoment(tester);
      await _skip(tester);
      await _settleFinal(tester);
      expect(
        tester.getSemantics(_stepTitle),
        isSemantics(isLiveRegion: true, isHeader: true, label: 'The week is over.'),
      );
      expect(
        find.bySemanticsLabel(RegExp('^Write it down$_nbsp– only if you like')),
        findsOneWidget,
      );
      await _tapAndSettle(tester, _button(ClosingStep.close, 'secondary'));
      expect(
        find.bySemanticsLabel(RegExp('^One thing that counts this week')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('leaving', () {
    Future<WeekMomentResult?> openAndLeave(
      WidgetTester tester,
      Future<void> Function() leave, {
      WeekMomentNotes? notes,
    }) async {
      WeekMomentResult? result;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result =
                    await Navigator.of(context).push<WeekMomentResult>(
                      MaterialPageRoute(
                        builder: (_) => WeekMomentScreen(
                          story: _story(),
                          turn: _turn,
                          notes: notes ?? _RecordingNotes(),
                        ),
                      ),
                    ) ??
                    WeekMomentResult.closed,
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // the localizations load
      await tester.tap(find.text('open'));
      await _advance(tester, const Duration(milliseconds: 400));
      expect(find.byType(WeekMomentScreen), findsOneWidget);
      await leave();
      await _advance(tester, const Duration(milliseconds: 400));
      expect(find.byType(WeekMomentScreen), findsNothing);
      return result;
    }

    testWidgets('"Plan the week" pops continued', (tester) async {
      final notes = _RecordingNotes();
      final result = await openAndLeave(tester, notes: notes, () async {
        await _toPlanStep(tester);
        await tester.tap(_button(ClosingStep.plan, 'primary'));
      });
      expect(result, WeekMomentResult.continued);
      expect(notes.planned, ['']);
    });

    testWidgets('"Plan the week" with a text plans it, then continues', (
      tester,
    ) async {
      final notes = _RecordingNotes();
      final result = await openAndLeave(tester, notes: notes, () async {
        await _toPlanStep(tester);
        await tester.enterText(
          find.byKey(const ValueKey('week_moment_plan_field')),
          'Call Anna',
        );
        await tester.tap(_button(ClosingStep.plan, 'primary'));
      });
      expect(result, WeekMomentResult.continued);
      expect(notes.planned, ['Call Anna']);
      expect(find.textContaining('“Now” is full'), findsNothing);
    });

    testWidgets('a full "Now" says the plan waits in "Someday"', (
      tester,
    ) async {
      final result = await openAndLeave(
        tester,
        notes: _RecordingNotes(nowFull: true),
        () async {
          await _toPlanStep(tester);
          await tester.enterText(
            find.byKey(const ValueKey('week_moment_plan_field')),
            'Call Anna',
          );
          await tester.tap(_button(ClosingStep.plan, 'primary'));
        },
      );
      expect(result, WeekMomentResult.continued);
      expect(find.textContaining('“Now” is full'), findsOneWidget);
    });

    testWidgets('"Enjoy life" pops closed', (tester) async {
      final notes = _RecordingNotes();
      final result = await openAndLeave(tester, notes: notes, () async {
        await _toPlanStep(tester);
        await tester.tap(_button(ClosingStep.plan, 'secondary'));
      });
      expect(result, WeekMomentResult.closed);
      expect(notes.planned, isEmpty);
    });

    testWidgets('the route pops closed on back', (tester) async {
      WeekMomentResult? result;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await showWeekMoment(context, story: _story()),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await _advance(tester, const Duration(milliseconds: 400));
      await tester.binding.handlePopRoute();
      await _advance(tester, const Duration(milliseconds: 400));
      expect(find.byType(WeekMomentScreen), findsNothing);
      expect(result, WeekMomentResult.closed);
    });

    testWidgets('back in the close step counts as closed', (tester) async {
      final result = await openAndLeave(tester, () async {
        await _skip(tester);
        await _settleFinal(tester);
        await tester.binding.handlePopRoute();
      });
      expect(result, WeekMomentResult.closed);
    });

    testWidgets('the card is not there before the final act', (tester) async {
      await _pumpMoment(tester);
      expect(_card, findsNothing);
      expect(_button(ClosingStep.close, 'primary'), findsNothing);
    });

    testWidgets('leaving mid-act leaves no timer behind', (tester) async {
      await _pumpMoment(tester);
      await _advance(tester, const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await _pumpMoment(tester);
      await _skip(tester);
      await _advance(tester, const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      // The test framework fails on any timer still pending here.
    });
  });

  group('act texts', () {
    final oldMain = find.text('Another week has passed.');
    final oldEyebrow = find.text('THIS WEEK');
    final newEyebrow = find.text('YOUR PHASE');

    /// Lands act 1 and starts the switch to act 2.
    Future<void> switchToPhase(WidgetTester tester) async {
      await _tapStage(tester);
      await _settleTexts(tester);
      await _tapStage(tester);
    }

    testWidgets('fade through: the old text leaves before the new comes', (
      tester,
    ) async {
      await _pumpMoment(tester);
      await switchToPhase(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expect(_opacityOf(tester, oldMain), greaterThan(0));
      expect(_opacityOf(tester, oldEyebrow), greaterThan(0));
      expect(_opacityOf(tester, newEyebrow), 0);
      for (final main in tester.widgetList<Text>(
        find.byKey(const ValueKey('week_moment_main')),
      )) {
        if (main.data == 'Another week has passed.') continue;
        expect(_opacityOf(tester, find.text(main.data!)), 0);
      }
      await tester.pump(const Duration(milliseconds: 200));
      expect(_opacityOf(tester, oldMain), 0);
      expect(_opacityOf(tester, oldEyebrow), 0);
      expect(_opacityOf(tester, newEyebrow), greaterThan(0));
      await _settleTexts(tester);
      expect(find.byKey(const ValueKey('week_moment_main')), findsOneWidget);
      expect(oldMain, findsNothing);
      expect(_opacityOf(tester, newEyebrow), 1);
    });

    testWidgets('only the current act is announced while switching', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpMoment(tester);
      await switchToPhase(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.bySemanticsLabel(RegExp('^Another week has passed')),
        findsNothing,
      );
      expect(find.bySemanticsLabel('THIS WEEK'), findsNothing);
      handle.dispose();
    });

    testWidgets('reduced motion switches the texts at once', (tester) async {
      await _pumpMoment(tester, reduceMotion: true);
      await switchToPhase(tester);
      await tester.pump();
      expect(oldMain, findsNothing);
      expect(find.byKey(const ValueKey('week_moment_main')), findsOneWidget);
      expect(_opacityOf(tester, newEyebrow), 1);
    });
  });

  group('accessibility', () {
    testWidgets('reduced motion: acts land at once but still hold', (
      tester,
    ) async {
      await _pumpMoment(tester, reduceMotion: true);
      expect(_pose(tester).fill, 1);
      await _advance(tester, const Duration(seconds: 3));
      expect(find.text('THIS WEEK'), findsOneWidget);
      await _advance(tester, const Duration(milliseconds: 700));
      final pose = _pose(tester);
      expect(pose.to, WeekMomentAct.phase);
      expect(pose.t, 1);
      expect(find.text('YOUR PHASE'), findsOneWidget);
    });

    testWidgets('with a screen reader only a tap moves on', (tester) async {
      await _pumpMoment(tester, screenReader: true);
      await _advance(tester, const Duration(seconds: 12));
      expect(find.text('THIS WEEK'), findsOneWidget);
      await _tapStage(tester);
      await _settleTexts(tester);
      expect(find.text('YOUR PHASE'), findsOneWidget);
      await _advance(tester, const Duration(seconds: 12));
      expect(find.text('YOUR PHASE'), findsOneWidget);
    });

    testWidgets('each act is a live region, the stage has a label and hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpMoment(tester);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('week_moment_main'))),
        isSemantics(
          isLiveRegion: true,
          label:
              'Another week has passed. In your 37th${_nbsp}year of life, '
              '34${_nbsp}weeks remain.',
        ),
      );
      final stage = tester.getSemantics(
        find.byKey(const ValueKey('week_moment_stage')),
      );
      expect(
        stage,
        isSemantics(label: 'Your life in weeks', hasTapAction: true),
      );
      expect(stage.hintOverrides?.onTapHint, 'continue');
      handle.dispose();
    });
  });

  group('layout', () {
    /// Walks the card's steps with a long text in each field, with and
    /// without the keyboard.
    Future<void> walkSteps(WidgetTester tester, String reason) async {
      const long =
          'A very long sentence about what was beautiful this week, and it '
          'goes on and on so that the field needs several lines.';
      for (final step in ClosingStep.values) {
        await tester.enterText(
          find.byKey(ValueKey('week_moment_${step.name}_field')),
          long,
        );
        await _settleTexts(tester);
        expect(tester.takeException(), isNull, reason: '$reason $step');
        tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
        await _settleTexts(tester);
        expect(tester.takeException(), isNull, reason: '$reason $step kbd');
        tester.view.resetViewInsets();
        await _settleTexts(tester);
        if (step == ClosingStep.close) {
          await _tapAndSettle(tester, _button(step, 'secondary'));
        }
      }
    }

    Future<void> walkActs(
      WidgetTester tester, {
      required String lang,
      ThemeStyle style = ThemeStyle.stoic,
      Brightness brightness = Brightness.light,
      double textScale = 1,
    }) async {
      final story = _story();
      final reason = '$lang ${style.name} ${brightness.name} x$textScale';
      await _pumpMoment(
        tester,
        story: story,
        lang: lang,
        style: style,
        brightness: brightness,
        textScale: textScale,
        address: PersonalAddress('Maximiliane'),
      );
      for (final act in story.acts) {
        await _settleTexts(tester);
        expect(tester.takeException(), isNull, reason: '$reason $act');
        await _tapStage(tester); // lands
        await _tapStage(tester); // next act
      }
      await _settleFinal(tester);
      expect(tester.takeException(), isNull, reason: '$reason final');
      await walkSteps(tester, reason);
      await tester.pumpWidget(const SizedBox());
      await _pumpMoment(
        tester,
        story: _story(withPhase: false),
        lang: lang,
        style: style,
        brightness: brightness,
        textScale: textScale,
      );
      await _skip(tester);
      await _settleFinal(tester);
      expect(tester.takeException(), isNull, reason: '$reason skipped');
      await walkSteps(tester, '$reason no phase');
      await tester.pumpWidget(const SizedBox());
    }

    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('no overflow on a Pixel 5 ($lang)', (tester) async {
        await walkActs(tester, lang: lang);
      });

      testWidgets('no overflow at text scale 1.3, Warm dark ($lang)', (
        tester,
      ) async {
        await walkActs(
          tester,
          lang: lang,
          style: ThemeStyle.warm,
          brightness: Brightness.dark,
          textScale: 1.3,
        );
      });
    }
  });
}
