import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_due.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';

/// Everything the weekly moment reads from the app's services, in one
/// value: the launcher decides and builds the story from it alone.
class WeekMomentInputs {
  const WeekMomentInputs({
    required this.birthDate,
    required this.lifeExpectancyYears,
    required this.rhythm,
    this.anchor,
    required this.onboarded,
    required this.enabled,
    this.lastShown,
    required this.since,
    this.phases = const [],
    this.showPhases = true,
    this.userName = '',
  });

  /// Reads the settings, the moment's store and the Compass data.
  static Future<WeekMomentInputs> load() async {
    final compass = await CompassService.load();
    return WeekMomentInputs(
      birthDate: SettingsService.getBirthDate(),
      lifeExpectancyYears: SettingsService.getLifeExpectancyYears(),
      rhythm: ReminderService.rhythm(),
      anchor: SettingsService.getRhythmAnchor(),
      onboarded: SettingsService.hasCompletedOnboarding(),
      enabled: WeekMomentStore.enabled,
      lastShown: WeekMomentStore.lastShown,
      since: WeekMomentStore.since,
      phases: compass.phases,
      showPhases: SettingsService.getVisualizationSettings().showPhases,
      userName: SettingsService.getUserName(),
    );
  }

  final DateTime? birthDate;
  final int lifeExpectancyYears;
  final ReminderRhythm rhythm;
  final DateTime? anchor;
  final bool onboarded;
  final bool enabled;
  final DateTime? lastShown;
  final DateTime since;
  final List<LifePhase> phases;
  final bool showPhases;
  final String userName;

  bool get hasBirthDate => birthDate != null;

  PersonalAddress get address => PersonalAddress(userName);

  /// The latest reminder time at or before [now], if the rhythm has one.
  DateTime? latestReminder(DateTime now) =>
      WeekMomentDue.latestReminder(now, rhythm, anchor: anchor);

  /// Whether a tap on the reminder of [reminderDay] shows the moment.
  bool showsOnTap(DateTime reminderDay) => WeekMomentDue.showOnTap(
        enabled: enabled,
        hasBirthDate: hasBirthDate,
        lastShown: lastShown,
        reminderDay: reminderDay,
      );

  /// Whether opening the app at [now] catches the moment up.
  bool catchUpDue(DateTime now) => WeekMomentDue.catchUpDue(
        now: now,
        rhythm: rhythm,
        anchor: anchor,
        enabled: enabled,
        onboarded: onboarded,
        hasBirthDate: hasBirthDate,
        lastShown: lastShown,
        since: since,
      );

  /// The story on [today]; needs a [birthDate].
  WeekMomentStory storyOn(DateTime today) => WeekMomentStory.of(
        birthDate: birthDate!,
        lifeExpectancyYears: lifeExpectancyYears,
        today: WeekMomentDue.reminderDayOf(today),
        phases: phases,
        rhythm: rhythm,
        showPhases: showPhases,
      );
}
