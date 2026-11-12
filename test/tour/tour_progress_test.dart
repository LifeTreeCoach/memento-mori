import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _start(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  TourProgressStore.clearCacheForTesting();
  await TourProgressStore.initialize();
}

void main() {
  test('nothing stored: no tour seen', () async {
    await _start({});
    expect(TourProgressStore.isSeen('compass'), isFalse);
  });

  test('markSeen round-trips through storage', () async {
    await _start({});
    await TourProgressStore.markSeen('compass');
    await TourProgressStore.markSeen('people');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(TourProgressStore.key),
        '{"seen":["compass","people"],"v":1}');

    TourProgressStore.clearCacheForTesting();
    await TourProgressStore.initialize();
    expect(TourProgressStore.isSeen('compass'), isTrue);
    expect(TourProgressStore.isSeen('people'), isTrue);
    expect(TourProgressStore.isSeen('life'), isFalse);
  });

  for (final bad in ['not json', '[1,2]', '{"seen":"x"}', '{"v":1}', '']) {
    test('unreadable value "$bad" counts as none seen', () async {
      await _start({TourProgressStore.key: bad});
      expect(TourProgressStore.isSeen('compass'), isFalse);
    });
  }

  test('decode keeps only string ids', () {
    expect(TourProgressStore.decode('{"seen":["a",3,null,"b"],"v":1}'),
        {'a', 'b'});
  });

  test('reset forgets everything', () async {
    await _start({});
    await TourProgressStore.markSeen('compass');
    await TourProgressStore.reset();
    final prefs = await SharedPreferences.getInstance();
    expect(TourProgressStore.isSeen('compass'), isFalse);
    expect(prefs.containsKey(TourProgressStore.key), isFalse);
  });

  test('revision bumps on changes only', () async {
    await _start({});
    final before = TourProgressStore.revision.value;
    await TourProgressStore.markSeen('compass');
    expect(TourProgressStore.revision.value, before + 1);
    await TourProgressStore.markSeen('compass');
    expect(TourProgressStore.revision.value, before + 1);
    await TourProgressStore.reset();
    expect(TourProgressStore.revision.value, before + 2);
  });
}
