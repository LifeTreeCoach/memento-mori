import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/week_moment/year_block_layout.dart';

const double _eps = 1e-6;
const Rect _area = Rect.fromLTWH(16, 100, 360, 300);

bool _contains(Rect outer, Rect inner) =>
    inner.left >= outer.left - _eps &&
    inner.top >= outer.top - _eps &&
    inner.right <= outer.right + _eps &&
    inner.bottom <= outer.bottom + _eps;

List<Rect> _cells(YearBlockLayout layout) => [
  for (var i = 0; i < layout.length; i++) layout.cellRect(i),
];

void main() {
  group('YearBlockLayout', () {
    test('52 cells form 4 rows of 13', () {
      final layout = YearBlockLayout(_area, length: 52);
      expect(layout.rows, 4);
      final cells = _cells(layout);
      final firstRowTop = cells.first.top;
      expect(cells.where((c) => c.top == firstRowTop).length, 13);
      expect(cells[13].top, greaterThan(cells[12].top));
      expect(cells[13].left, cells[0].left);
    });

    test('a 53rd cell starts a 5th row', () {
      final layout = YearBlockLayout(_area, length: 53);
      expect(layout.rows, 5);
      expect(layout.cellRect(52).left, layout.cellRect(0).left);
      expect(layout.cellRect(52).top, greaterThan(layout.cellRect(51).top));
    });

    test('cells are square, inside the area and do not overlap', () {
      for (final length in [52, 53]) {
        final cells = _cells(YearBlockLayout(_area, length: length));
        for (var i = 0; i < cells.length; i++) {
          expect(cells[i].width, closeTo(cells[i].height, _eps));
          expect(_contains(_area, cells[i]), isTrue);
          for (var j = i + 1; j < cells.length; j++) {
            final overlap = cells[i].intersect(cells[j]);
            expect(overlap.width <= _eps || overlap.height <= _eps, isTrue);
          }
        }
      }
    });

    test('the block is centred in the area', () {
      final layout = YearBlockLayout(_area, length: 52);
      final block = layout.cellRect(0).expandToInclude(layout.cellRect(51));
      expect(block.center.dx, closeTo(_area.center.dx, _eps));
      expect(block.center.dy, closeTo(_area.center.dy, _eps));
      expect(block.width, closeTo(layout.blockSize.width, _eps));
      expect(block.height, closeTo(layout.blockSize.height, _eps));
    });

    test('radius follows the cell size like the grid', () {
      final layout = YearBlockLayout(_area, length: 52);
      expect(layout.radius, closeTo(layout.cellSize * 0.2, _eps));
    });
  });

  group('morph', () {
    const from = Rect.fromLTWH(0, 0, 20, 20);
    const to = Rect.fromLTWH(200, 300, 5, 5);

    test('morphRect is from at 0 and to at 1', () {
      expect(morphRect(from, to, 0), from);
      expect(morphRect(from, to, 1), to);
    });

    test('every cell is at 0 at t=0 and at 1 at t=1', () {
      for (var i = 0; i < 53; i++) {
        expect(morphProgress(i, 0, 53), 0);
        expect(morphProgress(i, 1, 53), closeTo(1, _eps));
      }
    });

    test('cell 0 progresses first', () {
      for (final t in [0.1, 0.3, 0.5, 0.8]) {
        final first = morphProgress(0, t, 52);
        final last = morphProgress(51, t, 52);
        expect(first, greaterThan(last));
      }
      expect(morphProgress(51, 0.2, 52), 0);
      expect(morphProgress(0, 0.2, 52), greaterThan(0));
    });

    test('progress is monotonic in t', () {
      var previous = 0.0;
      for (var i = 0; i <= 50; i++) {
        final p = morphProgress(20, i / 50, 52);
        expect(p, greaterThanOrEqualTo(previous - _eps));
        previous = p;
      }
    });
  });
}
