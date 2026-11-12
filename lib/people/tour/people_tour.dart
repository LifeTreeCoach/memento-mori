import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// The two People tours (`tour_people_*` strings): one for the empty tab
/// (add, import, menu) and one once people are listed (reminders, groups,
/// a person, menu, add button).
abstract final class PeopleTour {
  /// Ids in the [TourProgressStore].
  static const String emptyId = 'people_empty';
  static const String listId = 'people_list';

  /// Pause before the list tour after people appeared (or adding / the
  /// import ended), so the list, a snackbar and the Add button settled.
  static const Duration settleDelay = Duration(milliseconds: 800);

  static const String addAnchor = 'people_tour_add';
  static const String importAnchor = 'people_tour_import';
  static const String menuAnchor = 'people_tour_menu';
  static const String remindersAnchor = 'people_tour_reminders';
  static const String groupsAnchor = 'people_tour_groups';
  static const String personAnchor = 'people_tour_person';
  static const String fabAnchor = 'people_tour_fab';

  static const TourStep _menu = TourStep(
    id: 'menu',
    anchorId: menuAnchor,
    titleKey: 'tour_people_menu_title',
    bodyKey: 'tour_people_menu_body',
  );

  static const List<TourStep> emptySteps = [
    TourStep(
      id: 'add',
      anchorId: addAnchor,
      titleKey: 'tour_people_add_title',
      bodyKey: 'tour_people_add_body',
    ),
    TourStep(
      id: 'import',
      anchorId: importAnchor,
      titleKey: 'tour_people_import_title',
      bodyKey: 'tour_people_import_body',
    ),
    _menu,
  ];

  /// The groups step drops out by itself when no group is in use (the
  /// filter bar, its anchor, is not built then).
  static const List<TourStep> listSteps = [
    TourStep(
      id: 'reminders',
      anchorId: remindersAnchor,
      titleKey: 'tour_people_reminders_title',
      bodyKey: 'tour_people_reminders_body',
    ),
    TourStep(
      id: 'groups',
      anchorId: groupsAnchor,
      titleKey: 'tour_people_groups_title',
      bodyKey: 'tour_people_groups_body',
    ),
    TourStep(
      id: 'person',
      anchorId: personAnchor,
      titleKey: 'tour_people_person_title',
      bodyKey: 'tour_people_person_body',
    ),
    _menu,
    TourStep(
      id: 'fab',
      anchorId: fabAnchor,
      titleKey: 'tour_people_fab_title',
      bodyKey: 'tour_people_fab_body',
    ),
  ];

  static String idFor({required bool empty}) => empty ? emptyId : listId;

  static List<TourStep> stepsFor({required bool empty}) =>
      empty ? emptySteps : listSteps;

  static List<TourStep> get allSteps => [...emptySteps, ...listSteps];
}
