import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Colour and size effects of the spiral layout's dots.
abstract final class VisualizationEffects {
  static const int _decadeYears = 10;
  static const double _pulseAmplitude = 0.3;

  /// Gold for decades.
  static final Color _decadeColor =
      const Color(0xFFFFD700).withValues(alpha: 0.8);

  /// Brightness factor per quarter of the year: winter, spring, summer,
  /// autumn.
  static const List<double> _seasonFactors = [0.8, 1.2, 1.1, 0.9];
  static const int _seasons = 4;

  /// Gold for every item in a decade year (10, 20, ...), else null.
  /// [itemsPerYear] is 52 in the weeks view, 12 for months, 1 for years.
  static Color? getMilestoneColor(int index, int itemsPerYear) {
    if (itemsPerYear <= 0) return null;
    final year = index ~/ itemsPerYear;
    return year > 0 && year % _decadeYears == 0 ? _decadeColor : null;
  }

  /// [baseColor] brightened or darkened for the season of item [index]:
  /// spring brighter, summer warmer, autumn deeper, winter cooler.
  /// Views with fewer than four items per year have no seasons.
  static Color getSeasonalColor(Color baseColor, int index, int itemsPerYear) {
    if (itemsPerYear < _seasons) return baseColor;
    final factor = _seasonFactor(index % itemsPerYear, itemsPerYear);
    // Channels are 0..1 doubles.
    double scaled(double channel) => (channel * factor).clamp(0.0, 1.0);
    return Color.from(
      alpha: baseColor.a,
      red: scaled(baseColor.r),
      green: scaled(baseColor.g),
      blue: scaled(baseColor.b),
      colorSpace: baseColor.colorSpace,
    );
  }

  static double _seasonFactor(int itemInYear, int itemsPerYear) {
    final season = math.min(itemInYear * _seasons ~/ itemsPerYear, _seasons - 1);
    return _seasonFactors[season];
  }

  /// Size factor pulsing around 1 for the current item, else 1.
  static double getPulseAnimation(
      double animationValue, int currentIndex, int targetIndex) {
    if (currentIndex != targetIndex) return 1.0;
    return 1.0 + (math.sin(animationValue * 2 * math.pi) * _pulseAmplitude);
  }
}
