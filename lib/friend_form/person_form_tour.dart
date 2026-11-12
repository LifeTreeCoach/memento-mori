import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// The one-time tip on the add-person form (`tour_person_form_*` strings):
/// points at the lifespan estimate once the first person has a name and a
/// birthday with year. "Estimate now" opens the estimate, "Later" does
/// nothing.
abstract final class PersonFormTour {
  /// Id in the [TourProgressStore].
  static const String id = 'person_form_estimate';

  static const String estimateAnchor = 'person_form_tour_estimate';

  static const List<TourStep> steps = [
    TourStep(
      id: 'estimate',
      anchorId: estimateAnchor,
      titleKey: 'tour_person_form_estimate_title',
      bodyKey: 'tour_person_form_estimate_body',
      primaryLabelKey: 'tour_person_form_estimate_now',
      secondaryLabelKey: 'tour_person_form_later',
    ),
  ];

  /// Whether the form is ready for the tip: adding (not editing) the very
  /// first person, with a name, a birthday with year and no estimate yet.
  /// Seen state and route are checked by the [TourTrigger].
  static bool fits({
    required bool isEditing,
    required bool firstPerson,
    required String name,
    required DateTime? birthDate,
    required bool yearUnknown,
    required bool hasEstimate,
  }) {
    return !isEditing &&
        firstPerson &&
        name.trim().isNotEmpty &&
        birthDate != null &&
        !yearUnknown &&
        !hasEstimate;
  }
}
