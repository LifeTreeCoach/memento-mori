import 'package:memento_mori_life_in_weeks/compass/ui/compass_tour.dart';
import 'package:memento_mori_life_in_weeks/friend_form/person_form_tour.dart';
import 'package:memento_mori_life_in_weeks/people/tour/people_tour.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';

/// The stored value of [TourProgressStore.key] with every tour seen.
String get allToursSeen => TourProgressStore.encode({
      CompassTour.id,
      PeopleTour.emptyId,
      PeopleTour.listId,
      PersonFormTour.id,
    });

/// Mock preferences entry that marks every tour seen, so tour overlays
/// stay out of tests about something else.
Map<String, Object> get toursSeenPrefs => {TourProgressStore.key: allToursSeen};

/// Re-reads the tour progress from the (freshly mocked) preferences.
Future<void> reloadTourProgress() async {
  TourProgressStore.clearCacheForTesting();
  await TourProgressStore.initialize();
}
