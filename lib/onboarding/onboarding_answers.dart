import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result_store.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/settings/life_expectancy_sheet.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/widget_service.dart';

/// What the user tells the onboarding, kept until the flow is finished.
class OnboardingAnswers {
  OnboardingAnswers({
    this.birthDate,
    this.name = '',
    this.lifeExpectancyYears = LifeCalculator.defaultLifeExpectancyYears,
    this.language = 'en',
    this.lifespan = const LifespanProfile(),
    this.lifespanStore = const SettingsLifespanResultStore(),
  });

  /// Prefilled from earlier settings (e.g. restored preferences); the
  /// estimate starts without answers, they are never stored.
  factory OnboardingAnswers.fromSettings({
    LifespanResultStore lifespanStore = const SettingsLifespanResultStore(),
  }) => OnboardingAnswers(
    birthDate: SettingsService.getBirthDate(),
    name: SettingsService.getUserName(),
    lifeExpectancyYears: SettingsService.getLifeExpectancyYears(),
    language: SettingsService.getLanguage(),
    lifespanStore: lifespanStore,
  );

  DateTime? birthDate;
  String name;
  int lifeExpectancyYears;

  /// Prefilled from the device language; saved live when changed.
  String language;

  /// The lifespan estimate's answers, kept in memory for this session
  /// (back navigation); only its result is saved, once one was applied.
  LifespanProfile lifespan;

  /// Where the result of [lifespan] is saved (the user's own settings).
  final LifespanResultStore lifespanStore;

  /// A birth date is valid when it lies strictly before [today].
  bool hasValidBirthDate(DateTime today) {
    final date = birthDate;
    if (date == null) return false;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }

  static int clampLifeExpectancy(int years) =>
      years.clamp(minLifeExpectancyYears, maxLifeExpectancyYears);

  LifeCalculator calculator(DateTime today) => LifeCalculator(
    birthDate: birthDate!,
    lifeExpectancyYears: lifeExpectancyYears,
    now: today,
  );

  /// Persists the answers, rebuilds the app via [controller] (when present)
  /// and publishes the widget inputs once.
  Future<void> save(AppSettingsController? controller) async {
    SettingsService.setLanguage(language);
    SettingsService.setUserName(name.trim());
    SettingsService.setBirthDate(birthDate!);
    await SettingsService.setLifeExpectancyYears(lifeExpectancyYears);
    await lifespanStore.save(lifespan);
    controller?.reload();
    await WidgetService.publishInputs();
  }
}
