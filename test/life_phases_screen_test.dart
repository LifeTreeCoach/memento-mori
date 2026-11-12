import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/home_screen.dart';
import 'package:memento_mori_life_in_weeks/life/alternative_layout_view.dart';
import 'package:memento_mori_life_in_weeks/life/coming_week_style.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/life/now_cell_pulse.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/life/phase_legend.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

import 'support/compass_test_app.dart';

Finder _gridPaint() => find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is LifeGridPainter);

LifeGridPainter _grid(WidgetTester tester) =>
    tester.widget<CustomPaint>(_gridPaint()).painter! as LifeGridPainter;

/// Months mode (birth 1990-11-17, today 2026-11-02: 431 months lived),
/// with [visual] settings.
Future<void> _init({
  VisualizationSettings visual = const VisualizationSettings(enableAnimations: false),
}) =>
    initCompassTest(extra: {
      'display_mode': 'months',
      'visualization_settings': jsonEncode(visual.toMap()),
    });

/// School from age 6, "Building up" from age 32 until mid 2028.
Future<void> _addPhases() async {
  await CompassService.startPhase(
      preset: PhasePreset.school, start: DateTime(1996, 11, 17), today: compassToday);
  await CompassService.startPhase(
    preset: PhasePreset.buildUp,
    start: DateTime(2022, 11, 17),
    plannedEnd: DateTime(2028, 6, 1),
    today: compassToday,
  );
}

/// The coming-week style of the breathing current cell.
ComingWeekStyle? _comingWeek(WidgetTester tester) =>
    tester.widget<NowCellPulse>(find.byType(NowCellPulse)).comingWeek;

/// The coming-week style of the theme around the grid.
ComingWeekStyle _themeComingWeek(WidgetTester tester) =>
    ComingWeekStyle.of(tester.element(find.byType(NowCellPulse)));

Future<void> _tapCell(WidgetTester tester, int index) async {
  final origin = tester.getTopLeft(_gridPaint());
  await tester.tapAt(origin + _grid(tester).geometry.cellRect(index).center);
  await tester.pump(const Duration(milliseconds: 400)); // double-tap timeout
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no phases: no legend, plain grid', (tester) async {
    await _init();
    await pumpCompassApp(tester, HomeScreen(now: compassToday));
    expect(find.byType(PhaseLegend), findsNothing);
    expect(_grid(tester).phaseRuns, isEmpty);
    expect(_grid(tester).style.phaseColors, isNull);
    // Without phases the coming week keeps the same style.
    expect(_comingWeek(tester), _themeComingWeek(tester));
  });

  testWidgets('a phase colours the grid and shows the legend', (tester) async {
    await _init();
    await _addPhases();
    await pumpCompassApp(tester, HomeScreen(now: compassToday));

    expect(find.byType(PhaseLegend), findsOneWidget);
    expect(find.text('School 6–32'), findsOneWidget);
    expect(find.text('Building up 32–now'), findsOneWidget);
    expect(find.text('planned'), findsOneWidget);
    final grid = _grid(tester);
    expect(grid.phaseRuns.map((r) => r.kind), [
      PhaseSlotKind.earlier,
      PhaseSlotKind.current,
      PhaseSlotKind.planned,
    ]);
    expect(grid.style.phaseColors, isNotNull);
  });

  testWidgets('the coming week is light, framed and ringed in gold; '
      'planned weeks are tinted', (tester) async {
    await _init();
    await _addPhases();
    await pumpCompassApp(tester, HomeScreen(now: compassToday));

    final context = tester.element(find.byType(NowCellPulse));
    final scheme = Theme.of(context).colorScheme;
    final style = _comingWeek(tester)!;
    expect(style.fill, scheme.surface);
    expect(style.frame, scheme.onSurface);
    expect(style.ring, PhaseColors.of(context).comingRingOn(scheme.surface));
    final grid = _grid(tester);
    final planned = grid.cellColorSlot(grid.livedCells + 1);
    expect(grid.colorOfSlot(planned), PhaseColors.of(context).plannedTint);
  });

  testWidgets('switched off in Settings: no legend, no phase colours',
      (tester) async {
    await _init();
    await _addPhases();
    await pumpCompassApp(tester, HomeScreen(now: compassToday));
    expect(find.byType(PhaseLegend), findsOneWidget);

    SettingsService.setVisualizationSettings(const VisualizationSettings(
        enableAnimations: false, showPhases: false));
    await pumpCompassApp(tester, HomeScreen(now: compassToday));
    expect(find.byType(PhaseLegend), findsNothing);
    expect(_grid(tester).phaseRuns, isEmpty);
    expect(_comingWeek(tester), _themeComingWeek(tester));
  });

  testWidgets('the cell detail names the phase of the cell', (tester) async {
    await _init();
    await _addPhases();
    await pumpCompassApp(tester, HomeScreen(now: compassToday));

    await _tapCell(tester, 100); // age 8
    expect(find.text('In your phase: School'), findsOneWidget);
    Navigator.of(tester.element(find.text('In your phase: School'))).pop();
    await tester.pumpAndSettle();

    await _tapCell(tester, 440); // planned rest of "Building up"
    expect(find.text('Planned in your phase: Building up'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const ValueKey('cell_phase')))).pop();
    await tester.pumpAndSettle();

    await _tapCell(tester, 20); // before the first phase
    expect(find.byKey(const ValueKey('cell_phase')), findsNothing);
  });

  testWidgets('alternative layouts get the phases as fractions',
      (tester) async {
    await _init(
        visual: const VisualizationSettings(
            enableAnimations: false, layoutType: LayoutType.spiral));
    await _addPhases();
    await pumpCompassApp(tester, HomeScreen(now: compassToday));
    final view =
        tester.widget<AlternativeLayoutView>(find.byType(AlternativeLayoutView));
    expect(view.phaseFractions, hasLength(3));
    expect(view.phaseFractions.first.from, closeTo(72 / 960, 1e-9));
    expect(find.byType(PhaseLegend), findsOneWidget);
  });
}
