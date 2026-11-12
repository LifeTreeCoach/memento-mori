import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';

/// A thin whole-life ribbon: the time before the first phase, earlier
/// phases, the current phase, its planned rest and the remaining lifespan
/// (segments from [ribbonSegments]).
class PhaseRibbon extends StatelessWidget {
  const PhaseRibbon({super.key, required this.segments, this.height = 8});

  final List<RibbonSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const ValueKey('compass_phase_ribbon'),
      size: Size.fromHeight(height),
      painter: PhaseRibbonPainter(
        segments: segments,
        phaseColors: PhaseColors.of(context),
        remaining: LifePalette.of(context).remaining,
      ),
    );
  }
}

/// Paints [segments] on a rounded [remaining] track.
class PhaseRibbonPainter extends CustomPainter {
  const PhaseRibbonPainter({
    required this.segments,
    required this.phaseColors,
    required this.remaining,
  });

  final List<RibbonSegment> segments;
  final PhaseColors phaseColors;
  final Color remaining;

  /// Colour of [segment].
  Color colorOf(RibbonSegment segment) => switch (segment.tone) {
        RibbonTone.before => phaseColors.before,
        RibbonTone.earlier => phaseColors.earlierAt(segment.earlierIndex),
        RibbonTone.current => phaseColors.current,
        RibbonTone.planned => phaseColors.planned,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final track = Offset.zero & size;
    canvas.clipRRect(
        RRect.fromRectAndRadius(track, Radius.circular(size.height / 2)));
    canvas.drawRect(track, Paint()..color = remaining);
    for (final segment in segments) {
      final rect = Rect.fromLTRB(segment.from * size.width, 0,
          segment.to * size.width, size.height);
      canvas.drawRect(rect, Paint()..color = colorOf(segment));
    }
  }

  @override
  bool shouldRepaint(PhaseRibbonPainter old) =>
      !listEquals(old.segments, segments) ||
      old.phaseColors != phaseColors ||
      old.remaining != remaining;
}
