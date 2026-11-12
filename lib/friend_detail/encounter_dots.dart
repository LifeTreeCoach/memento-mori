import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/people/shared_time.dart';

/// One dot per encounter left; above [maxDots] encounters one dot stands
/// for 10 (100, ...) of them, see [encountersPerDot].
class EncounterDots extends StatelessWidget {
  const EncounterDots({
    super.key,
    required this.encounters,
    required this.color,
    this.maxDots = 400,
  });

  final int encounters;
  final Color color;
  final int maxDots;

  static const double diameter = 6;
  static const double gap = 4;
  static const double _pitch = diameter + gap;

  /// Number of dots drawn for [encounters].
  static int dotCount(int encounters, {int maxDots = 400}) {
    if (encounters <= 0) return 0;
    final scale = encountersPerDot(encounters, maxDots: maxDots);
    return (encounters / scale).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final dots = dotCount(encounters, maxDots: maxDots);
    if (dots == 0) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final columns = ((constraints.maxWidth + gap) / _pitch).floor().clamp(1, dots);
      final rows = (dots / columns).ceil();
      return CustomPaint(
        size: Size(constraints.maxWidth, rows * _pitch - gap),
        painter: _DotsPainter(dots: dots, columns: columns, color: color),
      );
    });
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.dots, required this.columns, required this.color});

  final int dots;
  final int columns;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const radius = EncounterDots.diameter / 2;
    for (var i = 0; i < dots; i++) {
      final column = i % columns;
      final row = i ~/ columns;
      canvas.drawCircle(
        Offset(column * EncounterDots._pitch + radius,
            row * EncounterDots._pitch + radius),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) =>
      oldDelegate.dots != dots ||
      oldDelegate.columns != columns ||
      oldDelegate.color != color;
}
