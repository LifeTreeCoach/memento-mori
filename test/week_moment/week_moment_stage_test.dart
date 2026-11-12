import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/life/coming_week_style.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/week_moment/moment_camera.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/next_week_glow.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_frames.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_mix.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/stage_pose.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_stage.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/year_cells_painter.dart';
import 'package:memento_mori_life_in_weeks/week_moment/year_block_layout.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';

WeekMomentStory _story({required bool withPhase}) => WeekMomentStory.of(
  birthDate: DateTime(1990, 7, 10),
  lifeExpectancyYears: 80,
  today: DateTime(2026, 11, 12),
  phases: [
    if (withPhase)
      LifePhase(
        id: 'now',
        name: 'Building',
        start: DateTime(2025, 6, 1),
        plannedEnd: DateTime(2027, 6, 1),
      ),
  ],
  rhythm: ReminderRhythm.weekly,
  showPhases: true,
);

Widget _host(
  WeekMomentStory story,
  StagePose pose,
  Brightness brightness, {
  ThemeStyle style = ThemeStyle.stoic,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: AppTheme.build(style: style, brightness: brightness),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 393,
        height: 600,
        child: WeekMomentStage(story: story, pose: pose),
      ),
    ),
  ),
);

/// Every pose the screen can drive: each act transition at t 0, 0.5, 1.
List<StagePose> _poses(bool withPhase) {
  final acts = actsFor(hasPhase: withPhase);
  return [
    const StagePose.at(WeekMomentAct.week, fill: 0),
    const StagePose.at(WeekMomentAct.week, fill: 0.5),
    for (var i = 0; i + 1 < acts.length; i++)
      for (final t in const [0.0, 0.5, 1.0])
        StagePose(from: acts[i], to: acts[i + 1], t: t),
    const StagePose.at(WeekMomentAct.next, pulse: true),
  ];
}

List<LifeGridPainter> _gridPainters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<LifeGridPainter>()
    .toList();

