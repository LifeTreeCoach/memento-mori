import 'dart:math' as math;

/// Content left below the viewport (in logical pixels) above which the
/// scroll thread stays visible at rest.
const double scrollThreadMoreBelowThreshold = 16;

/// Shortest thread length in logical pixels.
const double scrollThreadMinLength = 24;

/// Where the scroll thread sits inside its track.
typedef ScrollThreadGeometry = ({double top, double length});

/// True while more than [scrollThreadMoreBelowThreshold] of content lies
/// below the viewport.
bool hasMoreBelow(double extentAfter) =>
    extentAfter > scrollThreadMoreBelowThreshold;

/// Thread position for a scroll view: [length] is the viewport's share of
/// the content (at least [minLength]), [top] follows the scroll fraction.
/// Both stay inside [trackHeight], also during overscroll.
ScrollThreadGeometry scrollThreadGeometry({
  required double pixels,
  required double maxScrollExtent,
  required double viewportDimension,
  required double trackHeight,
  double minLength = scrollThreadMinLength,
}) {
  final track = math.max(0.0, trackHeight);
  final length = _threadLength(
    maxScrollExtent: maxScrollExtent,
    viewportDimension: viewportDimension,
    track: track,
    minLength: minLength,
  );
  final fraction = maxScrollExtent > 0
      ? (pixels / maxScrollExtent).clamp(0.0, 1.0)
      : 0.0;
  return (top: (track - length) * fraction, length: length);
}

double _threadLength({
  required double maxScrollExtent,
  required double viewportDimension,
  required double track,
  required double minLength,
}) {
  final content = viewportDimension + math.max(0.0, maxScrollExtent);
  final ratio = content > 0 ? viewportDimension / content : 1.0;
  return (track * ratio).clamp(math.min(minLength, track), track);
}
