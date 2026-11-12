import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// WCAG 2 contrast ratio of two opaque colours (1..21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The candidate with the highest contrast against [background].
Color mostReadableOn(Color background, List<Color> candidates) {
  assert(candidates.isNotEmpty);
  return candidates.reduce(
    (best, next) =>
        contrastRatio(next, background) > contrastRatio(best, background)
        ? next
        : best,
  );
}

/// Perceptual distance of two opaque colours (CIE76 ΔE in L*a*b*, D65):
/// about 2 is just noticeable, 20 and more reads as a different colour.
double deltaE(Color a, Color b) {
  final la = _lab(a), lb = _lab(b);
  var sum = 0.0;
  for (var i = 0; i < 3; i++) {
    sum += (la[i] - lb[i]) * (la[i] - lb[i]);
  }
  return math.sqrt(sum);
}

List<double> _lab(Color c) {
  double linear(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = linear(c.r), g = linear(c.g), b = linear(c.b);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}
