import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_geometry.dart';

/// Sizes the tour card ([TourGeometry.cardWidthFor], at most the safe
/// height) and places it with [TourGeometry.layout] once it is measured.
class TourCardLayout extends SingleChildLayoutDelegate {
  const TourCardLayout({required this.target, required this.padding});

  /// The anchor's bounds; null = centred.
  final Rect? target;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final screen = constraints.biggest;
    return BoxConstraints(
      minWidth: TourGeometry.cardWidthFor(screen.width),
      maxWidth: TourGeometry.cardWidthFor(screen.width),
      maxHeight: TourGeometry.maxCardHeightFor(screen, padding),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return TourGeometry.layout(
      screen: size,
      padding: padding,
      target: target,
      card: childSize,
    ).cardOffset;
  }

  @override
  bool shouldRelayout(TourCardLayout oldDelegate) =>
      oldDelegate.target != target || oldDelegate.padding != padding;
}
