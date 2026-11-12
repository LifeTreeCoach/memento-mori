import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/week_moment/moment_camera.dart';

const double _eps = 1e-6;

LifeGridGeometry _weeksGrid() =>
    LifeGridGeometry(mode: LifeMode.weeks, totalCells: 80 * 52, maxWidth: 400);

const Size _viewport = Size(393, 700);
const int _now = 52 * 40 + 12;

Rect _phase(LifeGridGeometry grid, int from, int to, Rect year) =>
    MomentFrames.phase(
      grid,
      from,
      to,
      year,
      nowCell: _now,
      viewport: _viewport,
    );

bool _contains(Rect outer, Rect inner) =>
    inner.left >= outer.left - _eps &&
    inner.top >= outer.top - _eps &&
    inner.right <= outer.right + _eps &&
    inner.bottom <= outer.bottom + _eps;

void main() {
  group('CameraFit.fit', () {
    const viewport = Size(400, 800);

    test('contains the frame in the padded viewport and centres it', () {
      const frame = Rect.fromLTWH(100, 2000, 300, 60);
      final fit = CameraFit.fit(frame, viewport, maxScale: 100);
      final screen = fit.toScreen(frame);
      final padded = CameraFit.defaultPadding.deflateRect(
        Offset.zero & viewport,
      );
      expect(_contains(padded, screen), isTrue);
      expect(screen.center.dx, closeTo(padded.center.dx, _eps));
      expect(screen.center.dy, closeTo(padded.center.dy, _eps));
      expect(screen.width, closeTo(padded.width, _eps));
    });

    test('clamps the scale to maxScale', () {
      const frame = Rect.fromLTWH(0, 0, 10, 10);
      final fit = CameraFit.fit(frame, viewport, maxScale: 3);
      expect(fit.scale, 3);
      final screen = fit.toScreen(frame);
      expect(screen.center.dx, closeTo(200, _eps));
      expect(screen.center.dy, closeTo(400, _eps));
    });

    test('toScreenPoint and matrix agree', () {
      final fit = CameraFit.fit(const Rect.fromLTWH(20, 40, 100, 50), viewport);
      const point = Offset(33, 77);
      final viaMatrix = MatrixUtils.transformPoint(fit.matrix, point);
      final direct = fit.toScreenPoint(point);
      expect(viaMatrix.dx, closeTo(direct.dx, _eps));
      expect(viaMatrix.dy, closeTo(direct.dy, _eps));
    });
  });

  group('lerpFrame', () {
    const a = Rect.fromLTWH(0, 0, 10, 20);
    const b = Rect.fromLTWH(100, 200, 1000, 400);

    test('is exact at the endpoints', () {
      expect(lerpFrame(a, b, 0), a);
      expect(lerpFrame(a, b, 1), b);
    });

    test('moves the centre linearly and the width geometrically', () {
      final mid = lerpFrame(a, b, 0.5);
      expect(mid.center, Offset.lerp(a.center, b.center, 0.5));
      expect(mid.width, closeTo(100, _eps));
    });

    test('width grows monotonically', () {
      var previous = a.width;
      for (var i = 1; i <= 20; i++) {
        final width = lerpFrame(a, b, i / 20).width;
        expect(width, greaterThan(previous));
        previous = width;
      }
    });
  });

  group('MomentFrames', () {
    final grid = _weeksGrid();

    test('cellsBounds within one row spans exactly those cells', () {
      final bounds = MomentFrames.cellsBounds(grid, 3, 6);
      expect(bounds.left, grid.cellRect(3).left);
      expect(bounds.right, grid.cellRect(5).right);
      expect(bounds.height, closeTo(grid.cellSize, _eps));
    });

    test('a year crossing a row spans the full width of both rows', () {
      final year = MomentFrames.year(grid, 52 * 40 + 7, 52);
      expect(year.left, grid.cellRect(0).left);
      expect(year.right, grid.cellRect(51).right);
      expect(year.top, grid.cellRect(52 * 40).top);
      expect(year.bottom, grid.cellRect(52 * 41).bottom);
    });

    test('phase frame has the aspect of the viewport target', () {
      final year = MomentFrames.year(grid, 52 * 40 + 7, 52);
      final phase = _phase(grid, 52 * 40 + 20, 52 * 40 + 30, year);
      final target = CameraFit.targetOf(_viewport);
      expect(
        phase.width / phase.height,
        closeTo(target.width / target.height, 1e-9),
      );
      expect(phase.width, lessThan(grid.size.width));
    });

    test('phase frame is centred on the now cell and covers the year', () {
      final year = MomentFrames.year(grid, 52 * 40 + 7, 52);
      final phase = _phase(grid, 52 * 40 + 20, 52 * 40 + 30, year);
      final now = grid.cellRect(_now);
      expect(phase.center.dx, closeTo(now.center.dx, _eps));
      expect(phase.top, lessThanOrEqualTo(year.top - grid.pitch + _eps));
      expect(
        phase.bottom,
        greaterThanOrEqualTo(year.bottom + grid.pitch - _eps),
      );
    });

    test('phase frame never needs more than maxScale', () {
      final year = MomentFrames.year(grid, 52 * 40 + 7, 52);
      final phase = _phase(grid, 52 * 40 + 20, 52 * 40 + 30, year);
      final fit = CameraFit.fit(phase, _viewport);
      expect(fit.scale, closeTo(CameraFit.defaultMaxScale, 1e-9));
      final screen = fit.toScreen(phase);
      final target = CameraFit.targetOf(_viewport);
      expect(screen.width, closeTo(target.width, 1e-6));
      expect(screen.height, closeTo(target.height, 1e-6));
    });

    test('phase frame keeps a long phase and stays in the world', () {
      final year = MomentFrames.year(grid, 52 * 40, 52);
      final phase = _phase(grid, 52 * 5, 52 * 41, year);
      final phaseTop = grid.cellRect(52 * 5).top;
      expect(phase.top, lessThanOrEqualTo(phaseTop + _eps));
      expect(phase.bottom, greaterThanOrEqualTo(year.bottom - _eps));
      expect(CameraFit.fit(phase, _viewport).scale, lessThan(3));
      expect(_contains(MomentFrames.life(grid), phase), isTrue);
    });

    test('phase frame is clamped at the start of life and the left edge', () {
      final year = MomentFrames.year(grid, 0, 52);
      final phase = MomentFrames.phase(
        grid,
        0,
        10,
        year,
        nowCell: 2,
        viewport: _viewport,
      );
      expect(phase.top, 0);
      expect(phase.left, 0);
      expect(
        phase.height,
        greaterThanOrEqualTo(5 * grid.pitch - grid.gap - _eps),
      );
    });

    test('phase frame falls back to full width in a wide viewport', () {
      final year = MomentFrames.year(grid, 52 * 40 + 7, 52);
      final phase = MomentFrames.phase(
        grid,
        52 * 30,
        52 * 41,
        year,
        nowCell: _now,
        viewport: const Size(1600, 300),
      );
      expect(phase.left, 0);
      expect(phase.width, closeTo(grid.size.width, _eps));
    });

    test('life frame is the whole world', () {
      expect(MomentFrames.life(grid), Offset.zero & grid.size);
    });

    test('next frame is centred on the cell at maxScale', () {
      const cell = 52 * 40 + 25;
      final next = MomentFrames.next(grid, cell, viewport: _viewport);
      final rect = grid.cellRect(cell);
      expect(next.center.dx, closeTo(rect.center.dx, _eps));
      expect(next.center.dy, closeTo(rect.center.dy, _eps));
      final fit = CameraFit.fit(next, _viewport);
      expect(fit.scale, closeTo(CameraFit.defaultMaxScale, 1e-9));
      expect(fit.toScreen(rect).width, closeTo(rect.width * 3, 1e-6));
    });

    test('next frame is clamped at the start and the end of life', () {
      final world = MomentFrames.life(grid);
      final start = MomentFrames.next(grid, 1, viewport: _viewport);
      expect(start.top, 0);
      expect(start.left, 0);
      expect(_contains(start, grid.cellRect(1)), isTrue);
      final last = grid.totalCells - 1;
      final end = MomentFrames.next(grid, last, viewport: _viewport);
      expect(end.bottom, closeTo(world.bottom, _eps));
      expect(end.right, closeTo(world.right, _eps));
      expect(_contains(end, grid.cellRect(last)), isTrue);
    });
  });
}
