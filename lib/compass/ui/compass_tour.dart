import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// The Compass tour: what a phase is, then the phase header, the question
/// of the week, "Now" and "Someday & Lived" (`tour_compass_*` strings).
abstract final class CompassTour {
  /// Id in the [TourProgressStore].
  static const String id = 'compass';

  static const String phaseAnchor = 'compass_tour_phase';
  static const String questionAnchor = 'compass_tour_question';
  static const String nowAnchor = 'compass_tour_now';
  static const String somedayAnchor = 'compass_tour_someday';

  static const List<TourStep> steps = [
    TourStep(
      id: 'phase_intro',
      titleKey: 'tour_compass_phase_title',
      bodyKey: 'tour_compass_phase_body',
      primaryLabelKey: 'tour_compass_show_me',
      secondaryLabelKey: 'tour_compass_not_now',
    ),
    TourStep(
      id: 'phase_header',
      anchorId: phaseAnchor,
      titleKey: 'tour_compass_header_title',
      bodyKey: 'tour_compass_header_body',
    ),
    TourStep(
      id: 'question',
      anchorId: questionAnchor,
      titleKey: 'tour_compass_question_title',
      bodyKey: 'tour_compass_question_body',
    ),
    TourStep(
      id: 'now',
      anchorId: nowAnchor,
      titleKey: 'tour_compass_now_title',
      bodyKey: 'tour_compass_now_body',
    ),
    TourStep(
      id: 'someday',
      anchorId: somedayAnchor,
      titleKey: 'tour_compass_someday_title',
      bodyKey: 'tour_compass_someday_body',
    ),
  ];
}