void main() {
  for (final withPhase in const [true, false]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'renders every pose (phase: $withPhase, ${brightness.name})',
        (tester) async {
          final story = _story(withPhase: withPhase);
          for (final pose in _poses(withPhase)) {
            await tester.pumpWidget(_host(story, pose, brightness));
            expect(tester.takeException(), isNull, reason: '$pose');
          }
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets('reuses the grid painters between frames', (tester) async {
    final story = _story(withPhase: true);
    const first = StagePose(
      from: WeekMomentAct.week,
      to: WeekMomentAct.phase,
      t: 0.2,
    );
    await tester.pumpWidget(_host(story, first, Brightness.light));
    final before = _gridPainters(tester);
    expect(before, hasLength(2));

    const later = StagePose(
      from: WeekMomentAct.phase,
      to: WeekMomentAct.life,
      t: 0.7,
    );
    await tester.pumpWidget(_host(story, later, Brightness.light));
    final after = _gridPainters(tester);
    for (var i = 0; i < before.length; i++) {
      expect(identical(before[i], after[i]), isTrue);
    }
  });

  testWidgets('pulses the next week only when asked', (tester) async {
    final story = _story(withPhase: false);
    await tester.pumpWidget(
      _host(story, const StagePose.at(WeekMomentAct.next), Brightness.dark),
    );
    expect(find.byType(NextWeekGlow), findsNothing);
    await tester.pumpWidget(
      _host(
        story,
        const StagePose.at(WeekMomentAct.next, pulse: true),
        Brightness.dark,
      ),
    );
    expect(find.byType(NextWeekGlow), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('the final act emphasises the coming week, nothing after it',
      (tester) async {
    final story = _story(withPhase: true);
    await tester.pumpWidget(
      _host(
        story,
        const StagePose.at(WeekMomentAct.next, pulse: true),
        Brightness.light,
      ),
    );
    final glowCell = tester.widget<NextWeekGlow>(find.byType(NextWeekGlow)).cell;
    final coming = tester.getRect(
      find.byKey(const ValueKey('week_moment_coming_week')),
    );
    final origin = tester.getTopLeft(find.byType(WeekMomentStage));
    expect(coming.center - origin, offsetMoreOrLessEquals(glowCell.center));
    final painter = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byKey(const ValueKey('week_moment_coming_week')),
        matching: find.byType(CustomPaint),
      ),
    ).painter! as ComingWeekPainter;
    final context = tester.element(find.byType(WeekMomentStage));
    expect(painter.style, ComingWeekStyle.of(context));
    expect(find.byKey(const ValueKey('week_moment_now_outline')), findsNothing);
    await tester.pumpAndSettle();
  });

  test('the next frame is centred on the coming week', () {
    final story = _story(withPhase: true);
    final geometry = LifeGridGeometry(
      mode: LifeMode.weeks,
      totalCells: story.worldCells,
      maxWidth: 393,
      gutterWidth: 22,
    );
    final frames = StageFrames(geometry, story);
    const viewport = Size(393, 600);
    expect(frames.comingCell, story.nowCell);
    expect(
      frames.frameOf(WeekMomentAct.next, viewport),
      MomentFrames.next(geometry, story.nowCell, viewport: viewport),
    );
  });

  group('next week glow', () {
    const finalPose = StagePose.at(WeekMomentAct.next, pulse: true);
    NextWeekGlow glow(WidgetTester tester) =>
        tester.widget<NextWeekGlow>(find.byType(NextWeekGlow));

    for (final style in ThemeStyle.values) {
      for (final brightness in Brightness.values) {
        testWidgets('glows in the ring gold, clear on the surface in '
            '${style.name} ${brightness.name}', (tester) async {
          final story = _story(withPhase: false);
          await tester.pumpWidget(
            _host(story, finalPose, brightness, style: style),
          );
          final context = tester.element(find.byType(NextWeekGlow));
          final surface = Theme.of(context).colorScheme.surface;
          expect(glow(tester).color, ComingWeekStyle.of(context).ring);
          expect(
            contrastRatio(glow(tester).color, surface),
            greaterThanOrEqualTo(PhaseColors.minRingContrast),
          );
          await tester.pumpAndSettle();
        });
      }
    }

    testWidgets('has a halo beyond the cell, below the coming week', (
      tester,
    ) async {
      final story = _story(withPhase: false);
      await tester.pumpWidget(_host(story, finalPose, Brightness.light));
      final cell = glow(tester).cell;
      final painted = tester.getRect(
        find.descendant(
          of: find.byType(NextWeekGlow),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        painted.width,
        greaterThan(cell.width + 2 * NextWeekGlow.minHalo - 1),
      );
      final stack = tester.widget<Stack>(
        find
            .descendant(
              of: find.byType(WeekMomentStage),
              matching: find.byType(Stack),
            )
            .first,
      );
      final keys = [for (final child in stack.children) child.key];
      expect(
        keys.indexOf(const ValueKey('week_moment_next_pulse')),
        lessThan(keys.indexOf(const ValueKey('week_moment_coming_week'))),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('keeps the halo without breathing when motion is off', (
      tester,
    ) async {
      final story = _story(withPhase: false);
      await tester.pumpWidget(
        _host(story, finalPose, Brightness.dark, reduceMotion: true),
      );
      await tester.pump();
      expect(find.byType(NextWeekGlow), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(NextWeekGlow),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1);
    });
  });

  testWidgets('is hidden from semantics', (tester) async {
    final handle = tester.ensureSemantics();
    final story = _story(withPhase: true);
    await tester.pumpWidget(
      _host(story, const StagePose.at(WeekMomentAct.life), Brightness.light),
    );
    expect(
      find.descendant(
        of: find.byType(WeekMomentStage),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    handle.dispose();
  });

  group('StageMix', () {
    test('act 1 shows only the year block', () {
      final mix = StageMix.of(const StagePose.at(WeekMomentAct.week));
      expect(mix.gridOpacity, 0);
      expect(mix.morph, 0);
      expect(mix.blockOpacity, 1);
    });

    test('leaving act 1 fades the grid in after 40 %', () {
      StageMix at(double t) => StageMix.of(
        StagePose(from: WeekMomentAct.week, to: WeekMomentAct.phase, t: t),
      );
      expect(at(0.3).phaseLayer, 0);
      expect(at(0.7).phaseLayer, greaterThan(0));
      expect(at(1).phaseLayer, 1);
      expect(at(1).lifeLayer, 0);
      expect(at(1).blockOpacity, 0);
      expect(at(0.5).blockOpacity, 1);
    });

    test('phase to life crossfades the layers', () {
      final mix = StageMix.of(
        const StagePose(
          from: WeekMomentAct.phase,
          to: WeekMomentAct.life,
          t: 0.5,
        ),
      );
      expect(mix.phaseLayer, closeTo(0.5, 0.05));
      expect(mix.phaseLayer + mix.lifeLayer, closeTo(1, 1e-9));
      expect(mix.morph, isNull);
    });

    test('life and next show the life layer', () {
      for (final act in [WeekMomentAct.life, WeekMomentAct.next]) {
        final mix = StageMix.of(StagePose.at(act));
        expect(mix.lifeLayer, 1);
        expect(mix.phaseLayer, 0);
      }
    });
  });

  group('YearCells', () {
    const lived = Color(0xFF000000);
    const remaining = Color(0xFFFFFFFF);
    final year = _story(withPhase: false).year;
    final cells = YearCells(
      year: year,
      block: YearBlockLayout(
        const Rect.fromLTWH(0, 0, 300, 120),
        length: year.length,
      ),
      colors: const YearCellColors(
        lived: lived,
        remaining: remaining,
        coming: _coming,
        target: _target,
      ),
      grid: GridCellPlacement(
        rectOf: (cell) => Rect.fromLTWH(cell.toDouble(), 500, 4, 4),
        radius: 1,
      ),
    );
    final passed = year.passedFrom - year.yearStart;

    test('the passed weeks fill from remaining to lived', () {
      expect(cells.at(fill: 0, morph: 0)[passed].color, remaining);
      expect(cells.at(fill: 1, morph: 0)[passed].color, lived);
    });

    test('the coming week keeps its style in the block and on the grid',
        () {
      final now = year.nowCell - year.yearStart;
      for (final morph in const [0.0, 0.5, 1.0]) {
        final cell = cells.at(fill: 1, morph: morph)[now];
        expect(cell.coming, _coming, reason: 'morph $morph');
        expect(cell.color, _coming.fill);
      }
      expect(cells.at(fill: 1, morph: 1)[now].rect, _gridRect(year.nowCell));
      expect(cells.at(fill: 1, morph: 1)[0].coming, isNull);
      expect(cells.blockColorOf(year.nowCell, 0), _coming.fill);
    });

    test('at the end of the morph every cell sits in the grid', () {
      final landed = cells.at(fill: 1, morph: 1);
      expect(landed, hasLength(year.length));
      for (var i = 0; i < landed.length; i++) {
        final cell = year.yearStart + i;
        expect(landed[i].rect, Rect.fromLTWH(cell.toDouble(), 500, 4, 4));
        final isNow = cell == year.nowCell;
        expect(landed[i].color, isNow ? _coming.fill : _targetColor);
        expect(landed[i].radius, 1);
      }
    });
  });
}

Rect _gridRect(int cell) => Rect.fromLTWH(cell.toDouble(), 500, 4, 4);

const _coming = ComingWeekStyle(
  fill: Color(0xFFFAF8F4),
  frame: Color(0xFF111111),
  ring: Color(0xFFD4973A),
);

const _targetColor = Color(0xFF00FF00);
Color _target(int cell) => _targetColor;
