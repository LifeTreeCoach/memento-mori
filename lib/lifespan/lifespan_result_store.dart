import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';

/// Where the result of the user's own lifespan estimate is kept. Only the
/// [LifespanResult] is persisted, never the answers of a [LifespanProfile].
abstract interface class LifespanResultStore {
  /// The kept result; null before the first applied estimate.
  LifespanResult? load();

  /// Keeps the result of [profile]; nothing is written before an estimate
  /// was applied.
  Future<void> save(LifespanProfile profile);
}

/// The user's own result under `lifespan_result` in [SettingsService].
class SettingsLifespanResultStore implements LifespanResultStore {
  const SettingsLifespanResultStore();

  @override
  LifespanResult? load() => SettingsService.getLifespanResult();

  @override
  Future<void> save(LifespanProfile profile) async {
    final applied = profile.applied;
    if (applied == null) return;
    await SettingsService.setLifespanResult(LifespanResult.of(applied));
  }
}
