import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_painter.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/phase_cells.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

const _lived = Color(0xFF222222);
const _remaining = Color(0xFFEEEEEE);

LifeGridGeometry _geometry(LifeMode mode) => LifeGridGeometry(
      mode: mode,
      totalCells: mode == LifeMode.weeks ? 52 * 80 : (mode == LifeMode.months ? 960 : 80),
      maxWidth: 345,
      gutterWidth: 22,
    );

LifeGridStyle _style({PhaseColors? phases, bool seasons = false}) =>
    LifeGridStyle(
      lived: _lived,
      remaining: _remaining,
      milestone: const Color(0xFF999999),
      label: const TextStyle(fontSize: 9),
      showSeasons: seasons,
      phaseColors: phases,
    );

/// Months mode, 440 months lived: earlier 0..72, 72..228, current
/// 228..441, planned 441..470.
const List<PhaseCellRun> _runs = [
  PhaseCellRun(
      from: 0, to: 72, kind: PhaseSlotKind.earlier, earlierIndex: 0, phaseId: 'a'),
  PhaseCellRun(
      from: 72, to: 228, kind: PhaseSlotKind.earlier, earlierIndex: 1, phaseId: 'b'),
  PhaseCellRun(from: 228, to: 441, kind: PhaseSlotKind.current, phaseId: 'c'),
  PhaseCellRun(from: 441, to: 470, kind: PhaseSlotKind.planned, phaseId: 'c'),
];

