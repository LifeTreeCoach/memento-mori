import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Where the card sits relative to the hole.
enum CardPlacement { below, above, bottom, centred }

/// The computed spotlight layout.
class TourLayout {
  const TourLayout({
    required this.hole,
    required this.cardOffset,
    required this.placement,
  });

  /// The spotlight hole (rounded by [TourGeometry.holeRadius]); null for a
  /// centred step.
  final Rect? hole;
  final Offset cardOffset;
  final CardPlacement placement;
}

/// Pure layout of a coach mark: the hole around the target and a card
/// that never covers it while it fits, always inside the safe area.
class TourGeometry {
  TourGeometry._();

  static const double holeInflation = 8;
  static const double holeRadius = 16;
  static const double margin = 16;
  static const double gap = 12;
  static const double maxCardWidth = 360;

  /// min(screen width - 32, 360).
  static double cardWidthFor(double screenWidth) =>
      math.max(0, math.min(screenWidth - 2 * margin, maxCardWidth));

  /// The tallest card that fits the safe area with margins.
  static double maxCardHeightFor(Size screen, EdgeInsets padding) =>
      math.max(0, screen.height - padding.vertical - 2 * margin);

  /// The hole around [target]: inflated by [holeInflation].
  static Rect holeFor(Rect target) => target.inflate(holeInflation);

  static TourLayout layout({
    required Size screen,
    required EdgeInsets padding,
    required Rect? target,
    required Size card,
  }) {
    final top = padding.top + margin;
    final bottom = screen.height - padding.bottom - margin;
    if (target == null) {
      return TourLayout(
        hole: null,
        cardOffset: Offset((screen.width - card.width) / 2,
            _clamp(top + (bottom - top - card.height) / 2, top, bottom, card)),
        placement: CardPlacement.centred,
      );
    }
    final hole = holeFor(target);
    final x = _clampX(hole.center.dx - card.width / 2, screen, card);
    final below = hole.bottom + gap;
    if (below + card.height <= bottom) {
      return TourLayout(
          hole: hole, cardOffset: Offset(x, below), placement: CardPlacement.below);
    }
    final above = hole.top - gap - card.height;
    if (above >= top) {
      return TourLayout(
          hole: hole, cardOffset: Offset(x, above), placement: CardPlacement.above);
    }
    return TourLayout(
      hole: hole,
      cardOffset: Offset(x, _clamp(bottom - card.height, top, bottom, card)),
      placement: CardPlacement.bottom,
    );
  }

  static double _clampX(double x, Size screen, Size card) {
    final maxX = math.max(margin, screen.width - margin - card.width);
    return x.clamp(margin, maxX).toDouble();
  }

  /// Keeps the card's top inside [top, bottom - height] (top wins when the
  /// card is taller than the safe area).
  static double _clamp(double y, double top, double bottom, Size card) =>
      math.max(top, math.min(y, bottom - card.height));
}
