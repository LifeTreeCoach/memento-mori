import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// Whole-life bar from birth to the expected end: lived before the phase,
/// the phase so far (gold), its planned rest and the remaining lifespan.
/// Segment changes animate (unless motion is off). An optional [marker]
/// marks one day (e.g. today) with a ringed dot.
class LifespanBar extends StatelessWidget {
  const LifespanBar({
    super.key,
    required this.fractions,
    this.height = 10,
    this.semanticsLabel,
    this.marker,
    this.colors,
  });

  final LifespanBarFractions fractions;
  final double height;
  final String? semanticsLabel;

  /// Position (0..1) of the marked day; null for no marker.
  final double? marker;

  /// Overrides the phase colours (e.g. for a bar without phases).
  final LifespanBarColors? colors;

  @override
  Widget build(BuildContext context) {
    final colors = this.colors ?? LifespanBarColors.of(context);
    final marker = this.marker;
    final markerStyle = marker == null ? null : BarMarker.of(context, marker);
    return Semantics(
      label: semanticsLabel,
      child: TweenAnimationBuilder<LifespanBarFractions>(
        tween: _FractionsTween(end: fractions),
        duration: Motion.of(context, Motion.medium),
        curve: Motion.standard,
        builder: (context, value, _) => CustomPaint(
          size: Size.fromHeight(height),
          painter: LifespanBarPainter(
              fractions: value, colors: colors, marker: markerStyle),
        ),
      ),
    );
  }
}

class _FractionsTween extends Tween<LifespanBarFractions> {
  _FractionsTween({required LifespanBarFractions end})
      : super(begin: end, end: end);

  @override
  LifespanBarFractions lerp(double t) =>
      LifespanBarFractions.lerp(begin!, end!, t);
}

/// Colours of the [LifespanBar] layers.
@immutable
class LifespanBarColors {
  const LifespanBarColors({
    required this.lived,
    required this.phase,
    required this.planned,
    required this.remaining,
  });

  factory LifespanBarColors.of(BuildContext context) {
    final palette = LifePalette.of(context);
    final phases = PhaseColors.of(context);
    return LifespanBarColors(
      lived: phases.before,
      phase: phases.current,
      planned: phases.planned,
      remaining: palette.remaining,
    );
  }

  final Color lived;
  final Color phase;
  final Color planned;
  final Color remaining;

  @override
  bool operator ==(Object other) =>
      other is LifespanBarColors &&
      other.lived == lived &&
      other.phase == phase &&
      other.planned == planned &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(lived, phase, planned, remaining);
}

/// A ringed dot on the [LifespanBar] at [at] (0..1).
@immutable
class BarMarker {
  const BarMarker({required this.at, required this.fill, required this.ring});

  /// The marker in the phase gold (readable on the surface), ringed in the
  /// surface colour so it stands out on the gold band.
  factory BarMarker.of(BuildContext context, double at) => BarMarker(
        at: at,
        fill: PhaseStyle.readableGold(context),
        ring: Theme.of(context).colorScheme.surface,
      );

  final double at;
  final Color fill;
  final Color ring;

  @override
  bool operator ==(Object other) =>
      other is BarMarker &&
      other.at == at &&
      other.fill == fill &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(at, fill, ring);
}

/// Paints [LifespanBarFractions] as a rounded bar (plus an optional
/// [marker], drawn over the bar's edges).
class LifespanBarPainter extends CustomPainter {
  const LifespanBarPainter({
    required this.fractions,
    required this.colors,
    this.marker,
  });

  final LifespanBarFractions fractions;
  final LifespanBarColors colors;
  final BarMarker? marker;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(bar, Radius.circular(size.height / 2)));
    canvas.drawRect(bar, Paint()..color = colors.remaining);
    _band(canvas, size, 0, fractions.phaseStart, colors.lived);
    _band(canvas, size, fractions.phaseStart, fractions.today, colors.phase);
    _band(canvas, size, fractions.today, fractions.plannedEnd, colors.planned);
    canvas.restore();
    if (marker case final marker?) _marker(canvas, size, marker);
  }

  void _marker(Canvas canvas, Size size, BarMarker marker) {
    final radius = size.height * 0.75;
    final x = (marker.at * size.width).clamp(radius, size.width - radius);
    final center = Offset(x.toDouble(), size.height / 2);
    canvas.drawCircle(center, radius + 2, Paint()..color = marker.ring);
    canvas.drawCircle(center, radius, Paint()..color = marker.fill);
  }

  void _band(Canvas canvas, Size size, double from, double to, Color color) {
    if (to <= from) return;
    final rect = Rect.fromLTRB(
        from * size.width, 0, to * size.width, size.height);
    canvas.drawRect(rect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(LifespanBarPainter old) =>
      old.fractions != fractions ||
      old.colors != colors ||
      old.marker != marker;
}
