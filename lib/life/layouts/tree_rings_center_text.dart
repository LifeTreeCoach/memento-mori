import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The Tree Rings centre text (years lived over percent grown), laid out
/// once so its bounds can keep decade labels clear of it.
class TreeRingsCenterText {
  TreeRingsCenterText({
    required this.main,
    required this.percent,
    this.scale = 1,
  });

  final TextPainter main;
  final TextPainter percent;

  /// Font scale the painters were laid out with; spacing scales with it.
  final double scale;

  /// Space between the text and the edge of the disc behind it.
  static const double discPadding = 6;

  /// Gap between the two lines at scale 1.
  static const double _lineGap = 6;

  /// Margin around the text in [boundsAt].
  static const double _boundsMargin = 2;

  double get _gap => _lineGap * scale;

  double get _height => main.height + _gap + percent.height;

  double get _width => math.max(main.width, percent.width);

  /// Half the diagonal of the text block: the smallest disc around it.
  double get radius => math.sqrt(_width * _width + _height * _height) / 2;

  Offset _mainOffset(Offset center) =>
      Offset(center.dx - main.width / 2, center.dy - _height / 2);

  Offset _percentOffset(Offset center) => Offset(center.dx - percent.width / 2,
      center.dy - _height / 2 + main.height + _gap);

  /// Union of both text boxes around [center], with a small margin.
  Rect boundsAt(Offset center) => (_mainOffset(center) & main.size)
      .expandToInclude(_percentOffset(center) & percent.size)
      .inflate(_boundsMargin);

  void paint(Canvas canvas, Offset center) {
    main.paint(canvas, _mainOffset(center));
    percent.paint(canvas, _percentOffset(center));
  }

  void dispose() {
    main.dispose();
    percent.dispose();
  }
}
