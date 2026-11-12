import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 11, 12, 15, 30);

  Future<void> start(Map<String, Object> values, {DateTime? on}) async {
    SharedPreferences.setMockInitialValues(values);
    WeekMomentStore.clearCacheForTesting();
    await WeekMomentStore.initialize(today: on ?? today);
  }

  test('defaults: enabled, never shown, since today', () async {
    await start({});
    expect(WeekMomentStore.enabled, isTrue);
    expect(WeekMomentStore.lastShown, isNull);
    expect(WeekMomentStore.since, DateTime(2026, 11, 12));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(WeekMomentStore.sinceKey), '2026-11-12');
  });

  test('since is recorded only once', () async {
    await start({WeekMomentStore.sinceKey: '2026-10-01'});
    expect(WeekMomentStore.since, DateTime(2026, 10, 1));
    await WeekMomentStore.initialize(today: DateTime(2027, 1, 1));
    expect(WeekMomentStore.since, DateTime(2026, 10, 1));
  });

  test('enabled and lastShown round-trip', () async {
    await start({});
    final before = WeekMomentStore.revision.value;
    await WeekMomentStore.setEnabled(false);
    await WeekMomentStore.markShown(DateTime(2026, 11, 15, 19));
    expect(WeekMomentStore.revision.value, before + 2);

    WeekMomentStore.clearCacheForTesting();
    await WeekMomentStore.initialize(today: DateTime(2026, 12, 1));
    expect(WeekMomentStore.enabled, isFalse);
    expect(WeekMomentStore.lastShown, DateTime(2026, 11, 15));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(WeekMomentStore.lastShownKey), '2026-11-15');
  });

  test('resetForDiagnostics clears lastShown and moves since back', () async {
    await start({WeekMomentStore.lastShownKey: '2026-11-15'});
    await WeekMomentStore.resetForDiagnostics();
    expect(WeekMomentStore.lastShown, isNull);
    expect(WeekMomentStore.since, DateTime(2000, 1, 1));
  });

  test('before initialize: defaults, since today', () {
    WeekMomentStore.clearCacheForTesting();
    final now = DateTime.now();
    expect(WeekMomentStore.enabled, isTrue);
    expect(WeekMomentStore.lastShown, isNull);
    expect(WeekMomentStore.since, DateTime(now.year, now.month, now.day));
  });
}
