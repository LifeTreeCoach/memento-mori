import 'package:flutter/foundation.dart';

/// One coach mark of a product tour.
///
/// [anchorId] names the [TourAnchor] to spotlight; null shows a centred
/// card without a hole. Texts are localization keys.
@immutable
class TourStep {
  const TourStep({
    required this.id,
    this.anchorId,
    required this.titleKey,
    required this.bodyKey,
    this.primaryLabelKey,
    this.secondaryLabelKey,
  });

  final String id;
  final String? anchorId;
  final String titleKey;
  final String bodyKey;

  /// Replaces "Next"/"Done" when set.
  final String? primaryLabelKey;

  /// Replaces "Skip" when set.
  final String? secondaryLabelKey;

  bool get isCentred => anchorId == null;
}
