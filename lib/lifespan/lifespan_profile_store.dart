import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';

/// Where a [LifespanProfile] is kept (the user's own in the settings,
/// another person's elsewhere).
abstract interface class LifespanProfileStore {
  /// The stored profile; empty before the first estimate.
  LifespanProfile load();

  /// Keeps [profile]; nothing is written before an estimate exists.
  Future<void> save(LifespanProfile profile);
}

/// The user's own profile: the four `lifespan_*` keys in
/// [SettingsService] (`lifespan_country`, `lifespan_sex`,
/// `lifespan_answers`, `lifespan_estimate`).
class SettingsLifespanProfileStore implements LifespanProfileStore {
  const SettingsLifespanProfileStore();

  @override
  LifespanProfile load() => LifespanProfile(
    country: SettingsService.getLifespanCountry(),
    sex: SettingsService.getLifespanSex(),
    answers: SettingsService.getLifespanAnswers(),
    applied: SettingsService.getLifespanEstimate(),
  );

  @override
  Future<void> save(LifespanProfile profile) async {
    final applied = profile.applied;
    if (applied == null) return;
    await SettingsService.setLifespanCountry(profile.effectiveCountry!);
    await SettingsService.setLifespanSex(profile.effectiveSex!);
    await SettingsService.setLifespanAnswers(profile.answers);
    await SettingsService.setLifespanEstimate(applied);
  }
}
