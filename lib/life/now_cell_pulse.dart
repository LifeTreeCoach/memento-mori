import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/coming_week_style.dart';
import 'package:memento_mori_life_in_weeks/theme/breath.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// The current cell, glowing in the "now" colour. With [comingWeek] it is
/// drawn in that style (opaque, so the breath never muddies it) and only
/// its halo, in [color], breathes.
///
/// It breathes for a few slow cycles whenever it becomes visible (first
/// shown, tab re-selected, app resumed) and then settles to a static glow
/// with no ticker, so an idle screen doesn't repaint. With motion off it is
/// always static. Only this small widget repaints.
class NowCellPulse extends StatefulWidget {
  const NowCellPulse({
    super.key,
    required this.cell,
    required this.radius,
    required this.color,
    this.comingWeek,
  });

  /// Number of breaths before the glow settles.
  static const int breaths = BreathCycle.defaultCycles;

  /// The cell's rectangle in the parent's coordinates.
  final Rect cell;
  final double radius;
  final Color color;
  final ComingWeekStyle? comingWeek;

  @override
  State<NowCellPulse> createState() => _NowCellPulseState();
}

class _NowCellPulseState extends State<NowCellPulse>
    with SingleTickerProviderStateMixin {
  late final BreathCycle _cycle =
      BreathCycle(vsync: this, cycles: NowCellPulse.breaths);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cycle.update(
      motion: Motion.enabled(context),
      visible: TickerMode.valuesOf(context).enabled,
    );
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = math.min(widget.cell.width, 6.0);
    return Positioned.fromRect(
      rect: widget.cell.inflate(glow),
      child: IgnorePointer(
        child: CustomPaint(
          painter: _NowCellPainter(
            breath: _cycle.breath,
            inset: glow,
            radius: widget.radius,
            color: widget.color,
            comingWeek: widget.comingWeek,
          ),
        ),
      ),
    );
  }
}

class _NowCellPainter extends CustomPainter {
  _NowCellPainter({
    required this.breath,
    required this.inset,
    required this.radius,
    required this.color,
    required this.comingWeek,
  }) : super(repaint: breath);

  final Animation<double> breath;
  final double inset;
  final double radius;
  final Color color;
  final ComingWeekStyle? comingWeek;

  @override
  void paint(Canvas canvas, Size size) {
    final t = breath.value;
    final cell = (Offset.zero & size).deflate(inset);
    final style = comingWeek;
    if (style != null) {
      _paintHalo(canvas, cell, t);
      style.paint(canvas, cell, radius);
      return;
    }
    final glow = Paint()
      ..color = color.withValues(alpha: 0.3 + 0.35 * t)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, inset * (0.4 + 0.3 * t));
    canvas.drawRRect(
      RRect.fromRectAndRadius(cell.inflate(inset * 0.35), Radius.circular(radius)),
      glow,
    );
    final fill = Paint()..color = color.withValues(alpha: 0.75 + 0.25 * t);
    canvas.drawRRect(RRect.fromRectAndRadius(cell, Radius.circular(radius)), fill);
  }

  /// A soft glow around the coming week's ring, brightest at full breath.
  void _paintHalo(Canvas canvas, Rect cell, double t) {
    final spread = ComingWeekStyle.ringWidthOf(cell.width) + inset * 0.2 * t;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.2 + 0.35 * t)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, inset * (0.3 + 0.3 * t));
    canvas.drawRRect(
      RRect.fromRectAndRadius(cell.inflate(spread), Radius.circular(radius + spread)),
      glow,
    );
  }

  @override
  bool shouldRepaint(_NowCellPainter old) =>
      old.breath != breath ||
      old.inset != inset ||
      old.radius != radius ||
      old.color != color ||
      old.comingWeek != comingWeek;
}
