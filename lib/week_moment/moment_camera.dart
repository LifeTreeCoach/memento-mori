import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:memento_mori_life_in_weeks/life/life_grid_geometry.dart';

/// Maps world coordinates (the painted life grid) to screen coordinates:
/// `screen = world * scale + offset`.
@immutable
class CameraFit {
  const CameraFit({required this.scale, required this.offset});

  final double scale;
  final Offset offset;

  static const EdgeInsets defaultPadding = EdgeInsets.all(24);

  /// The closest the camera zooms in (world units to screen points).
  static const double defaultMaxScale = 3;

  /// The area of [viewport] that [fit] fills with a frame.
  static Size targetOf(Size viewport, {EdgeInsets padding = defaultPadding}) =>
      padding.deflateRect(Offset.zero & viewport).size;

  /// Contains [frame] in the padded [viewport], centred, with the scale
  /// clamped to [maxScale].
  static CameraFit fit(
    Rect frame,
    Size viewport, {
    EdgeInsets padding = defaultPadding,
    double maxScale = defaultMaxScale,
  }) {
    final target = padding.deflateRect(Offset.zero & viewport);
    final scale = _containScale(frame.size, target.size, maxScale);
    return CameraFit(
      scale: scale,
      offset: target.center - frame.center * scale,
    );
  }

  static double _containScale(Size frame, Size target, double maxScale) {
    const minExtent = 1e-6;
    final byWidth =
        math.max(0.0, target.width) / math.max(frame.width, minExtent);
    final byHeight =
        math.max(0.0, target.height) / math.max(frame.height, minExtent);
    return math.min(math.min(byWidth, byHeight), maxScale);
  }

  Offset toScreenPoint(Offset world) => world * scale + offset;

  Rect toScreen(Rect world) => Rect.fromPoints(
    toScreenPoint(world.topLeft),
    toScreenPoint(world.bottomRight),
  );

  /// Translate + scale, for a `Transform` around the world-sized child.
  Matrix4 get matrix => Matrix4(
    scale,
    0,
    0,
    0, //
    0,
    scale,
    0,
    0, //
    0,
    0,
    1,
    0, //
    offset.dx,
    offset.dy,
    0,
    1,
  );
}

/// Interpolates camera frames: the centre moves linearly, the size changes
/// geometrically (so zooming feels even). Exact at both endpoints.
Rect lerpFrame(Rect a, Rect b, double t) {
  if (t <= 0) return a;
  if (t >= 1) return b;
  final center = Offset.lerp(a.center, b.center, t)!;
  return Rect.fromCenter(
    center: center,
    width: _lerpGeometric(a.width, b.width, t),
    height: _lerpGeometric(a.height, b.height, t),
  );
}

double _lerpGeometric(double a, double b, double t) {
  if (a <= 0 || b <= 0) return a + (b - a) * t;
  return a * math.pow(b / a, t);
}

/// Camera frames of the weekly moment, in the world of a [LifeGridGeometry].
abstract final class MomentFrames {
  /// Bounding box of the cells `from` (inclusive) to [toExclusive].
  static Rect cellsBounds(
    LifeGridGeometry geometry,
    int from,
    int toExclusive,
  ) {
    final last = math.max(from, toExclusive - 1);
    final first = geometry.cellRect(from);
    final end = geometry.cellRect(last);
    if (from ~/ geometry.columns == last ~/ geometry.columns) {
      return first.expandToInclude(end);
    }
    final left = geometry.cellRect(0).left;
    final right = geometry.cellRect(geometry.columns - 1).right;
    return Rect.fromLTRB(left, first.top, right, end.bottom);
  }

  /// The year of life: [length] (52 or 53) cells from [yearStart].
  static Rect year(LifeGridGeometry geometry, int yearStart, int length) =>
      cellsBounds(geometry, yearStart, yearStart + length);

  /// A zoomed-in window on the phase cells `from` to [toExclusive]: their
  /// rows and those of [yearFrame], plus [paddingRows] above and below, at
  /// least [minRows] rows, in the aspect of [viewport] and centred
  /// horizontally on [nowCell] (see [window]).
  static Rect phase(
    LifeGridGeometry geometry,
    int from,
    int toExclusive,
    Rect yearFrame, {
    required int nowCell,
    required Size viewport,
    int minRows = 5,
    int paddingRows = 1,
  }) {
    final cells = cellsBounds(geometry, from, toExclusive);
    final band = cells
        .expandToInclude(yearFrame)
        .inflate(paddingRows * geometry.pitch);
    final minHeight = _rowsHeight(geometry, minRows);
    final rows = band.height >= minHeight
        ? band
        : Rect.fromCenter(
            center: band.center,
            width: band.width,
            height: minHeight,
          );
    final focusX = geometry.cellRect(nowCell).center.dx;
    return window(geometry, rows, focusX, viewport);
  }

  /// The whole life grid.
  static Rect life(LifeGridGeometry geometry) => Offset.zero & geometry.size;

  /// A zoomed-in window on [cell]: [rowsAround] rows above and below its
  /// row, in the aspect of [viewport] and centred on it (see [window]).
  static Rect next(
    LifeGridGeometry geometry,
    int cell, {
    required Size viewport,
    int rowsAround = 3,
  }) {
    final rect = geometry.cellRect(cell);
    final rows = Rect.fromCenter(
      center: rect.center,
      width: rect.width,
      height: _rowsHeight(geometry, 2 * rowsAround + 1),
    );
    return window(geometry, rows, rect.center.dx, viewport);
  }

  /// A frame covering the rows of [rows], centred on [focusX], with the
  /// aspect of the [viewport]'s fit target so it fills the screen (and
  /// crops the grid horizontally). Grown around its centre until the
  /// camera needs no more than [maxScale]; never wider than the world (then
  /// full width, contained by width); kept inside the world.
  static Rect window(
    LifeGridGeometry geometry,
    Rect rows,
    double focusX,
    Size viewport, {
    double maxScale = CameraFit.defaultMaxScale,
  }) {
    final world = life(geometry);
    final target = CameraFit.targetOf(viewport);
    if (target.width <= 0 || target.height <= 0) {
      return _clampToWorld(_fullWidth(rows, world), world);
    }
    final height = math.max(rows.height, target.height / maxScale);
    final width = math.min(height * target.width / target.height, world.width);
    final frame = Rect.fromCenter(
      center: Offset(focusX, rows.center.dy),
      width: width,
      height: height,
    );
    return _clampToWorld(frame, world);
  }

  static Rect _fullWidth(Rect rows, Rect world) =>
      Rect.fromLTRB(world.left, rows.top, world.right, rows.bottom);

  static double _rowsHeight(LifeGridGeometry geometry, int rows) =>
      rows * geometry.pitch - geometry.gap;

  /// Shifts [rect] into [world] (shrinking it only if it is larger).
  static Rect _clampToWorld(Rect rect, Rect world) {
    final width = math.min(rect.width, world.width);
    final height = math.min(rect.height, world.height);
    final left = rect.left.clamp(world.left, world.right - width);
    final top = rect.top.clamp(world.top, world.bottom - height);
    return Rect.fromLTWH(left, top, width, height);
  }
}