LifeGridPainter _painter({
  List<PhaseCellRun> runs = const [],
  PhaseColors? phases,
  bool seasons = false,
  LifeMode mode = LifeMode.months,
}) =>
    LifeGridPainter(
      geometry: _geometry(mode),
      livedCells: 440,
      style: _style(phases: phases, seasons: seasons),
      phaseRuns: runs,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final phases = PhaseColors.stoicLight;

  group('cellColorSlot without phases', () {
    test('lived before the current cell, remaining from it', () {
      final painter = _painter();
      expect(painter.cellColorSlot(0), const CellColorSlot(CellFill.lived));
      expect(painter.cellColorSlot(439), const CellColorSlot(CellFill.lived));
      expect(painter.cellColorSlot(441), const CellColorSlot(CellFill.remaining));
      expect(painter.colorOfSlot(painter.cellColorSlot(0)), _lived);
    });

    test('runs without phase colours are ignored', () {
      final painter = _painter(runs: _runs);
      expect(painter.cellColorSlot(100), const CellColorSlot(CellFill.lived));
      expect(painter.cellColorSlot(450), const CellColorSlot(CellFill.remaining));
    });

    test('seasons split lived cells into quarters', () {
      final painter = _painter(seasons: true);
      expect(painter.cellColorSlot(0), const CellColorSlot(CellFill.lived, 0));
      expect(painter.cellColorSlot(4), const CellColorSlot(CellFill.lived, 1));
      expect(painter.cellColorSlot(11), const CellColorSlot(CellFill.lived, 3));
    });
  });

  group('cellColorSlot with phases', () {
    final painter = _painter(runs: _runs, phases: phases);

    test('earlier phases cycle their tones by index', () {
      expect(painter.cellColorSlot(10),
          const CellColorSlot(CellFill.phaseEarlier, 0));
      expect(painter.cellColorSlot(100),
          const CellColorSlot(CellFill.phaseEarlier, 1));
      expect(painter.colorOfSlot(painter.cellColorSlot(10)), phases.earlierAt(0));
      expect(painter.colorOfSlot(painter.cellColorSlot(100)), phases.earlierAt(1));
    });

    test('current up to and including the current cell, then planned', () {
      expect(painter.cellColorSlot(300), const CellColorSlot(CellFill.phaseCurrent));
      expect(painter.cellColorSlot(440), const CellColorSlot(CellFill.phaseCurrent));
      expect(painter.cellColorSlot(441), const CellColorSlot(CellFill.phasePlanned));
      expect(painter.colorOfSlot(painter.cellColorSlot(300)), phases.current);
    });

    test('planned cells: the pale planned tint, distinct from remaining', () {
      final planned = painter.cellColorSlot(450);
      expect(painter.colorOfSlot(planned), phases.plannedTint);
      expect(painter.colorOfSlot(planned), isNot(_remaining));
      expect(painter.colorOfSlot(planned), isNot(phases.current));
    });

    test('cells after the planned end stay remaining', () {
      expect(painter.cellColorSlot(470), const CellColorSlot(CellFill.remaining));
      expect(painter.colorOfSlot(painter.cellColorSlot(900)), _remaining);
    });

    test('seasons stay on cells outside phases only', () {
      final seasonal = _painter(
        runs: const [
          PhaseCellRun(
              from: 120, to: 441, kind: PhaseSlotKind.current, phaseId: 'c'),
        ],
        phases: phases,
        seasons: true,
      );
      expect(seasonal.cellColorSlot(4), const CellColorSlot(CellFill.lived, 1));
      expect(seasonal.cellColorSlot(124),
          const CellColorSlot(CellFill.phaseCurrent));
    });
  });

  group('repaint', () {
    test('phase colours are part of the style', () {
      expect(_style(phases: phases), _style(phases: phases));
      expect(_style(phases: phases) == _style(), isFalse);
      expect(_style(phases: phases).hashCode, _style(phases: phases).hashCode);
    });

    test('changed runs repaint, equal runs do not', () {
      final a = _painter(runs: _runs, phases: phases);
      expect(a.shouldRepaint(_painter(runs: List.of(_runs), phases: phases)),
          isFalse);
      expect(a.shouldRepaint(_painter(runs: _runs.sublist(1), phases: phases)),
          isTrue);
    });
  });

  group('painting', () {
    Future<ui.Image> render(LifeGridPainter painter) async {
      final recorder = ui.PictureRecorder();
      final size = painter.geometry.size;
      painter.paint(Canvas(recorder), size);
      return recorder
          .endRecording()
          .toImage(size.width.ceil(), size.height.ceil());
    }

    Future<Color> pixelAt(ui.Image image, Offset offset) async {
      final data = await image.toByteData();
      final index = (offset.dy.floor() * image.width + offset.dx.floor()) * 4;
      final bytes = data!.buffer.asUint8List();
      return Color.fromARGB(
          bytes[index + 3], bytes[index], bytes[index + 1], bytes[index + 2]);
    }

    test('cells are filled with the colour of their slot', () async {
      final painter = _painter(runs: _runs, phases: phases);
      final image = await render(painter);
      for (final cell in [10, 100, 300, 450, 900]) {
        final center = painter.geometry.cellRect(cell).center;
        expect(await pixelAt(image, center),
            isSameColorAs(painter.colorOfSlot(painter.cellColorSlot(cell)),
                threshold: 1 / 255),
            reason: 'cell $cell');
      }
      image.dispose();
    });

    test('planned cells are tinted to the edge, no ring', () async {
      final painter = _painter(
          runs: _runs, phases: phases, mode: LifeMode.months);
      final image = await render(painter);
      final cell = painter.geometry.cellRect(450);
      for (final point in [
        cell.center,
        Offset(cell.left + 1.5, cell.center.dy),
        Offset(cell.right - 1.5, cell.center.dy),
      ]) {
        expect(await pixelAt(image, point),
            isSameColorAs(phases.plannedTint, threshold: 1 / 255),
            reason: '$point');
      }
      image.dispose();
    });

    test('without runs the picture is unchanged', () async {
      final plain = await render(_painter());
      final withColours = await render(_painter(phases: phases));
      final a = await plain.toByteData();
      final b = await withColours.toByteData();
      expect(a!.buffer.asUint8List(), b!.buffer.asUint8List());
      plain.dispose();
      withColours.dispose();
    });
  });
}
