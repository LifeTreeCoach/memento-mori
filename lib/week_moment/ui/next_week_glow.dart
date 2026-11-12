import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/breath.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// The soft halo around the coming week in the final act, in a warm
/// [color] (the coming week's ring gold), "this week ahead is yours". The
/// cell itself is drawn on top in the coming-week style.
///
/// It fades in, then breathes for a few slow cycles and settles (no ticker
/// when idle). With motion off it shows the settled glow at once.
class NextWeekGlow extends StatefulWidget {
  const NextWeekGlow({
    super.key,
    required this.cell,
    required this.radius,
    required this.color,
  });

  /// Halo size relative to the cell width, within [minHalo]..[maxHalo].
  static const double haloShare = 0.8;
  static const double minHalo = 6;
  static const double maxHalo = 22;

  /// How far the halo reaches beyond a cell of [width].
  static double haloOf(double width) =>
      (width * haloShare).clamp(minHalo, maxHalo);

  /// The cell's rectangle in the parent's coordinates.
  final Rect cell;
  final double radius;
  final Color color;

  @override
  State<NextWeekGlow> createState() => _NextWeekGlowState();
}

class _NextWeekGlowState extends State<NextWeekGlow>
    with SingleTickerProviderStateMixin {
  late final BreathCycle _cycle = BreathCycle(vsync: this);

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
    final halo = NextWeekGlow.haloOf(widget.cell.width);
    return Positioned.fromRect(
      rect: widget.cell.inflate(halo),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Motion.of(context, Motion.long),
          curve: Motion.standard,
          builder: (context, appear, _) => Opacity(
            opacity: appear,
            child: CustomPaint(painter: _painter(halo)),
          ),
        ),
      ),
    );
  }

  NextWeekGlowPainter _painter(double halo) => NextWeekGlowPainter(
    breath: _cycle.breath,
    halo: halo,
    radius: widget.radius,
    color: widget.color,
  );
}

/// Paints the halo around the cell [halo] inside its canvas.
@visibleForTesting
class NextWeekGlowPainter extends CustomPainter {
  NextWeekGlowPainter({
    required this.breath,
    required this.halo,
    required this.radius,
    required this.color,
  }) : super(repaint: breath);

  final Animation<double> breath;
  final double halo;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = breath.value;
    final cell = (Offset.zero & size).deflate(halo);
    _paintHalo(canvas, cell, t);
  }

  /// A soft warm glow around the cell, widest and brightest at full breath.
  void _paintHalo(Canvas canvas, Rect cell, double t) {
    final spread = halo * (0.35 + 0.15 * t);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35 + 0.25 * t)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, halo * 0.45);
    canvas.drawRRect(_rounded(cell.inflate(spread), radius + spread), paint);
  }

  static RRect _rounded(Rect rect, double radius) =>
      RRect.fromRectAndRadius(rect, Radius.circular(math.max(0, radius)));

  @override
  bool shouldRepaint(NextWeekGlowPainter old) =>
      old.breath != breath ||
      old.halo != halo ||
      old.radius != radius ||
      old.color != color;
}
